module_options+=(
	["interface_checklist,author"]="@Tearran"
	["interface_checklist,maintainer"]="@Tearran"
	["interface_checklist,feature"]="interface_checklist"
	["interface_checklist,example"]="interface_checklist <title> <prompt> <options_array>"
	["interface_checklist,desc"]="Reusable helper function to display a checklist using whiptail, dialog, or read."
	["interface_checklist,status"]="Active"
	["interface_checklist,group"]="Helpers"
	["interface_checklist,arch"]="arm64"
)
# Helper function to display a checklist using whiptail/dialog/read
function interface_checklist() {
	local title="$1"
	local prompt="$2"
	local -n options_array="$3" # Use a nameref to pass the array by reference
	local dialog_height=20
	local dialog_width=78
	local menu_height=10

	# Prepare options for the checklist
	local checklist_items=()
	for ((i = 0; i < ${#options_array[@]}; i += 3)); do
		checklist_items+=("${options_array[i]}" "${options_array[i+1]}" "${options_array[i+2]}")
	done

	# Display the checklist based on the dialog tool
	local selected_items=""
	case $DIALOG in
		"whiptail")
			selected_items=$(whiptail --title "$title" --checklist \
				"$prompt" $dialog_height $dialog_width $menu_height \
				"${checklist_items[@]}" 3>&1 1>&2 2>&3)
			;;
		"dialog")
			selected_items=$(dialog --title "$title" --checklist \
				"$prompt" $dialog_height $dialog_width $menu_height \
				"${checklist_items[@]}" 2>&1 >/dev/tty)
			;;
		"read")
			echo "$title"
			echo "$prompt"
			for ((i = 0; i < ${#options_array[@]}; i += 3)); do
				echo "$((i / 3 + 1)). ${options_array[i]} - ${options_array[i+1]} (Default: ${options_array[i+2]})"
			done
			echo "Enter the numbers of the items you want to select, separated by spaces:"
			read -r selected_indexes
			selected_items=""
			for index in $selected_indexes; do
				selected_items+=" ${options_array[((index - 1) * 3)]}"
			done
			;;
	esac

	# Return the selected items
	if [[ -z "$selected_items" ]]; then
		echo "Checklist canceled."
		return 1
	fi

	echo "$selected_items"
}

module_options+=(
	["process_package_selection,author"]="@Tearran"
	["process_package_selection,maintainer"]="@Tearran"
	["process_package_selection,feature"]="process_package_selection"
	["process_package_selection,example"]="process_package_selection <title> <prompt> <checklist_options_array>"
	["process_package_selection,desc"]="Reusable helper function to process user-selected packages for installation or removal."
	["process_package_selection,status"]="Active"
	["process_package_selection,group"]="Helpers"
	["process_package_selection,arch"]="x86-64 arm64 armhf"
)
#
function process_package_selection() {
	local title="$1"
	local prompt="$2"
	local -a checklist_options=("${!3}") # Accept checklist array as reference

	# Display checklist to user and get selected packages
	local selected_packages
	selected_packages=$(interface_checklist "$title Management" "$prompt" checklist_options)

	# Check if user canceled or made no selection
	if [[ $? -ne 0 ]]; then
		echo "No changes made."
		return 1
	fi

	# Processing all packages from the checklist
	echo "Processing package selections..."
	for ((i = 0; i < ${#checklist_options[@]}; i += 3)); do
		local package="${checklist_options[i]}"
		local current_state="${checklist_options[i+2]}" # Current state in checklist (ON/OFF)
		local is_selected="OFF" # Default to OFF

		# Check if the package is in the selected list
		if [[ "$selected_packages" == *"$package"* ]]; then
			is_selected="ON"
		fi

		# Compare current state with selected state and act accordingly
		if [[ "$is_selected" == "ON" && "$current_state" == "OFF" ]]; then
			# Package is selected but not installed, install it
			echo "Installing $package..."
			pkg_install "$package"
		elif [[ "$is_selected" == "OFF" && "$current_state" == "ON" ]]; then
			# Package is deselected but installed, remove it
			echo "Removing $package..."
			pkg_remove "$package"
		fi
	done

	echo "Package management complete."
}