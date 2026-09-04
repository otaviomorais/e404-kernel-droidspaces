# E404 Kernel - Droidspaces Edition

Xiaomi SM8250 (Snapdragon 865/870) kernel based on [E404 Kernel](https://github.com/kvsnr113/xiaomi_sm8250_kernel_e404) with [Droidspaces](https://droidspaces.org) containerization support.

## What is Droidspaces?

Droidspaces is a lightweight Linux containerization tool for Android that lets you run full Linux distributions (Ubuntu, Debian, Arch, Alpine, etc.) natively on your Android device — without chroot, without Termux.

## Supported Devices

| Device | Codename | Android |
|--------|----------|---------|
| Xiaomi Mi 10 | umi | MIUI/HyperOS/AOSP |
| Xiaomi Mi 10 Pro | cmi | MIUI/HyperOS/AOSP |
| Xiaomi Mi 10 Ultra | cas | MIUI/HyperOS/AOSP |
| Xiaomi Mi 10T / Redmi K30S | apollo | MIUI/HyperOS/AOSP |
| Xiaomi Mi 11X / POCO F3 / Redmi K40 | alioth | MIUI/HyperOS/AOSP |
| Xiaomi 10S | thyme | MIUI/HyperOS/AOSP |
| Redmi K30 Pro / POCO F2 Pro | lmi | MIUI/HyperOS/AOSP |
| Redmi K40S / POCO F4 | munch | MIUI/HyperOS/AOSP |
| Xiaomi Pad 5 Pro | elish | MIUI/HyperOS/AOSP |
| Xiaomi Pad 5 Pro 5G | enuma | MIUI/HyperOS/AOSP |
| Xiaomi Pad 6 | pipa | MIUI/HyperOS/AOSP |

## Droidspaces Fixes Applied

This kernel includes the following config fixes for full Droidspaces compatibility:

### Critical Fixes
- `CONFIG_ANDROID_PARANOID_NETWORK=n` — Fixes "socket: permission denied" networking
- `CONFIG_CGROUP_DEVICE=y` — Fixes container /dev setup
- `CONFIG_USER_NS=y` — Fixes Docker unsafe procfs errors

### Namespace & Cgroup
- `CONFIG_POSIX_MQUEUE=y` — IPC message queue support
- `CONFIG_CGROUP_PIDS=y` — PID cgroup tracking
- `CONFIG_MEMCG=y` — Memory cgroup limits per container
- `CONFIG_FAIR_GROUP_SCHED=y` — Fair CPU scheduling between containers

### Filesystem
- `CONFIG_OVERLAY_FS=y` — Volatile mode support
- `CONFIG_TMPFS_POSIX_ACL=y` — POSIX ACL on tmpfs (NixOS support)
- `CONFIG_TMPFS_XATTR=y` — Extended attributes on tmpfs

### Networking (NAT mode)
- `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y` — Address type matching
- `CONFIG_NETFILTER_XT_TARGET_MASQUERADE=y` — NAT masquerade
- `CONFIG_NF_CONNTRACK_NETLINK=y` — Connection tracking netlink

### Firewall (UFW/Fail2ban)
- `CONFIG_IP_SET=y` + hash modules
- `CONFIG_NETFILTER_XT_MATCH_*` — Comment, conntrack, multiport, etc.
- `CONFIG_NETFILTER_XT_TARGET_REJECT/LOG/NFLOG`

## Build

### Automatic (GitHub Actions)

Push to `main` or create a tag `v*` to trigger automatic builds for all devices.

### Manual Build

```bash
# Clone this repo
git clone --depth=1 https://github.com/otaviomorais/e404-kernel-droidspaces.git
cd e404-kernel-droidspaces

# Clone E404 source
git clone --depth=1 -b staging-bpf https://github.com/kvsnr113/xiaomi_sm8250_kernel_e404.git kernel

# Apply Droidspaces fixes
bash patches/droidspaces-defconfig-fix.sh kernel/arch/arm64/configs/vendor

# Setup toolchain
git clone --depth=1 https://github.com/nicman23/neutron-clang.git toolchain/clang
export PATH="$(pwd)/toolchain/clang/bin:$PATH"

# Build (example: POCO F4 / munch)
cd kernel
make ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 \
  O=out vendor/munch_defconfig

make -j$(nproc) ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 O=out
```

## Known Issues

1. **Systemd v258+**: Modern distros (Arch, Fedora) with systemd >= v258 won't boot on this 4.19 kernel. Use Ubuntu 22.04/24.04 or Debian 12/13.
2. **Docker networking**: Use `--network=host` or set `"iptables": false` in Docker daemon.json to avoid nf_tables conflicts.
3. **Docker/Podman cgroup**: Configure Docker to use `cgroupfs` driver and `vfs` storage driver (BPF_CGROUP_DEVICE not available on 4.19).
4. **OverlayFS on f2fs**: Use rootfs.img mode (`--rootfs-img=`) instead of directory mode on /data (f2fs).

## Credits

- [kvsnr113](https://github.com/kvsnr113) — E404 Kernel
- [ravindu644](https://github.com/ravindu644) — Droidspaces
- [nicman23](https://github.com/nicman23) — Neutron Clang toolchain

## License

GPL v2 (same as Linux kernel)
