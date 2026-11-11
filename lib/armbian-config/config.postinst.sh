#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi
#if [ -f /etc/lightdm/slick-greeter.conf ]; then sed -i 's/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg/armbian-4k-neon-gray-penguin-gauss.jpg/g' /etc/lightdm/slick-greeter.conf; fi

# Cinnamon defaults name gedit and eog, which are not installed.
# Without them, text opens in LibreOffice and images in GIMP. The Cinnamon
# session puts /usr/share/cinnamon first in XDG_DATA_DIRS, so this file
# overrides the packaged one. /etc/xdg/mimeapps.list stays in control.
rm -f /etc/xdg/x-cinnamon-mimeapps.list
install -d /usr/share/cinnamon/applications
cat > /usr/share/cinnamon/applications/x-cinnamon-mimeapps.list <<EOF
[Default Applications]
text/plain=org.gnome.TextEditor.desktop;
image/bmp=org.gnome.Loupe.desktop;viewnior.desktop;
image/gif=org.gnome.Loupe.desktop;viewnior.desktop;
image/jpeg=org.gnome.Loupe.desktop;viewnior.desktop;
image/png=org.gnome.Loupe.desktop;viewnior.desktop;
image/tiff=org.gnome.Loupe.desktop;viewnior.desktop;
image/webp=org.gnome.Loupe.desktop;viewnior.desktop;
EOF

# disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i /etc/pulse/default.pa; fi

##dconf desktop settings
keys=/etc/dconf/db/local.d/00-desktop
profile=/etc/dconf/profile/user

install -Dv /dev/null $keys
install -Dv /dev/null $profile

# gather dconf settings
# deconf dump org/nemo/ > nemo_backup
# deconf dump org/cinnamon/ > cinnamon_desktop_backup

echo "[org/nemo/list-view]
default-visible-columns=['name', 'size', 'type', 'date_modified', 'owner', 'permissions']

[org/nemo/preferences]
quick-renames-with-pause-in-between=true
show-advanced-permissions=true
show-compact-view-icon-toolbar=false
show-full-path-titles=true
show-hidden-files=true
show-home-icon-toolbar=true
show-icon-view-icon-toolbar=false
show-image-thumbnails='never'
show-list-view-icon-toolbar=false
show-new-folder-icon-toolbar=true
show-open-in-terminal-toolbar=true

[org/nemo/window-state]
geometry='800x550+550+244'
maximized=false
sidebar-bookmark-breakpoint=5

[org/cinnamon]
desklet-decorations=0
desktop-effects=false
enabled-applets=['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:show-desktop@cinnamon.org:1', 'panel1:left:2:grouped-window-list@cinnamon.org:2', 'panel1:right:0:systray@cinnamon.org:3', 'panel1:right:1:xapp-status@cinnamon.org:4', 'panel1:right:2:notifications@cinnamon.org:5', 'panel1:right:3:printers@cinnamon.org:6', 'panel1:right:4:removable-drives@cinnamon.org:7', 'panel1:right:5:keyboard@cinnamon.org:8', 'panel1:right:6:favorites@cinnamon.org:9', 'panel1:right:7:network@cinnamon.org:10', 'panel1:right:8:sound@cinnamon.org:11', 'panel1:right:9:power@cinnamon.org:12', 'panel1:right:10:calendar@cinnamon.org:13']
enabled-desklets=@as []
next-applet-id=14
panels-height=['1:33']
panels-resizable=['1:true']
startup-animation=false

[org/cinnamon/desktop/a11y/applications]
screen-keyboard-enabled=false
screen-reader-enabled=false

[org/cinnamon/desktop/a11y/mouse]
dwell-click-enabled=false
dwell-threshold=10
dwell-time=1.2
secondary-click-enabled=false
secondary-click-time=1.2

[org/cinnamon/desktop/background]
picture-options='zoom'
picture-uri='file:///usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
primary-color='#456789'
secondary-color='#FFFFFF'

[org/cinnamon/desktop/applications/terminal]
exec='/usr/bin/terminator'

[org/cinnamon/desktop/default-applications/terminal]
exec='/usr/bin/terminator'

[org/cinnamon/desktop/interface]
clock-show-date=true
cursor-theme='whiteglass'
gtk-theme='Numix'
icon-theme='Numix'
scaling-factor=uint32 0
toolkit-accessibility=false

[org/cinnamon/desktop/media-handling]
autorun-never=false

