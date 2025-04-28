
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
