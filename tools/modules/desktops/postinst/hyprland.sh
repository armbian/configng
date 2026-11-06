#!/bin/bash
set +e

# Debian forky and sid install the Omarchy port (armbian-hyprland-shell). It
# brings its own complete configuration: do not add the Waybar setup to it.
if dpkg-query -W -f='${db:Status-Abbrev}' armbian-hyprland-shell 2>/dev/null | grep -q '^ii'; then
	exit 0
fi

# Armbian defaults for Hyprland.
src="$(dirname "$(readlink -f "$0")")/../hyprland"

# System defaults. Replaced on every run; users override them in their
# own hyprland.conf, which sources this file first.
install -Dm644 "$src/hypr/armbian.conf" /etc/xdg/hypr/armbian.conf
install -Dm755 "$src/bin/power-menu" /usr/lib/armbian/hyprland/power-menu
install -Dm755 "$src/bin/key-help" /usr/lib/armbian/hyprland/key-help

# Create a user file only if it does not exist: never overwrite edits.
# Root reads the source; the owner writes the file, so a symlink in the
# home cannot redirect a root write.
user_file() {
	local home="$1" owner="$2" path="$3" from="$4"
	if [ -f "$from" ]; then
		cat "$from"
	else
		printf '%s\n' "$from"
	fi | runuser -u "$owner" -- sh -c '
		if [ -e "$1" ] || [ -L "$1" ]; then
			cat > /dev/null
			exit 0
		fi
		mkdir -p "$(dirname "$1")" && cat > "$1"' _ "$home/$path"
}

# Newer foot renamed the [colors] section to [colors-dark] and rejects
# the old name; older foot knows only [colors]. Use what this foot takes.
foot_ini=$(mktemp)
cp "$src/foot/foot.ini" "$foot_ini"
if ! foot --check-config -c "$foot_ini" > /dev/null 2>&1; then
	sed -i 's/^\[colors\]$/[colors-dark]/' "$foot_ini"
fi

# Helper entries that only clutter the application launcher.
hidden_apps="footclient foot-server uuctl thunar-settings"

for home in /etc/skel /home/*; do
	[ -d "$home" ] || continue
	if [ "$home" = "/etc/skel" ]; then
		owner=root
	else
		owner=$(stat -c '%U' "$home")
		# Only homes of regular users.
		[ "$owner" = "root" ] || [ "$owner" = "UNKNOWN" ] && continue
	fi
	user_file "$home" "$owner" .config/hypr/hyprland.conf "# Your Hyprland settings. Values here override the Armbian defaults.
source = /etc/xdg/hypr/armbian.conf"
	user_file "$home" "$owner" .config/hypr/hyprlock.conf "$src/hypr/hyprlock.conf"
	user_file "$home" "$owner" .config/hypr/hypridle.conf "$src/hypr/hypridle.conf"
	user_file "$home" "$owner" .config/waybar/config.jsonc "$src/waybar/config.jsonc"
	user_file "$home" "$owner" .config/waybar/style.css "$src/waybar/style.css"
	user_file "$home" "$owner" .config/mako/config "$src/mako/config"
	user_file "$home" "$owner" .config/fuzzel/fuzzel.ini "$src/fuzzel/fuzzel.ini"
	user_file "$home" "$owner" .config/foot/foot.ini "$foot_ini"
	for app in $hidden_apps; do
		user_file "$home" "$owner" ".local/share/applications/${app}.desktop" "[Desktop Entry]
Type=Application
Name=${app}
Hidden=true"
	done
done

rm -f "$foot_ini"
