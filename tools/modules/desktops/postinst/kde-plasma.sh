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
# user at login, so this also reaches existing users and keeps the
# rest of their layout.
updates=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates
mkdir -p "$updates"
cat > "$updates/armbian-branding.js" <<- EOF
desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://${wallpaper}");
});
panels().forEach(function (p) {
    p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
        w.currentConfigGroup = ["General"];
        w.writeConfig("icon", "${logo}");
    });
});
EOF

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

# An earlier version wrote a partial Plasma layout to /etc/skel. New
# users then got a desktop without a panel. Remove it.
skel_layout=/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
if [ -f "$skel_layout" ] && ! grep -q 'org.kde.panel' "$skel_layout"; then
	rm -f "$skel_layout"
fi
