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

# Re-enable systemd suspend. SpacemiT ships a sleep.conf with
# AllowSuspend=no on the K1 so `systemctl suspend` fails with
# "Sleep verb 'suspend' is disabled by config". Suspend does work
# on shipped K1 boards (verified on musebook), so drop a drop-in
# that re-enables it. Path is sleep.conf.d/ so an upgrade of the
# Bianbu-shipped config doesn't clobber the override.
install -d /etc/systemd/sleep.conf.d
cat > /etc/systemd/sleep.conf.d/99-armbian-allow-suspend.conf <<- 'EOF'
	# Managed by armbian-config (module_desktops, bianbu postinst).
	# Re-enables suspend on Bianbu/K1 — SpacemiT's stock sleep.conf
	# disables it. Remove this file to fall back to the SpacemiT
	# default.
	[Sleep]
	AllowSuspend=yes
EOF
# Pick up the new value without forcing a daemon-reload that would
# disturb running units in the chrooted build environment; logind
# re-reads sleep.conf on each `systemctl suspend` invocation, so the
# override is live on first boot regardless.
