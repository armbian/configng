#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i /etc/pulse/default.pa; fi

# create i3 session file for LightDM
mkdir -p /usr/share/xsessions
if [ ! -f /usr/share/xsessions/i3.desktop ]; then
	cat > /usr/share/xsessions/i3.desktop <<- 'XSEOF'
	[Desktop Entry]
	Name=i3
	Comment=Improved tiling window manager
	Exec=/etc/X11/Xsession i3
	Type=Application
	XSEOF
fi

# set wallpaper and startup apps in i3 config
if [ -f /etc/i3/config ]; then
	# wallpaper
	grep -q "feh --bg-scale" /etc/i3/config || \
		echo "exec_always --no-startup-id feh --bg-scale /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg" >> /etc/i3/config
	# use terminator instead of default terminal
	sed -i 's/i3-sensible-terminal/terminator/g' /etc/i3/config
	# start nm-applet
	grep -q "nm-applet" /etc/i3/config || \
		echo "exec --no-startup-id nm-applet" >> /etc/i3/config
	# start dunst
	grep -q "dunst" /etc/i3/config || \
		echo "exec --no-startup-id dunst" >> /etc/i3/config
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
