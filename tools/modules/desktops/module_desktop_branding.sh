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

			# Distributor logo for GNOME Settings -> About (and any
			# other DE that reads LOGO= from /etc/os-release).
			#
			# /etc/os-release on Armbian sets LOGO="armbian-logo".
			# gnome-control-center 46's setup_os_logo() in
			# panels/system/about/cc-about-page.c builds an array
			# of icon NAME candidates from LOGO=:
			#   armbian-logo-text-dark
			#   armbian-logo-text
			#   armbian-logo-dark
			#   armbian-logo
			# and resolves them via gtk_icon_theme_lookup_by_gicon()
			# at 192px against the hicolor theme. No path heuristic,
			# no fallback to ID=, just the icon-theme lookup.
			#
			# We have to install the icon under a hicolor directory
			# whose entry in /usr/share/icons/hicolor/index.theme is
			# kind to PNGs at arbitrary sizes. The scalable/apps
			# directory accepts any PNG and is always indexed.
			# Sized directories like 128x128/apps validate that the
			# file's actual pixel dimensions match the directory
			# name, and even when they do, on noble the cache
			# rebuild silently fails to register the entry — so
			# scalable/apps is the only reliably-working target.
			if [[ -f "$desktop_dir/branding/pixmaps/armbian.png" ]]; then
				mkdir -p /usr/share/icons/hicolor/scalable/apps
				cp "$desktop_dir/branding/pixmaps/armbian.png" \
					/usr/share/icons/hicolor/scalable/apps/armbian-logo.png
				# Clean up stale installs from previous (broken)
				# attempts at this step.
				rm -f /usr/share/icons/hicolor/128x128/apps/armbian-logo.png
				rm -f /usr/share/icons/hicolor/256x256/apps/armbian-logo.png
				# Refresh the hicolor index so the icon is picked up
				# without requiring a re-login. Failure is non-fatal.
				gtk-update-icon-cache -q -f /usr/share/icons/hicolor 2>/dev/null || true
			fi

			# GNOME wallpaper properties
			if [[ -f "$desktop_dir/branding/armbian.xml" ]]; then
				mkdir -p /usr/share/gnome-background-properties
				cp "$desktop_dir/branding/armbian.xml" /usr/share/gnome-background-properties/
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
