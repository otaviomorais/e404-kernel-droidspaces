#!/usr/bin/env bash
# Package the built kernel into an AnyKernel3 flashable zip for alioth (POCO F3).
# Usage: package_anykernel.sh <kernel_dir> <anykernel_dir> <zip_name>
set -euo pipefail

KERNEL_DIR="${1:?kernel dir required}"
AK_DIR="${2:?anykernel dir required}"
ZIP_NAME="${3:?zip name required}"

# Track repo root (parent of KERNEL_DIR)
REPO_ROOT="$(cd "$KERNEL_DIR/.." && pwd)"

# Locate the kernel image (prefer Image.gz-dtb, then others)
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
if [ ! -f "$IMAGE" ]; then
  for img in Image Image.gz Image.gz-dtb; do
    if [ -f "$KERNEL_DIR/out/arch/arm64/boot/$img" ]; then
      IMAGE="$KERNEL_DIR/out/arch/arm64/boot/$img"
      break
    fi
  done
  if [ ! -f "$IMAGE" ]; then
    echo "ERROR: No kernel image found!"
    ls -la "$KERNEL_DIR/out/arch/arm64/boot/"
    exit 1
  fi
fi

DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb"

cd "$REPO_ROOT/$AK_DIR"

# Clean previous artifacts (stock AK3 root)
rm -f *.zip *.gz *.img
rm -rf dtb ALIOTH-* boot-files 2>/dev/null

# Stage kernel/dtbo with stock AK3 bare-name convention
IMGNAME=$(basename "$IMAGE")
cp "$REPO_ROOT/$IMAGE" "$IMGNAME" || { echo "copy failed for $IMAGE"; exit 1; }
[ -f "$REPO_ROOT/$DTBO" ] && cp "$REPO_ROOT/$DTBO" dtbo.img
[ -d "$REPO_ROOT/$DTB" ] && cp -r "$REPO_ROOT/$DTB" dtb/

echo "=== kernel image staged as: $IMGNAME ==="
ls -la "$IMGNAME" dtbo.img 2>/dev/null

# The stock osm0sis anykernel.sh is a Galaxy Nexus (tuna/omap) template.
# Replace it entirely with a minimal, correct alioth config.
cat > anykernel.sh << 'AKEOF'
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=E404-DroidSpaces by otaviomorais
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=alioth
device.name2=aliothin
device.name3=apollo
device.name4=alioth_eea
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

write_boot;
## end boot install
AKEOF

echo "=== anykernel.sh written for alioth ==="
grep -E "device.name1|BLOCK=|IS_SLOT_DEVICE=|do.devicecheck" anykernel.sh

cd "$REPO_ROOT/$AK_DIR"
zip -r9 "$REPO_ROOT/$ZIP_NAME" . -x '*.git*'

echo "=== Package created ==="
ls -lh "$REPO_ROOT/$ZIP_NAME"
