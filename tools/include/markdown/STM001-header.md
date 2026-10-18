Native public-beta Steam for **arm64**. The installer downloads Valve's linuxarm64 client, and the latest arm64 Proton-CachyOS and Proton-GE builds into the desktop user's home.

Windows games use the FEX build shipped inside those Proton trees. Native x86_64 Linux games use that same Steam FEX tool. The installer extracts FEX's official Arch rootfs to `~/.local/share/fex-emu/RootFS/ArchLinux` and links it to `/usr/share/guestos/fex-mesa`, which is the path Steam's FEX tool uses. It does not install a separate FEX package.

Because that path is system-wide, only one user per system can run x86_64 games through this setup.
