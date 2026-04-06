
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

# package.sh

# internal function
_pkg_have_stdin() { [[ -t 0 ]]; }

declare -A module_options
module_options+=(
	["apt_operation_progress,author"]="@igorpecovnik"
	["apt_operation_progress,desc"]="Internal wrapper for APT operations with progress display"
	["apt_operation_progress,status"]="Internal"
)

# Wrapper for apt operations with progress display
# Replaces debconf-apt-progress with dialog_gauge UI
# Usage: apt_operation_progress <operation> [apt_args...]
# Operations: update, upgrade, full-upgrade, install, remove, fix-broken
apt_operation_progress() {
	local operation="$1"
	shift
	local args=("$@")
	local title="APT Operation"
	local error_file=$(mktemp)
	local exit_code

	case "$operation" in
		update)
			title="Package Update"
			;;
		upgrade)
			title="Package Upgrade"
			;;
		full-upgrade)
			title="Full Package Upgrade"
			;;
		install)
			title="Install Package"
			;;
		remove|autopurge)
			title="Remove Package"
			;;
		fix-broken)
			title="Fix Broken Packages"
			;;
		*)
			title="APT Operation"
			;;
	esac

	if [[ "$DIALOG" == "read" ]]; then
		# For read mode, just run without progress
		if [[ "$operation" == "fix-broken" ]]; then
			apt-get -y --fix-broken install "$@" 2>&1 | tee "$error_file"
		elif [[ "$operation" == "autopurge" ]]; then
			apt-get -y autopurge "$@" 2>&1 | tee "$error_file"
		else
			apt-get -y "$operation" "$@" 2>&1 | tee "$error_file"
		fi
		exit_code=${PIPESTATUS[0]}
	else
		# With dialog/whiptail, show progress
		(
			echo "XXX"
			echo "0"
			echo "Starting $operation..."
			echo "XXX"

			# Build apt command
			local apt_cmd
			if [[ "$operation" == "fix-broken" ]]; then
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y --fix-broken install ${args[*]}"
			elif [[ "$operation" == "autopurge" ]]; then
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y autopurge ${args[*]}"
			else
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y $operation ${args[*]}"
			fi

			# Run apt command and capture output
			eval "$apt_cmd" 2>&1 | while IFS= read -r line; do
				# Parse apt output for progress indicators
				if [[ "$line" =~ ^(Hit|Get|Reading|Download|Fetch|Hit|Preparing|Unpacking|Setting|Selecting|Processing) ]]; then
					echo "XXX"
					echo "0"
					echo "$line"
					echo "XXX"
				elif [[ "$line" =~ (Err|Error|FAILED|could not|unable to) ]]; then
					echo "XXX"
					echo "0"
					echo "Error: $line"
					echo "XXX"
				fi
			done

			echo "XXX"
			echo "100"
			echo "$operation complete!"
			echo "XXX"
		) | dialog_gauge "$title" "Processing $operation..." 8 80

		exit_code=$?
	fi

	# Show any errors
	if [[ -s "$error_file" ]]; then
		if [[ $exit_code -ne 0 ]]; then
			dialog_msgbox "$title Failed" "$operation failed.\n\n$(cat "$error_file" | tail -20)" 12 60
		fi
	fi

	rm -f "$error_file"
	return $exit_code
}

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
	apt_operation_progress full-upgrade "$@"
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
	local exit_code
	apt_operation_progress install "$@"
	exit_code=$?

	if [[ $exit_code == 100 ]]; then
		dpkg --configure -a
		apt_operation_progress install "$@"
		exit_code=$?
	fi

	return $exit_code
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
	local exit_code
	apt_operation_progress autopurge "$@"
	exit_code=$?

	if [[ $exit_code == 100 ]]; then
		dpkg --configure -a
		apt_operation_progress autopurge "$@"
		exit_code=$?
	fi

	return $exit_code
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
	apt_operation_progress update
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
	apt_operation_progress upgrade "$@"
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
	apt_operation_progress fix-broken "$@"
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

	# Check if dialog tools are available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		if [[ -x "$(command -v dialog)" ]]; then
			DIALOG="dialog"
		elif [[ -x "$(command -v whiptail)" ]]; then
			DIALOG="whiptail"
		else
			# No dialog tool available, use text-based interface
			DIALOG="read"
		fi
	fi

	# Check if udevadm is available
	if ! [[ -x "$(command -v udevadm)" ]]; then
		missing_dependencies+=("udev")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# Check if curl is available (required for Docker API)
	if ! [[ -x "$(command -v curl)" ]]; then
		missing_dependencies+=("curl")
	fi

	# Check if unbuffer is available (required for real-time Docker pull progress)
	if ! [[ -x "$(command -v unbuffer)" ]]; then
		missing_dependencies+=("expect")
	fi

	# Check if stdbuf is available (required for line buffering)
	if ! [[ -x "$(command -v stdbuf)" ]]; then
		missing_dependencies+=("coreutils")
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

	# Running container under the actual user (handles sudo)
	# When run with sudo, get the real user's UID/GID, not root's
	if [[ -n "$SUDO_USER" ]]; then
		# Running with sudo - use the real user who invoked sudo
		DOCKER_USERUID=$(id -u "$SUDO_USER")
		DOCKER_GROUPUID=$(id -g "$SUDO_USER")
	elif [[ $EUID -eq 0 ]]; then
		# Running as root without sudo - try to detect an interactive non-root user
		# Try logname first (most reliable)
		local detected_user=$(logname 2>/dev/null)
		if [[ -z "$detected_user" ]] || [[ "$detected_user" == "root" ]]; then
			# Fall back to 'who am i' parsing
			detected_user=$(who am i 2>/dev/null | awk '{print $1}')
			if [[ -z "$detected_user" ]] || [[ "$detected_user" == "root" ]]; then
				# No interactive user detected - use sensible defaults
				# This allows root operations that don't involve Docker
				DOCKER_USERUID=1000
				DOCKER_GROUPUID=1000
			else
				# Use detected user from 'who am i'
				DOCKER_USERUID=$(id -u "$detected_user")
				DOCKER_GROUPUID=$(id -g "$detected_user")
			fi
		else
			# Use detected user from logname
			DOCKER_USERUID=$(id -u "$detected_user")
			DOCKER_GROUPUID=$(id -g "$detected_user")
		fi
	else
		# Running as regular user without sudo
		DOCKER_USERUID=$(id -u)
		DOCKER_GROUPUID=$(id -g)
	fi

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

	BACKTITLE="\Zb\Z7Support Armbian:\Zn https://github.com/sponsors/armbian"
	TITLE="armbian-config"
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
	elif [ "$DIALOG" = "read" ]; then
		# Text-based interface doesn't support colors, just return success
		return 0
	else
		echo "Invalid dialog type: $DIALOG"
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
	["parse_menu_items,desc"]="Parse json to get list of desired menu or submenu items. Can return pairs or triplets depending on --with-help flag."
	["parse_menu_items,example"]="parse_menu_items 'menu_options_array'\nparse_menu_items 'menu_options_array' --with-help"
	["parse_menu_items,doc_link"]=""
	["parse_menu_items,status"]="Active"
)
#
# Function to parse the menu items
#
parse_menu_items() {
	local -n options=$1
	local with_help=false

	# Check if --with-help flag is passed
	[[ "$2" == "--with-help" ]] && with_help=true

	while IFS= read -r id; do
		IFS= read -r description
		IFS= read -r condition
		IFS= read -r container_type
		IFS= read -r help_text
		# Append [C] for container-based software
		if [[ "$container_type" != "null" && -n "$container_type" ]]; then
			description="$description [C]"
		fi
		# If the condition field is not empty and not null, run the function specified in the condition
		if [[ -n $condition && $condition != "null" ]]; then
			# If the function returns a truthy value, add the menu item to the menu
			if eval $condition; then
				if $with_help; then
					# Return triplets: id, description, help
					options+=("$id" "  -  $description" "$help_text")
				else
					# Return pairs: id, description
					options+=("$id" "  -  $description")
				fi
			fi
		else
			# If the condition field is empty or null, add the menu item to the menu
			if $with_help; then
				# Return triplets: id, description, help
				options+=("$id" "  -  $description " "$help_text")
			else
				# Return pairs: id, description
				options+=("$id" "  -  $description ")
			fi
		fi
	done < <(echo "$json_data" | jq -r '.menu[] | '${parent_id:+".. | objects | select(.id==\"$parent_id\") | .sub[]? |"}' select(.status != "Disabled") | "\(.id)\n\(.description)\n\(.condition)\n\(.container_type // "null")\n\(.help // "")"' || exit 1)
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
	local status=" "

	while true; do
		local menu_options=()

		parse_menu_items menu_options --with-help

		local OPTION=$(dialog_menu "armbian-config" "$status" 0 100 10 --ok-button Select --cancel-button Exit --item-help -- "${menu_options[@]}")
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
	local status=""
	local menu_title

	# Build menu title from parent IDs
	if [[ -n "$top_parent_id" && -n "$parent_id" ]]; then
		menu_title="$TITLE > $top_parent_id > $parent_id"
	elif [[ -n "$parent_id" ]]; then
		menu_title="$TITLE > $parent_id"
	else
		menu_title="$TITLE"
	fi

	# Get the 'description' text for the current menu item to use as prompt
	local description_text=$(jq -r --arg id "$parent_id" '.menu[] | .. | objects | select(.id==$id) | .description // ""' "$json_file" 2>/dev/null)
	status="$description_text"

	while true; do
		# Get the submenu options for the current parent_id
		local submenu_options=()
		parse_menu_items submenu_options --with-help

		local OPTION=$(dialog_menu "$menu_title" "$status" 0 100 10 --ok-button Select --cancel-button Back --item-help -- "${submenu_options[@]}")

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
		get_user_continue "\n\n$about\n\nWould you like to continue?" process_input
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

	# Display the "OK" message box with the input data using the dialog_msgbox wrapper
	if [[ $DIALOG != "bash" ]]; then
		dialog_msgbox "$TITLE" "$input" 0 0
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
			# Display the lines in the buffer in the infobox using the dialog_infobox wrapper
			dialog_infobox "$TITLE" "$(printf "%s\n" "${buffer[@]}")" 16 90
			sleep 0.5
		done
	else

		input="$1"
		# Display the infobox using the dialog_infobox wrapper
		dialog_infobox "$TITLE" "$input" 6 80
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

	# Display the menu and get the user's choice using the dialog_menu wrapper
	[[ $DIALOG != "bash" ]] && choice=$(dialog_menu "$TITLE" "Choose an option:" 0 0 9 -- "${options[@]}")

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

	if dialog_yesno "Warning" "$message" "Yes" "No" 15 80; then
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
	} | dialog_gauge "$TITLE" "$message" 15 80

	# Execute the next action after the gauge completes
	[[ -n "$next_action" ]] && $next_action
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
		if dialog_yesno "" "$message" "Yes" "No" 10 80; then
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
	[[ "$1" =~ ^[a-zA-Z0-9_=-]+$ ]] && echo "$1" || die "Invalid argument: $1"
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

