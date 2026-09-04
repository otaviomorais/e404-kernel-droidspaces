# E404 Kernel - Droidspaces Edition

Xiaomi SM8250 (Snapdragon 865/870) kernel based on [E404 Kernel](https://github.com/kvsnr113/xiaomi_sm8250_kernel_e404) with [Droidspaces](https://droidspaces.org) containerization support.

## Supported Device

| Device | Codename | SoC |
|--------|----------|-----|
| POCO F3 / Mi 11X / Redmi K40 | alioth | Snapdragon 870 |

## What is Droidspaces?

Droidspaces is a lightweight Linux containerization tool for Android that lets you run full Linux distributions (Ubuntu, Debian, Arch, Alpine, etc.) natively on your device.

## Droidspaces Fixes

This kernel applies a Kconfig fragment on top of the E404 defconfig with all required Droidspaces configs:

- `CONFIG_ANDROID_PARANOID_NETWORK=n` — Fixes container networking
- `CONFIG_CGROUP_DEVICE=y` — Container /dev setup
- `CONFIG_USER_NS=y` — Docker procfs fix
- `CONFIG_OVERLAY_FS=y`, `CONFIG_MEMCG=y`, `CONFIG_IP_SET=y`, and more

## Build

### Automatic (GitHub Actions)

Push to `main` or create a tag `v*` to trigger a build.

### Manual

```bash
git clone https://github.com/otaviomorais/e404-kernel-droidspaces.git
cd e404-kernel-droidspaces

# Clone kernel source + toolchain
git clone --depth=1 -b staging-bpf https://github.com/kvsnr113/xiaomi_sm8250_kernel_e404.git kernel
git clone --depth=1 https://github.com/nicman23/neutron-clang.git toolchain/clang
git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git AnyKernel3

export PATH="$(pwd)/toolchain/clang/bin:$PATH"

# Build
cd kernel
make -j$(nproc) O=out CC="ccache clang" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  LLVM=1 LLVM_IAS=1 vendor/alioth_defconfig

scripts/kconfig/merge_config.sh -m .config ../droidspaces.config
make -j$(nproc) O=out CC="ccache clang" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  LLVM=1 LLVM_IAS=1 olddefconfig

make -j$(nproc) O=out CC="ccache clang" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  LLVM=1 LLVM_IAS=1
```

## Known Issues

- **Systemd v258+**: Won't boot on 4.19 kernel. Use Ubuntu 22.04/24.04 or Debian 12/13.
- **Docker networking**: Use `--network=host` or `"iptables": false` in daemon.json.
- **Docker/Podman cgroup**: Use `cgroupfs` driver + `vfs` storage driver.
- **OverlayFS on f2fs**: Use rootfs.img mode instead of directory mode.

## Credits

- [kvsnr113](https://github.com/kvsnr113) — E404 Kernel
- [ravindu644](https://github.com/ravindu644) — Droidspaces
- [nicman23](https://github.com/nicman23) — Neutron Clang

## License

GPL v2
