#!/bin/sh
# Install the patched driver under its own name (nouveaupatched). The distro's Mesa is not touched:
# only programs started with LIBVA_DRIVER_NAME=nouveaupatched use it (see wrappers/).
# Undo: sudo ./install.sh --remove
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
cd "$(dirname "$0")"
D=$(for d in /usr/lib/x86_64-linux-gnu/dri /usr/lib64/dri /usr/lib/dri; do [ -f $d/nouveau_drv_video.so ] && echo $d && break; done)
[ -n "$D" ] || { echo "Cannot find the system nouveau_drv_video.so (install mesa-va-drivers)"; exit 1; }
if [ "$1" = --remove ]; then rm -f "$D/nouveaupatched_drv_video.so" "$D/nouveaupatched.MESA_VERSION"; echo "Removed."; exit 0; fi
install -m644 out/nouveau_drv_video.so "$D/nouveaupatched_drv_video.so"
install -m644 out/MESA_VERSION "$D/nouveaupatched.MESA_VERSION"
echo "Installed in $D for Mesa $(cat out/MESA_VERSION). Rebuild after a Mesa upgrade."
