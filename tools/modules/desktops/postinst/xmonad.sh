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
