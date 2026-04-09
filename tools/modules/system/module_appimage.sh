module_options+=(
	["module_appimage,author"]="@igorpecovnik"
	["module_appimage,feature"]="module_appimage"
	["module_appimage,desc"]="Download and manage AppImage applications"
	["module_appimage,example"]="install remove status help"
	["module_appimage,status"]="Active"
	["module_appimage,arch"]=""
	["module_appimage,help_install"]="Download and install an AppImage (app=name)"
	["module_appimage,help_remove"]="Remove an installed AppImage (app=name)"
	["module_appimage,help_status"]="Check if an AppImage is installed (app=name)"
)

# AppImage registry: name -> GitHub repo
declare -A APPIMAGE_REPO=(
	["armbian-imager"]="armbian/imager"
)

# AppImage display names
declare -A APPIMAGE_NAME=(
	["armbian-imager"]="Armbian Imager"
)

# AppImage arch mapping: dpkg arch -> AppImage arch suffix
declare -A APPIMAGE_ARCH=(
	["arm64"]="aarch64"
	["amd64"]="amd64"
	["armhf"]="armhf"
)

#
# Module to download and manage AppImage applications
#
function module_appimage() {

	local APPIMAGE_DIR="/armbian/appimages"
	local APPIMAGE_DESKTOP_DIR="/usr/share/applications"

	# read app name from parameters
	local app=""
	local parameter
	IFS=' ' read -r -a parameter <<< "${2}"
	for selected in "${parameter[@]}"; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ "${split[0]}" == "app" ]] && app="${split[1]}"
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_appimage,example"]}"

	case "$1" in
		"${commands[0]}")
			# install
			if [[ -z "$app" ]]; then
				echo "Error: specify app=name. Available: ${!APPIMAGE_REPO[*]}" >&2
				return 1
			fi

			local repo="${APPIMAGE_REPO[$app]:-}"
			if [[ -z "$repo" ]]; then
				echo "Error: unknown app '$app'. Available: ${!APPIMAGE_REPO[*]}" >&2
				return 1
			fi

			local arch=$(dpkg --print-architecture)
			local appimage_arch="${APPIMAGE_ARCH[$arch]:-}"
			if [[ -z "$appimage_arch" ]]; then
				echo "Error: architecture '$arch' not supported for AppImages" >&2
				return 1
			fi

			# ensure FUSE support for AppImages
			pkg_install libfuse2 fuse3
			# AppImages need fusermount but fuse3 only provides fusermount3
			if ! command -v fusermount > /dev/null 2>&1 && command -v fusermount3 > /dev/null 2>&1; then
				ln -sf "$(command -v fusermount3)" /usr/local/bin/fusermount
			fi
			# Set FUSERMOUNT_PROG system-wide for AppImage compatibility
			local fmount=$(command -v fusermount3 2>/dev/null || command -v fusermount 2>/dev/null)
			if [[ -n "$fmount" ]] && ! grep -q FUSERMOUNT_PROG /etc/environment 2>/dev/null; then
				echo "FUSERMOUNT_PROG=${fmount}" >> /etc/environment
			fi

			# get latest release download URL
			local download_url
			download_url=$(curl -sL "https://api.github.com/repos/${repo}/releases/latest" | \
				grep -o "https://.*${appimage_arch}\.AppImage" | head -1)

			if [[ -z "$download_url" ]]; then
				echo "Error: no AppImage found for ${app} on ${appimage_arch}" >&2
				return 1
			fi

			local filename=$(basename "$download_url")

			echo "Downloading ${app} for ${appimage_arch}..."
			mkdir -p "$APPIMAGE_DIR"
			curl -sL "$download_url" -o "${APPIMAGE_DIR}/${filename}"
			chmod +x "${APPIMAGE_DIR}/${filename}"

			# create stable symlink
			ln -sf "${APPIMAGE_DIR}/${filename}" "${APPIMAGE_DIR}/${app}"

			# create desktop entry
			local display_name="${APPIMAGE_NAME[$app]:-$app}"
			cat > "${APPIMAGE_DESKTOP_DIR}/${app}.desktop" <<- EOF
			[Desktop Entry]
			Version=1.0
			Type=Application
			Name=${display_name}
			Exec=env FUSERMOUNT_PROG=$(command -v fusermount3 || command -v fusermount) ${APPIMAGE_DIR}/${app}
			Icon=/usr/share/pixmaps/armbian/armbian.png
			Terminal=false
			Categories=Utility;
			EOF

			echo "${app} installed: ${APPIMAGE_DIR}/${filename}"
		;;

		"${commands[1]}")
			# remove
			if [[ -z "$app" ]]; then
				echo "Error: specify app=name" >&2
				return 1
			fi
			rm -f "${APPIMAGE_DIR}/${app}" "${APPIMAGE_DIR}/${app}"_*.AppImage "${APPIMAGE_DIR}/"*"${app}"*.AppImage
			rm -f "${APPIMAGE_DESKTOP_DIR}/${app}.desktop"
			rmdir "${APPIMAGE_DIR}" 2>/dev/null || true
			echo "${app} removed"
		;;

		"${commands[2]}")
			# status
			if [[ -z "$app" ]]; then
				# list all installed
				if [[ -d "$APPIMAGE_DIR" ]]; then
					ls -1 "$APPIMAGE_DIR"/*.AppImage 2>/dev/null | while read f; do
						echo "$(basename "$f")"
					done
				fi
				return 0
			fi
			[[ -x "${APPIMAGE_DIR}/${app}" ]] && return 0 || return 1
		;;

		"${commands[3]}")
			show_module_help "module_appimage" "AppImage" \
				"Available apps: ${!APPIMAGE_REPO[*]}\nInstall dir: ${APPIMAGE_DIR}\nExample: module_appimage install app=armbian-imager" "native"
		;;

		*)
			show_module_help "module_appimage" "AppImage" \
				"Available apps: ${!APPIMAGE_REPO[*]}\nInstall dir: ${APPIMAGE_DIR}\nExample: module_appimage install app=armbian-imager" "native"
		;;
	esac
}