#
# Dialog abstraction layer - provides unified interface for whiptail/dialog
# Maintains backward compatibility while allowing easy switching between dialog tools
#

module_options+=(
	["dialog_menu,author"]="@armbian"
	["dialog_menu,desc"]="Display a menu dialog using the configured dialog tool. Supports --item-help for additional help text per item."
	["dialog_menu,example"]="dialog_menu \"Title\" \"Prompt\" option1 \"Description 1\" option2 \"Description 2\"\n# With --item-help:\ndialog_menu \"Title\" \"Prompt\" --item-help tag1 \"Item 1\" \"Help for item 1\" tag2 \"Item 2\" \"Help for item 2\""
	["dialog_menu,feature"]="dialog_menu"
	["dialog_menu,status"]="Active"
)

#
# Function to strip dialog color codes
# Removes \Z sequences (e.g., \Zb\Z1\Zn) used by dialog colors
# Used when whiptail is active since it doesn't support color codes
#
strip_color_codes() {
	local text="$1"
	# Remove all dialog color escape sequences \Z<any char>
	echo "$text" | sed 's/\\Z.//g'
}

# Display a menu dialog with proper redirection for each dialog tool
dialog_menu() {
	local title="$1"
	local prompt="$2"
	local height="${3:-0}"
	local width="${4:-80}"
	local list_height="${5:-9}"
	shift 5

	# Parse arguments: everything before -- is extra args, everything after is data
	local extra_args=()
	local options=()
	local use_item_help=false

	while [[ $# -gt 0 ]]; do
		if [[ "$1" == "--" ]]; then
			shift
			break
		elif [[ "$1" == --* ]]; then
			# For dialog options that require arguments (like --ok-button), consume both the flag and its value
			case "$1" in
				--ok-button|--cancel-button|--yes-button|--no-button|--default-item|--backtitle)
					extra_args+=("$1")
					shift
					if [[ $# -gt 0 && "$1" != --* ]]; then
						extra_args+=("$1")
						shift
					fi
					;;
				--item-help)
					use_item_help=true
					extra_args+=("$1")
					shift
					;;
				*)
					extra_args+=("$1")
					shift
					;;
			esac
		else
			break
		fi
	done

	# All remaining arguments are data (options)
	options=("$@")

	case "$DIALOG" in
		"whiptail")
			# whiptail doesn't support --item-help, convert triplets to pairs
			local whiptail_args=()
			local whiptail_options=()
			for arg in "${extra_args[@]}"; do
				[[ "$arg" != "--item-help" ]] && whiptail_args+=("$arg")
			done
			# If using item-help, convert triplets (tag, item, help) to pairs (tag, item)
			if $use_item_help; then
				for ((j=0; j<${#options[@]}; j+=3)); do
					whiptail_options+=("${options[j]}" "${options[j+1]}")
				done
			else
				whiptail_options=("${options[@]}")
			fi
			whiptail --title "$(strip_color_codes "$title")" "${whiptail_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --menu "$prompt" $height $width $list_height "${whiptail_options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --menu "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"read")
			# Fallback to read - handle --no-items and --item-help if present
			local use_no_items=false
			for arg in "${extra_args[@]}"; do
				[[ "$arg" == "--no-items" ]] && use_no_items=true
			done

			# Debug: show options array
			[[ -n "$debug" ]] && echo "DEBUG: options array has ${#options[@]} elements" >&2
			[[ -n "$debug" ]] && echo "DEBUG: use_item_help=$use_item_help" >&2

			if $use_no_items; then
				# Simple list without descriptions
				local i=1
				for item in "${options[@]}"; do
					echo "$i. $item" >&2
					((i++))
				done
			elif $use_item_help; then
				# Triplets of tag, item, and help text
				local i=1
				for ((j=0; j<${#options[@]}; j+=3)); do
					# Remove "  -  " prefix from description for cleaner display
					local desc="${options[j+1]#\  -\  }"
					echo "$i. ${options[j]} - $desc - ${options[j+2]}" >&2
					((i++))
				done
			else
				# Pairs of item and description
				local i=1
				for ((j=0; j<${#options[@]}; j+=2)); do
					# Remove "  -  " prefix from description for cleaner display
					local desc="${options[j]#\  -\  }"
					echo "$i. $desc - ${options[j+1]}" >&2
					((i++))
				done
			fi
			read -p "Enter choice number: " choice_index
			if [[ "$choice_index" =~ ^[0-9]+$ ]] && [ "$choice_index" -ge 1 ] && [ "$choice_index" -lt "$i" ]; then
				if $use_no_items; then
					echo "${options[((choice_index-1))]}"
				elif $use_item_help; then
					echo "${options[((choice_index-1)*3)]}"
				else
					echo "${options[((choice_index-1)*2)]}"
				fi
			fi
			;;
	esac
}

module_options+=(
	["dialog_inputbox,author"]="@armbian"
	["dialog_inputbox,desc"]="Display an input box dialog using the configured dialog tool"
	["dialog_inputbox,example"]="dialog_inputbox \"Title\" \"Prompt\" \"default_value\""
	["dialog_inputbox,feature"]="dialog_inputbox"
	["dialog_inputbox,status"]="Active"
)

# Display an input box dialog with proper redirection for each dialog tool
dialog_inputbox() {
	local title="$1"
	local prompt="$2"
	local default="${3:-}"
	local height="${4:-0}"
	local width="${5:-80}"
	local extra_args=("${@:6}")

	# Parse remaining arguments as extra args

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --inputbox "$prompt" $height $width "$default" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --inputbox "$prompt" $height $width "$default" 3>&1 1>&2 2>&3
			;;
		"read")
			read -p "$prompt [$default]: " result
			echo "${result:-$default}"
			;;
	esac
}

module_options+=(
	["dialog_passwordbox,author"]="@armbian"
	["dialog_passwordbox,desc"]="Display a password input dialog using the configured dialog tool"
	["dialog_passwordbox,example"]="dialog_passwordbox "Title" "Prompt""
	["dialog_passwordbox,feature"]="dialog_passwordbox"
	["dialog_passwordbox,status"]="Active"
)

# Display a password input dialog with proper redirection for each dialog tool
dialog_passwordbox() {
	local title="$1"
	local prompt="$2"
	local height="${3:-0}"
	local width="${4:-80}"
	local extra_args=("${@:5}")
	# Parse remaining arguments as extra args

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --passwordbox "$prompt" $height $width 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --insecure --passwordbox "$prompt" $height $width 3>&1 1>&2 2>&3
			;;
		"read")
			# For read mode, use read -s to hide input
			read -s -p "$prompt: " result
			echo ""
			echo "$result"
			;;
	esac
}

module_options+=(
	["dialog_yesno,author"]="@armbian"
	["dialog_yesno,desc"]="Display a yes/no dialog using the configured dialog tool"
	["dialog_yesno,example"]="dialog_yesno \"Title\" \"Question\""
	["dialog_yesno,feature"]="dialog_yesno"
	["dialog_yesno,status"]="Active"
)

# Display a yes/no dialog with proper redirection for each dialog tool
dialog_yesno() {
	local title="$1"
	local prompt="$2"
	local yes_label="${3:-Yes}"
	local no_label="${4:-No}"
	local height="${5:-0}"
	local width="${6:-80}"
	local extra_args=("${@:7}")
	# Parse remaining arguments as extra args

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --yes-button "$yes_label" --no-button "$no_label" --yesno "$prompt" $height $width 3>&1 1>&2 2>&3
			clear
			;;
		"dialog")
			dialog --clear --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --yes-button "$yes_label" --no-button "$no_label" --yesno "$prompt" $height $width
			;;
		"read")
			read -p "$prompt [$yes_label/$no_label]: " choice
			local choice_lower=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
			local yes_label_lower=$(echo "$yes_label" | tr '[:upper:]' '[:lower:]')
			[[ "$choice_lower" == "y" ]] || [[ "$choice_lower" == "yes" ]] || [[ "$choice_lower" == "$yes_label_lower" ]]
			;;
	esac
}

module_options+=(
	["dialog_msgbox,author"]="@armbian"
	["dialog_msgbox,desc"]="Display a message box using the configured dialog tool"
	["dialog_msgbox,example"]="dialog_msgbox \"Title\" \"Message\""
	["dialog_msgbox,feature"]="dialog_msgbox"
	["dialog_msgbox,status"]="Active"
)

# Display a message box with proper handling for each dialog tool
dialog_msgbox() {
	local title="$1"
	local prompt="$2"
	local height="${3:-0}"
	local width="${4:-0}"
	local extra_args=("${@:5}")

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --msgbox "$prompt" $height $width
			;;
		"dialog")
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --msgbox "$prompt" $height $width
			;;
		"read")
			echo "$prompt"
			read -p "Press Enter to continue..."
			;;
	esac
}

module_options+=(
	["dialog_infobox,author"]="@armbian"
	["dialog_infobox,desc"]="Display an info box using the configured dialog tool"
	["dialog_infobox,example"]="dialog_infobox \"Title\" \"Message\" 6 80"
	["dialog_infobox,feature"]="dialog_infobox"
	["dialog_infobox,status"]="Active"
)

# Display an info box with proper handling for each dialog tool
dialog_infobox() {
	local title="$1"
	local prompt="$2"
	local height="${3:-6}"
	local width="${4:-80}"

	local extra_args=("${@:5}")

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --infobox "$prompt" $height $width
			;;
		"dialog")
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --infobox "$prompt" $height $width
			;;
		"read")
			echo "$prompt"
			;;
	esac
}

module_options+=(
	["dialog_gauge,author"]="@armbian"
	["dialog_gauge,desc"]="Display a gauge dialog for progress indication"
	["dialog_gauge,example"]="echo 50 | dialog_gauge \"Title\" \"Progress\" 10 70"
	["dialog_gauge,feature"]="dialog_gauge"
	["dialog_gauge,status"]="Active"
)

# Display a gauge dialog (typically used with pipes for progress bars)
dialog_gauge() {
	local title="$1"
	local prompt="$2"
	local height="${3:-10}"
	local width="${4:-70}"

	# Parse remaining arguments as extra args
	local extra_args=("${@:5}")
	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --gauge "$prompt" $height $width 0
			;;
		"dialog")
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --gauge "$prompt" $height $width 0
			;;
		"read")
			# For read mode, just display the prompt
			echo "$prompt"
			cat > /dev/null  # Consume the input
			;;
	esac
}

