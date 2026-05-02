#!/bin/bash
set +e
# Bianbu is a GNOME variant (gdm3 / GNOME Shell). Branding is much
# narrower than the stock GNOME postinst — Bianbu ships its own
# opinionated favorites, theme, and panel config from SpacemiT, and
# we want to leave those alone. The only piece we override is the
# wallpaper, so an installed image actually looks like Armbian.
#
# picture-uri-dark is set explicitly because Bianbu defaults to dark
# mode under GNOME 46; without it the override only takes effect in
# light mode and the user keeps seeing Bianbu's stock background.

keys=/etc/dconf/db/local.d/00-bg
profile=/etc/dconf/profile/user

install -Dv /dev/null "$keys"
install -Dv /dev/null "$profile"

cat >> "$keys" <<- EOF

	[org/gnome/desktop/background]
	picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
	picture-uri-dark='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
	picture-options='zoom'
	primary-color='#456789'
	secondary-color='#FFFFFF'

	[org/gnome/desktop/screensaver]
	picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
	picture-options='zoom'
	primary-color='#456789'
	secondary-color='#FFFFFF'
EOF

echo "user-db:user
system-db:local" >> "$profile"

dconf update

if [ -d /usr/share/glib-2.0/schemas ]; then
	glib-compile-schemas /usr/share/glib-2.0/schemas
fi
