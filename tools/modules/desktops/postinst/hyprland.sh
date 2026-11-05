#!/bin/bash
set +e

# Armbian defaults for Hyprland.
src="$(dirname "$(readlink -f "$0")")/../hyprland"

# System defaults. Replaced on every run; users override them in their
# own hyprland.conf, which sources this file first.
install -Dm644 "$src/hypr/armbian.conf" /etc/xdg/hypr/armbian.conf

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
	# Real users own their files.
	if [ "$home" != "/etc/skel" ]; then
		owner=$(stat -c '%U:%G' "$home")
		chown -R "$owner" "$home/.config/hypr" "$home/.config/waybar" \
			"$home/.config/mako" "$home/.config/fuzzel"
	fi
done
