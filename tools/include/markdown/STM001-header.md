Native public-beta Steam for **arm64**. The installer downloads Valve's linuxarm64 client into the desktop user's home.

Native x86_64 Linux games use the FEX tool shipped with Steam. The installer extracts FEX's official Arch rootfs to `~/.local/share/fex-emu/RootFS/ArchLinux` and links it to `/usr/share/guestos/fex-mesa`, which is the path Steam's FEX tool uses. It does not install a separate FEX package.

Windows games use the FEX build shipped inside a Proton tree. Proton-CachyOS and Proton-GE are optional menu entries. Each installs the latest arm64 release into `compatibilitytools.d`.

Because the FEX guest path is system-wide, only one user per system can run x86_64 games through this setup.
