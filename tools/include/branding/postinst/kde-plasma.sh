#!/bin/bash
set +e

# Configure SDDM theme
if [ -d /usr/share/sddm/themes/plasma-chili ]; then
	mkdir -p /etc/sddm.conf.d
	cat > /etc/sddm.conf.d/10-armbian-theme.conf <<- 'SDDMEOF'
	[Theme]
	Current=plasma-chili
	SDDMEOF
fi

# Set Armbian wallpaper as default for Plasma
mkdir -p /etc/xdg
cat > /etc/xdg/plasma-workspace-wallpaper.js <<- 'WPEOF'
var Desktops = desktops();
for (var i = 0; i < Desktops.length; i++) {
    var d = Desktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    d.writeConfig("Image", "file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg");
}
WPEOF

# Let NetworkManager coexist with systemd-networkd (only if networkd is active)
if command -v NetworkManager > /dev/null 2>&1 && systemctl is-active --quiet systemd-networkd 2>/dev/null; then
	mkdir -p /etc/NetworkManager/conf.d
	cat > /etc/NetworkManager/conf.d/10-armbian-unmanaged.conf <<- NMEOF
	[keyfile]
	unmanaged-devices=type:ethernet
	NMEOF
	systemctl restart NetworkManager 2>/dev/null || true
fi
