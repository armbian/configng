module_options+=(
	["module_obs_rockchip,author"]="@HeyMeco"
	["module_obs_rockchip,maintainer"]="@HeyMeco"
	["module_obs_rockchip,feature"]="module_obs_rockchip"
	["module_obs_rockchip,example"]="install remove status supported help"
	["module_obs_rockchip,desc"]="OBS Studio with Rockchip MPP encoders, HDMI input and camera sources"
	["module_obs_rockchip,status"]="Active"
	["module_obs_rockchip,doc_link"]="https://github.com/HeyMeco/obs-jfmpp"
	["module_obs_rockchip,group"]="Media"
	["module_obs_rockchip,arch"]="arm64"
	["module_obs_rockchip,help_install"]="Install obs-studio-rockchip from the Armbian repository"
	["module_obs_rockchip,help_remove"]="Remove obs-studio-rockchip; OBS settings in the home directory stay"
	["module_obs_rockchip,help_status"]="Return success when obs-studio-rockchip is installed"
	["module_obs_rockchip,help_supported"]="Return success on an arm64 Rockchip board running a release the package is built for"
)

# Built by https://github.com/HeyMeco/obs-jfmpp and synced into <release>-desktop
# through armbian/os external/obs-studio-rockchip-<release>.conf.
module_obs_rockchip_package="obs-studio-rockchip"
module_obs_rockchip_releases="trixie resolute"

#
# Succeed on an arm64 Rockchip SoC running one of the releases the package is
# published for. The device tree is checked rather than BOARDFAMILY, which has
# several Rockchip spellings (rockchip64, rk35xx, rockchip-rk3588, ...).
#
module_obs_rockchip_supported() {
	[[ "$(dpkg --print-architecture)" == "arm64" ]] || return 1
	[[ -r /proc/device-tree/compatible ]] || return 1
	tr '\0' '\n' < /proc/device-tree/compatible | grep -q '^rockchip,' || return 1
	[[ " ${module_obs_rockchip_releases} " == *" ${DISTROID} "* ]]
}

#
# Module OBS Studio for Rockchip
#
# Installs OBS Studio linked against jellyfin-ffmpeg with Rockchip MPP/RGA:
# hardware H.264/HEVC encoders, the RK3588 HDMI input source and the MIPI CSI
# camera source. Native package, replaces the distribution's obs-studio.
#
function module_obs_rockchip() {
	local title="OBS Studio for Rockchip"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_obs_rockchip,example"]}"

	case "$1" in

		"${commands[0]}") # install
			if ! module_obs_rockchip_supported; then
				echo "$title needs an arm64 Rockchip board running Armbian ${module_obs_rockchip_releases// / or }." >&2
				return 1
			fi
			pkg_update
			pkg_install "$module_obs_rockchip_package"
		;;

		"${commands[1]}") # remove
			pkg_remove "$module_obs_rockchip_package"
		;;

		"${commands[2]}") # status
			pkg_installed "$module_obs_rockchip_package"
		;;

		"${commands[3]}") # supported
			module_obs_rockchip_supported
		;;

		"${commands[4]}") # help
			echo -e "\nUsage: ${module_options["module_obs_rockchip,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_obs_rockchip,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t\t- Install $title."
			echo -e "\tremove\t\t- Remove $title."
			echo -e "\tstatus\t\t- Status $title."
			echo -e "\tsupported\t- Check this board can run $title."
			echo
		;;

		*)
			${module_options["module_obs_rockchip,feature"]} ${commands[4]}
		;;

	esac
}
