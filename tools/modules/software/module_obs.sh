module_options+=(
	["module_obs,author"]="@HeyMeco"
	["module_obs,maintainer"]="@HeyMeco"
	["module_obs,feature"]="module_obs"
	["module_obs,example"]="install remove status supported help"
	["module_obs,desc"]="OBS Studio; hardware acceleration auto-selected (Rockchip MPP / NVIDIA NVENC / VAAPI)"
	["module_obs,status"]="Preview"
	["module_obs,doc_link"]="https://obsproject.com/"
	["module_obs,group"]="Media"
	["module_obs,arch"]="x86-64 arm64"
	["module_obs,help_install"]="Install OBS Studio, choosing the Rockchip hardware build where available"
	["module_obs,help_remove"]="Remove OBS Studio; settings in the home directory stay"
	["module_obs,help_status"]="Return success when OBS Studio is installed"
	["module_obs,help_supported"]="Return success on an architecture OBS Studio is available for"
)

# OBS Studio with hardware acceleration auto-selected for the board, the same
# idea as module_jellyfin (Rockchip / NVIDIA / VAAPI where the hardware is
# present):
#
#   arm64 Rockchip RK3588 (vendor kernel, supported release)
#       -> obs-studio-rockchip: MPP H.264/HEVC encoders, RK3588 HDMI input and
#          MIPI CSI camera sources. Built by https://github.com/HeyMeco/obs-jfmpp
#          and synced into <release>-desktop via armbian/os.
#   x86 with an NVIDIA GPU -> distro obs-studio, which uses NVENC at runtime
#          (needs the proprietary NVIDIA driver).
#   x86 Intel/AMD          -> distro obs-studio, VAAPI via /dev/dri.
#   anything else          -> distro obs-studio, x264 software encoding.
#
module_obs_rk_package="obs-studio-rockchip"
module_obs_rk_releases="trixie resolute"
module_obs_std_package="obs-studio"

#
# True on an arm64 Rockchip SoC running a release the hardware build is
# published for. The device tree is checked rather than BOARDFAMILY, which has
# several Rockchip spellings (rockchip64, rk35xx, rockchip-rk3588, ...).
#
module_obs_is_rockchip() {
	[[ "$(dpkg --print-architecture)" == "arm64" ]] || return 1
	[[ -r /proc/device-tree/compatible ]] || return 1
	tr '\0' '\n' < /proc/device-tree/compatible | grep -q '^rockchip,' || return 1
	[[ " ${module_obs_rk_releases} " == *" ${DISTROID} "* ]]
}

# The OBS package best suited to this hardware.
module_obs_package() {
	if module_obs_is_rockchip; then echo "$module_obs_rk_package"; else echo "$module_obs_std_package"; fi
}

# Human description of the acceleration OBS will use here (for help/summary).
module_obs_accel() {
	if module_obs_is_rockchip; then
		echo "Rockchip MPP H.264/HEVC (hardware)"
	elif lspci 2>/dev/null | grep -qiE 'vga.*nvidia|3d.*nvidia|display.*nvidia'; then
		echo "NVIDIA NVENC (needs the proprietary driver)"
	elif [[ -e /dev/dri/renderD128 ]]; then
		echo "VAAPI (Intel/AMD, hardware)"
	else
		echo "x264 (software)"
	fi
}

# OBS Studio is packaged for amd64 and arm64.
module_obs_supported() {
	[[ "$(dpkg --print-architecture)" =~ ^(amd64|arm64)$ ]]
}

# status: installed under either package name
module_obs_status() {
	pkg_installed "$module_obs_rk_package" || pkg_installed "$module_obs_std_package"
}

#
# Module OBS Studio (multi-arch, hardware-accelerated where possible)
#
function module_obs() {
	local title="OBS Studio"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_obs,example"]}"

	case "$1" in

		"${commands[0]}") # install
			if ! module_obs_supported; then
				echo "$title is available on amd64 and arm64 only." >&2
				return 1
			fi
			local pkg
			pkg="$(module_obs_package)"
			echo "$title: installing $pkg — acceleration: $(module_obs_accel)"
			pkg_update
			pkg_install "$pkg"
		;;

		"${commands[1]}") # remove
			if pkg_installed "$module_obs_rk_package"; then pkg_remove "$module_obs_rk_package"; fi
			if pkg_installed "$module_obs_std_package"; then pkg_remove "$module_obs_std_package"; fi
		;;

		"${commands[2]}") # status
			module_obs_status
		;;

		"${commands[3]}") # supported
			module_obs_supported
		;;

		"${commands[4]}") # help
			echo -e "\nUsage: ${module_options["module_obs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_obs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t\t- Install $title (acceleration: $(module_obs_accel))."
			echo -e "\tremove\t\t- Remove $title."
			echo -e "\tstatus\t\t- Status $title."
			echo -e "\tsupported\t- Check this system can run $title."
			echo
		;;

		*)
			${module_options["module_obs,feature"]} ${commands[4]}
		;;

	esac
}
