
module_options+=(
["manage_dtoverlays,author"]="@viraniac"
["manage_dtoverlays,maintainer"]="@igorpecovnik,@The-going"
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
	if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		# Raspberry Pi has different name
		overlayconf="/boot/firmware/config.txt"
		local overlaydir=$(find /boot/dtb/ -maxdepth 1 -type d \( -name "overlay" -o -name "overlays" \) | head -n1)
		local overlay_prefix=$(awk -F= '/^overlay_prefix=/ {print $2}' "$overlayconf")
	else
		local overlaydir="$(find /boot/dtb/ -name overlay -and -type d)"
		local overlay_prefix=$(awk -F"=" '/overlay_prefix/ {print $2}' $overlayconf)
	fi
	if [[ -z $(find "$overlaydir" -name "*$overlay_prefix*" 2>/dev/null) && "$LINUXFAMILY" != "bcm2711" ]]; then
		echo "Invalid overlay_prefix $overlay_prefix"; exit 1
	fi

	[[ ! -f "${overlayconf}" || ! -d "${overlaydir}" ]] && echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message && return 1

	# check /boot/boot.scr scenario overlay(s)/${overlay_prefix}-${overlay_name}.dtbo
	# or overlay(s)/${overlay_name}.dtbo.
	# scenario:
	# 00 - The /boot/boot.scr script cannot load the overlays provided by Armbian.
	# 01 - It is possible to load only if the full name of the overlay is written.
	# 10 - Loading is possible only if the overlay name is written without a prefix.
	# 11 - Both spellings will be loaded.
	scenario=$(
		awk 'BEGIN{p=0;s=0}
			/load.*overlays?\/\${overlay_prefix}-\${overlay_file}.dtbo/{p=1}
			/load.*overlays?\/\${overlay_file}.dtbo/{s=1}
			END{print p s}
		' /boot/boot.scr
	)

	while true; do
		local options=()
		j=0

		if [[ "${scenario}" == "10" ]] || [[ "${scenario}" == "11" ]]; then
			# read overlays
			available_overlays=$(
				# Find the files that match the overlay prefix pattern.
				# Remove the overlay prefix, file extension, and path
				# in one pass. Sort it out.
				find "${overlaydir}"/ -name "$overlay_prefix"'*.dtbo' 2>/dev/null | \
				awk -F'/' -v p="${overlay_prefix}-" '{
					gsub(p, "", $NF)
					gsub(".dtbo", "", $NF)
					print $NF
				}' | sort
			)
		fi

		# Check the branch in case it is not available in /etc/armbian-release
		update_kernel_env

		# Add support for rk3588 vendor kernel overlays which don't have overlay prefix mostly
		builtin_overlays=""
		if [[ "${scenario}" == "01" ]] || [[ "${scenario}" == "11" ]]; then

			if [[ $BOARDFAMILY == "rockchip-rk3588" ]] && [[ $BRANCH == "vendor" ]]; then
				builtin_overlays=$(
					find "${overlaydir}"/ -name '*.dtbo' ! -name "$overlay_prefix"'*.dtbo' 2>/dev/null | \
					awk -F'/' -v p="${overlay_prefix}" '{
						if ($0 !~ p) {
							gsub(".dtbo", "", $NF)
							print $NF
						}
					}' | sort
				)
			fi
		fi

		if [[ "${scenario}" == "00" ]]; then
			$DIALOG --title " Manage devicetree overlays " \
				--no-button "Cancel" \
				--yes-button "Exit" \
				--yesno "    The overlays provided by Armbian cannot be loaded\n    by /boot/boot.scr script.\n" 11 44
				exit_status=$?
			if [ $exit_status == 0 ]; then
				exit 0
			fi
			break
		fi

		for overlay in ${available_overlays} ${builtin_overlays}; do
			local status="OFF"
			grep '^overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			# Raspberry Pi
			grep '^dtoverlay' ${overlayconf} | grep -qw ${overlay} && status=ON
			# handle case where overlay_prefix is part of overlay name
			if [[ -n $overlay_prefix ]]; then
				candidate="${overlay#$overlay_prefix}"
				candidate="${candidate#'-'}" # remove any trailing hyphen
			else
				candidate="$overlay"
			fi
			grep '^overlays' ${overlayconf} | grep -qw ${candidate} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$($DIALOG --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "\nUse <space> to toggle functions and save them.\nExit when you are done.\n\n    overlay_prefix=$overlay_prefix\n " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				# handle case where overlay_prefix is part of overlay name
				IFS=' ' read -r -a ovs <<< "$newoverlays"
				newoverlays=""
				# remove prefix, if any
				for ov in "${ovs[@]}"; do
					if [[ -n $overlay_prefix && $ov == "$overlay_prefix"* ]]; then
						ov="${ov#$overlay_prefix}"
					fi
					# remove '-' hyphen from beginning of ov, if any
					ov="${ov#-}"
					newoverlays+="$ov "
				done
				newoverlays="${newoverlays% }"
				# Raspberry Pi
				if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
					# Remove any existing Armbian config block
					if grep -q '^# Armbian config$' "$overlayconf"; then
						sed -i '/^# Armbian config$/,$d' "$overlayconf"
					fi
					# Append fresh marker and overlays atomically
					{
						echo "# Armbian config"
						while IFS= read -r ov; do
							printf 'dtoverlay=%s\n' "$ov"
						done <<< "$newoverlays"
					} >> "$overlayconf"
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
