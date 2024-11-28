module_options+=(
	["set_runtime_variables,author"]="@igorpecovnik"
	["set_runtime_variables,ref_link"]=""
	["set_runtime_variables,feature"]="set_runtime_variables"
	["set_runtime_variables,desc"]="Run time variables Migrated procedures from Armbian config."
	["set_runtime_variables,example"]="set_runtime_variables"
	["set_runtime_variables,status"]="Active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables() {

	missing_dependencies=()

	# Check if whiptail is available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		missing_dependencies+=("whiptail")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# If any dependencies are missing, print a combined message and exit
	if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
		if is_package_manager_running; then
			sudo apt install ${missing_dependencies[*]}
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if systemctl is-active NetworkManager 1> /dev/null; then
		NETWORK_RENDERER=NetworkManager
	else
		NETWORK_RENDERER=networkd
	fi

	DIALOG_CANCEL=1
	DIALOG_ESC=255

	# we have our own lsb_release which does not use Python. Others shell install it here
	if [[ ! -f /usr/bin/lsb_release ]]; then
		if is_package_manager_running; then
			sleep 3
		fi
		debconf-apt-progress -- apt-get update
		debconf-apt-progress -- apt -y -qq --allow-downgrades --no-install-recommends install lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc)
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	BACKTITLE="Contribute: https://github.com/armbian/configng"
	TITLE="Armbian configuration utility"
	[[ -z "${DEFAULT_ADAPTER// /}" ]] && DEFAULT_ADAPTER="lo"

	# detect desktop
	check_desktop

}


module_options+=(
	["update_json_data,author"]="@Tearran"
	["update_json_data,ref_link"]=""
	["update_json_data,feature"]="update_json_data"
	["update_json_data,desc"]="Update JSON data with system information"
	["update_json_data,example"]="update_json_data"
	["update_json_data,status"]="review"
	["update_json_data,doc_link"]=""

)
#
# Update JSON data with system information
update_json_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg value "$2" \
		'(.menu[] | select(.id == $key).description) += " (" + $value + ")"')
}

module_options+=(
	["update_submenu_data,author"]="@Tearran"
	["update_submenu_data,ref_link"]=""
	["update_submenu_data,feature"]="update_submenu_data"
	["update_submenu_data,desc"]="Update submenu descriptions based on conditions"
	["update_submenu_data,example"]="update_submenu_data"
	["update_submenu_data,status"]="review"
	["update_submenu_data,doc_link"]=""
)
#
# Update submenu descriptions based on conditions
update_submenu_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg subkey "$2" --arg value "$3" \
		'(.menu[] | select(.id==$key).sub[] | select(.id == $subkey).description) += " (" + $value + ")"')
}


module_options+=(
	["update_sub_submenu_data,author"]="@Tearran"
	["update_sub_submenu_data,feature"]="update_sub_submenu_data"
	["update_sub_submenu_data,desc"]="Update sub-submenu descriptions based on conditions"
	["update_sub_submenu_data,example"]="update_sub_submenu_data \"MenuID\" \"SubID\" \"SubSubID\" \"CMD\""
	["update_sub_submenu_data,status"]=""
)
#
# Update sub-submenu descriptions based on conditions
update_sub_submenu_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg subkey "$2" --arg subsubkey "$3" --arg value "$4" \
		'(.menu[] | select(.id == $key).sub[] |
		select(.id == $subkey).sub[] |
		select(.id == $subsubkey).description) += " (" + $value + ")"')
}
