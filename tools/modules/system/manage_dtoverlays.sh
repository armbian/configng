
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
["manage_dtoverlays,arch"]="aarch64 armhf riscv64"
)
#
# @description Enable/disable device tree overlays
#
# Usage: manage_dtoverlays
#        manage_dtoverlays help
#
# Edits /boot/armbianEnv.txt (or /boot/firmware/config.txt on
# Raspberry Pi). The file is rewritten via temp + atomic mv and
# the previous content is preserved as <name>.bak — on an SBC a
# corrupted boot config is a brick, so the rewrite must be all-or-
# nothing.
#
function manage_dtoverlays() {
	local arg="${1:-}"

	case "$arg" in
		help)
			echo "Usage: manage_dtoverlays"
			echo "       manage_dtoverlays help"
			echo ""
			echo "Interactive TUI for enabling/disabling device tree overlays."
			echo "Edits /boot/armbianEnv.txt or /boot/firmware/config.txt."
			echo "Backs up the previous file as <name>.bak before each change"
			echo "and writes the new content atomically."
			return 0
		;;
	esac

	local changes="false"
	local pi_config="/boot/firmware/config.txt"
	local armbian_env="/boot/armbianEnv.txt"
	local boot_scr="/boot/boot.scr"
	local is_pi="false"
	local overlayconf overlaydir overlay_prefix

	if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		is_pi="true"
		overlayconf="$pi_config"
		overlaydir=$(find /boot/dtb/ -maxdepth 1 -type d \( -name "overlay" -o -name "overlays" \) 2>/dev/null | head -n1)
	else
		overlayconf="$armbian_env"
		overlaydir=$(find /boot/dtb/ -name overlay -and -type d 2>/dev/null)
	fi

	# Anchored match — the previous unanchored form would also pick
	# up keys like `something_overlay_prefix_FOO=`.
	overlay_prefix=$(awk -F= '/^overlay_prefix=/ {print $2}' "$overlayconf" 2>/dev/null)

	if [[ "$is_pi" != "true" ]] && [[ -z $(find "$overlaydir" -name "*${overlay_prefix}*" 2>/dev/null) ]]; then
		echo "Invalid overlay_prefix ${overlay_prefix}" >&2
		return 1
	fi

	if [[ ! -f "$overlayconf" || ! -d "$overlaydir" ]]; then
		echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message
		return 1
	fi

	# Detect what spellings /boot/boot.scr will accept:
	#   00 — overlays cannot be loaded by boot.scr
	#   01 — only full name (with prefix) loads
	#   10 — only short name (without prefix) loads
	#   11 — both spellings load
	local scenario
	scenario=$(
		awk 'BEGIN{p=0;s=0}
			/load.*overlays?\/\${overlay_prefix}-\${overlay_file}.dtbo/{p=1}
			/load.*overlays?\/\${overlay_file}.dtbo/{s=1}
			END{print p s}
		' "$boot_scr" 2>/dev/null
	)

	while true; do
		local options=()
		local available_overlays=""
		local builtin_overlays=""

		if [[ "$scenario" == "10" || "$scenario" == "11" ]]; then
			available_overlays=$(
				set -o pipefail
				find "$overlaydir"/ -name "${overlay_prefix}*.dtbo" 2>/dev/null | \
				awk -F'/' -v p="${overlay_prefix}-" '{
					gsub(p, "", $NF)
					gsub(".dtbo", "", $NF)
					print $NF
				}' | sort
			)
		fi

		# Refresh BRANCH from /etc/armbian-release for the rk3588 check below.
		update_kernel_env

		# rk3588 vendor kernel ships overlays without the standard prefix;
		# pick those up so they're selectable too.
		if [[ "$scenario" == "01" || "$scenario" == "11" ]]; then
			if [[ "$BOARDFAMILY" == "rockchip-rk3588" && "$BRANCH" == "vendor" ]]; then
				builtin_overlays=$(
					set -o pipefail
					find "$overlaydir"/ -name '*.dtbo' ! -name "${overlay_prefix}*.dtbo" 2>/dev/null | \
					awk -F'/' -v p="${overlay_prefix}" '{
						if ($0 !~ p) {
							gsub(".dtbo", "", $NF)
							print $NF
						}
					}' | sort
				)
			fi
		fi

		if [[ "$scenario" == "00" ]]; then
			dialog_yesno "Manage devicetree overlays" "    The overlays provided by Armbian cannot be loaded\n    by /boot/boot.scr script.\n" "Exit" "Cancel" 11 44
			local exit_status=$?
			if [[ "$exit_status" == 0 ]]; then
				return 0
			fi
			break
		fi

		local overlay status candidate
		for overlay in ${available_overlays} ${builtin_overlays}; do
			status="OFF"
			# grep -F: overlay names can contain '.' / '-' which sed/grep would
			# otherwise treat as regex metacharacters; -w keeps word boundaries.
			grep '^overlays=' "$overlayconf" | grep -qwF -- "$overlay" && status="ON"
			# Raspberry Pi
			grep '^dtoverlay=' "$overlayconf" | grep -qwF -- "$overlay" && status="ON"
			if [[ -n "$overlay_prefix" ]]; then
				candidate="${overlay#$overlay_prefix}"
				candidate="${candidate#-}"
			else
				candidate="$overlay"
			fi
			grep '^overlays=' "$overlayconf" | grep -qwF -- "$candidate" && status="ON"
			options+=( "$overlay" "" "$status" )
		done

		local selection
		selection=$(dialog_checklist "Manage devicetree overlays" "\nUse <space> to toggle functions and save them.\nExit when you are done.\n\n    overlay_prefix=$overlay_prefix\n " 0 0 0 --cancel-button "Back" --ok-button "Save" -- "${options[@]}")
		local exit_status=$?

		case "$exit_status" in
			0)
				changes="true"
				local newoverlays
				newoverlays=$(echo "$selection" | sed 's/"//g')

				# Strip the overlay_prefix from each selected name so the
				# stored value matches what u-boot expects in armbianEnv.txt.
				local -a ovs
				IFS=' ' read -r -a ovs <<< "$newoverlays"
				newoverlays=""
				local ov
				for ov in "${ovs[@]}"; do
					if [[ -n "$overlay_prefix" && "$ov" == "$overlay_prefix"* ]]; then
						ov="${ov#$overlay_prefix}"
					fi
					ov="${ov#-}"
					newoverlays+="$ov "
				done
				newoverlays="${newoverlays% }"

				if ! _dtoverlays_write_config "$overlayconf" "$is_pi" "$newoverlays"; then
					return 1
				fi
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					dialog_yesno "Reboot required" "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34
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

