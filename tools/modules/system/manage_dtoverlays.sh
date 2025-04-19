
module_options+=(
["manage_dtoverlays,author"]="@viraniac"
["manage_dtoverlays,maintainer"]="@igorpecovnik,@The-Going"
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
	# Raspberry Pi has different name
	local overlaydir
	overlaydir=$(find /boot/dtb/ -maxdepth 1 -type d \
	\( -name "overlay" -o -name "overlays" \) | head -n1)
	local overlay_prefix
	overlay_prefix=$(awk -F= '/^overlay_prefix=/ {print $2}' "$overlayconf")
	local overlay_prefix=$(awk -F"=" '/overlay_prefix/ {print $2}' $overlayconf)
	if [[ -z $(find "$overlaydir" -name "*$overlay_prefix*" 2>/dev/null) && "$LINUXFAMILY" != "bcm2711" ]]; then
		echo "Invalid overlay_prefix $overlay_prefix"; exit 1
	fi

	[[ ! -f "${overlayconf}" || ! -d "${overlaydir}" ]] && echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message && return 1

	while true; do
		local options=()
		j=0

		# read overlays
		if [[ "${LINUXFAMILY}" == bcm2711 ]]; then
			available_overlays=$(ls -1 ${overlaydir}/*.dtbo | sed 's/.dtbo//g' | awk -F'/' '{print $NF}')
			overlayconf="/boot/firmware/config.txt"
		elif [[ -n "${BOOT_SOC}" ]]; then
			available_overlays=$(ls -1 ${overlaydir}/${overlay_prefix}*.dtbo | sed 's/^.*\('${overlay_prefix}'.*\)/\1/g' | grep -E "$BOOT_SOC|$BOARD" | sed 's/'${overlay_prefix}'-//g' | sed 's/.dtbo//g')
		else
			available_overlays=$(ls -1 ${overlaydir}/${overlay_prefix}*.dtbo | sed 's/^.*\('${overlay_prefix}'.*\)/\1/g' | sed 's/'${overlay_prefix}'-//g' | sed 's/.dtbo//g')
		fi

		# Check the branch in case it is not available in /etc/armbian-release
		update_kernel_env

		# Add support for rk3588 vendor kernel overlays which don't have overlay prefix mostly
		builtin_overlays=""
		if [[ $BOARDFAMILY == "rockchip-rk3588" ]] && [[ $BRANCH == "vendor" ]]; then
			builtin_overlays=$(ls -1 ${overlaydir}/*.dtbo | grep -v ${overlay_prefix} | sed 's#^'${overlaydir}'/##' | sed 's/.dtbo//g')
		fi

		for overlay in ${available_overlays}; do
			local status="OFF"
			grep '^overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			# Raspberry Pi
			grep '^dtoverlay' ${overlayconf} | grep -qw ${overlay} && status=ON
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
				# Raspberry Pi
				if [[ "${LINUXFAMILY}" == bcm2711 ]]; then
					# Ensure a single marker, remove old block
					if grep -q '^# Armbian config$' "$overlayconf"; then
						# Delete marker & following lines
						sed -i '/^# Armbian config$/,$d' "$overlayconf"
					fi
					# Append fresh marker
					echo "# Armbian config" >> "$overlayconf"
					# Append one dtoverlay line per selected overlay
					while IFS= read -r overlay; do
						printf 'dtoverlay=%s\n' "$overlay" >> "$overlayconf"
					done <<< "$newoverlays"
				else
					sed -i "s/^overlays=.*/overlays=$newoverlays/" ${overlayconf}
					if ! grep -q "^overlays" ${overlayconf}; then echo "overlays=$newoverlays" >> ${overlayconf}; fi
				fi
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
