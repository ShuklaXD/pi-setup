#!/usr/bin/env python3
"""sso-minter — hands the browser an app session cookie so you never see a login.

Cloudflare Access has already established who you are by the time a request
reaches this box (and on the LAN we treat the network as trusted). The apps
behind it, though, keep their own login forms and speak no SSO of any kind:
Portainer CE has no OIDC, Deluge has no header auth.

Caddy therefore routes a request here *only* when the browser is missing that
app's session cookie. We log in to the app ourselves with credentials from the
environment, then 302 the browser back to the URL it originally asked for,
carrying the app's Set-Cookie. Every request after that carries the cookie and
Caddy proxies it straight through — websockets, streaming and all — so nothing
in this process sits in the hot path.

Adding an app is a new entry in APPS plus a site block in the Caddyfile.
"""

import json
import os
import ssl
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LISTEN_PORT = int(os.environ.get("MINTER_PORT", "8000"))

# A freshly minted cookie is reused for this long. A page load fires many
# parallel requests and every one of them arrives here cookie-less; without this
# they would each drive a separate login against the upstream.
CACHE_TTL = int(os.environ.get("MINTER_CACHE_TTL", "60"))

# Breaks a redirect loop if the browser refuses the cookie we set.
GUARD_COOKIE = "sso_mint_attempt"

_insecure = ssl.create_default_context()
_insecure.check_hostname = False
_insecure.verify_mode = ssl.CERT_NONE


def _post_json(url, payload, timeout=15):
    """POST json, returning (status, body, [Set-Cookie, ...]). No redirects."""
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_insecure) as resp:
            return resp.status, resp.read(), resp.headers.get_all("Set-Cookie") or []
    except urllib.error.HTTPError as e:
        return e.code, e.read(), e.headers.get_all("Set-Cookie") or []


def _pick_cookie(set_cookies, name):
    """Return the raw Set-Cookie string for `name`, or None."""
    for raw in set_cookies:
        if raw.split("=", 1)[0].strip() == name:
            return raw
    return None


def mint_portainer():
    base = os.environ.get("PORTAINER_URL", "https://portainer:9443").rstrip("/")
    user = os.environ["PORTAINER_USER"]
    password = os.environ["PORTAINER_PASSWORD"]

    status, body, cookies = _post_json(
        f"{base}/api/auth", {"username": user, "password": password}
    )
    if status != 200:
        raise RuntimeError(f"portainer login returned {status}: {body[:200]!r}")

    raw = _pick_cookie(cookies, "portainer_api_key")
    if raw:
        return raw
    # Portainer only started setting the session cookie in 2.19. Older builds
    # hand the JWT back in the body under the same name the UI reads.
    jwt = json.loads(body or b"{}").get("jwt")
    if not jwt:
        raise RuntimeError("portainer login gave neither a cookie nor a jwt")
    return f"portainer_api_key={jwt}; Path=/; HttpOnly; SameSite=Strict"


def mint_deluge():
    base = os.environ.get("DELUGE_URL", "http://gluetun:8112").rstrip("/")
    password = os.environ["DELUGE_PASSWORD"]

    status, body, cookies = _post_json(
        f"{base}/json", {"method": "auth.login", "params": [password], "id": 1}
    )
    if status != 200:
        raise RuntimeError(f"deluge login returned {status}: {body[:200]!r}")
    # Deluge answers 200 with {"result": false} on a bad password.
    if json.loads(body or b"{}").get("result") is not True:
        raise RuntimeError("deluge rejected the password (check DELUGE_PASSWORD)")

    raw = _pick_cookie(cookies, "_session_id")
    if not raw:
        raise RuntimeError("deluge login set no _session_id cookie")
    return raw


APPS = {
    "portainer": {"cookie": "portainer_api_key", "mint": mint_portainer},
    "deluge": {"cookie": "_session_id", "mint": mint_deluge},
}

_cache = {}          # app -> (raw_set_cookie, minted_at)
_cache_lock = threading.Lock()


def cookie_for(app):
    """Mint (or reuse) the upstream session cookie for `app`."""
    with _cache_lock:
        hit = _cache.get(app)
        if hit and (time.time() - hit[1]) < CACHE_TTL:
            return hit[0]
        raw = APPS[app]["mint"]()
        _cache[app] = (raw, time.time())
        return raw


def rewrite_cookie(raw, secure):
    """Re-scope the upstream's cookie to the gateway's own origin.

    Domain is dropped so it defaults to whatever host the browser used (a
    subdomain over the tunnel, a LAN IP at home), Path is widened to the whole
    app, and Secure is kept only when the browser is actually on HTTPS —
    otherwise the LAN's plain-HTTP Deluge would silently discard it.
    """
    parts = [p.strip() for p in raw.split(";")]
    out = [parts[0]]
    seen = set()
    for attr in parts[1:]:
        key = attr.split("=", 1)[0].strip().lower()
        if key in ("domain", "path", "secure"):
            continue
        seen.add(key)
        out.append(attr)
    out.append("Path=/")
    if "samesite" not in seen:
        out.append("SameSite=Lax")
    if secure:
        out.append("Secure")
    return "; ".join(out)


class Handler(BaseHTTPRequestHandler):
    server_version = "sso-minter"
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        print("minter: " + (fmt % args), flush=True)

    def _send(self, status, body=b"", headers=()):
        self.send_response(status)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _fail(self, msg):
        self.log_message("%s", msg)
        self._send(
            502,
            (
                "SSO gateway could not log you in to this app automatically.\n\n"
                f"{msg}\n\n"
                "Check the credentials in modules/150-sso-gateway/.env, then:\n"
                "  docker restart sso-minter\n"
            ).encode(),
            [("Content-Type", "text/plain; charset=utf-8")],
        )

    def handle_request(self):
        app = self.headers.get("X-Sso-App", "")
        if app not in APPS:
            self._send(404, b"unknown app\n", [("Content-Type", "text/plain")])
            return

        # We only ever get here without the app cookie. If our own guard cookie
        # is already present, the last mint did not stick — redirecting again
        # would just spin the browser.
        if GUARD_COOKIE in (self.headers.get("Cookie") or ""):
            self._fail(
                f"the {app} session cookie was set but the browser did not send "
                "it back — check the clock, and that Secure/SameSite suit how "
                "you are reaching this page."
            )
            return

        try:
            raw = cookie_for(app)
        except Exception as exc:  # noqa: BLE001 — surfaced to the browser
            self._fail(f"{type(exc).__name__}: {exc}")
            return

        secure = self.headers.get("X-Forwarded-Proto", "http") == "https"
        self._send(
            302,
            b"",
            [
                ("Location", self.path),
                ("Set-Cookie", rewrite_cookie(raw, secure)),
                ("Set-Cookie", f"{GUARD_COOKIE}=1; Path=/; Max-Age=10; SameSite=Lax"),
            ],
        )

    do_GET = do_POST = do_HEAD = do_PUT = do_DELETE = do_PATCH = handle_request


if __name__ == "__main__":
    for app, cfg in APPS.items():
        print(f"minter: serving {app} (cookie {cfg['cookie']})", flush=True)
    ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), Handler).serve_forever()
