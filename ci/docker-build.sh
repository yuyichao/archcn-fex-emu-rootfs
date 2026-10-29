#!/bin/bash
# Run inside a privileged archlinux docker container with the repo as the
# working directory: set up the build host and build the rootfs.

set -euo pipefail

echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# Enable multilib and add archlinuxcn at the end. The image's pacman.conf comes
# from devtools and may not have a (commented out) multilib section.
sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' /etc/pacman.conf
if ! pacman-conf --repo-list | grep -qx multilib; then
  cat >> /etc/pacman.conf <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
fi
cat >> /etc/pacman.conf <<'EOF'

[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
EOF

pacman-key --init
pacman-key --populate archlinux
pacman-key --lsign-key farseerfc@archlinux.org
pacman -Sy --noconfirm archlinux-keyring
pacman -Su --noconfirm --needed archlinuxcn-keyring arch-install-scripts erofs-utils xz

./build.sh

xz -T0 out/default.erofs
