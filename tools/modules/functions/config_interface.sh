
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
	local status="$ARMBIAN $KERNELID ($DISTRO $DISTROID)"
	local backtitle="$BACKTITLE"


	while true; do
		local menu_options=()

		parse_menu_items menu_options --with-help

		local OPTION=$(dialog_menu "$TITLE" "$status" 0 80 10 --backtitle "$backtitle" --ok-button Select --cancel-button Exit --item-help -- "${menu_options[@]}")
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
		parse_menu_items submenu_options --with-help

		local OPTION=$(dialog_menu "$top_parent_id $parent_id" "$status" 0 80 10 --backtitle "$backtitle" --ok-button Select --cancel-button Back --item-help -- "${submenu_options[@]}")

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

	if dialog_yesno "" "$message" "Yes" "No" 15 80; then
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
			whiptail --title "$title" "${whiptail_args[@]}" --menu "$prompt" $height $width $list_height "${whiptail_options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --title "$title" "${extra_args[@]}" --menu "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"read")
			# Fallback to read - handle --no-items and --item-help if present
			local use_no_items=false
			for arg in "${extra_args[@]}"; do
				[[ "$arg" == "--no-items" ]] && use_no_items=true
			done

			if $use_no_items; then
				# Simple list without descriptions
				local i=1
				for item in "${options[@]}"; do
					echo "$i. $item"
					((i++))
				done
			elif $use_item_help; then
				# Triplets of tag, item, and help text
				local i=1
				for ((j=0; j<${#options[@]}; j+=3)); do
					echo "$i. ${options[j+1]} - ${options[j+2]}"
					((i++))
				done
			else
				# Pairs of item and description
				local i=1
				for ((j=0; j<${#options[@]}; j+=2)); do
					echo "$i. ${options[j]} - ${options[j+1]}"
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
			whiptail --title "$title" "${extra_args[@]}" --inputbox "$prompt" $height $width "$default" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --title "$title" "${extra_args[@]}" --inputbox "$prompt" $height $width "$default" 3>&1 1>&2 2>&3
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
			whiptail --title "$title" "${extra_args[@]}" --passwordbox "$prompt" $height $width 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --title "$title" "${extra_args[@]}" --insecure --passwordbox "$prompt" $height $width 3>&1 1>&2 2>&3
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
			whiptail --title "$title" "${extra_args[@]}" --yes-button "$yes_label" --no-button "$no_label" --yesno "$prompt" $height $width 3>&1 1>&2 2>&3
			;;
		"dialog")
			dialog --title "$title" "${extra_args[@]}" --yes-button "$yes_label" --no-button "$no_label" --yesno "$prompt" $height $width
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
			whiptail --title "$title" "${extra_args[@]}" --msgbox "$prompt" $height $width
			;;
		"dialog")
			dialog --title "$title" "${extra_args[@]}" --msgbox "$prompt" $height $width
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
			whiptail --title "$title" "${extra_args[@]}" --infobox "$prompt" $height $width
			;;
		"dialog")
			TERM=ansi dialog --title "$title" "${extra_args[@]}" --infobox "$prompt" $height $width
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
			whiptail --title "$title" "${extra_args[@]}" --gauge "$prompt" $height $width 0
			;;
		"dialog")
			dialog --title "$title" "${extra_args[@]}" --gauge "$prompt" $height $width 0
			;;
		"read")
			# For read mode, just display the prompt
			echo "$prompt"
			cat > /dev/null  # Consume the input
			;;
	esac
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
			whiptail --title "$title" "${extra_args[@]}" --checklist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --title "$title" "${extra_args[@]}" --checklist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
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
			whiptail --title "$title" "${extra_args[@]}" --radiolist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
			;;
		"dialog")
			# dialog outputs selection to stderr by default; swap stdout/stderr (3>&1 1>&2 2>&3) to capture stderr to stdout for command substitution
			dialog --title "$title" "${extra_args[@]}" --radiolist "$prompt" $height $width $list_height "${options[@]}" 3>&1 1>&2 2>&3
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
	["wait_for_container_ready,desc"]="Wait for a Docker container to be ready by checking for build_version label"
	["wait_for_container_ready,example"]="wait_for_container_ready \"container_name\" 20 3"
	["wait_for_container_ready,feature"]="wait_for_container_ready"
	["wait_for_container_ready,status"]="Active"
)

# Wait for a Docker container to be ready
# Usage: wait_for_container_ready <container_name> [max_attempts] [sleep_interval] [check_type] [extra_condition]
# check_type: "build_version" (default) or "running"
wait_for_container_ready() {
	local container_name="$1"
	local max_attempts="${2:-20}"
	local sleep_interval="${3:-3}"
	local check_type="${4:-build_version}"
	local extra_condition="${5:-}"

	for ((i=1; i<=max_attempts; i++)); do
		local container_ready=false

		case "$check_type" in
			"running")
				local state
				state="$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					container_ready=true
				fi
				;;
			"build_version"|*)
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
