=== "What gets installed"

    - Steam client from the `linuxarm64` public-beta manifest, into `~/.local/share/Steam`
    - Proton-CachyOS and Proton-GE, the latest arm64 release of each
    - **Update Proton** later replaces both with their newest release
    - A desktop launcher that starts `steamrtarm64/steam`
    - FEX's official Arch rootfs, extracted to `~/.local/share/fex-emu/RootFS/ArchLinux` and linked from `/usr/share/guestos/fex-mesa` so x86_64 Linux games can start

    Host packages supply `libibus` and `libva`. The installer does not download the steamrt3 tarball. **Update Proton** also refreshes the FEX rootfs when FEX publishes a new image.

=== "First launch"

    When the desktop user already has a graphical session, install runs `steam -deckard -exitsteam` once so the client can bootstrap, then quits. The menu entry itself does not use `-deckard`.

    Over SSH, with no display, that pass is skipped. Launch Steam from the menu and sign in. The first game launch lets Steam download Steam Linux Runtime 4.0 for arm64.

=== "Remove and purge"

    - **Remove** deletes the client and the Proton trees. Games, userdata, and the FEX rootfs stay.
    - **Purge** deletes `~/.local/share/Steam`, `~/.steam`, the extracted FEX rootfs if this module created it, and a `libvpx.so.6` compatibility link if this module created it.
