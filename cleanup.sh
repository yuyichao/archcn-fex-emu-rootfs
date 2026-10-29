#!/bin/bash
# Strip an installed rootfs down to what FEX-Emu needs.
#
# Ported from Scripts/Arch/cleanup.sh of asahi-alarm/RootFS, which is modeled
# on the Fedora FEX rootfs cleanup:
# https://pagure.io/fedora-kiwi-descriptions/blob/rawhide/f/config.sh
# https://pagure.io/fedora-kiwi-descriptions/blob/rawhide/f/fex-excludes.yaml

set -euo pipefail

if (( $# != 1 )); then
  echo "Usage: $0 <rootfs dir>" >&2
  exit 1
fi

root=$(realpath -- "$1")

# This deletes most of the tree, make sure we are pointed at the right one.
if [[ $root == / || ! -e $root/usr/lib/os-release ]]; then
  echo "$root does not look like a rootfs" >&2
  exit 1
fi
if findmnt -rn -o TARGET | grep -q -- "^$root/"; then
  echo "Something is still mounted under $root" >&2
  exit 1
fi

rm -rf "$root"/{boot,dev,home,media,mnt,opt,proc,root,run,srv,sys,tmp,var}

# rm everything in /usr/share except wine and mesa related stuff
find "$root"/usr/share -mindepth 1 -maxdepth 1 \
    \! -name wine -a \
    \! -name mesa-demos -a \
    \! -name drirc.d -a \
    \! -name glvnd -a \
    \! -name vulkan -a \
    \! -name licenses \
    -exec rm -rf {} +

# rm everything in /etc except ld stuff and OpenCL vendors
find "$root"/etc -mindepth 1 -maxdepth 1 \
    \! -name 'ld.so*' -a \
    \! -name OpenCL \
    -exec rm -rf {} +

# rm non-libs in lib
rm -rf "$root"/usr/lib/{locale,tmpfiles.d,systemd,modprobe.d,kbd,cmake}
rm -rf "$root"/usr/lib/python*

# rm misc stuff
rm -rf "$root"/usr/{include,games,local,src,tmp}

# Finally, remove most binaries except Wine stuff, Mesa stuff, the shell,
# path-related stuff, and system info tools.
find "$root"/usr/bin -mindepth 1 -maxdepth 1 \
    \! -name 'cat' -a \
    \! -name 'strace' -a \
    \! -name 'wine*' -a \
    \! -name 'mango*' -a \
    \! -name notepad -a \
    \! -name 'msi*' -a \
    \! -name regedit -a \
    \! -name regsvr32 -a \
    \! -name 'vulkan*' -a \
    \! -name 'vk*' -a \
    \! -name clinfo -a \
    \! -name 'eglinfo*' -a \
    \! -name 'glxinfo*' -a \
    \! -name 'egltri_*' -a \
    \! -name es2_info -a \
    \! -name 'es2gears_*' -a \
    \! -name es2tri -a \
    \! -name 'glxgears*' -a \
    \! -name vkgears -a \
    \! -name '*eglgears*' -a \
    \! -name 'xauth' -a \
    \! -name 'xeyes' -a \
    \! -name mesa-overlay-control.py -a \
    \! -name ulimit -a \
    \! -name ldd -a \
    \! -name ldconfig -a \
    \! -name env -a \
    \! -name sh -a \
    \! -name bash -a \
    \! -name ls -a \
    \! -name file -a \
    \! -name stat -a \
    \! -name dirname -a \
    \! -name realpath -a \
    \! -name readlink -a \
    \! -name basename -a \
    \! -name nproc -a \
    \! -name uname -a \
    \! -name arch \
    -exec rm -rf {} +
