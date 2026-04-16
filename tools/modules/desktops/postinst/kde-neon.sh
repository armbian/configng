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

fi
