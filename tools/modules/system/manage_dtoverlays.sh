#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	local overlaydir="$(find /boot/dtb/ -name overlay -and -type d)"
	local overlay_prefix=$(awk -F"=" '/overlay_prefix/ {print $2}' $overlayconf)
	if [[ -z $(find ${overlaydir} -name *$overlay_prefix* 2> /dev/null) ]] ; then
		echo "Invalid overlay_prefix $overlay_prefix"; exit 1
	fi

	[[ ! -f "${overlayconf}" || ! -d "${overlaydir}" ]] && echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message && return 1

	while true; do
		local options=()
		j=0

		if [[ -n "${BOOT_SOC}" ]]; then
			available_overlays=$(ls -1 ${overlaydir}/${overlay_prefix}*.dtbo | sed 's/^.*\('${overlay_prefix}'.*\)/\1/g' | grep -E "$BOOT_SOC|$BOARD" | sed 's/'${overlay_prefix}'-//g' | sed 's/.dtbo//g')
		else
			available_overlays=$(ls -1 ${overlaydir}/${overlay_prefix}*.dtbo | sed 's/^.*\('${overlay_prefix}'.*\)/\1/g' | sed 's/'${overlay_prefix}'-//g' | sed 's/.dtbo//g')
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
