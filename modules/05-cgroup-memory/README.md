# 05-cgroup-memory

Enables the kernel **cgroup memory controller** so Docker `mem_limit` /
`mem_reservation` actually take effect.

## Why this exists

Raspberry Pi OS ships with the memory cgroup controller **disabled** — the boot
cmdline contains `cgroup_disable=memory`. Without this fix, every container memory
limit is **silently ignored** (Docker prints "Your kernel does not support memory
limit capabilities ... Limitation discarded.") and a runaway process (e.g. a
SnapOtter AI job) could exhaust RAM and take down other containers.

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