[org/cinnamon/desktop/screensaver]
picture-options='zoom'
picture-uri='file:///usr/share/backgrounds/armbian-lightdm/armbian03-Dre0x-Minum-dark-3840x2160'
primary-color='#456789'
secondary-color='#FFFFFF'

[org/cinnamon/desktop/wm/preferences]
num-workspaces=2
theme='Numix'

[org/cinnamon/settings-daemon/peripherals/touchpad]
disable-while-typing=true
horiz-scroll-enabled=false
motion-acceleration=5.4820717131474108
motion-threshold=2
natural-scroll=false
scroll-method='two-finger-scrolling'
three-finger-click=2
two-finger-click=3

[org/cinnamon/settings-daemon/plugins/power]
button-power='interactive'
critical-battery-action='hibernate'
idle-brightness=30
idle-dim-time=90
lid-close-ac-action='nothing'
lid-close-battery-action='nothing'
sleep-display-ac=600
sleep-display-battery=600
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org/cinnamon/settings-daemon/plugins/xsettings]
buttons-have-icons=true
menus-have-icons=true

[org/cinnamon/sounds]
login-enabled=false
logout-enabled=false
plug-enabled=false
switch-enabled=false
tile-enabled=false
unplug-enabled=false" >> $keys

echo "user-db:user
system-db:local" >> $profile

dconf update

#re-compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then glib-compile-schemas /usr/share/glib-2.0/schemas; fi

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

	# copy patched config to skel so users don't get the first-run wizard
	mkdir -p /etc/skel/.config/i3
	cp /etc/i3/config /etc/skel/.config/i3/config

	# also copy to existing users
	for home in /home/*; do
		user=$(basename "$home")
		if id "$user" > /dev/null 2>&1 && [ ! -f "$home/.config/i3/config" ]; then
			mkdir -p "$home/.config/i3"
			cp /etc/i3/config "$home/.config/i3/config"
			chown -R "$(id -u "$user"):$(id -g "$user")" "$home/.config/i3"
		fi
	done
fi

#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi
if [ -f /etc/lightdm/slick-greeter.conf ]; then sed -i 's/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg/armbian-4k-blue-circle-gauss.jpg/g' /etc/lightdm/slick-greeter.conf; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

#!/bin/bash
set +e
# Bianbu is a GNOME variant (gdm3 / GNOME Shell). Branding is much
# narrower than the stock GNOME postinst — Bianbu ships its own
# opinionated favorites, theme, and panel config from SpacemiT, and
# we want to leave those alone. The only piece we override is the
# wallpaper, so an installed image actually looks like Armbian.
#
# Both picture-uri (light) and picture-uri-dark (dark) are set
# explicitly. Bianbu defaults to dark mode under GNOME, and on
# GNOME 42+ the shell reads picture-uri-dark when the appearance is
# dark and ignores picture-uri entirely — without picture-uri-dark the
# Armbian override only takes effect in light mode and the user keeps
# seeing Bianbu's stock background. Light and dark Armbian variants
# track GNOME's color-scheme automatically.

keys=/etc/dconf/db/local.d/00-bg
profile=/etc/dconf/profile/user

install -Dv /dev/null "$keys"
install -Dv /dev/null "$profile"

cat >> "$keys" <<- EOF

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

#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi
#if [ -f /etc/lightdm/slick-greeter.conf ]; then sed -i 's/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg/armbian-4k-purplepunk-gauss.jpg/g' /etc/lightdm/slick-greeter.conf; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i /etc/pulse/default.pa; fi

##dconf desktop settings
keys=/etc/dconf/db/local.d/00-desktop
profile=/etc/dconf/profile/user

install -Dv /dev/null $keys
install -Dv /dev/null $profile

# gather dconf settings
# deconf dump org/nemo/ > nemo_backup
# deconf dump org/budgie/ > budgie_desktop_backup

echo "[org/nemo/desktop]
desktop-layout='true::false'
font='Noto Sans UI 11'

[org/nemo/list-view]
default-visible-columns=['name', 'size', 'type', 'date_modified', 'owner', 'permissions']

[org/nemo/preferences]
quick-renames-with-pause-in-between=true
show-advanced-permissions=true
show-compact-view-icon-toolbar=false
show-full-path-titles=true
show-hidden-files=true
show-home-icon-toolbar=true
show-icon-view-icon-toolbar=false
show-image-thumbnails='never'
show-list-view-icon-toolbar=false
show-new-folder-icon-toolbar=true
show-open-in-terminal-toolbar=true

[org/nemo/window-state]
geometry='800x550+550+244'
maximized=false
sidebar-bookmark-breakpoint=5

[org/gnome/desktop/background]
color-shading-type='solid'
picture-options='stretched'
picture-uri='file:////usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
primary-color='#008094'

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout='0'

[org/gnome/desktop/interface]
cursor-theme='DMZ-White'
document-font-name='Noto Sans UI 11'
font-name='Noto Sans UI 11'
gtk-im-module='gtk-im-context-simple'
gtk-theme='Numix'
icon-theme='LoginIcons'
monospace-font-name='Noto Mono 11'
toolkit-accessibility=false

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/armbian-lightdm/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg'

[org/cinnamon/desktop/applications/terminal]
exec='/usr/bin/terminator'

[org/cinnamon/desktop/default-applications/terminal]
exec='/usr/bin/terminator'

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'
num-workspaces=2
theme='Plata-Compact'
titlebar-font='Noto Sans UI Bold 11'

[org/ubuntubudgie/budgie-wpreviews]
allworkspaces=true
enable-previews=true" >> $keys

echo "user-db:user
system-db:local" >> $profile

dconf update

#re-compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then glib-compile-schemas /usr/share/glib-2.0/schemas; fi

#!/bin/bash
set +e

# Configure SDDM theme and wallpaper
# plasma-chili only works with X11 greeter (Ubuntu), skip on Wayland greeter (Trixie)
if [ -d /usr/share/sddm/themes/plasma-chili ] && [ -f /etc/sddm.conf ]; then
	# Ubuntu: has /etc/sddm.conf, uses X11 greeter
	cp /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg \
		/usr/share/sddm/themes/plasma-chili/components/artwork/background.jpg 2>/dev/null || true
	if grep -q '^Current=' /etc/sddm.conf; then
		sed -i 's/^Current=.*/Current=plasma-chili/' /etc/sddm.conf
	else
		sed -i '/^\[Theme\]/a Current=plasma-chili' /etc/sddm.conf
	fi
