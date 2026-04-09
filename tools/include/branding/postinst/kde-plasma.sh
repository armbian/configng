#!/bin/bash
set +e

# Configure SDDM theme and wallpaper
# plasma-chili only works with X11 greeter (Ubuntu), skip on Wayland greeter (Trixie)
if [ -d /usr/share/sddm/themes/plasma-chili ] && [ -f /etc/sddm.conf ]; then
	# Ubuntu: has /etc/sddm.conf, uses X11 greeter
	cp /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg \
		/usr/share/sddm/themes/plasma-chili/components/artwork/background.jpg 2>/dev/null || true
	sed -i 's/^Current=.*/Current=plasma-chili/' /etc/sddm.conf
fi

# Set Armbian wallpaper as Plasma default
mkdir -p /etc/xdg
cat > /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc <<- 'PLASMAEOF'
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.desktopcontainment
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg
FillMode=1
PLASMAEOF

# Let NetworkManager coexist with systemd-networkd (only if networkd is active)
if command -v NetworkManager > /dev/null 2>&1 && systemctl is-active --quiet systemd-networkd 2>/dev/null; then
	mkdir -p /etc/NetworkManager/conf.d
	cat > /etc/NetworkManager/conf.d/10-armbian-unmanaged.conf <<- NMEOF
	[keyfile]
	unmanaged-devices=type:ethernet
	NMEOF
	systemctl restart NetworkManager 2>/dev/null || true
fi