#
# Atomically rewrite the boot config with the new overlay selection.
# Writes to <conf>.tmp, copies the existing <conf> to <conf>.bak (so
# the user has one rollback hop), then mv's tmp into place. A failure
# anywhere in the pipeline leaves the original file untouched.
#
function _dtoverlays_write_config() {
	local conf="$1"
	local is_pi="$2"
	local newoverlays="$3"
	local conf_tmp="${conf}.tmp"
	local conf_bak="${conf}.bak"

	if [[ "$is_pi" == "true" ]]; then
		{
			# Preserve everything before our managed block, then re-emit
			# the block from scratch with the current selection.
			if grep -q '^# Armbian config$' "$conf"; then
				sed '/^# Armbian config$/,$d' "$conf"
			else
				cat "$conf"
			fi
			echo "# Armbian config"
			local ov
			while IFS= read -r ov; do
				printf 'dtoverlay=%s\n' "$ov"
			done <<< "$newoverlays"
		} > "$conf_tmp"
	else
		if grep -q "^overlays=" "$conf"; then
			sed "s|^overlays=.*|overlays=${newoverlays}|" "$conf" > "$conf_tmp"
		else
			cat "$conf" > "$conf_tmp"
			echo "overlays=${newoverlays}" >> "$conf_tmp"
		fi
	fi

	if [[ ! -s "$conf_tmp" ]]; then
		echo "Error: would have written empty boot config to ${conf}" >&2
		rm -f "$conf_tmp"
		return 1
	fi

	cp -p "$conf" "$conf_bak" 2>/dev/null || true

	if ! mv "$conf_tmp" "$conf"; then
		echo "Error: failed to install ${conf}" >&2
		rm -f "$conf_tmp"
		return 1
	fi
}
