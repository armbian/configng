#!/bin/bash
module_options+=(
	["_prompt_text_input,author"]="@Tearran"
	["_prompt_text_input,feature"]="prompt_text_input"
	["_prompt_text_input,example"]=""
	["_prompt_text_input,desc"]="Prompt the user for text input with a default value"
	["_prompt_text_input,status"]="Draft"
)

# This function prompts the user for text input, with a default value provided.
# It uses different dialog tools (`whiptail`, `dialog`) or plain `read` based on the environment.
#
# Draft Note:
# The function may not but should handle empty results to avoid continuing with invalid input.
function _prompt_text_input() {
	local prompt_text="$1"
	local default_value="$2"
	local result

	if [[ "$DIALOG" == "whiptail" ]]; then
		result=$(whiptail --inputbox "$prompt_text" 8 39 "$default_value" 3>&1 1>&2 2>&3)
	elif [[ "$DIALOG" == "dialog" ]]; then
		result=$(dialog --inputbox "$prompt_text" 8 39 "$default_value" 3>&1 1>&2 2>&3)
	else
		read -p "$prompt_text [$default_value]: " result
		result=${result:-$default_value}
	fi

	# Check if the user cancelled the input (result is empty)
	# Consider logging the cancellation event for debugging purposes.
	if [[ -z "$result" ]]; then
		echo "Input cancelled by user."
		return 1
	fi

	echo "$result"
}

# Main function for the module
function _edit_playground() {
	case "$1" in
		"help")
			# Help message formatted for see_menu
			echo "
Usage: _edit_playground [option]
Options:
	workgroup	- Change the workgroup name
	server_string	- Update the server string
	netbios_name	- Modify the NetBIOS name
	share_path	- Adjust the path for the Samba share
			"
			;;
		"workgroup")
			workgroup=$(_prompt_text_input "Enter the workgroup" "WORKGROUP")
			echo "$workgroup"
			;;
		"server_string")
			server_string=$(_prompt_text_input "Enter the server string" "Samba Server %v")
			echo "$server_string"
			;;
		"netbios_name")
			netbios_name=$(_prompt_text_input "Enter the NetBIOS name" "ubuntu")
			echo "$netbios_name"
			;;
		"share_path")
			share_path=$(_prompt_text_input "Enter the path for the Samba share" "/srv/samba/anonymous")
			echo "$share_path"
			;;
		*)
			echo "Invalid option. Use 'help' for usage information."
			;;
	esac
}

# Use case examples for TUI with case switch
function module_tui_playground() {
	case "$1" in
		"help")
		echo "
Usage: module_tui_playground [option]
Options:
	text_input   - multiple prompts in a row.
	see_menu     - Prompt for selectable text inputs
	dialog       - Same as see_menu and uses dialog if installed
		"
		;;
		"text_input")
		workgroup=$(_prompt_text_input "Enter the workgroup" "WORKGROUP")
		server_string=$(_prompt_text_input "Enter the server string" "Samba Server %v")
		netbios_name=$(_prompt_text_input "Enter the netbios name" "ubuntu")
		share_path=$(_prompt_text_input "Enter the path for the Samba share" "/srv/samba/anonymous")
		echo -e "Workgroup: $workgroup\nServer String: $server_string\nNetBIOS Name: $netbios_name\nShare Path: $share_path" | show_message
		;;
		"see_menu")
			see_menu _edit_playground | show_message
		;;
		"dialog")
		DIALOG="dialog"

		echo -e "This is an Ok dialog that is using $DIALOG" | show_message
		see_menu _edit_playground
		echo "This is an info box using $DIALOG" | show_infobox
		;;
		*)
		echo "Invalid option. Use 'help' for usage information."
		;;
	esac
	}
