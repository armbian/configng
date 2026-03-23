module_options+=(
	["manage_odroid_board,author"]="@GeoffClements"
	["manage_odroid_board,ref_link"]=""
	["manage_odroid_board,feature"]="Odroid board"
	["manage_odroid_board,desc"]="Select optimised Odroid board configuration"
	["manage_odroid_board,example"]="select"
	["manage_odroid_board,status"]="Stable"
	["manage_odroid_board,arch"]="armhf"
)
#
# @description Select optimised board configuration
#
function manage_odroid_board() {

	local board_list=("Odroid XU4" "Odroid XU3" "Odroid XU3 Lite" "Odroid HC1/HC2")
	local board_id=("xu4" "xu3" "xu3l" "hc1")
	local -a list
	local state

	local env_file=/boot/armbianEnv.txt
	local current_board=$(grep -oP '^board_name=\K.*' ${env_file})
	local target_board=${current_board}

	for board_num in $(seq 0 $((${#board_list[@]} - 1))); do
		if [[ "${board_id[${board_num}]}" == "${current_board}" ]]; then
			state=on
		else
			state=off
		fi
	list+=("${board_id[${board_num}]}" "${board_list[${board_num}]}" "${state}")
	done

	if target_board=$(dialog_radiolist "Select optimised board configuration" "" 10 42 4 --notags -- "${list[@]}"); then
		sed -i "s/^board_name=.*/board_name=${target_board}/" ${env_file} 2> /dev/null && \
		grep -q "^board_name=${target_board}" ${env_file} 2>/dev/null || \
		echo "board_name=${target_board}" >> ${env_file}
		sed -i "s/^BOARD_NAME.*/BOARD_NAME=\"Odroid ${target_board^^}\"/" /etc/armbian-release

		if dialog_yesno " Reboot required " "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
		reboot
		fi
	fi
}
