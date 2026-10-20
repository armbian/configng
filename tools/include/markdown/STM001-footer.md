=== "What gets installed"

    - Steam client from the `linuxarm64` public-beta manifest, into `~/.local/share/Steam`
    - A desktop launcher that starts `steamrtarm64/steam`
    - FEX's official Arch rootfs, extracted to `~/.local/share/fex-emu/RootFS/ArchLinux` and linked from `/usr/share/guestos/fex-mesa` so x86_64 Linux games can start
    - Proton-CachyOS and Proton-GE only when you choose those menu entries. Each installs the latest arm64 release and replaces an older copy of the same tool

    Host packages supply `libibus` and `libva`. The installer does not download the steamrt3 tarball. **Update FEX and Proton** refreshes the FEX rootfs when FEX publishes a new image, and updates a Proton tool only when that tool is already installed.

=== "First launch"

    When the desktop user already has a graphical session, install runs `steam -deckard -exitsteam` once so the client can bootstrap, then quits. The menu entry itself does not use `-deckard`.

    Over SSH, with no display, that pass is skipped. Launch Steam from the menu and sign in. The first game launch lets Steam download Steam Linux Runtime 4.0 for arm64.

=== "Remove and purge"

    - **Remove Proton-CachyOS** or **Remove Proton-GE** deletes that compatibility tool. Games and the Steam client stay. Each entry is shown only when that tool is installed.
    - **Remove** deletes the client and any Proton-CachyOS or Proton-GE trees. Games, userdata, and the FEX rootfs stay.
    - **Purge** deletes `~/.local/share/Steam`, `~/.steam`, the extracted FEX rootfs if this module created it, and a `libvpx.so.6` compatibility link if this module created it.