fi

# Set Armbian wallpaper for skel and users without existing config
for home in /etc/skel /home/*; do
	[ -d "$home" ] || continue
	# skip if user already has a Plasma config
	[ "$home" != "/etc/skel" ] && [ -f "$home/.config/plasma-org.kde.plasma.desktop-appletsrc" ] && continue
	mkdir -p "$home/.config"
	cat > "$home/.config/plasma-org.kde.plasma.desktop-appletsrc" <<- 'PLASMAEOF'
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
	# fix ownership for real users
	if [ "$home" != "/etc/skel" ]; then
		user=$(basename "$home")
		chown "$user:$user" "$home/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null
	fi
done

#!/bin/bash
set +e

# Armbian branding for KDE Plasma. System defaults only: users can
# still change everything.
wallpaper=/usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg
wallpaper_blurred=/usr/share/backgrounds/armbian-lightdm/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg
# Shipped by every armbian-bsp-cli package (packages/bsp/common).
logo=/usr/share/pixmaps/armbian-logo.svg

# SDDM: Breeze works with the Qt5 and the Qt6 greeter. Use the
# Armbian background.
if [ -d /usr/share/sddm/themes/breeze ]; then
	cat > /usr/share/sddm/themes/breeze/theme.conf.user <<- EOF
	[General]
	background=${wallpaper_blurred}
	EOF
fi

# Wallpaper and launcher logo. Plasma runs each update script once per
# user at login, so this also reaches existing users. It changes only
# values that are still at the Plasma default, so a user's own choice
# and the rest of the layout stay.
updates=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates
mkdir -p "$updates"
cat > "$updates/armbian-branding.js" <<- EOF
	desktops().forEach(function (d) {
		d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
		var image = d.readConfig("Image");
		if (d.wallpaperPlugin == "org.kde.image" && (!image || image.indexOf("/wallpapers/Next") >= 0)) {
			d.writeConfig("Image", "file://${wallpaper}");
		}
	});
	panels().forEach(function (p) {
		p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
			w.currentConfigGroup = ["General"];
			var icon = w.readConfig("icon");
			if (!icon || icon.indexOf("start-here") === 0) {
				w.writeConfig("icon", "${logo}");
			}
		});
	});
EOF

# Pin Armbian Imager to the panel. The package ships
# "Armbian Imager.desktop"; armbian-imager is only built for some arches.
for imager in armbian-imager.desktop "Armbian Imager.desktop"; do
	[ -f "/usr/share/applications/${imager}" ] || continue
	cat >> "$updates/armbian-branding.js" <<- EOF
	var imager = "applications:${imager}";
	panels().forEach(function (p) {
		p.widgets("org.kde.plasma.icontasks").forEach(function (w) {
			w.currentConfigGroup = ["General"];
			var l = w.readConfig("launchers");
			if (w.configKeys.indexOf("launchers") < 0) {
				// No key: the task manager default (Plasma main.xml).
				l = ["applications:systemsettings.desktop", "applications:org.kde.discover.desktop",
					"preferred://filemanager", "preferred://browser"];
			} else if (!l) {
				// The user removed all launchers.
				l = [];
			} else if (typeof l === "string") {
				l = l.split(",");
			}
			if (l.indexOf(imager) < 0) {
				l.push(imager);
				w.writeConfig("launchers", l);
			}
		});
	});
	EOF
	break
done

# Lock screen wallpaper.
cat > /etc/xdg/kscreenlockerrc <<- EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=file://${wallpaper}
EOF

# System Settings > About this System.
cat > /etc/xdg/kcm-about-distrorc <<- EOF
[General]
LogoPath=${logo}
Website=https://www.armbian.com
EOF

# No KDE splash: Plymouth goes straight to the desktop.
cat > /etc/xdg/ksplashrc <<- EOF
[KSplash]
Engine=none
Theme=None
EOF

# Debian kwallet-pam 6.7.4-3 adds pam_kwallet5 to common-auth. Then
# sudo and polkit ask for a password after a fingerprint match
# (Debian #1146345). SDDM loads pam_kwallet5 itself, so login still
# unlocks the wallet.
if [ -f /usr/share/pam-configs/kde-kwallet ]; then
	DEBIAN_FRONTEND=noninteractive pam-auth-update --disable kde-kwallet
fi

# An earlier version wrote a partial Plasma layout to /etc/skel. New
# users then got a desktop without a panel. Remove it.
skel_layout=/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
if [ -f "$skel_layout" ] && ! grep -q 'org.kde.panel' "$skel_layout"; then
	rm -f "$skel_layout"
fi

#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi
#if [ -f /etc/lightdm/slick-greeter.conf ]; then sed -i 's/armbian03-Dre0x-Minum-dark-blurred-3840x2160.jpg/armbian-4k-neglated-gauss.jpg/g' /etc/lightdm/slick-greeter.conf; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

#remove linked file
rm /etc/alternatives/deepin-default-background
ln -s /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg /etc/alternatives/deepin-default-background

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

cat >> "$keys" <<- EOF

	[org/gnome/shell]
	favorite-apps = [${favorites}]
	# Tray icons. Debian and Ubuntu use different UUIDs. GNOME skips a missing one.
	enabled-extensions = ['appindicatorsupport@rgcjonas.gmail.com', 'ubuntu-appindicators@ubuntu.com']

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

#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi


#Adjust xsettings.xml for NumixBlue Theme Ubuntu
if [ -f /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ]; then sed -i 's/Xfce-dusk/NumixBlue/g' /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml; fi

# Adjust menu
if [ -f /etc/xdg/menus/xfce-applications.menu ]; then
sed -i -n '/<Menuname>Settings<\/Menuname>/{p;:a;N;/<Filename>xfce4-session-logout.desktop<\/Filename>/!ba;s/.*\n/\
\t<Separator\/>\n\t<Merge type="all"\/>\n        <Separator\/>\n        <Filename>armbian-donate.desktop<\/Filename>\
\n        <Filename>armbian-support.desktop<\/Filename>\n/};p' /etc/xdg/menus/xfce-applications.menu
fi

# XFCE has no default applications list. Without it, PDF and images
# open in Chrome and text in LibreOffice Writer. The data directory keeps
# /etc/xdg/mimeapps.list in control.
install -d /usr/share/applications
cat > /usr/share/applications/xfce-mimeapps.list <<EOF
[Default Applications]
application/pdf=org.gnome.Papers.desktop;org.gnome.Evince.desktop;
text/plain=org.xfce.mousepad.desktop;
image/bmp=org.xfce.ristretto.desktop;viewnior.desktop;
image/gif=org.xfce.ristretto.desktop;viewnior.desktop;
image/jpeg=org.xfce.ristretto.desktop;viewnior.desktop;
image/png=org.xfce.ristretto.desktop;viewnior.desktop;
image/tiff=org.xfce.ristretto.desktop;viewnior.desktop;
image/webp=org.xfce.ristretto.desktop;viewnior.desktop;
EOF

# Hide few items
if [ -f /usr/share/applications/display-im6.q16.desktop ]; then mv /usr/share/applications/display-im6.q16.desktop /usr/share/applications/display-im6.q16.desktop.hidden; fi
if [ -f /usr/share/applications/display-im6.desktop ]; then  mv /usr/share/applications/display-im6.desktop /usr/share/applications/display-im6.desktop.hidden; fi
if [ -f /usr/share/applications/vim.desktop ]; then  mv /usr/share/applications/vim.desktop /usr/share/applications/vim.desktop.hidden; fi
if [ -f /usr/share/applications/libreoffice-startcenter.desktop ]; then mv /usr/share/applications/libreoffice-startcenter.desktop /usr/share/applications/libreoffice-startcenter.desktop.hidden; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi

# xmonad has no session autostart of its own, so the wallpaper, the status
# bar and the tray helpers are started from ~/.xprofile, which both the plain
# and the GNOME Flashback session read.
#
# Written from here rather than shipped in desktops/skel/: that directory is
# copied into /etc/skel wholesale for whichever desktop is installing
# (module_desktop_branding.sh), so a .xprofile placed there would start xmobar
# and friends under XFCE, GNOME and KDE too. The guard below is the second
# half of that -- it keeps the commands inert if some other desktop is
# installed alongside xmonad and inherits this file anyway.
#
# DESKTOP_SESSION is the .desktop basename: 'xmonad' or
# 'gnome-flashback-xmonad'. Matching on it rather than XDG_CURRENT_DESKTOP,
# which the flashback session sets to GNOME-Flashback:GNOME and so cannot be
# told apart from gnome-flashback-metacity.
mkdir -p /etc/skel
cat > /etc/skel/.xprofile <<- 'XPROFILEEOF'
	#!/bin/sh
	case "${DESKTOP_SESSION:-}" in
	*xmonad*)
		[ -x /usr/bin/feh ] && feh --bg-scale /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg &
		[ -x /usr/bin/xmobar ] && xmobar &
		[ -x /usr/bin/nm-applet ] && nm-applet &
		[ -x /usr/bin/dunst ] && dunst &
		;;
	esac
XPROFILEEOF
chmod 644 /etc/skel/.xprofile

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
unplug-enabled=false

[org/mate/panel/general]
object-id-list=['menu-bar', 'notification-area', 'clock', 'show-desktop-button', 'window-list', 'workspace-switcher']
toplevel-id-list=['top', 'bottom']

[org/mate/panel/toplevels/top]
expand=true
orientation='top'
size=24

[org/mate/panel/toplevels/bottom]
expand=true
orientation='bottom'
size=24

[org/mate/panel/objects/menu-bar]
locked=true
toplevel-id='top'
position=0
object-type='menu-bar'

[org/mate/panel/objects/notification-area]
locked=true
toplevel-id='top'
position=10
panel-right-stick=true
object-type='applet'
applet-iid='NotificationAreaAppletFactory::NotificationArea'

[org/mate/panel/objects/clock]
locked=true
toplevel-id='top'
position=0
panel-right-stick=true
object-type='applet'
applet-iid='ClockAppletFactory::ClockApplet'

[org/mate/panel/objects/show-desktop-button]
locked=true
toplevel-id='bottom'
position=0
object-type='applet'
applet-iid='WnckletFactory::ShowDesktopApplet'

[org/mate/panel/objects/window-list]
locked=true
toplevel-id='bottom'
position=1
object-type='applet'
applet-iid='WnckletFactory::WindowListApplet'

[org/mate/panel/objects/workspace-switcher]
locked=true
toplevel-id='bottom'
position=0
panel-right-stick=true
object-type='applet'
applet-iid='WnckletFactory::WorkspaceSwitcherApplet'" >> $keys

echo "user-db:user
system-db:local" >> $profile

dconf update

# System dconf database + gsettings schema override handle defaults
# for both new and existing users without touching user databases

# Override MATE default schema for wallpaper
mkdir -p /usr/share/glib-2.0/schemas
cat > /usr/share/glib-2.0/schemas/90-armbian-mate.gschema.override <<- 'GSEOF'
[org.mate.background]
picture-filename='/usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg'
picture-options='zoom'
primary-color='#456789'

[org.mate.interface]
gtk-theme='Numix'
icon-theme='Numix'

[org.mate.Marco.general]
theme='Numix'
num-workspaces=2

[org.mate.caja.desktop]
home-icon-visible=false
computer-icon-visible=false
trash-icon-visible=false
volumes-visible=false
GSEOF

#re-compile schemas
if [ -d /usr/share/glib-2.0/schemas ]; then glib-compile-schemas /usr/share/glib-2.0/schemas; fi

