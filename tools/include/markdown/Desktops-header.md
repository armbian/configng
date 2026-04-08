Armbian desktop installation uses upstream meta-packages from Debian and Ubuntu repositories, making it distro-agnostic and independent of pre-built Armbian desktop packages.

**How it works:**

- Installs the desktop environment meta-package (e.g., `xfce4`, `gnome-session`) along with essential extras
- Tracks all newly installed packages so uninstall cleanly removes everything added on top of CLI, including dependencies
- Applies Armbian branding: wallpapers, icons, login screen theme, and default user settings
- Configures the display manager (LightDM, GDM3, or SDDM) with auto-login
- Installs Armbian Imager as an AppImage for writing OS images
- Sets up Profile Sync Daemon (psd) to keep browser profiles in RAM, reducing flash media wear
- Removes unnecessary bloat pulled in by meta-packages

**Networking:**

Desktop environments that require NetworkManager (e.g., GNOME) install it alongside the existing `systemd-networkd`. Wired Ethernet interfaces remain managed by `systemd-networkd`, while NetworkManager handles WiFi and VPN connections. This avoids disrupting existing network configuration.

**Supported desktops:**

| Desktop | Best for | Resources |
|---|---|---|
| XFCE | Single board computers, low-end hardware | ~300 MB RAM |
| GNOME | Modern desktops, touchscreen devices | ~800 MB RAM |
| Cinnamon | Users familiar with Windows layout | ~500 MB RAM |

!!! note "Switching desktops"

    Only one desktop environment should be installed at a time. Remove the current desktop before installing a different one to avoid package conflicts and mixed configurations.
