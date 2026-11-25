#!/bin/sh
# Build the patched nouveau VA-API driver for the Mesa version your distro ships.
# Usage: ./build.sh [mesa-version]   (default: the installed mesa-va-drivers version)
# Needs the Mesa build dependencies (see README). Does not touch the system; result in ./out/.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
V=${1:-$(dpkg-query -W -f='${Version}' mesa-va-drivers 2>/dev/null | sed -E 's/^[0-9]+://; s/[-~+].*//')}
[ -n "$V" ] || { echo "Give the Mesa version, e.g. ./build.sh 25.2.8"; exit 1; }
W=${WORKDIR:-$HERE/work}; mkdir -p "$W"; cd "$W"
[ -d mesa-$V ] || { curl -fsSL -o mesa-$V.tar.xz https://archive.mesa3d.org/mesa-$V.tar.xz; tar xf mesa-$V.tar.xz; }
cd mesa-$V
for P in "$HERE"/patches/*.patch; do
  if patch -p1 --dry-run -s < "$P" >/dev/null 2>&1; then patch -p1 -s < "$P"
  elif patch -p1 -R --dry-run -s < "$P" >/dev/null 2>&1; then echo "($(basename "$P") already applied)"
  else echo "STOP: $(basename "$P") does not apply to Mesa $V. Please open an issue."; exit 2; fi
done
B=$W/build-$V
[ -d "$B" ] || ${MESON:-meson} setup "$B" -Dbuildtype=release -Db_ndebug=if-release \
  -Dgallium-drivers=nouveau -Dgallium-va=enabled -Dgallium-vdpau=disabled -Dvulkan-drivers= \
  -Dglx=disabled -Degl=disabled -Dgbm=disabled -Dgles1=disabled -Dgles2=disabled -Dopengl=false \
  -Dllvm=disabled -Dplatforms=x11 -Dvideo-codecs=all ${MESON_EXTRA:-}
ninja -C "$B"
so=$(find "$B" -name nouveau_drv_video.so -o -name libgallium_drv_video.so | head -1)
mkdir -p "$HERE/out"; strip -o "$HERE/out/nouveau_drv_video.so" "$so"
echo "$V" > "$HERE/out/MESA_VERSION"
echo "Built for Mesa $V: $HERE/out/nouveau_drv_video.so"
echo "Next: sudo ./install.sh"