module_options+=(
	["show_module_help,author"]="@armbian"
	["show_module_help,desc"]="Generic module help dialog for containers and native installs"
	["show_module_help,example"]="show_module_help \"module_headers\" \"Kernel Headers\" \"\" \"native\""
	["show_module_help,feature"]="show_module_help"
	["show_module_help,status"]="Active"
)

#
# Generic module help dialog - works for containers and native installs
# Usage: show_module_help <module_prefix> <title> [additional_info] [module_type]
#   module_prefix: e.g., "module_unbound", "module_headers"
#   title: Display title for the help dialog
#   additional_info: Optional extra info to append (e.g., port, image)
#   module_type: Optional, "container" (default) or "native"
#
show_module_help() {
	local module_prefix="$1"
	local title="$2"
	local additional_info="${3:-}"
	local module_type="${4:-container}"

	local feature="${module_options["${module_prefix},feature"]}"
	local desc="${module_options["${module_prefix},desc"]}"
	local example="${module_options["${module_prefix},example"]}"
	local doc_link="${module_options["${module_prefix},doc_link"]}"

	local help_text="Usage: $feature <command>\n\n"
	help_text+="Available commands:\n\n"

	# Parse commands and create descriptions
	IFS=' ' read -r -a commands <<< "$example"
	for cmd in "${commands[@]}"; do
		# Check if module has custom description for this command
		local custom_desc="${module_options["${module_prefix},help_${cmd}"]}"
		if [[ -n "$custom_desc" ]]; then
			help_text+="  $cmd  - $custom_desc\n"
			continue
		fi

		# Fall back to default descriptions based on module type
		case "$cmd" in
			install)
				if [[ "$module_type" == "container" ]]; then
					help_text+="  install  - Pull Docker image and create container\n"
				else
					help_text+="  install  - $desc\n"
				fi
				;;
			remove)
				if [[ "$module_type" == "container" ]]; then
					help_text+="  remove   - Remove container and image\n"
				else
					help_text+="  remove   - Remove installed packages\n"
				fi
				;;
			purge)
				if [[ "$module_type" == "container" ]]; then
					help_text+="  purge    - Remove container, image, and all data directories\n"
				else
					help_text+="  purge    - Remove packages and all configuration/data\n"
				fi
				;;
			status)
				help_text+="  status   - Show installation status\n"
				;;
			help)
				help_text+="  help     - Show this help message\n"
				;;
			password)
				help_text+="  password - Set admin password\n"
				;;
			*)
				help_text+="  $cmd  - $cmd command\n"
				;;
		esac
	done

	[[ -n "$additional_info" ]] && help_text+="\n$additional_info"
	help_text+="\nDocumentation: $doc_link"

	if [[ "$DIALOG" == "read" ]]; then
		echo -e "$help_text"
	else
		dialog_msgbox "$title Help" "$help_text" 20 70
	fi
}

