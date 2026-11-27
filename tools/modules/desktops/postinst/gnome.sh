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
# Build the favorites list dynamically — armbian-imager is only
# published for amd64/arm64 (see common.yaml mid-tier arch gate),
# so skip the shortcut on arches where the .desktop file isn't
# going to exist. Uses the file presence at postinst time as the
# single source of truth: if apt just installed armbian-imager,
# the .desktop is there; if it was stripped via tier_overrides,
# it isn't, and the favorites bar stays clean instead of showing
# a broken shortcut.
# Dock: the terminal, then the browsers that are installed. Ptyxis where
# the release ships it, else Terminator (still installed for splits).
if [ -f /usr/share/applications/org.gnome.Ptyxis.desktop ]; then
	favorites="'org.gnome.Ptyxis.desktop'"
else
	favorites="'terminator.desktop'"
fi
for app in chromium.desktop chromium-browser.desktop google-chrome.desktop; do
	if [ -f "/usr/share/applications/${app}" ]; then
		favorites="${favorites}, '${app}'"
	fi
done
# The armbian-imager package ships "Armbian Imager.desktop".
for app in armbian-imager.desktop "Armbian Imager.desktop"; do
	if [ -f "/usr/share/applications/${app}" ]; then
		favorites="${favorites}, '${app}'"
	fi
done

# Tray icons. Debian and Ubuntu use different UUIDs. GNOME skips a missing one.
extensions="'appindicatorsupport@rgcjonas.gmail.com', 'ubuntu-appindicators@ubuntu.com'"

# Tiling Shell replaces Ubuntu Tiling Assistant. Debian and Ubuntu do not
# package it, so get the build for this GNOME version from
# extensions.gnome.org. If the download fails, the image has no tiling.
tilingshell_uuid='tilingshell@ferrarodomenico.com'
tilingshell_dir="/usr/share/gnome-shell/extensions/${tilingshell_uuid}"
shell_ver=$(dpkg-query -W -f='${Version}' gnome-shell 2>/dev/null)
# Leading digits after the epoch: 1:43.9-1 -> 43, 48~beta-4 -> 48.
# Enable the extension only when the download, extraction and schemas all succeed.
tilingshell_ok=0
if [[ "${shell_ver#*:}" =~ ^([0-9]+) ]] &&
	python3 - "$tilingshell_uuid" "${BASH_REMATCH[1]}" "$tilingshell_dir" <<- 'PYEOF'
	import io, json, sys, urllib.request, zipfile
	uuid, shell, dest = sys.argv[1:]
	ego = "https://extensions.gnome.org"
	url = f"{ego}/extension-info/?uuid={uuid}&shell_version={shell}"
	info = json.load(urllib.request.urlopen(url, timeout=60))
	data = urllib.request.urlopen(ego + info["download_url"], timeout=120).read()
	zipfile.ZipFile(io.BytesIO(data)).extractall(dest)
	PYEOF
then
	[[ -f "${tilingshell_dir}/metadata.json" ]] &&
		glib-compile-schemas "${tilingshell_dir}/schemas" &&
		tilingshell_ok=1
fi
if [[ ${tilingshell_ok} == 1 ]]; then
	extensions="${extensions}, '${tilingshell_uuid}'"
else
	rm -rf "$tilingshell_dir"
	echo "Warning: Tiling Shell install failed, image has no tiling extension" >&2
fi

cat >> "$keys" <<- EOF

	[org/gnome/shell]
	favorite-apps = [${favorites}]
	enabled-extensions = [${extensions}]
	disabled-extensions = ['tiling-assistant@ubuntu.com']

	# Tiling Shell layouts. Layout 1 suits ultrawide screens: two stacked
	# tiles on each side, two equal columns in the center.
	[org/gnome/shell/extensions/tilingshell]
	layouts-json='[{"id":"Layout 1","tiles":[{"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0.22,"y":0,"width":0.28,"height":1,"groups":[2,5]},{"x":0.5,"y":0,"width":0.28,"height":1,"groups":[5,3]},{"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},{"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}]},{"id":"Layout 2","tiles":[{"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},{"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"Layout 4","tiles":[{"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},{"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}]}]'

	[org/gnome/settings-daemon/plugins/power]
	sleep-inactive-ac-timeout='0'

	# Clickpad right-click. Modern Lenovo / Dell / HP laptops use
	# clickpads (no separate physical buttons under the touchpad), and
	# GNOME's per-arch defaults sometimes leave new users without a
	# working right-click out of the box.
	#
	# tap-to-click=true: single-finger tap → left click.
	# click-method='areas': physical press in the bottom-right corner
	#                       of the touchpad → right-click. Verified
	#                       working on a current-gen Lenovo where the
	#                       'fingers' (two-finger tap) default did not
	#                       reliably trigger BTN_RIGHT.
	#
	# Alternative (single-valued, so only one of the two): swap the
	# line below to click-method='fingers' if you prefer two-finger
	# tap. The system-wide default here is just a default — users can
	# override per-account via 'gsettings set …' or GNOME Settings.
	[org/gnome/desktop/peripherals/touchpad]
	tap-to-click=true
	click-method='areas'

	[org/gnome/desktop/interface]
	icon-theme='Numix'

	[org/gnome/desktop/background]
	picture-uri='file:///usr/share/backgrounds/armbian/armbian18-Dre0x-Minum-light-3840x2160.jpg'
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

# Ptyxis defaults: the neutral GNOME palette instead of Ubuntu's, and
# the same transparency as Terminator. Users can still change both.
if [ -f /usr/share/applications/org.gnome.Ptyxis.desktop ]; then
	cat > /usr/share/glib-2.0/schemas/90_armbian-ptyxis.gschema.override <<- EOF
		[org.gnome.Ptyxis.Profile]
		palette='gnome'
		opacity=0.90
	EOF
fi

#compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then
	glib-compile-schemas /usr/share/glib-2.0/schemas
fi
