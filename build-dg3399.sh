#!/bin/bash
set -e

#==============================================
# iStoreOS dg3399 one-key local build script
#==============================================

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$ROOT_DIR/../openwrt"
BOARD="dg3399"
REPO_URL="https://github.com/istoreos/istoreos.git"
REPO_BRANCH="istoreos-24.10"

echo "=============================================="
echo " iStoreOS dg3399 Local Build"
echo " ROOT:     $ROOT_DIR"
echo " OPENWRT:  $OPENWRT_DIR"
echo " BRANCH:   $REPO_BRANCH"
echo "=============================================="

#----------------------------------------------
# 1. Prepare openwrt source
#----------------------------------------------
if [ ! -d "$OPENWRT_DIR/.git" ]; then
  echo "[PREP] openwrt not found, cloning..."
  git clone "$REPO_URL" -b "$REPO_BRANCH" "$OPENWRT_DIR"
else
  echo "[PREP] openwrt exists"
  cd "$OPENWRT_DIR"
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD || true)"
  if [ "$CURRENT_BRANCH" != "$REPO_BRANCH" ]; then
    echo "WARNING: openwrt branch is '$CURRENT_BRANCH', expected '$REPO_BRANCH'"
    echo "         build will continue, but result may differ"
  fi
fi

cd "$OPENWRT_DIR"

#----------------------------------------------
# 2. feeds before update
#----------------------------------------------
echo "[1/8] diy-part1"
chmod +x "$ROOT_DIR/$BOARD/diy-part1.sh"
"$ROOT_DIR/$BOARD/diy-part1.sh"

#----------------------------------------------
# 3. feeds update & install
#----------------------------------------------
echo "[2/8] feeds update/install"
./scripts/feeds update -a
./scripts/feeds install -a

#----------------------------------------------
# 4. Load board config
#----------------------------------------------
echo "[3/8] load .config"
cp "$ROOT_DIR/$BOARD/.config" .config

#----------------------------------------------
# 5. diy-part2
#----------------------------------------------
echo "[4/8] diy-part2"
chmod +x "$ROOT_DIR/$BOARD/diy-part2.sh"
"$ROOT_DIR/$BOARD/diy-part2.sh"

#----------------------------------------------
# 6. Remove known bad packages
#----------------------------------------------
echo "[5/8] cleanup bad packages"
sed -i '/CONFIG_PACKAGE_luci-app-baidupcs-web=y/d' .config

#----------------------------------------------
# 7. defconfig
#----------------------------------------------
echo "[6/8] make defconfig"
make defconfig

#----------------------------------------------
# 8. download
#----------------------------------------------
echo "[7/8] make download"
make download -j8
find dl -size -1024c -delete

#----------------------------------------------
# 9. build
#----------------------------------------------
echo "[8/8] start compile"
make -j$(nproc)

echo "=============================================="
echo " BUILD FINISHED"
echo " Output:"
ls bin/targets/rockchip/armv8/ || true
echo "=============================================="
