#!/bin/bash
# Build the x86_64 FEX-Emu rootfs image (default.erofs) on an x86_64 Arch Linux
# host. Packages are installed with the host pacman configuration, which must
# have the multilib and archlinuxcn repos enabled.

set -euo pipefail

srcdir=$(dirname "$(realpath -- "$0")")
workdir=$srcdir/work
outdir=$srcdir/out

usage() {
  cat <<EOF
Usage: $0 [-w <workdir>] [-o <outdir>]

  -w <workdir>  Directory for the rootfs tree (default: $workdir)
  -o <outdir>   Directory for default.erofs and pkglist.txt (default: $outdir)
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

while getopts 'w:o:h' opt; do
  case $opt in
    w) workdir=$OPTARG ;;
    o) outdir=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
(( OPTIND > $# )) || { usage >&2; exit 1; }

(( EUID == 0 )) || die "must be run as root"
[[ $(uname -m) == x86_64 ]] || die "must be run on an x86_64 host"
command -v pacstrap >/dev/null || die "pacstrap not found, install arch-install-scripts"
command -v mkfs.erofs >/dev/null || die "mkfs.erofs not found, install erofs-utils"

repos=$(pacman-conf --repo-list)
for repo in multilib archlinuxcn; do
  grep -qx "$repo" <<< "$repos" || die "$repo repo is not enabled in the pacman configuration"
done

mapfile -t packages < <(sed 's/#.*//' "$srcdir/packages.x86_64" | xargs -n1)

mkdir -p "$workdir" "$outdir"
workdir=$(realpath -- "$workdir")
outdir=$(realpath -- "$outdir")
rootdir=$workdir/rootfs

if [[ -e $rootdir ]]; then
  if findmnt -rn -o TARGET | grep -q -- "^$rootdir/"; then
    die "something is still mounted under $rootdir"
  fi
  rm -rf --one-file-system "$rootdir"
fi
mkdir "$rootdir"

# -G/-M: don't copy the host keyring/mirrorlist, /etc is removed anyway.
pacstrap -G -M "$rootdir" "${packages[@]}"

find "$rootdir"/usr/bin -perm /6000 -delete
chmod +r "$rootdir"/usr/lib/dbus-daemon-launch-helper

# The pacman database is removed by the cleanup.
pacman -r "$rootdir" --dbpath "$rootdir/var/lib/pacman" -Q > "$outdir/pkglist.txt"

"$srcdir/cleanup.sh" "$rootdir"

rm -f "$outdir/default.erofs"
mkfs.erofs -x-1 -zlz4hc,12 "$outdir/default.erofs" "$rootdir"
