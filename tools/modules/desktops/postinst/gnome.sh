#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi
#if [ -f /etc/lightdm/slick-greeter.conf ]; then sed -i 's/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg/armbian-4k-black-psycho-gauss.jpg/g' /etc/lightdm/slick-greeter.conf; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

# set wallpapper to armbian
keys=/etc/dconf/db/local.d/00-bg
profile=/etc/dconf/profile/user

install -Dv /dev/null $keys
install -Dv /dev/null $profile

# set default shortcuts
echo "
[org/gnome/shell]
favorite-apps = ['terminator.desktop', 'org.gnome.Nautilus.desktop', 'armbian-imager.desktop']

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout='0'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
picture-options='zoom'
primary-color='#456789'
secondary-color='#FFFFFF'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
picture-options='zoom'
primary-color='#456789'
secondary-color='#FFFFFF'" >> $keys

echo "user-db:user
system-db:local" >> $profile

dconf update

# Hide Canonical's "Ubuntu" panel entry from the GNOME app grid.
# /usr/share/applications/gnome-ubuntu-panel.desktop is shipped by
# gnome-control-center on Ubuntu. It points at the icon
# preferences-ubuntu-panel which only exists in Ubuntu's icon theme,
# so on a non-Ubuntu-themed install (like Armbian) it renders as a
# broken grey-triangle icon labelled "Proxy" (the localized name of
# the panel) in the Activities overview.
#
# We can't remove the .desktop file directly because dpkg owns it
# and any gnome-control-center upgrade would put it back. Instead
# drop a hider stub at /usr/local/share/applications/, which the
# XDG spec gives precedence over /usr/share/applications/.
if [ -f /usr/share/applications/gnome-ubuntu-panel.desktop ]; then
	mkdir -p /usr/local/share/applications
	cat > /usr/local/share/applications/gnome-ubuntu-panel.desktop <<- 'HIDEEOF'
	[Desktop Entry]
	Type=Application
	NoDisplay=true
	Hidden=true
	HIDEEOF
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

#compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then
	glib-compile-schemas /usr/share/glib-2.0/schemas
fi
