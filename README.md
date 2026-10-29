# archcn-fex-emu-rootfs

Builds the x86_64 Arch Linux rootfs image used by [FEX-Emu](https://github.com/FEX-Emu/FEX)
on aarch64 hosts (`/usr/share/fex-emu/RootFS/default.erofs`).

All packages come from binary repos (core, extra, multilib, archlinuxcn); nothing
is built from the AUR. The rootfs contains no mesa drivers: `mesa-fex-dummy`
satisfies the dependencies, and the drivers are shipped separately as the
`mesa-fex-emu-overlay-{x86_64,i386}` overlay images so they can be updated
without rebuilding the rootfs.

The package list and cleanup are based on
[asahi-alarm/RootFS](https://github.com/asahi-alarm/RootFS) (`Configs/Arch.json`
and `Scripts/Arch/cleanup.sh`).

## Building

Requirements on the build host:

- x86_64 Arch Linux, run as root
- `arch-install-scripts` and `erofs-utils`
- `multilib` and `archlinuxcn` enabled in `/etc/pacman.conf`, with
  `archlinuxcn-keyring` installed

The host pacman configuration is used to install the packages.

```
sudo ./build.sh [-w <workdir>] [-o <outdir>]
```

The rootfs tree is created in `work/rootfs` and the outputs are written to `out/`:

- `default.erofs`: the rootfs image
- `pkglist.txt`: installed packages and versions

## Files

- `packages.x86_64`: packages to install
- `build.sh`: installs the packages with `pacstrap`, runs the cleanup and
  creates the erofs image
- `cleanup.sh`: removes everything FEX-Emu does not need from the tree
  (most of `/etc`, `/var`, `/usr/share`, `/usr/bin`, ...)
