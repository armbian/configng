=== "What gets installed"

    **arm64**

    - Steam client from the `linuxarm64` public-beta manifest, into `~/.local/share/Steam`
    - A desktop launcher that starts `steamrtarm64/steam`
    - FEX's official Arch rootfs, extracted to `~/.local/share/fex-emu/RootFS/ArchLinux` and linked from `/usr/share/guestos/fex-mesa` so x86_64 Linux games can start
    - Proton-CachyOS and Proton-GE only when you choose those menu entries. Each installs the latest arm64 release and replaces an older copy of the same tool

    Host packages supply `libibus` and `libva`. The installer does not download the steamrt3 tarball. **Update Steam** refreshes the FEX rootfs when FEX publishes a new image, and updates a Proton tool only when that tool is already installed.

    **amd64**

    - Valve's `steam-launcher` package from `https://repo.steampowered.com/steam/`
    - `steam-libs-amd64` and `steam-libs-i386`
    - The i386 dpkg architecture, when it is not already enabled

    **Update Steam** upgrades those packages. The Steam client still updates itself after you launch it.

=== "First launch"

    On arm64, when the desktop user already has a graphical session, install runs `steam -deckard -exitsteam` once so the client can bootstrap, then quits. The menu entry itself does not use `-deckard`. Over SSH, with no display, that pass is skipped. Launch Steam from the menu and sign in. The first game launch lets Steam download Steam Linux Runtime 4.0 for arm64.

    On amd64, launch Steam from the menu and sign in. The official package downloads the client on that first launch.

=== "Remove and purge"

    - **Remove Proton-CachyOS** or **Remove Proton-GE** deletes that compatibility tool. These entries are arm64 only. Games and the Steam client stay. Each entry is shown only when that tool is installed.
    - **Remove** on arm64 deletes the client and any Proton-CachyOS or Proton-GE trees. Games, userdata, and the FEX rootfs stay. On amd64 it removes the `steam-launcher` package and the library metapackages. Games and userdata stay, and Valve's apt repository stays so a later install can use it.
    - **Purge** deletes `~/.local/share/Steam`, `~/.steam`, and, when this module created them, the extracted FEX rootfs and a `libvpx.so.6` compatibility link. On amd64 it also removes the launcher packages, Valve's apt source, and the repository key. The i386 architecture is not turned back off.
