#!/bin/bash
set +e

# Configure SDDM theme and wallpaper
mkdir -p /etc/sddm.conf.d
if [ -d /usr/share/sddm/themes/plasma-chili ]; then
	# Set plasma-chili theme with Armbian wallpaper
	cp /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg \
		/usr/share/sddm/themes/plasma-chili/components/artwork/background.jpg 2>/dev/null || true

	if [ -f /etc/sddm.conf ]; then
		sed -i 's/^Current=.*/Current=plasma-chili/' /etc/sddm.conf
	else
		cat > /etc/sddm.conf.d/10-armbian-theme.conf <<- 'SDDMEOF'
		[Theme]
		Current=plasma-chili
		SDDMEOF
	fi
fi

# For Wayland greeter (Trixie), set background via Plasma greeter config
if command -v kwriteconfig6 > /dev/null 2>&1 || command -v kwriteconfig5 > /dev/null 2>&1; then
	mkdir -p /var/lib/sddm/.config
	cat > /var/lib/sddm/.config/kdeglobals <<- 'KDEEOF'
	[General]
	ColorScheme=BreezeDark
	KDEEOF
	chown -R sddm:sddm /var/lib/sddm/.config 2>/dev/null || true
fi

# Let NetworkManager coexist with systemd-networkd (only if networkd is active)
if command -v NetworkManager > /dev/null 2>&1 && systemctl is-active --quiet systemd-networkd 2>/dev/null; then
	mkdir -p /etc/NetworkManager/conf.d
	cat > /etc/NetworkManager/conf.d/10-armbian-unmanaged.conf <<- NMEOF
	[keyfile]
	unmanaged-devices=type:ethernet
	NMEOF
	systemctl restart NetworkManager 2>/dev/null || true
fi
