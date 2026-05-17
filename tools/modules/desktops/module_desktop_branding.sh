module_options+=(
	["module_desktop_branding,author"]="@igorpecovnik"
	["module_desktop_branding,feature"]="module_desktop_branding"
	["module_desktop_branding,desc"]="Install Armbian desktop branding assets"
	["module_desktop_branding,example"]="module_desktop_branding xfce"
	["module_desktop_branding,status"]="Active"
	["module_desktop_branding,arch"]="arm64 amd64 armhf riscv64"
)

#
# Install Armbian desktop branding (wallpapers, icons, greeter config, skel, postinst)
# Usage: module_desktop_branding <de_name>
#
function module_desktop_branding() {
	local de="$1"
	local desktop_dir="${desktops_dir}"

	case "$de" in
		help|"")
			echo "Usage: module_desktop_branding <de_name>"
			echo ""
			echo "Install Armbian branding assets for a desktop environment:"
			echo "  - Greeter configuration (LightDM, SDDM)"
			echo "  - Default user skeleton configs"
			echo "  - Wallpapers and login wallpapers"
			echo "  - Desktop icons and login logo"
			echo "  - GNOME wallpaper properties XML"
			echo "  - DE-specific post-install configuration"
			return 0
		;;
		*)
			if [[ ! -d "$desktop_dir" ]]; then
				echo "Warning: desktops directory not found at $desktop_dir" >&2
				return 0
			fi

			dialog_infobox "Desktop" "Installing Armbian branding for ${de}..."

			# greeter configuration (lightdm)
			if [[ -d "$desktop_dir/greeters/lightdm" ]]; then
				mkdir -p /etc/armbian/lightdm
				cp -R "$desktop_dir/greeters/lightdm/." /etc/armbian/lightdm/
				cp -R /etc/armbian/lightdm/. /etc/lightdm/ 2>/dev/null || true
			fi

			# default user skeleton
			if [[ -d "$desktop_dir/skel" ]]; then
				cp -R "$desktop_dir/skel/." /etc/skel/
			fi

			# wallpapers
			if [[ -d "$desktop_dir/branding/wallpapers" ]]; then
				mkdir -p /usr/share/backgrounds/armbian
				cp "$desktop_dir/branding/wallpapers/"*.jpg /usr/share/backgrounds/armbian/ 2>/dev/null || true
			fi

			# lightdm wallpapers
			if [[ -d "$desktop_dir/branding/wallpapers-lightdm" ]]; then
				mkdir -p /usr/share/backgrounds/armbian-lightdm
				cp "$desktop_dir/branding/wallpapers-lightdm/"*.jpg /usr/share/backgrounds/armbian-lightdm/ 2>/dev/null || true
			fi

			# desktop icons
			if [[ -d "$desktop_dir/branding/icons" ]]; then
				mkdir -p /usr/share/icons/armbian
				cp "$desktop_dir/branding/icons/"* /usr/share/icons/armbian/ 2>/dev/null || true
			fi

			# login logo
			if [[ -d "$desktop_dir/branding/pixmaps" ]]; then
				mkdir -p /usr/share/pixmaps/armbian
				cp "$desktop_dir/branding/pixmaps/"* /usr/share/pixmaps/armbian/ 2>/dev/null || true
			fi

			# Distributor logo for GNOME Settings -> About / KDE Info
			# Center / etc. is shipped by armbian-base-files (the same
			# package that sets LOGO="armbian-logo" in /etc/os-release).
			# Do NOT try to install it from here — keeping the icon
			# coupled to the os-release line in one .deb is the only
			# way to keep them in sync, and previous attempts to ship
			# it from here all silently failed for one icon-cache
			# reason or another.

			# Clean up any stray armbian-logo files left behind by
			# earlier (broken) versions of this branding step. Safe
			# even if armbian-base-files later ships its own.
			rm -f /usr/share/icons/hicolor/scalable/apps/armbian-logo.png
			rm -f /usr/share/icons/hicolor/128x128/apps/armbian-logo.png
			rm -f /usr/share/icons/hicolor/256x256/apps/armbian-logo.png

			# Browser / mail branding — system-wide policy files that
			# set the Armbian welcome page, homepage, and bookmarks for
			# browsers, and disable telemetry / studies for Mozilla apps.
			# Files for apps that aren't installed sit harmlessly in
			# /etc/<app>/policies/ (each app only reads its own dir at
			# startup). `recommended/` (Chromium-family) means the user
			# can change defaults after first run; Mozilla's policies.json
			# is a single combined file per app.
			# Single overlay tree under branding/browsers/etc/ rsync'd
			# into /etc/ — each app's canonical drop-in path:
			#   chromium:    /etc/chromium/policies/recommended/armbian.json   (homepage, first-run, etc.)
			#                /etc/chromium/policies/managed/armbian.json       (ManagedBookmarks — mandatory-only policy)
			#                /etc/chromium/master_preferences                  (suppress bundled defaults)
			#                /etc/chromium.d/armbian-flags                     (enable VPU hardware video decoder)
			#                /etc/chromium.d/armbian-widevine                  (WebGL fallback + Netflix CrOS UA spoof)
			#   chrome:      /etc/opt/chrome/policies/recommended/armbian.json
			#                /etc/opt/chrome/policies/managed/armbian.json
			#                /etc/opt/chrome/master_preferences
			#   firefox:     /etc/firefox/policies/policies.json
			#   firefox-esr: /etc/firefox-esr/policies/policies.json
			#   thunderbird: /etc/thunderbird/policies/policies.json
			#
			# master_preferences suppresses the bundled default bookmark
			# import on new profiles (xtradeb chromium ships Debian /
			# Ubuntu / XtraDeb shortcuts; Google Chrome ships its own
			# defaults). Existing profiles keep what they already have.
			# The Armbian "Managed bookmarks" folder still appears via
			# the policy file regardless — it lives in a separate read-
			# only space.
			if [[ -d "$desktop_dir/branding/browsers/etc" ]]; then
				# --no-preserve=ownership: keep mode + timestamps from the
				# source tree but always land as root:root in /etc/. Defends
				# against dev/test runs where the source files might be
				# owned by the developer's UID rather than root (in
				# production the deb deploys them as root anyway).
				cp -a --no-preserve=ownership "$desktop_dir/branding/browsers/etc/." /etc/
			fi

			# Parallel overlay under branding/browsers/usr/ — currently carries
			# /usr/bin/chromium.armbian, the Armbian-owned replacement for the
			# stock Chromium launcher. The stock wrapper word-splits
			# $CHROMIUM_FLAGS and cannot pass flags whose value contains
			# spaces (like --user-agent="..."), which makes
			# /etc/chromium.d/armbian-widevine's CrOS UA ineffective on its
			# own. Our wrapper is a near-identical drop-in that execs through
			# `eval` instead, preserving quoted values.
			if [[ -d "$desktop_dir/branding/browsers/usr" ]]; then
				cp -a --no-preserve=ownership "$desktop_dir/branding/browsers/usr/." /usr/
			fi

			# If we've shipped the Armbian Chromium wrapper and the chromium
			# package is installed, swap /usr/bin/chromium to point at it.
			# The swap uses dpkg-divert so a future `apt upgrade chromium`
			# lands the upstream wrapper in /usr/bin/chromium.upstream
			# instead of clobbering the symlink we created here.
			# Skipped inside containers / CI where dpkg is typically not
			# operational on the live rootfs.
			if [[ -x /usr/bin/chromium.armbian && -x /usr/bin/chromium ]] \
				&& command -v dpkg-divert >/dev/null 2>&1 \
				&& ! _desktop_in_container 2>/dev/null; then
				if ! dpkg-divert --list /usr/bin/chromium 2>/dev/null | grep -q "diversion of /usr/bin/chromium"; then
					dpkg-divert --local --rename \
						--divert /usr/bin/chromium.upstream \
						--add /usr/bin/chromium >/dev/null 2>&1 || true
				fi
				# The divert renamed the original file out of the way;
				# put our wrapper in its place as a symlink so future
				# updates to /usr/bin/chromium.armbian (via branding
				# re-runs) propagate automatically.
				if [[ ! -L /usr/bin/chromium || "$(readlink /usr/bin/chromium)" != "/usr/bin/chromium.armbian" ]]; then
					ln -sf /usr/bin/chromium.armbian /usr/bin/chromium
				fi
			fi

			# SDDM theme (for desktops using sddm)
			if [[ -d "$desktop_dir/greeters/sddm/themes" && "$DESKTOP_DM" == "sddm" ]]; then
				mkdir -p /usr/share/sddm/themes
				cp -R "$desktop_dir/greeters/sddm/themes/"* /usr/share/sddm/themes/ 2>/dev/null || true
			fi

			# DE-specific postinst script (skip inside containers / CI)
			if [[ -f "$desktop_dir/postinst/${de}.sh" ]]; then
				if _desktop_in_container 2>/dev/null; then
					echo "Skipping ${de} postinst (running inside container/CI)" >&2
				else
					dialog_infobox "Desktop" "Running ${de} post-install configuration..."
					bash "$desktop_dir/postinst/${de}.sh" || true
				fi
			fi
		;;
	esac
}
