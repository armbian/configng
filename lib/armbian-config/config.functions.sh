
# Start of config ng interface

module_options+=(
	["set_colors,author"]="@Tearran"
	["set_colors,ref_link"]=""
	["set_colors,feature"]="set_colors"
	["set_colors,desc"]="Change the background color of the terminal or dialog box"
	["set_colors,example"]="set_colors 0-7"
	["set_colors,doc_link"]=""
	["set_colors,status"]="Active"
)
#
# Function to set the tui colors
#
function set_colors() {
	local color_code=$1

	if [ "$DIALOG" = "whiptail" ]; then
		set_newt_colors "$color_code"
		#echo "color code: $color_code" | show_infobox ;
	elif [ "$DIALOG" = "dialog" ]; then
		set_term_colors "$color_code"
	else
		echo "Invalid dialog type"
		return 1
	fi
}

#
# Function to set the colors for newt
#
function set_newt_colors() {
	local color_code=$1
	case $color_code in
		0) color="black" ;;
		1) color="red" ;;
		2) color="green" ;;
		3) color="yellow" ;;
		4) color="blue" ;;
		5) color="magenta" ;;
		6) color="cyan" ;;
		7) color="white" ;;
		8) color="black" ;;
		9) color="red" ;;
		*) return ;;
	esac
	export NEWT_COLORS="root=,$color"
}

#
# Function to set the colors for terminal
#
function set_term_colors() {
	local color_code=$1
	case $color_code in
		0) color="\e[40m" ;; # black
		1) color="\e[41m" ;; # red
		2) color="\e[42m" ;; # green
		3) color="\e[43m" ;; # yellow
		4) color="\e[44m" ;; # blue
		5) color="\e[45m" ;; # magenta
		6) color="\e[46m" ;; # cyan
		7) color="\e[47m" ;; # white
		*)
			echo "Invalid color code"
			return 1
			;;
	esac
	echo -e "$color"
}

#
# Function to reset the colors
#
function reset_colors() {
	echo -e "\e[0m"
}

module_options+=(
	["parse_menu_items,author"]="@viraniac"
	["parse_menu_items,ref_link"]=""
	["parse_menu_items,feature"]="parse_menu_items"
	["parse_menu_items,desc"]="Parse json to get list of desired menu or submenu items"
	["parse_menu_items,example"]="parse_menu_items 'menu_options_array'"
	["parse_menu_items,doc_link"]=""
	["parse_menu_items,status"]="Active"
)
#
# Function to parse the menu items
#
parse_menu_items() {
	local -n options=$1
	while IFS= read -r id; do
		IFS= read -r description
		IFS= read -r condition
		# If the condition field is not empty and not null, run the function specified in the condition
		if [[ -n $condition && $condition != "null" ]]; then
			# If the function returns a truthy value, add the menu item to the menu
			if eval $condition; then
				options+=("$id" "  -  $description")
			fi
		else
			# If the condition field is empty or null, add the menu item to the menu
			options+=("$id" "  -  $description ")
		fi
	done < <(echo "$json_data" | jq -r '.menu[] | '${parent_id:+".. | objects | select(.id==\"$parent_id\") | .sub[]? |"}' select(.status != "Disabled") | "\(.id)\n\(.description)\n\(.condition)"' || exit 1)
}

module_options+=(
	["generate_top_menu,author"]="@Tearran"
	["generate_top_menu,ref_link"]=""
	["generate_top_menu,feature"]="generate_top_menu"
	["generate_top_menu,desc"]="Build the main menu from a object"
	["generate_top_menu,example"]="generate_top_menu 'json_data'"
	["generate_top_menu,status"]="Active"
)
#
# Function to generate the main menu from a JSON object
#
generate_top_menu() {
	local json_data="$1"
	local status="$ARMBIAN $KERNELID ($DISTRO $DISTROID)"
	local backtitle="$BACKTITLE"


	while true; do
		local menu_options=()

		parse_menu_items menu_options

		local OPTION=$($DIALOG --backtitle "$backtitle" --title "$TITLE" --menu "$status" 0 80 9 "${menu_options[@]}" \
			--ok-button Select --cancel-button Exit 3>&1 1>&2 2>&3)
		local exitstatus=$?

		if [ $exitstatus = 0 ]; then
			[ -z "$OPTION" ] && break
			[[ -n "$debug" ]] && echo "$OPTION"
			generate_menu "$OPTION"
		fi
	done
}

