# 05-cgroup-memory

Enables the kernel **cgroup memory controller** so Docker `mem_limit` /
`mem_reservation` actually take effect.

## Why this exists

The memory cgroup controller is **disabled** by a `cgroup_disable=memory` boot
arg. Without this fix, every container memory limit is **silently ignored**
(Docker prints "Your kernel does not support memory limit capabilities ...
Limitation discarded.") and a runaway process (e.g. a SnapOtter AI job) could
exhaust RAM and take down other containers.

> **Note on this machine:** the `cgroup_disable=memory` arg is **injected by the
> firmware** — it's in `/proc/device-tree/chosen/bootargs` but NOT in
> `cmdline.txt`. The firmware prepends its own args and appends `cmdline.txt`
> last, so adding `cgroup_enable=memory cgroup_memory=1` to `cmdline.txt`
> overrides it (kernel command line is last-wins). Verify after reboot.

## What it does

Edits the active boot cmdline (`/boot/firmware/cmdline.txt`, or `/boot/cmdline.txt`
on older layouts):
- removes `cgroup_disable=memory`
- adds `cgroup_enable=memory cgroup_memory=1`
- backs the file up to `*.bak` first; keeps it a single line.

**A reboot is required** for the change to take effect:

```sh
sudo reboot
```

Verify afterwards:

```sh
grep -w memory /sys/fs/cgroup/cgroup.controllers   # should print "... memory ..."
```

Idempotent: once the controller is active it does nothing and skips the reboot.
Runs early (`05`) so a fresh-machine `./install.sh` enables it before services
that rely on memory limits.
