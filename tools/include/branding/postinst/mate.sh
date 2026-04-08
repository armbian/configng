#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi

# disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i /etc/pulse/default.pa; fi

##dconf desktop settings
keys=/etc/dconf/db/local.d/00-desktop
profile=/etc/dconf/profile/user

install -Dv /dev/null $keys
install -Dv /dev/null $profile

echo "[org/mate/desktop/background]
picture-options='zoom'
picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
primary-color='#456789'
secondary-color='#FFFFFF'

[org/mate/desktop/applications/terminal]
exec='/usr/bin/terminator'

[org/mate/desktop/default-applications/terminal]
exec='/usr/bin/terminator'

[org/mate/desktop/interface]
clock-show-date=true
cursor-theme='DMZ-White'
gtk-theme='Numix'
icon-theme='Numix'
scaling-factor=uint32 0
toolkit-accessibility=false

[org/mate/desktop/screensaver]
picture-options='zoom'
picture-uri='file:///usr/share/backgrounds/armbian-lightdm/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg'
primary-color='#456789'
secondary-color='#FFFFFF'

[org/mate/desktop/wm/preferences]
num-workspaces=2
theme='Numix'

[org/mate/settings-daemon/plugins/power]
button-power='interactive'
lid-close-ac-action='nothing'
lid-close-battery-action='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org/mate/settings-daemon/plugins/xsettings]
buttons-have-icons=true
menus-have-icons=true

[org/mate/sounds]
login-enabled=false
logout-enabled=false
plug-enabled=false
switch-enabled=false
tile-enabled=false
unplug-enabled=false" >> $keys

echo "user-db:user
system-db:local" >> $profile

dconf update

# Clear user-level dconf overrides so system defaults apply (wallpaper, theme, etc.)
for home in /home/*; do
	[ -d "$home/.config/dconf" ] && rm -f "$home/.config/dconf/user" 2>/dev/null
done

# Let NetworkManager coexist with systemd-networkd
if command -v NetworkManager > /dev/null 2>&1; then
	mkdir -p /etc/NetworkManager/conf.d
	cat > /etc/NetworkManager/conf.d/10-armbian-unmanaged.conf <<- NMEOF
	[keyfile]
	unmanaged-devices=type:ethernet
	NMEOF
	systemctl restart NetworkManager 2>/dev/null || true
fi

#re-compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then glib-compile-schemas /usr/share/glib-2.0/schemas; fi