module_options+=(
	["generate_menu,author"]="@Tearran"
	["generate_menu,ref_link"]=""
	["generate_menu,feature"]="generate_menu"
	["generate_menu,desc"]="Generate a submenu from a parent_id"
	["generate_menu,example"]="generate_menu 'parent_id'"
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

module_options+=(
	["execute_command,author"]="@Tearran"
	["execute_command,ref_link"]=""
	["execute_command,feature"]="execute_command"
	["execute_command,desc"]="Needed by generate_menu"
	["execute_command,example"]="execute_command 'id'"
	["execute_command,doc_link"]=""
	["execute_command,status"]="Active"
)
#
# Function to execute the command
#
function execute_command() {
	local id=$1

	# Extract commands
	local commands=$(jq -r --arg id "$id" '
		.menu[] |
		.. |
		objects |
		select(.id == $id) |
		.command[]?' "$json_file")

	# Check if a about exists
	local about=$(jq -r --arg id "$id" '
		.menu[] |
		.. |
		objects |
		select(.id == $id) |
		.about?' "$json_file")

	# If a about exists, display it and wait for user confirmation
	if [[ "$about" != "null" && $INPUTMODE != "cmd" ]]; then
		get_user_continue "$about\nWould you like to continue?" process_input
	fi

	# Execute each command
	for command in "${commands[@]}"; do
		[[ -n "$debug" ]] && echo "$command"
		eval "$command"
	done
}

module_options+=(
	["show_message,author"]="@Tearran"
	["show_message,ref_link"]=""
	["show_message,feature"]="show_message"
	["show_message,desc"]="Display a message box"
	["show_message,example"]="show_message <<< 'hello world' "
	["show_message,doc_link"]=""
	["show_message,status"]="Active"
)
#
# Function to display a message box
#
function show_message() {
	# Read the input from the pipe
	input=$(cat)

	# Display the "OK" message box with the input data
	if [[ $DIALOG != "bash" ]]; then
		$DIALOG --title "$TITLE" --msgbox "$input" 0 0
	else
		echo -e "$input"
		read -p -r "Press [Enter] to continue..."
	fi
}

module_options+=(
	["show_infobox,author"]="@Tearran"
	["show_infobox,ref_link"]=""
	["show_infobox,feature"]="show_infobox"
	["show_infobox,desc"]="pipeline strings to an infobox "
	["show_infobox,example"]="show_infobox <<< 'hello world' ; "
	["show_infobox,doc_link"]=""
	["show_infobox,status"]="Active"
)
#
# Function to display an infobox with a message
#
function show_infobox() {
	export TERM=ansi
	local input
	local BACKTITLE="$BACKTITLE"
	local -a buffer # Declare buffer as an array
	if [ -p /dev/stdin ]; then
		while IFS= read -r line; do
			buffer+=("$line") # Add the line to the buffer
			# If the buffer has more than 10 lines, remove the oldest line
			if ((${#buffer[@]} > 18)); then
				buffer=("${buffer[@]:1}")
			fi
			# Display the lines in the buffer in the infobox

			TERM=ansi $DIALOG --title "$TITLE" --infobox "$(printf "%s\n" "${buffer[@]}")" 16 90
			sleep 0.5
		done
	else

		input="$1"
		TERM=ansi $DIALOG --title "$TITLE" --infobox "$input" 6 80
	fi
	echo -ne '\033[3J' # clear the screen
}

module_options+=(
	["show_menu,author"]="@Tearran"
	["show_menu,ref_link"]=""
	["show_menu,feature"]="show_menu"
	["show_menu,desc"]="Display a menu from pipe"
	["show_menu,example"]="show_menu <<< armbianmonitor -h  ; "
	["show_menu,doc_link"]=""
	["show_menu,status"]="Active"
)
#
#
#
show_menu() {

	# Get the input and convert it into an array of options
	inpu_raw=$(cat)
	# Remove the lines before -h
	input=$(echo "$inpu_raw" | sed 's/-\([a-zA-Z]\)/\1/' | grep '^  [a-zA-Z] ' | grep -v '\[')
	options=()
	while read -r line; do
		package=$(echo "$line" | awk '{print $1}')
		description=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
		options+=("$package" "$description")
	done <<< "$input"

	# Display the menu and get the user's choice
	[[ $DIALOG != "bash" ]] && choice=$($DIALOG --title "$TITLE" --menu "Choose an option:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)

	# Check if the user made a choice
	if [ $? -eq 0 ]; then
		echo "$choice"
	else
		exit 0
	fi

}

module_options+=(
	["get_user_continue,author"]="@Tearran"
	["get_user_continue,ref_link"]=""
	["get_user_continue,feature"]="get_user_continue"
	["get_user_continue,desc"]="Display a Yes/No dialog box and process continue/exit"
	["get_user_continue,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["get_user_continue,doc_link"]=""
	["get_user_continue,status"]="Active"
)
#
# Function to display a Yes/No dialog box
#
function get_user_continue() {
	local message="$1"
	local next_action="$2"

	if $($DIALOG --yesno "$message" 15 80 3>&1 1>&2 2>&3); then
		$next_action
	else
		$next_action "No"
	fi
}


#
# Functions to display warning for 10 seconds with a gauge
#
module_options+=(
	["info_wait_autocontinue,author"]="@igorpecovnik"
	["info_wait_autocontinue,ref_link"]=""
	["info_wait_autocontinue,feature"]="info_wait_autocontinue"
	["info_wait_autocontinue,desc"]="Display a warning with a gauge for 10 seconds then continue"
	["info_wait_autocontinue,example"]=""
	["info_wait_autocontinue,doc_link"]=""
	["info_wait_autocontinue,status"]="Active"
)
function info_wait_continue() {
	local message="$1"
	local next_action="$2"
	{
	for ((i=0; i<=100; i+=10)); do
		sleep 1
		echo $i
	done
	} | $DIALOG --gauge "$message" 15 80 0
}

menu_options+=(
	["get_user_continue,author"]="@Tearran"
	["get_user_continue,ref_link"]=""
	["get_user_continue,feature"]="process_input"
	["get_user_continue,desc"]="used to process the user's choice paired with get_user_continue"
	["get_user_continue,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["get_user_continue,status"]="Active"
	["get_user_continue,doc_link"]=""
)
#
# Function to process the user's choice paired with get_user_continue
#
function process_input() {
	local input="$1"
	if [ "$input" = "No" ]; then
		# user canceled
		echo "User canceled. exiting"
		exit 0
	fi
}

module_options+=(
	["get_user_continue_secure,author"]="@Tearran"
	["get_user_continue_secure,ref_link"]=""
	["get_user_continue_secure,feature"]="get_user_continue_secure"
	["get_user_continue_secure,desc"]="Secure version of get_user_continue"
	["get_user_continue_secure,example"]="get_user_continue_secure 'Do you wish to continue?' process_input"
	["get_user_continue_secure,doc_link"]=""
	["get_user_continue_secure,status"]="Active"
)
#
# Secure version of get_user_continue
#
function get_user_continue_secure() {
	local message="$1"
	local next_action="$2"

	# Define a list of allowed functions
	local allowed_functions=("process_input" "other_function")
	# Check if the next_action is in the list of allowed functions
	found=0
	for func in "${allowed_functions[@]}"; do
		if [[ "$func" == "$next_action" ]]; then
			found=1
			break
		fi
	done

	if [[ "$found" -eq 1 ]]; then
		if $($DIALOG --yesno "$message" 10 80 3>&1 1>&2 2>&3); then
			$next_action
		else
			$next_action "No"
		fi
	else
		echo "Error: Invalid function"

		exit 1
	fi
}

module_options+=(
	["see_current_apt,author"]="@Tearran"
	["see_current_apt,ref_link"]=""
	["see_current_apt,feature"]="see_current_apt"
	["see_current_apt,desc"]="Check when apt list was last updated and suggest updating or update"
	["see_current_apt,example"]="see_current_apt or see_current_apt update"
	["see_current_apt,doc_link"]=""
	["see_current_apt,status"]="Active"
)
#
# Function to check when the package list was last updated
#
see_current_apt() {
	# Number of seconds in a day
	local update_apt="$1"
	local day=86400
	local ten_minutes=600
	# Get the current date as a Unix timestamp
	local now=$(date +%s)

	# Get the timestamp of the most recently updated file in /var/lib/apt/lists/
	local update=$(stat -c %Y /var/lib/apt/lists/* 2>/dev/null | sort -n | tail -1)

	# Check if the update timestamp was found
	if [[ -z "$update" ]]; then
		echo "No package lists found."
		return 1 # No package lists exist
	fi

	# Calculate the number of seconds since the last update
	local elapsed=$((now - update))

	# Check if any apt-related processes are running
	if ps -C apt-get,apt,dpkg > /dev/null; then
		echo "A package manager is currently running."
		export running_pkg="true"
		return 1 # The processes are running
	else
		export running_pkg="false"
	fi

	# Check if the package list is up-to-date
	if ((elapsed < ten_minutes)); then
		[[ "$update_apt" != "update" ]] && echo "The package lists are up-to-date."
		return 0 # The package lists are up-to-date
	else
		[[ "$update_apt" != "update" ]] && echo "Update the package lists." # Suggest updating
		[[ "$update_apt" == "update" ]] && pkg_update
		return 0 # The package lists are not up-to-date
	fi
}

module_options+=(
	["sanitize,author"]="@Tearran"
	["sanitize,desc"]="Make sure param contains only valid chars"
	["sanitize,example"]="sanitize 'foo_bar_42'"
	["sanitize,feature"]="sanitize"
	["sanitize,status"]="Interface"
)

sanitize() {
	[[ "$1" =~ ^[a-zA-Z0-9_=]+$ ]] && echo "$1" || die "Invalid argument: $1"
}

module_options+=(
	["die,author"]="@dimitry-ishenko"
	["die,desc"]="Exit with error code 1, optionally printing a message to stderr"
	["die,example"]="run_critical_function || die 'The world is about to end'"
	["die,feature"]="die"
	["die,status"]="Interface"
)

die() {
	(( $# )) && echo "$@" >&2
	exit 1
}


module_options+=(
	["is_package_manager_running,author"]="@armbian"
	["is_package_manager_running,ref_link"]=""
	["is_package_manager_running,feature"]="is_package_manager_running"
	["is_package_manager_running,desc"]="Migrated procedures from Armbian config."
	["is_package_manager_running,example"]="is_package_manager_running"
	["is_package_manager_running,status"]="Active"
)
#
# check if package manager is doing something
#
function is_package_manager_running() {

	if ps -C apt-get,apt,dpkg > /dev/null; then
		[[ -z $scripted ]] && echo -e "\nPackage manager is running in the background.\n\nCan't install dependencies. Try again later." | show_infobox
		return 0
	else
		return 1
	fi

}


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
			pkg_install ${missing_dependencies[*]}
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if srv_active NetworkManager; then
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
		pkg_install --update --allow-downgrades --no-install-recommends lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	[[ -f /etc/armbian-distribution-status ]] && DISTRO_STATUS="/etc/armbian-distribution-status"

	# Docker installatons read timezone and they will fail if this doesn't exist. This is often the case with some minimal Debian/Ubuntu installations.
	if [[ ! -f /etc/timezone ]]; then
		echo "America/New_York" | sudo tee /etc/timezone
	fi

	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc 2> /dev/null || grep "VERSION=" /etc/os-release | grep -oP '(?<=\().*(?=\))')
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"

	SOFTWARE_FOLDER="/armbian" # where we should keep 3rd party software
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	LOCALSUBNET=$(echo ${LOCALIPADD} | cut -d"." -f1-3).0/24

	# create local lan and docker lan whitelist for transmission
	TRANSMISSION_WHITELIST=$(echo ${LOCALIPADD} | cut -d"." -f1-3)".*"
	local docker_subnet=$(docker network inspect lsio 2> /dev/null | grep Subnet | xargs | cut -d" " -f2 | cut -d"/" -f1 | cut -d"." -f1-2)
	if [[ -n "${docker_subnet}" ]]; then
		TRANSMISSION_WHITELIST+=",${docker_subnet}.*.*"
	fi

	BACKTITLE="Contribute: https://github.com/armbian/configng"
	TITLE="Armbian configuration utility"
	[[ -z "${DEFAULT_ADAPTER// /}" ]] && DEFAULT_ADAPTER="lo"
	# zfs subsystem - determine if our kernel is not too recent
	ZFS_DKMS_VERSION=$(LC_ALL=C apt-cache policy zfs-dkms | grep Candidate | xargs | cut -d" " -f2 | cut -c-5)
	ZFS_KERNEL_MAX=$(wget -qO- https://raw.githubusercontent.com/openzfs/zfs/refs/tags/zfs-${ZFS_DKMS_VERSION}/META | grep Maximum | cut -d" " -f2)
	# sometimes Ubuntu sets higher version then existing tag. Lets probe previous version
	if [[ -z "${ZFS_KERNEL_MAX}" ]]; then
		local previous_version="$(printf "%03d" "$(expr "$(echo $ZFS_DKMS_VERSION | sed 's/\.//g')" - 1)")"
		local previous_version=$(echo "${previous_version:0:1}.${previous_version:1:1}.${previous_version:2:1}")
		ZFS_KERNEL_MAX=$(wget -qO- https://raw.githubusercontent.com/openzfs/zfs/refs/tags/zfs-${previous_version}/META | grep Maximum | cut -d" " -f2)
	fi
	# detect desktop
	check_desktop

}

#
# Retrieve info from currently installed kernel, update /etc/armbian-release if required
# (after switching kernel, but before a reboot, BRANCH can contain an outdated value)
#
function update_kernel_env() {
	local list_of_installed_kernels=$(dpkg -l | grep '^[hi]i' | grep linux-image | head -1)
	local new_branch=$(echo "$list_of_installed_kernels" | awk '{print $2}' | cut -d'-' -f3)
	# these don't necessarily match the system-wide values from /etc/armbian-release
	KERNELPKG_VERSION=$(echo "$list_of_installed_kernels" | awk '{print $3}')
	KERNELPKG_LINUXFAMILY=$(echo "$list_of_installed_kernels" | awk '{print $2}' | cut -d'-' -f4)

	[[ "$BRANCH" == "$new_branch" ]] && return

	# BRANCH has changed: update required
	if [[ -f /etc/armbian-release ]]; then
		if grep -q BRANCH /etc/armbian-release; then
			sed -i "s/BRANCH=.*/BRANCH=$new_branch/g" /etc/armbian-release
		else
			echo "BRANCH=$new_branch" >> /etc/armbian-release
		fi
	fi
	BRANCH=$new_branch
}


module_options+=(
	["check_desktop,author"]="@armbian"
	["check_desktop,ref_link"]=""
	["check_desktop,feature"]="check_desktop"
	["check_desktop,desc"]="Migrated procedures from Armbian config."
	["check_desktop,example"]="check_desktop"
	["check_desktop,status"]="Active"
	["check_desktop,doc_link"]=""
)
#
# read desktop parameters
#
function check_desktop() {

	unset DESKTOP_INSTALLED
	pkg_installed nodm && DESKTOP_INSTALLED="nodm"
	pkg_installed lightdm && DESKTOP_INSTALLED="lightdm"
	pkg_installed gdm3 && DESKTOP_INSTALLED="gnome"

	unset DISPLAY_MANAGER
	srv_active nodm && DISPLAY_MANAGER="nodm"
	srv_active lightdm && DISPLAY_MANAGER="lightdm"
	srv_active gdm && DISPLAY_MANAGER="gdm"
}

# service.sh

# internal function
_srv_system_running() { [[ $(systemctl is-system-running) =~ ^(running|degraded)$ ]]; }

declare -A module_options
module_options+=(
	["srv_active,author"]="@dimitry-ishenko"
	["srv_active,desc"]="Check if service is active"
	["srv_active,example"]="srv_active ssh.service"
	["srv_active,feature"]="srv_active"
	["srv_active,status"]="Interface"
)

srv_active()
{
	# fail inside container
	_srv_system_running && systemctl is-active --quiet "$@"
}

declare -A module_options
module_options+=(
	["srv_daemon_reload,author"]="@dimitry-ishenko"
	["srv_daemon_reload,desc"]="Reload systemd configuration"
	["srv_daemon_reload,example"]="srv_daemon_reload"
	["srv_daemon_reload,feature"]="srv_daemon_reload"
	["srv_daemon_reload,status"]="Interface"
)

srv_daemon_reload()
{
	# ignore inside container
	_srv_system_running && systemctl daemon-reload || true
}

module_options+=(
	["srv_disable,author"]="@dimitry-ishenko"
	["srv_disable,desc"]="Disable service"
	["srv_disable,example"]="srv_disable ssh.service"
	["srv_disable,feature"]="srv_disable"
	["srv_disable,status"]="Interface"
)

srv_disable() { systemctl disable "$@"; }

module_options+=(
	["srv_enable,author"]="@dimitry-ishenko"
	["srv_enable,desc"]="Enable service"
	["srv_enable,example"]="srv_enable ssh.service"
	["srv_enable,feature"]="srv_enable"
	["srv_enable,status"]="Interface"
)

srv_enable() { systemctl enable "$@"; }

module_options+=(
	["srv_enabled,author"]="@dimitry-ishenko"
	["srv_enabled,desc"]="Check if service is enabled"
	["srv_enabled,example"]="srv_enabled ssh.service"
	["srv_enabled,feature"]="srv_enabled"
	["srv_enabled,status"]="Interface"
)

srv_enabled() { systemctl is-enabled "$@"; }

module_options+=(
	["srv_mask,author"]="@dimitry-ishenko"
	["srv_mask,desc"]="Mask service"
	["srv_mask,example"]="srv_mask ssh.service"
	["srv_mask,feature"]="srv_mask"
	["srv_mask,status"]="Interface"
)

srv_mask() { systemctl mask "$@"; }

module_options+=(
	["srv_reload,author"]="@dimitry-ishenko"
	["srv_reload,desc"]="Reload service"
	["srv_reload,example"]="srv_reload ssh.service"
	["srv_reload,feature"]="srv_reload"
	["srv_reload,status"]="Interface"
)

srv_reload()
{
	# ignore inside container
	_srv_system_running && systemctl reload "$@" || true
}

module_options+=(
	["srv_restart,author"]="@dimitry-ishenko"
	["srv_restart,desc"]="Restart service"
	["srv_restart,example"]="srv_restart ssh.service"
	["srv_restart,feature"]="srv_restart"
	["srv_restart,status"]="Interface"
)

srv_restart()
{
	# ignore inside container
	_srv_system_running && systemctl restart "$@" || true
}

module_options+=(
	["srv_start,author"]="@dimitry-ishenko"
	["srv_start,desc"]="Start service"
	["srv_start,example"]="srv_start ssh.service"
	["srv_start,feature"]="srv_start"
	["srv_start,status"]="Interface"
)

srv_start()
{
	# ignore inside container
	_srv_system_running && systemctl start "$@" || true
}

module_options+=(
	["srv_status,author"]="@dimitry-ishenko"
	["srv_status,desc"]="Show service status information"
	["srv_status,example"]="srv_status ssh.service"
	["srv_status,feature"]="srv_status"
	["srv_status,status"]="Interface"
)

srv_status() { systemctl status "$@"; }

module_options+=(
	["srv_stop,author"]="@dimitry-ishenko"
	["srv_stop,desc"]="Stop service"
	["srv_stop,example"]="srv_stop ssh.service"
	["srv_stop,feature"]="srv_stop"
	["srv_stop,status"]="Interface"
)

srv_stop()
{
	# ignore inside container
	_srv_system_running && systemctl stop "$@" || true
}

module_options+=(
	["srv_unmask,author"]="@dimitry-ishenko"
	["srv_unmask,desc"]="Unmask service"
	["srv_unmask,example"]="srv_unmask ssh.service"
	["srv_unmask,feature"]="srv_unmask"
	["srv_unmask,status"]="Interface"
)

srv_unmask() { systemctl unmask "$@"; }


module_options+=(
	["set_interface,author"]="Tearran"
	["set_interface,feature"]="set_interface"
	["set_interface,desc"]="Check for (Whiptail, DIALOG, READ) tools and set the user interface."
	["set_interface,example"]=""
	["set_interface,status"]="review"
)
#
# Check for (Whiptail, DIALOG, READ) tools and set the user interface
set_interface() {
	# Set dialog tool hierarchy based on environment
	if [[ -x "$(command -v whiptail)" ]]; then
		DIALOG="whiptail"
	elif [[ -x "$(command -v dialog)" ]]; then
		DIALOG="dialog"
	else
		DIALOG="read"  # Fallback to read if no dialog tool is available
	fi
}



module_options+=(
	["see_menu,author"]="Tearran"
	["see_menu,feature"]="see_menu"
	["see_menu,desc"]="Uses Avalible (Whiptail, DIALOG, READ) for the menu interface"
	["see_menu,example"]="<function_name>"
	["see_menu,status"]="review"
)
#
# Uses Avalible (Whiptail, DIALOG, READ) for the menu interface
function see_menu() {
	# Check if the function name was provided
	local function_name="$1"

	# Get the help message from the specified function
	help_message=$("$function_name" help)

	# Prepare options for the dialog tool based on help message
	options=()
		while IFS= read -r line; do
		if [[ $line =~ ^[[:space:]]*([a-zA-Z0-9_-]+)[[:space:]]*-\s*(.*)$ ]]; then
			options+=("${BASH_REMATCH[1]}" "  -  ${BASH_REMATCH[2]}")
		fi
		done <<< "$help_message"

	# Display menu based on DIALOG tool
	case $DIALOG in
		"dialog")
		choice=$(dialog --title "${function_name^}" --menu "Choose an option:" 0 80 9 "${options[@]}" 2>&1 >/dev/tty)
		;;
		"whiptail")
		choice=$(whiptail --title "${function_name^}" --menu "Choose an option:" 0 80 9 "${options[@]}" 3>&1 1>&2 2>&3)
		;;
		"read")
		echo "Available options:"
		for ((i=0; i<${#options[@]}; i+=2)); do
			echo "$((i / 2 + 1)). ${options[i]} - ${options[i + 1]}"
		done
		read -p "Enter choice number: " choice_index
		choice=${options[((choice_index - 1) * 2)]}
		;;
	esac

	# Check if choice was made or canceled
	if [[ -z $choice ]]; then
		echo "Menu canceled."

		return 1
	fi

	# Call the specified function with the chosen option
	"$function_name" "$choice"
}

#set_interface
#see_menu "$@"


module_options+=(
	["check_os_status,author"]="@Tearran"
	["check_os_status,feature"]="check_os_status"
	["check_os_status,example"]="help"
	["check_os_status,desc"]="Check if the current OS is supported based on /etc/armbian-distribution-status"
	["check_os_status,status"]="Active"
)

function check_distro_status() {
	case "$1" in
		help)
			echo "Usage: check_os_status"
			echo "This function checks if the current OS is supported based on /etc/armbian-distribution-status."
			echo "It retrieves the current OS distribution and checks if it is listed as supported in the specified file."
		;;
		*)

			# Ensure OS detection succeeded
			# if [[ -z "$DISTROID" && -z "$ARMBIAN" ]]; then
			if [[ -z "$DISTROID" ]]; then
				echo "Error: Unable to detect the current OS distribution."
				exit 1
			fi

			# Check if the OS is listed as supported in the DISTRO_STATUS
			if grep -qE "^${DISTROID}=.*supported" "$DISTRO_STATUS" 2> /dev/null; then
				echo "The current $ARMBIAN ($DISTROID) is supported."
			else
			BACKTITLE="Warning: The current OS ($DISTROID) is not supported or not listed"
			set_colors 1
			info_wait_continue "Warning:

			The current OS ($DISTROID) is not a officially supported distro!

			The tool might still work well, but be aware that issues may
			not be accepted and addressed by the maintainers. However, you
			are welcome to contribute fixes for any problems you encounter.
			" process_input
			fi
		;;
	esac
}

# package.sh

# internal function
_pkg_have_stdin() { [[ -t 0 ]]; }

declare -A module_options
module_options+=(
	["pkg_configure,author"]="@dimitry-ishenko"
	["pkg_configure,desc"]="Configure an unconfigured package"
	["pkg_configure,example"]="pkg_configure"
	["pkg_configure,feature"]="pkg_configure"
	["pkg_configure,status"]="Interface"
)

pkg_configure()
{
	_pkg_have_stdin && debconf-apt-progress -- dpkg --configure "$@" || dpkg --configure "$@"
}

module_options+=(
	["pkg_full_upgrade,author"]="@dimitry-ishenko"
	["pkg_full_upgrade,desc"]="Upgrade installed packages (potentially removing some)"
	["pkg_full_upgrade,example"]="pkg_full_upgrade"
	["pkg_full_upgrade,feature"]="pkg_full_upgrade"
	["pkg_full_upgrade,status"]="Interface"
)

pkg_full_upgrade()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y full-upgrade "$@" || apt-get -y full-upgrade "$@"
}

module_options+=(
	["pkg_install,author"]="@dimitry-ishenko"
	["pkg_install,desc"]="Install package"
	["pkg_install,example"]="pkg_install neovim"
	["pkg_install,feature"]="pkg_install"
	["pkg_install,status"]="Interface"
)

pkg_install()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y install "$@" || apt-get -y install "$@"
}

module_options+=(
	["pkg_installed,author"]="@dimitry-ishenko"
	["pkg_installed,desc"]="Check if package is installed"
	["pkg_installed,example"]="pkg_installed mc"
	["pkg_installed,feature"]="pkg_installed"
	["pkg_installed,status"]="Interface"
)

pkg_installed()
{
	local status=$(dpkg -s "$1" 2>/dev/null | sed -n "s/Status: //p")
	! [[ -z "$status" || "$status" = *deinstall* || "$status" = *not-installed* ]]
}

module_options+=(
	["pkg_remove,author"]="@dimitry-ishenko"
	["pkg_remove,desc"]="Remove package"
	["pkg_remove,example"]="pkg_remove nmap"
	["pkg_remove,feature"]="pkg_remove"
	["pkg_remove,status"]="Interface"
)

pkg_remove()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y autopurge "$@" || apt-get -y autopurge "$@"
}

module_options+=(
	["pkg_update,author"]="@dimitry-ishenko"
	["pkg_update,desc"]="Update package repository"
	["pkg_update,example"]="pkg_update"
	["pkg_update,feature"]="pkg_update"
	["pkg_update,status"]="Interface"
)

pkg_update()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y update || apt-get -y update
}

module_options+=(
	["pkg_upgrade,author"]="@dimitry-ishenko"
	["pkg_upgrade,desc"]="Upgrade installed packages"
	["pkg_upgrade,example"]="pkg_upgrade"
	["pkg_upgrade,feature"]="pkg_upgrade"
	["pkg_upgrade,status"]="Interface"
)

pkg_upgrade()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y upgrade "$@" || apt-get -y upgrade "$@"
}

module_options+=(
	["pkg_fix,author"]="@igorpecovnik"
	["pkg_fix,desc"]="Fix dependency issues"
	["pkg_fix,example"]="pkg_fix"
	["pkg_fix,feature"]="pkg_fix"
	["pkg_fix,status"]="Interface"
)

pkg_fix()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y --fix-broken install "$@" || apt-get -y --fix-broken install "$@"
}

# module_default.sh

module_options+=(
	["module_default,author"]="@dimitry-ishenko"
	["module_default,desc"]="Default module implementation"
	["module_default,example"]="disable enable help install remove status"
	["module_default,feature"]="module_default"
)

module_default()
{
	local action="$1" modules="$2" packages="$3" services="$4"
	shift 4

	case "$action" in
		enable)  _module_default_invoke "$action" "$modules" "$services" "$@";;
		disable) _module_default_invoke "$action" "$modules" "$services" "$@";;
		help)    _module_default_invoke "$action" "$modules" "$modules" "$packages" "$services" "$@";;
		install) _module_default_invoke "$action" "$modules" "$packages" "$@";;
		remove)  _module_default_invoke "$action" "$modules" "$packages" "$@";;
		status)  _module_default_invoke "$action" "$modules" "$packages" "$services" "$@";;
		*)       _module_default_invoke "$action" "$modules" "$packages" "$services" "$@";;
	esac
}

