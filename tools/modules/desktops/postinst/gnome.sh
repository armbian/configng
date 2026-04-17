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

# Clean up any leftover gnome-ubuntu-panel.desktop hider stub. An
# earlier version of this postinst dropped a NoDisplay=true stub at
# /usr/local/share/applications/gnome-ubuntu-panel.desktop to hide
# Canonical's broken-iconed "Ubuntu" panel entry from the GNOME app
# grid. The stub turned out to break gnome-control-center entirely:
# the panel is a gnome-control-center compiled-in descriptor, not a
# normal app launcher, and on startup the panel-walk asserts on the
# stub being a valid desktop file, abort()s, and Settings will not
# launch at all. Strip the stub if it exists.
rm -f /usr/local/share/applications/gnome-ubuntu-panel.desktop

#compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then
	glib-compile-schemas /usr/share/glib-2.0/schemas
fi