module_options+=(
	["dialog_checklist,author"]="@armbian"
	["dialog_checklist,desc"]="Display a checklist dialog using the configured dialog tool"
	["dialog_checklist,example"]="dialog_checklist \"Title\" \"Prompt\" option1 \"Description 1\" ON option2 \"Description 2\" OFF"
	["dialog_checklist,feature"]="dialog_checklist"
	["dialog_checklist,status"]="Active"
)

# Display a checklist dialog with proper redirection for each dialog tool
dialog_checklist() {
	local title="$1"
	local prompt="$2"
	local height="${3:-0}"
	local width="${4:-80}"
	local list_height="${5:-9}"
	shift 5

	# Parse arguments: everything before -- is extra args, everything after is data
	local extra_args=()
	local options=()

	while [[ $# -gt 0 ]]; do
		if [[ "$1" == "--" ]]; then
			shift
			break
		elif [[ "$1" == --* ]]; then
			# For dialog options that require arguments, consume both the flag and its value
			case "$1" in
				--ok-button|--cancel-button|--yes-button|--no-button)
					extra_args+=("$1")
					shift
					if [[ $# -gt 0 && "$1" != --* ]]; then
						extra_args+=("$1")
						shift
					fi
					;;
				--separate-output|--nocancel)
					extra_args+=("$1")
					shift
					;;
				*)
					extra_args+=("$1")
					shift
					;;
			esac
		else
			break
		fi
	done

	# All remaining arguments are data (options)
	options=("$@")

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --checklist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --checklist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"read")
			# Fallback to read - handle checklist by showing numbered list
			local i=1
			for ((j=0; j<${#options[@]}; j+=3)); do
				local status="${options[j+2]}"
				local marker=" "
				[[ "$status" =~ ^[Oo][Nn]$ ]] && marker="*"
				echo "$i. [$marker] ${options[j]} - ${options[j+1]}"
				((i++))
			done
			read -p "Enter choice numbers (comma-separated): " choices
			for choice in ${choices//,/ }; do
				if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
					idx=$((choice - 1))
					echo "${options[idx*3]}"
				fi
			done
			;;
	esac
}

dialog_radiolist() {
	local title="$1"
	local prompt="$2"
	local height="${3:-0}"
	local width="${4:-80}"
	local list_height="${5:-9}"
	shift 5

	# Parse arguments: everything before -- is extra args, everything after is data
	local extra_args=()
	local options=()

	while [[ $# -gt 0 ]]; do
		if [[ "$1" == "--" ]]; then
			shift
			break
		elif [[ "$1" == --* ]]; then
			# For dialog options that require arguments, consume both the flag and its value
			case "$1" in
				--ok-button|--cancel-button|--yes-button|--no-button)
					extra_args+=("$1")
					shift
					if [[ $# -gt 0 && "$1" != --* ]]; then
						extra_args+=("$1")
						shift
					fi
					;;
				--separate-output|--nocancel|--notags)
					extra_args+=("$1")
					shift
					;;
				*)
					extra_args+=("$1")
					shift
					;;
			esac
		else
			break
		fi
	done

	# All remaining arguments are data (options)
	options=("$@")

	case "$DIALOG" in
		"whiptail")
			whiptail --title "$(strip_color_codes "$title")" "${extra_args[@]}" --backtitle "$(strip_color_codes "$BACKTITLE")" --radiolist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --colors --title "$title" "${extra_args[@]}" --backtitle "$BACKTITLE" --radiolist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"read")
			# Fallback to read - handle radiolist by showing numbered list
			local i=1
			for ((j=0; j<${#options[@]}; j+=3)); do
				local status="${options[j+2]}"
				local marker=" "
				[[ "$status" =~ ^[Oo][Nn]$ ]] && marker="*"
				echo "$i. [$marker] ${options[j]} - ${options[j+1]}"
				((i++))
			done
			read -p "Enter choice number: " choice
			if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
				idx=$((choice - 1))
				echo "${options[idx*3]}"
			fi
			;;
	esac
}

module_options+=(
	["wait_for_container_ready,author"]="@armbian"
	["wait_for_container_ready,desc"]="Wait for a Docker container to be ready (default: check if running)"
	["wait_for_container_ready,example"]="wait_for_container_ready \"container_name\" 20 3"
	["wait_for_container_ready,feature"]="wait_for_container_ready"
	["wait_for_container_ready,status"]="Active"
)

# Wait for a Docker container to be ready
# Usage: wait_for_container_ready <container_name> [max_attempts] [sleep_interval] [check_type] [extra_condition]
# check_type: "running" (default, works for all containers) or "build_version" (LinuxServer-specific)
wait_for_container_ready() {
	local container_name="$1"
	local max_attempts="${2:-20}"
	local sleep_interval="${3:-3}"
	local check_type="${4:-running}"
	local extra_condition="${5:-}"

	for ((i=1; i<=max_attempts; i++)); do
		local container_ready=false

		case "$check_type" in
			"running"|*)
				local state
				state="$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					container_ready=true
				fi
				;;
			"build_version")
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' "$container_name" >/dev/null 2>&1; then
					container_ready=true
				fi
				;;
		esac

		if $container_ready; then
			# Check extra condition if provided
			if [[ -n "$extra_condition" ]]; then
				if eval "$extra_condition"; then
					return 0
				fi
			else
				return 0
			fi
		fi
		sleep "$sleep_interval"
	done

	echo -e "\nTimed out waiting for ${container_name} to start, consult your container logs for more info (\`docker logs ${container_name}\`)"
	return 1
}

#
# Armbian Docker utilities
#

#
# Ensure Docker is available
# Usage: docker_ensure_docker
# Returns: 0 if Docker is available, exits if it fails to install
#
docker_ensure_docker() {
	if ! module_docker status >/dev/null 2>&1; then
		module_docker install
		# Wait for Docker daemon to be ready after installation
		local max_wait=30
		local wait_count=0
		while [[ $wait_count -lt $max_wait ]]; do
			if docker info >/dev/null 2>&1; then
				return 0
			fi
			sleep 1
			((wait_count++))
		done
		dialog_msgbox "Error" "Docker installation failed or timed out.\n\nDocker daemon is not responding.\nPlease install Docker manually and try again." 10 60
		return 1
	fi
	return 0
}

#
# Get container ID by name
# Usage: docker_get_container_id <container_name>
# Outputs: Container ID or empty string if not found
#
docker_get_container_id() {
	local container_name="$1"
	docker container ls -a --filter "name=^${container_name}$" --format '{{.ID}}' 2>/dev/null || echo ""
}

#
# Get image reference by image pattern
# Usage: docker_get_image_ref <image_pattern>
# Outputs: Image reference (repo:tag) or empty string if not found
#
docker_get_image_ref() {
	local image_pattern="$1"
	docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "$image_pattern" | head -1 || echo ""
}

#
# Check if container and image are installed
# Usage: docker_is_installed <container_name> <image_pattern>
# Returns: 0 if both container and image exist, 1 otherwise
#
docker_is_installed() {
	local container_name="$1"
	local image_pattern="$2"
	local container=$(docker_get_container_id "$container_name")
	local image=$(docker_get_image_ref "$image_pattern")
	[[ "${container}" && "${image}" ]] && return 0 || return 1
}

#
# Manage base directory with error handling
# Usage: docker_manage_base_dir <create|remove> <base_dir>
# Returns: 0 on success, 1 on failure
#
docker_manage_base_dir() {
	local mode="$1"
	local base_dir="$2"

	docker_ensure_docker

	case "$mode" in
		create)
			if [[ ! -d "$base_dir" ]]; then
				if ! mkdir -p "$base_dir"; then
					dialog_msgbox "Error" "Failed to create directory:\n$base_dir" 8 50
					return 1
				fi
				# Set ownership to the Docker user
				chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir"
			fi
			;;
		remove)
			if [[ -n "$base_dir" && -d "$base_dir" && "$base_dir" != "/" ]]; then
				rm -rf "$base_dir"
			fi
			;;
		*)
			dialog_msgbox "Error" "Invalid mode: $mode\nUse 'create' or 'remove'" 8 50
			return 1
			;;
	esac

	return 0
}

#
# Backward compatibility wrapper
# Deprecated: Use docker_manage_base_dir instead
#
docker_create_base_dir() {
	docker_manage_base_dir create "$1"
}

#
# Parse module commands array
# Usage: docker_parse_commands <module_prefix>
# Outputs: Array reference to commands
#
docker_parse_commands() {
	local module_prefix="$1"
	local commands_var="${module_prefix},example"
	IFS=' ' read -r -a commands <<< "${module_options["$commands_var"]}"
	echo "${commands[@]}"
}

#
# Docker operation with progress display
# Supports: pull, rm (container), rmi (image), run (container)
#
# Usage:
#   docker_operation_progress pull <image_name>
#   docker_operation_progress rm <container_name>
#   docker_operation_progress rmi <image_name>
#   docker_operation_progress run <container_name> [docker_run_args...]
#
# Example for run:
#   docker_operation_progress run mycontainer --name mycontainer -d -p 80:80 nginx
#
docker_operation_progress() {
	local operation="$1"
	local target="$2"
	local api_version="v1.41"
	local socket_path="/var/run/docker.sock"

	# Ensure Docker is available
	docker_ensure_docker

	# Argument validation
	if [[ -z "$operation" || -z "$target" ]]; then
		dialog_msgbox "Usage Error" "Usage: docker_operation_progress <pull|rm|rmi> <target>\n\n  pull <image>   - Pull Docker image\n  rm <container> - Remove container\n  rmi <image>    - Remove image" 12 60
		return 1
	fi

	# Validate operation type
	case "$operation" in
		pull|rm|rmi|run)
			;;
		*)
			dialog_msgbox "Error" "Invalid operation: $operation\n\nValid operations: pull, rm, rmi, run" 10 50
			return 1
			;;
	esac

	# Check for socket access
	if [[ ! -r "$socket_path" || ! -w "$socket_path" ]]; then
		dialog_msgbox "Permission Error" "Cannot access Docker socket at $socket_path\n\nYou may need to be in the 'docker' group or run with sudo." 12 60
		return 1
	fi

	# Check if docker is running
	if ! docker info &> /dev/null; then
		dialog_msgbox "Docker Error" "Docker daemon is not running.\nPlease start Docker and try again." 10 60
		return 1
	fi

	local exit_code
	local error_file=$(mktemp)
	local title="Docker $operation"

	case "$operation" in
		pull)
			# Ensure Docker is installed
			docker_ensure_docker || return 1

			# Check if image already exists
			local existing_image
			existing_image=$(docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "^${target}$" | head -1)

			if [[ -n "$existing_image" ]]; then
				# Image already exists, skip pull
				return 0
			fi

			# Pull image with progress via Docker API
			local raw_response_file=$(mktemp)
			local http_code_file=$(mktemp)

			(
				echo "XXX"
				echo "0"
				echo "Pulling: $target"
				echo "XXX"

				unbuffer curl --silent --show-error \
					--unix-socket "$socket_path" \
					-X POST "http://localhost/$api_version/images/create?fromImage=$target" \
					-w "%{http_code}" \
					-o "$raw_response_file" \
					2> "$error_file" \
				> "$http_code_file"

				# Check HTTP response code
				local http_code=$(<"$http_code_file")
				if [[ "$http_code" != "200" ]]; then
					echo "XXX"
					echo "0"
					echo "Error: HTTP $http_code"
					echo "XXX"
					exit 1
				fi

				# Check if response file has content
				if [[ ! -s "$raw_response_file" ]]; then
					echo "XXX"
					echo "0"
					echo "Error: Empty response from Docker API"
					echo "XXX"
					exit 1
				fi

				# Parse and display progress from captured response
				if ! jq -r --unbuffered '
						select(.status != null) or (.error != null) |
						if .error then
							"ERROR\n" + .error + "\n"
						elif .progressDetail.current and .progressDetail.total then
							# Calculate actual percentage
							"XXX\n" +
							((.progressDetail.current / .progressDetail.total) * 100 | floor | tostring) +
							"\nLayer: " + (.id[0:12] // "Unknown") + "...  " + .status +
							"\nXXX"
						else
							# No progress detail - show status
							"XXX\n0\n" + (.id // "Preparing") + "...  " + .status + "\nXXX"
						end
					' "$raw_response_file" 2>> "$error_file"; then
					echo "XXX"
					echo "0"
					echo "Error: Failed to parse Docker API response"
					echo "XXX"
					exit 1
				fi

				echo "XXX"
				echo "100"
				echo "Pull complete!"
				echo "XXX"
			) | dialog_gauge "$title" "Pulling: $target" 8 80

			exit_code=$?

			rm -f "$raw_response_file" "$http_code_file"

			# Verify and show result
			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Pull Failed" "Failed to pull: $target\n\nExit code: $exit_code\n\n${error_output}" 14 60
				return 1
			fi
			# Note: We trust the Docker API response. If HTTP 200 with no errors,
			# the pull succeeded. Additional verification can fail when running
			# in Docker-in-Docker scenarios due to image registration delays.
			;;

		rm)
			# Remove container - check if exists first
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${target}$"; then
				# Container doesn't exist, silently succeed
				return 0
			fi

			(
				echo "XXX"
				echo "0"
				echo "Removing container: $target"
				echo "XXX"

				# Remove container and show progress
				if docker rm -f "$target" 2> "$error_file"; then
					echo "XXX"
					echo "100"
					echo "Container removed successfully!"
					echo "XXX"
				else
					echo "XXX"
					echo "0"
					echo "Failed to remove container"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to remove container: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;

		rmi)
			# Remove image - check if exists first
			if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q "^${target}$"; then
				# Image doesn't exist, silently succeed
				return 0
			fi

			(
				echo "XXX"
				echo "0"
				echo "Removing image: $target"
				echo "XXX"

				# Remove image and show progress
				if docker rmi -f "$target" 2> "$error_file"; then
					echo "XXX"
					echo "100"
					echo "Image removed successfully!"
					echo "XXX"
				else
					echo "XXX"
					echo "0"
					echo "Failed to remove image"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to remove image: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;

		run)
			# Run container - $target is container name, rest are docker run args
			local docker_args=("${@:3}")
			(
				echo "XXX"
				echo "0"
				echo "Starting container: $target"
				echo "XXX"

				# Run the container and capture output
				if docker run "${docker_args[@]}" 2> "$error_file"; then
					echo "XXX"
					echo "50"
					echo "Container started. Waiting for ready..."
					echo "XXX"

					# Wait for container to be ready
					if wait_for_container_ready "$target" 2>/dev/null; then
						echo "XXX"
						echo "100"
						echo "Container is ready!"
						echo "XXX"
					else
						echo "XXX"
						echo "75"
						echo "Container started but readiness check timed out"
						echo "XXX"
					fi
				else
					echo "XXX"
					echo "0"
					echo "Failed to start container"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Starting: $target" 8 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to start container: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;
	esac

	# Clean up error file
	rm -f "$error_file"

	return 0
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
	["check_os_status,ref_link"]=""
	["check_os_status,feature"]="check_os_status"
	["check_os_status,desc"]="Check if the current OS distribution is supported"
	["check_os_status,example"]="check_os_status"
	["check_os_status,doc_link"]=""
	["check_os_status,status"]="Active"
)

#
# Check if current OS distribution is officially supported
# Shows a warning and prompts for confirmation if OS is not in the supported list
# Usage: check_distro_status
#
function check_distro_status() {
	case "$1" in
		help)
			echo "Usage: check_os_status"
			echo "This function checks if the current OS is supported based on /etc/armbian-distribution-status."
			echo "It retrieves the current OS distribution and checks if it is listed as supported in the specified file."
		;;
		*)

			# Ensure OS detection succeeded
			if [[ -z "$DISTROID" ]]; then
				dialog_msgbox "OS Detection Error" \
					"Unable to detect the current OS distribution.\n\nPlease ensure you're running on a supported system." \
					8 60
				return 1
			fi

			# Check if the OS is listed as supported in the DISTRO_STATUS
			if grep -qE "^${DISTROID}=.*supported" "$DISTRO_STATUS" 2> /dev/null; then
				# OS is supported - return silently
				return 0
			fi

			# OS not supported - show warning and continue after a brief pause
			if [[ "$DIALOG" == "read" ]]; then
				echo "Warning: The current OS ($DISTROID) is not officially supported."
				echo "The tool may still work, but issues may not be addressed by maintainers."
				echo "Continuing in 3 seconds..."
				sleep 3
			else
				local warning_msg="Warning: The current OS ($DISTROID) is not officially supported.\n\n"
				warning_msg+="The tool might still work, but issues may not be accepted or\n"
				warning_msg+="addressed by the maintainers. You are welcome to contribute fixes."

				dialog_msgbox "OS Support Warning" "$warning_msg" 10 60
				sleep 3
			fi
		;;
	esac
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

