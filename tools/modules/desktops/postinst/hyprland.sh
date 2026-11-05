#!/bin/bash
set +e

# Armbian defaults for Hyprland.
src="$(dirname "$(readlink -f "$0")")/../hyprland"

# System defaults. Replaced on every run; users override them in their
# own hyprland.conf, which sources this file first.
install -Dm644 "$src/hypr/armbian.conf" /etc/xdg/hypr/armbian.conf
install -Dm755 "$src/bin/power-menu" /usr/lib/armbian/hyprland/power-menu
install -Dm755 "$src/bin/key-help" /usr/lib/armbian/hyprland/key-help

# Create a user file only if it does not exist: never overwrite edits.
user_file() {
	local home="$1" path="$2" from="$3"
	[ -e "$home/$path" ] && return 0
	mkdir -p "$(dirname "$home/$path")"
	if [ -f "$from" ]; then
		cp "$from" "$home/$path"
	else
		printf '%s\n' "$from" > "$home/$path"
	fi
}

# Helper entries that only clutter the application launcher.
hidden_apps="footclient foot-server uuctl thunar-settings"

for home in /etc/skel /home/*; do
	[ -d "$home" ] || continue
	user_file "$home" .config/hypr/hyprland.conf "# Your Hyprland settings. Values here override the Armbian defaults.
source = /etc/xdg/hypr/armbian.conf"
	user_file "$home" .config/hypr/hyprlock.conf "$src/hypr/hyprlock.conf"
	user_file "$home" .config/hypr/hypridle.conf "$src/hypr/hypridle.conf"
	user_file "$home" .config/waybar/config.jsonc "$src/waybar/config.jsonc"
	user_file "$home" .config/waybar/style.css "$src/waybar/style.css"
	user_file "$home" .config/mako/config "$src/mako/config"
	user_file "$home" .config/fuzzel/fuzzel.ini "$src/fuzzel/fuzzel.ini"
	user_file "$home" .config/foot/foot.ini "$src/foot/foot.ini"
	for app in $hidden_apps; do
		user_file "$home" ".local/share/applications/${app}.desktop" "[Desktop Entry]
Type=Application
Name=${app}
Hidden=true"
	done
	# Real users own their files.
	if [ "$home" != "/etc/skel" ]; then
		owner=$(stat -c '%U:%G' "$home")
		chown -R "$owner" "$home/.config/hypr" "$home/.config/waybar" \
			"$home/.config/mako" "$home/.config/fuzzel" "$home/.config/foot" \
			"$home/.local/share/applications"
		chown "$owner" "$home/.local" "$home/.local/share"
	fi
done