_module_default_invoke()
{
	local action="$1" modules="$2"
	shift 2

	for module in $modules default; do
		local fn="module_${module}_${action}"
		if [[ $(type -t "$fn") == "function" ]]; then
			"$fn" "$@"
			return 0
		fi
	done

	echo "Unknown action '$action'"
	return 1
}

module_default_disable()
{
	local services="$1"
	echo "Disabling $services..."
	srv_disable $services
}

module_default_enable()
{
	local services="$1"
	echo "Enabling $services..."
	srv_enable $services
}

module_default_help()
{
	local module=($1) packages="$2" services="$3" extra="$4"

	local text="
Usage: module_$module <action> [options...]

Where <action> is one of:
	disable     Disable service(s) for $module.
	enable      Enable service(s) for $module.
	help        Show this help screen.
	install     Install package(s) for $module.
	remove      Remove package(s) for $module.
	status      Check $module status (installed and/or enabled)."

	# remove "install" and "remove" lines, if the module doesn't install anything (eg, service-only module)
	[[ -n "$packages" ]] || text=`grep -Pve " (install|remove) " <<< "$text"`

	# remove "enable" and "disable" lines, if the module doesn't have any services (eg, software-only module)
	[[ -n "$services" ]] || text=`grep -Pve " (enable|disable) " <<< "$text"`

	# remove the "status" line, if the modules doesn't have status (eg, internal module
	# that doesn't install any packages and doesn't have any services)
	[[ -n "$packages$services" ]] || text=`grep -Pv " status " <<< "$text"`

	echo "$text"
	[[ -z "$extra" ]] || echo "$extra"
	echo
}

module_default_install()
{
	local packages="$1"
	echo "Installing $packages..."
	pkg_install $packages
}

module_default_remove()
{
	local packages="$1"
	echo "Removing $packages..."
	pkg_remove $packages
}

module_default_status()
{
	local packages="$1" services="$2"
	[[ -z "$services" ]] || srv_enabled $services || return 1
	[[ -z "$packages" ]] || pkg_installed $packages
}

