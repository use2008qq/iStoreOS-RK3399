#!/bin/bash
set -e

#==============================================
# iStoreOS dg3399 one-key local build script
#==============================================

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$ROOT_DIR/../openwrt"
BOARD="dg3399"

echo "=============================================="
echo " iStoreOS dg3399 Local Build"
echo " ROOT: $ROOT_DIR"
echo " OPENWRT: $OPENWRT_DIR"
echo "=============================================="

#----------------------------------------------
# 1. Check openwrt source
#----------------------------------------------
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "ERROR: openwrt source not found"
  exit 1
fi

cd "$OPENWRT_DIR"

#----------------------------------------------
# 2. feeds before update
#----------------------------------------------
echo "[1/7] diy-part1"
chmod +x "$ROOT_DIR/$BOARD/diy-part1.sh"
"$ROOT_DIR/$BOARD/diy-part1.sh"

#----------------------------------------------
# 3. feeds update & install
#----------------------------------------------
echo "[2/7] feeds update/install"
./scripts/feeds update -a
./scripts/feeds install -a

#----------------------------------------------
# 4. Load board config
#----------------------------------------------
echo "[3/7] load .config"
cp "$ROOT_DIR/$BOARD/.config" .config

#----------------------------------------------
# 5. diy-part2
#----------------------------------------------
echo "[4/7] diy-part2"
chmod +x "$ROOT_DIR/$BOARD/diy-part2.sh"
"$ROOT_DIR/$BOARD/diy-part2.sh"

#----------------------------------------------
# 6. Remove known bad packages
#----------------------------------------------
echo "[5/7] cleanup bad packages"
sed -i '/CONFIG_PACKAGE_luci-app-baidupcs-web=y/d' .config

#----------------------------------------------
# 7. defconfig
#----------------------------------------------
echo "[6/7] make defconfig"
make defconfig

#----------------------------------------------
# 8. download
#----------------------------------------------
echo "[7/7] make download"
make download -j8
find dl -size -1024c -delete

#----------------------------------------------
# 9. build
#----------------------------------------------
echo "[BUILD] start compile"
make -j$(nproc)

echo "=============================================="
echo " BUILD FINISHED"
echo " Output:"
ls bin/targets/rockchip/armv8/ || true
echo "=============================================="
