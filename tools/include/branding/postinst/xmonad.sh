#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi

# create xmonad session file for LightDM
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/xmonad.desktop <<- 'XSEOF'
[Desktop Entry]
Name=Xmonad
Comment=Lightweight tiling window manager
Exec=/etc/X11/Xsession xmonad
Type=Application
DesktopNames=Xmonad
XSEOF

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

# set wallpaper via feh
mkdir -p /etc/xmonad
cat > /etc/xmonad/wallpaper.sh <<- 'WALLEOF'
#!/bin/bash
feh --bg-scale /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg
WALLEOF
chmod +x /etc/xmonad/wallpaper.sh

# Let NetworkManager coexist with systemd-networkd
if command -v NetworkManager > /dev/null 2>&1; then
	mkdir -p /etc/NetworkManager/conf.d
	cat > /etc/NetworkManager/conf.d/10-armbian-unmanaged.conf <<- NMEOF
	[keyfile]
	unmanaged-devices=type:ethernet
	NMEOF
	systemctl restart NetworkManager 2>/dev/null || true
fi
