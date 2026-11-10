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
