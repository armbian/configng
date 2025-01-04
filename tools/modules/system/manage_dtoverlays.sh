
module_options+=(
["manage_dtoverlays,author"]="@viraniac"
["manage_dtoverlays,maintainer"]=""
["manage_dtoverlays,ref_link"]=""
["manage_dtoverlays,feature"]="manage_dtoverlays"
["manage_dtoverlays,desc"]="Enable/disable device tree overlays"
["manage_dtoverlays,example"]=""
["manage_dtoverlays,status"]="Active"
["manage_dtoverlays,group"]="Kernel"
["manage_dtoverlays,port"]=""
["manage_dtoverlays,arch"]="aarch64 armhf"
)
#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	local overlaydir="/boot/dtb/overlay";
	[[ "$LINUXFAMILY" == "sunxi64" ]] && overlaydir="/boot/dtb/allwinner/overlay";
	[[ "$LINUXFAMILY" == "meson64" ]] && overlaydir="/boot/dtb/amlogic/overlay";
	[[ "$LINUXFAMILY" == "rockchip64" || "$LINUXFAMILY" == "rk3399" || "$LINUXFAMILY" == "rockchip-rk3588" || "$LINUXFAMILY" == "rk35xx" ]] && overlaydir="/boot/dtb/rockchip/overlay";

	[[ ! -f "${overlayconf}" || ! -d "${overlaydir}" ]] && echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message && return 1
	#[[ -f "${overlayconf}" ]] && source "${overlayconf}"
	while true; do
		local options=()
		j=0
		if [[ -n "${BOOT_SOC}" ]]; then
		available_overlays=$(ls -1 ${overlaydir}/*.dtbo | sed "s#^${overlaydir}/##" | sed 's/.dtbo//g' | grep -E "$BOOT_SOC|$BOARD" | tr '\n' ' ')
		else
		available_overlays=$(ls -1 ${overlaydir}/*.dtbo | sed "s#^${overlaydir}/##" | sed 's/.dtbo//g' | tr '\n' ' ')
		fi
		for overlay in ${available_overlays}; do
			local status="OFF"
			grep '^overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$($DIALOG --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "\nUse <space> to toggle functions and save them.\nExit when you are done.\n " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				sed -i "s/^overlays=.*/overlays=$newoverlays/" ${overlayconf}
				if ! grep -q "^overlays" ${overlayconf}; then echo "overlays=$newoverlays" >> ${overlayconf}; fi
				sync
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					$DIALOG --title " Reboot required " --yes-button "Reboot" \
						--no-button "Cancel" --yesno "A reboot is required to apply the changes. Shall we reboot now?" 7 34
					if [[ $? = 0 ]]; then
						reboot
					fi
				fi
				break
				;;
			255)
				;;
		esac
	done
}
