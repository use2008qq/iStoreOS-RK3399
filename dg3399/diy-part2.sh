#!/bin/bash
set -e

#==============================================
# dg3399 diy-part2.sh (Local / CI compatible)
#==============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[dg3399] Using script dir: $SCRIPT_DIR"

#----------------------------------------------
# 1. Add dg3399 device definition (idempotent)
#----------------------------------------------
ARMV8_MK="target/linux/rockchip/image/armv8.mk"

if ! grep -q "rockchip_dg3399" "$ARMV8_MK"; then
cat >> "$ARMV8_MK" << 'EOF'

define Device/rockchip_dg3399
  DEVICE_VENDOR := Rockchip
  DEVICE_MODEL := DG3399
  SOC := rk3399
  UBOOT_DEVICE_NAME := dg3399-rk3399
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-ata-ahci kmod-rtl8821ae kmod-usb-net-rtl8152 wpad \
    brcmfmac-nvram-43455-sdio cypress-firmware-43455-sdio
endef
TARGET_DEVICES += rockchip_dg3399
EOF
echo "[dg3399] Device definition added"
else
echo "[dg3399] Device definition already exists, skip"
fi

#----------------------------------------------
# 2. Replace u-boot Makefile
#----------------------------------------------
cp -f "$SCRIPT_DIR/uboot-rockchip/Makefile" \
      package/boot/uboot-rockchip/Makefile

#----------------------------------------------
# 3. Copy u-boot patch
#----------------------------------------------
mkdir -p package/boot/uboot-rockchip/patches
cp -f "$SCRIPT_DIR/uboot-rockchip/patches/991-rk3399-dg3399-uboot.patch" \
      package/boot/uboot-rockchip/patches/

#----------------------------------------------
# 4. Copy kernel patch (auto-detect kernel ver)
#----------------------------------------------
KPATCH_DIR="$(ls -d target/linux/rockchip/patches-* | head -n1)"

if [ -z "$KPATCH_DIR" ]; then
  echo "[dg3399] ERROR: kernel patches dir not found"
  exit 1
fi

cp -f "$SCRIPT_DIR/kernel-rockchip/patches/991-rockchip-rk3399-dg3399-kernel.patch" \
      "$KPATCH_DIR/"

echo "[dg3399] Patches applied successfully"
