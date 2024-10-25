module_options+=(
	["generate_menu,author"]="Tearran"
	["generate_menu,ref_link"]=""
	["generate_menu,feature"]="generate_menu"
	["generate_menu,desc"]="Generate a submenu from a parent_id"
	["generate_menu,example"]="generate_menu 'parent_id'"
	["generate_menu,doc_link"]=""
	["generate_menu,status"]="Active"
)
#
# Function to generate the submenu
#
function generate_menu() {
	local parent_id="$1"
	local top_parent_id="$2"
	local backtitle="$BACKTITLE"
	local status=""

	while true; do
		# Get the submenu options for the current parent_id
		local submenu_options=()
		parse_menu_items submenu_options

		local OPTION=$($DIALOG --backtitle "$BACKTITLE" --title "$top_parent_id $parent_id" --menu "$status" 0 80 9 "${submenu_options[@]}" \
			--ok-button Select --cancel-button Back 3>&1 1>&2 2>&3)

		local exitstatus=$?

		if [ $exitstatus = 0 ]; then
			[ -z "$OPTION" ] && break

			# Check if the selected option has a submenu
			local submenu_count=$(jq -r --arg id "$OPTION" '.menu[] | .. | objects | select(.id==$id) | .sub? | length' "$json_file")
			submenu_count=${submenu_count:-0} # If submenu_count is null or empty, set it to 0
			if [ "$submenu_count" -gt 0 ]; then
				# If it does, generate a new menu for the submenu
				[[ -n "$debug" ]] && echo "$OPTION"
				generate_menu "$OPTION" "$parent_id"
			else
				# If it doesn't, execute the command
				[[ -n "$debug" ]] && echo "$OPTION"
				execute_command "$OPTION"
			fi
		fi
	done
}

