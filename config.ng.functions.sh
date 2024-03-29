#!/bin/bash


module_options+=(
	["check_desktop,author"]="Igor Pecovnik"
	["check_desktop,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-functions#L137"
    ["check_desktop,feature"]="check_desktop"
    ["check_desktop,desc"]="Migrated procedures from Armbian config."
    ["check_desktop,example"]="check_desktop"
	["check_desktop,status"]="active"
)
#
# read desktop parameters
#
function check_desktop() {

	DISPLAY_MANAGER=""; DESKTOP_INSTALLED=""
	check_if_installed nodm && DESKTOP_INSTALLED="nodm";
	check_if_installed lightdm && DESKTOP_INSTALLED="lightdm";
	check_if_installed lightdm && DESKTOP_INSTALLED="gnome";
	[[ -n $(service lightdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="lightdm"
	[[ -n $(service nodm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="nodm"
	[[ -n $(service gdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="gdm"

}


module_options+=(
	["check_if_installed,author"]="Igor Pecovnik"
	["check_if_installed,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-functions#L183"
    ["check_if_installed,feature"]="check_if_installed"
    ["check_if_installed,desc"]="Migrated procedures from Armbian config."
    ["check_if_installed,example"]="check_if_installed nano"
	["check_if_installed,status"]="active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function check_if_installed (){

	local DPKG_Status="$(dpkg -s "$1" 2>/dev/null | awk -F": " '/^Status/ {print $2}')"
	if [[ "X${DPKG_Status}" = "X" || "${DPKG_Status}" = *deinstall* ]]; then
		return 1
	else
		return 0
	fi

}


module_options+=(
	["is_package_manager_running,author"]="Igor Pecovnik"
	["is_package_manager_running,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-functions#L200"
    ["is_package_manager_running,feature"]="is_package_manager_running"
    ["is_package_manager_running,desc"]="Migrated procedures from Armbian config."
    ["is_package_manager_running,example"]="is_package_manager_running"
	["is_package_manager_running,status"]="active"
)
#
# check if package manager is doing something
#
function is_package_manager_running() {

	if ps -C apt-get,apt,dpkg >/dev/null ; then
		[[ -z $scripted ]] && echo -e "\nPackage manager is running in the background. \n\nCan't install dependencies. Try again later." | show_infobox
		return 0
	else
		return 1
	fi

}


module_options+=(
	["set_runtime_variables,author"]="Igor Pecovnik"
	["set_runtime_variables,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-functions#L33"
    ["set_runtime_variables,feature"]="set_runtime_variables"
    ["set_runtime_variables,desc"]="Run time varibales Migrated procedures from Armbian config."
    ["set_runtime_variables,example"]="set_runtime_variables"
	["set_runtime_variables,status"]="active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables(){

    [[ -z "$DIALOG" ]] && echo "Please install whiptail" && exit 1 ;

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

    testing="$(date +"%B %d, %Y")"
    system="$(uname -m)"
    network="$(see_ping)"
    localisation="$LANG"
    install="$(see_current_apt)"

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE";
	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc)
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// }" ]] && ARMBIAN="$DISTRO $DISTROID"
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	BACKTITLE="Configuration utility, $ARMBIAN"
	[[ -n "$LOCALIPADD" ]] && BACKTITLE=$BACKTITLE", "$LOCALIPADD
	TITLE="$BOARD_NAME "
	[[ -z "${DEFAULT_ADAPTER// }" ]] && DEFAULT_ADAPTER="lo"
	OVERLAYDIR="/boot/dtb/overlay";
	[[ "$LINUXFAMILY" == "sunxi64" ]] && OVERLAYDIR="/boot/dtb/allwinner/overlay";
	[[ "$LINUXFAMILY" == "meson64" ]] && OVERLAYDIR="/boot/dtb/amlogic/overlay";
	[[ "$LINUXFAMILY" == "rockchip64" || "$LINUXFAMILY" == "rk3399" || "$LINUXFAMILY" == "rockchip-rk3588" || "$LINUXFAMILY" == "rk35xx" ]] && OVERLAYDIR="/boot/dtb/rockchip/overlay";
	# detect desktop
	check_desktop

}


module_options+=(
	["set_safe_boot,author"]="Igor Pecovnik"
    ["set_safe_boot,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L949C2-L949C25"
    ["set_safe_boot,feature"]="set_safe_boot"
    ["set_safe_boot,desc"]="Freeze/unhold Migrated procedures from Armbian config."
    ["set_safe_boot,example"]="set_safe_boot unhold or set_safe_boot freeze"
	["set_safe_boot,status"]="active"
)

set_safe_boot() {

	check_if_installed linux-u-boot-${BOARD}-${BRANCH} && PACKAGE_LIST+=" linux-u-boot-${BOARD}-${BRANCH}"
	check_if_installed linux-image-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-image-${BRANCH}-${LINUXFAMILY}"
	check_if_installed linux-dtb-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-dtb-${BRANCH}-${LINUXFAMILY}"
	check_if_installed linux-headers-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-headers-${BRANCH}-${LINUXFAMILY}"

	# new BSP
	check_if_installed armbian-${LINUXFAMILY} && PACKAGE_LIST+=" armbian-${LINUXFAMILY}"
	check_if_installed armbian-${BOARD} && PACKAGE_LIST+=" armbian-${BOARD}"
	check_if_installed armbian-${DISTROID} && PACKAGE_LIST+=" armbian-${DISTROID}"
	check_if_installed armbian-bsp-cli-${BOARD} && PACKAGE_LIST+=" armbian-bsp-cli-${BOARD}"
	check_if_installed armbian-${DISTROID}-desktop-xfce && PACKAGE_LIST+=" armbian-${DISTROID}-desktop-xfce"
	check_if_installed armbian-firmware && PACKAGE_LIST+=" armbian-firmware"
	check_if_installed armbian-firmware-full && PACKAGE_LIST+=" armbian-firmware-full"
	IFS=" "
	[[ "$1" == "unhold" ]] && local command="apt-mark unhold" && for word in $PACKAGE_LIST; do $command $word; done | show_infobox

	[[ "$1" == "freeze" ]] && local command="apt-mark hold" && for word in $PACKAGE_LIST; do $command $word; done | show_infobox

}



module_options+=(
	["connect_bt_interface,author"]="Igor Pecovnik"
	["connect_bt_interface,ref_link"]=""
    ["connect_bt_interface,feature"]="connect_bt_interface"
    ["connect_bt_interface,desc"]="Migrated procedures from Armbian config."
    ["connect_bt_interface,example"]="connect_bt_interface"
	["connect_bt_interface,status"]="active"
)
function connect_bt_interface(){

	IFS=$'\r\n'
	GLOBIGNORE='*'
	echo -e "\nDiscovering Bluetooth devices ... " |show_infobox
	BT_INTERFACES=($(hcitool scan | sed '1d'))

	local LIST=()
	for i in "${BT_INTERFACES[@]}"
	do
		local a=$(echo ${i[0]//[[:blank:]]/} | sed -e 's/^\(.\{17\}\).*/\1/')
		local b=${i[0]//$a/}
		local b=$(echo $b | sed -e 's/^[ \t]*//')
		LIST+=( "$a" "$b")
	done

	LIST_LENGTH=$((${#LIST[@]}/2));
	if [ "$LIST_LENGTH" -eq 0 ]; then
		BT_ADAPTER=${WLAN_INTERFACES[0]}
		echo -e "\nNo nearby Bluetooth devices were found!" | show_message
	else
		exec 3>&1
		#BT_ADAPTER=$(dialog --backtitle "$BACKTITLE" --no-collapse --title "Select interface" \
		#--clear --menu "" $((6+${LIST_LENGTH})) 50 15 "${LIST[@]}" 2>&1 1>&3)
       BT_ADAPTER=$( echo "${LIST[@]}" | show_menu )
		exec 3>&-
		if [[ $BT_ADAPTER != "" ]]; then
			echo -e "\nConnecting to $BT_ADAPTER " | show_infobox
			BT_EXEC=$(
			expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address\r";
			sleep 1;send "remove $address\r";sleep 1;expect -re $prompt;send "scan on\r";sleep 8;send "scan off\r";
			expect "Controller";send "trust $address\r";sleep 2;send "pair $address\r";sleep 2;send "connect $address\r";
			send_user "\nShould be paired now.\r";sleep 2;send "quit\r";expect eof')
			echo "$BT_EXEC" > /tmp/bt-connect-debug.log
				if [[ $(echo "$BT_EXEC" | grep "Connection successful" ) != "" ]]; then
					echo -e "\nYour device is ready to use!" | show_message
				else
					echo -e "\nError connecting. Try again!" | show_message
				fi
		fi
	fi

}


# Start of config ng

module_options+=(
	["set_colors,author"]="Joey Turner"
    ["set_colors,ref_link"]=""
    ["set_colors,feature"]="set_colors"
    ["set_colors,desc"]="Change the background color of the terminal or dialog box"
    ["set_colors,example"]="set_colors 0-7"
    ["set_colors,doc_link"]=""
    ["set_colors,status"]="candidate"
)

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
        *) break ;;
    esac
    export NEWT_COLORS="root=,$color"
}


#
# Function to set the colors for terminal
#
function set_term_colors() {
    local color_code=$1
    case $color_code in
        0) color="\e[40m" ;;  # black
        1) color="\e[41m" ;;  # red
        2) color="\e[42m" ;;  # green
        3) color="\e[43m" ;;  # yellow
        4) color="\e[44m" ;;  # blue
        5) color="\e[45m" ;;  # magenta
        6) color="\e[46m" ;;  # cyan
        7) color="\e[47m" ;;  # white
        *) echo "Invalid color code"; return 1 ;;
    esac
    echo -e "$color"
}


#
# Function to reset the colors
#
function reset_colors() {
    echo -e "\e[0m"
}


#
# Trap to reset the colors
#
trap reset_colors EXIT




#
# Function to generate the top menu ealy iteration may need to revert to one line command
#
function generate_top_menu_save() {
    local menu_options=()
    while IFS= read -r id
    do
        IFS= read -r description
        IFS= read -r condition
        # If the condition field is not empty and not null, run the function specified in the condition
        if [[ -n $condition && $condition != "null" ]]; then
            local condition_result=$(eval $condition)
            # If the function returns a truthy value, add the menu item to the menu
            if [[ $condition_result ]]; then
                menu_options+=("$id" "  -  $description")
            fi
        else
            # If the condition field is empty or null, add the menu item to the menu
            menu_options+=("$id" "  -  $description")
        fi
    done < <(jq -r '.menu[] | select(.show==true) | "\(.id)\n\(.description)\n\(.condition)"' "$modified_json_data"  || exit 1 )

    set_colors 4

    local OPTION=$($DIALOG --title "Menu" --menu "Choose an option" 0 80 9 "${menu_options[@]}" 3>&1 1>&2 2>&3)
    local exitstatus=$?

    if [ $exitstatus = 0 ]; then
        if [ "$OPTION" == "" ]; then
            exit 0
        fi    
        generate_menu "$OPTION"
    fi
}


module_options+=(
["generate_top_menu,author"]="Joey Turner"
["generate_top_menu,ref_link"]=""
["generate_top_menu,feature"]="generate_top_menu"
["generate_top_menu,desc"]="Build the main menu from a object"
["generate_top_menu,example"]="generate_top_menu 'json_data'"
["generate_top_menu,doc_link"]=""
["generate_top_menu,status"]="candidate"
)

generate_top_menu() {
    local json_data=$1
    local menu_options=()
    while IFS= read -r id
    do
        IFS= read -r description
        IFS= read -r requirements
        # If the condition field is not empty and not null, run the function specified in the condition
        if [[ -n $requirements && $requirements != "null" ]]; then
            local condition_result=$(eval $requirements)
            # If the function returns a truthy value, add the menu item to the menu
            if [[ $condition_result ]]; then
                menu_options+=("$id" "  -  $description ($something)")
            fi
        else
            # If the condition field is empty or null, add the menu item to the menu
            menu_options+=("$id" "  -  $description ")
        fi
    done < <(echo "$json_data" | jq -r '.menu[] | select(.show==true) | "\(.id)\n\(.description)\n\(.condition)"' || exit 1 )

    set_colors 4

    local OPTION=$($DIALOG --title "$TITLE"  --menu "$BACKTITLE" 0 80 9 "${menu_options[@]}" 3>&1 1>&2 2>&3)
    local exitstatus=$?

    if [ $exitstatus = 0 ]; then
        if [ "$OPTION" == "" ]; then
            exit 0
        fi    
        generate_menu "$OPTION"
    fi
}


#
# Function to generate the submenu
#
function generate_menu() {
    local parent_id=$1

    # Get the submenu options for the current parent_id
    local submenu_options=()
    while IFS= read -r id
    do
        IFS= read -r description
        submenu_options+=("$id" "  -  $description")
    done < <(jq -r --arg parent_id "$parent_id" '.menu[] | select(.id==$parent_id) | .sub[]? | select(.show==true) | "\(.id)\n\(.description)"' <<< "$json_data")


    local OPTION=$($DIALOG --title "$TITLE"  --menu "$BACKTITLE" 0 80 9 "${submenu_options[@]}" \
                            --ok-button Select --cancel-button Back 3>&1 1>&2 2>&3)

    local exitstatus=$?

    if [ $exitstatus = 0 ]; then
        if [ "$OPTION" == "" ]; then
            generate_top_menu
        fi
        # Check if the selected option has a submenu
        local submenu_count=$(jq -r --arg id "$OPTION" '.menu[] | .. | objects | select(.id==$id) | .sub[]? | length' "$json_file")
        submenu_count=${submenu_count:-0}  # If submenu_count is null or empty, set it to 0
        if [ "$submenu_count" -gt 0 ]; then
            # If it does, generate a new menu for the submenu
            set_colors 2 # "$?"
            generate_menu "$OPTION"
        else
            # If it doesn't, execute the command
            execute_command "$OPTION"
        fi
    fi
}



#
# Function to execute the command
#
function execute_command() {
    local id=$1
    local commands=$(jq -r --arg id "$id" '.menu[] | .. | objects | select(.id==$id) | .command[]' "$json_file")
    for command in "${commands[@]}"; do
        # Check if the command is not in the list of restricted commands       
            eval "$command"
    done
}




module_options+=(
["show_message,author"]="Joey Turner"
["show_message,ref_link"]="https://github.com/armbian/configng/blob/main/bin/armbian-interface#L62"
["show_message,feature"]="show_message"
["show_message,desc"]="Display a message box"
["show_message,example"]="show_message <<< 'hello world' "
["show_message,doc_link"]="https://github.com/armbian/configng/wiki/armbian%E2%80%90interface#ok-message-box"
["show_message,status"]="active"
)
#
# Function to display a message box
#
function show_message() {
    # Read the input from the pipe
    input=$(cat)

    # Display the "OK" message box with the input data
    if [[ $DIALOG != "bash" ]]; then
        $DIALOG  --title "$BACKTITLE"  --msgbox "$input" 0 0
    else
        echo -e "$input"
        read -p "Press [Enter] to continue..."
    fi
}

module_options+=(
["show_infobox,author"]="Joey Turner"
["show_infobox,ref_link"]=""
["show_infobox,feature"]="show_infobox"
["show_infobox,desc"]="Display an infobox with a message"
["show_infobox,example"]="show_infobox <<< 'hello world' ; "
["show_infobox,doc_link"]=""
["show_infobox,status"]="active"
)
#
# Function to display an infobox with a message
#
function show_infobox() {
    export TERM=ansi
    local input
    local BACKTITLE="$BACKTITLE"
    local -a buffer  # Declare buffer as an array
    if [ -p /dev/stdin ]; then
        while IFS= read -r line; do
            buffer+=("$line")  # Add the line to the buffer
            # If the buffer has more than 10 lines, remove the oldest line
            if (( ${#buffer[@]} > 18 )); then
                buffer=("${buffer[@]:1}")
            fi
            # Display the lines in the buffer in the infobox

            TERM=ansi $DIALOG --title "$BACKTITLE" --infobox "$(printf "%s\n" "${buffer[@]}" )" 18 90
            sleep 0.5
        done
    else
        
        input="$1"
        TERM=ansi $DIALOG --title "$BACKTITLE" --infobox "$( echo "$input" )" 6 80
    fi
        echo -ne '\033[3J' # clear the screen
}


module_options+=(
["show_menu,author"]="Joey Turner"
["show_menu,ref_link"]="https://github.com/armbian/configng/blob/main/lib/armbian-configng/system/see_monitor.sh"
["show_menu,feature"]="show_menu"
["show_menu,desc"]="Display a menu from pipe"
["show_menu,example"]="armbianmonitor -h show_menu ; "
["show_menu,doc_link"]=""
["show_menu,status"]="WIP"
)
show_menu(){

    # Get the input and convert it into an array of options
    inpu_raw=$(cat)
    # Remove the lines befor -h 
	input=$(echo "$inpu_raw" | sed 's/-\([a-zA-Z]\)/\1/' | grep '^  [a-zA-Z] ' | grep -v '\[')
    options=()
    while read -r line; do
        package=$(echo "$line" | awk '{print $1}')
        description=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        options+=("$package" "$description")
    done <<< "$input"

    # Display the menu and get the user's choice
    [[ $DIALOG != "bash" ]] && choice=$($DIALOG --title "Menu" --menu "Choose an option:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)

	# Check if the user made a choice
	if [ $? -eq 0 ]; then
	    echo "$choice"
	else
	    exit 0
	fi 

	}


module_options+=(
["get_user_continue,author"]="Joey Turner"
["get_user_continue,ref_link"]=""
["get_user_continue,feature"]="get_user_continue"
["get_user_continue,desc"]="Display a Yes/No dialog box and prosees continue/exit"
["get_user_continue,example"]="get_user_continue 'Do you wish to continue?' process_input"
["get_user_continue,doc_link"]=""
["get_user_continue,status"]="candidate"
)
#
# Function to display a Yes/No dialog box (WIP)
#
function get_user_continue() {
    local message="$1"
    local next_action=$2

    if $($DIALOG --yesno "$message" 10 80 3>&1 1>&2 2>&3); then
        $next_action
    else
        $next_action "No"
    fi
}



#
# Function to process the user's choice paired with get_user_continue
function process_input() {
    local input="$1"
    if [ "$input" = "No" ]; then
        exit 1
   fi
}


module_options+=(
["see_ping,author"]="Joey Turner"
["see_ping,ref_link"]=""
["see_ping,feature"]="see_ping"
["see_ping,desc"]="Check the internet connection with fallback DNS"
["see_ping,example"]="see_ping"
["see_ping,doc_link"]=""
["see_ping,status"]="active"
)
function see_ping() {
	# List of servers to ping
	servers=("1.1.1.1" "8.8.8.8")

	# Check for internet connection
	for server in "${servers[@]}"; do
	    if ping -q -c 1 -W 1 $server >/dev/null; then
	        echo "Internet connection: Present"
			break
	    else
	        echo "Internet connection: Failed"
			sleep 1
	    fi
	done

	if [[ $? -ne 0 ]]; then
		read -n 1 -s -p "Warning: Configuration cannot work properly without a working internet connection. \
		Press CTRL C to stop or any key to ignore and continue."
	fi
}


module_options+=(
["see_current_apt,author"]="Joey Turner"
["see_current_apt,ref_link"]=""
["see_current_apt,feature"]="see_current_apt"
["see_current_apt,desc"]="Check when apt list was last updated"
["see_current_apt,example"]="see_current_apt"
["see_current_apt,doc_link"]=""
["see_current_apt,status"]="active"
)
see_current_apt() {
    # Number of seconds in a day
    local day=86400

    # Get the current date as a Unix timestamp
    local now=$(date +%s)

    # Get the timestamp of the most recently updated file in /var/lib/apt/lists/
    local update=$(stat -c %Y /var/lib/apt/lists/* | sort -n | tail -1)

    # Calculate the number of seconds since the last update
    local elapsed=$(( now - update ))

    if ps -C apt-get,apt,dpkg >/dev/null; then
        echo "A pkg is running."
        export running_pkg="true"
        return 1  # The processes are running
    else
        export running_pkg="false"
        #echo "apt, apt-get, or dpkg is not currently running"
    fi
    # Check if the package list is up-to-date
    if (( elapsed < day )); then
        #echo "Checking for apt-daily.service"
        echo "$(date -u -d @${elapsed} +"%T")"
        return 0  # The package lists are up-to-date
    else
        #echo "Checking for apt-daily.service"
        echo "Update the package lists"
        return 1  # The package lists are not up-to-date
    fi
}



module_options+=(
["parse_json,author"]="Joey Turner"
["parse_json,ref_link"]=""
["parse_json,feature"]="parse_json"
["parse_json,desc"]="Parse the JSON data output to markdown"
["parse_json,example"]="parse_json"
["parse_json,doc_link"]=""
["parse_json,status"]="Candidate"
)
#
# Function to parse the JSON data ouput to markdown, for documentation
#
function parse_json() {
    # Read the JSON file into a variable
    json=$(cat $directory/etc/armbian-config/retro-config.json)

    # Get the length of the 'menu' array
    length=$(echo "$json" | jq '.menu | length')

    # Iterate over each element in the 'menu' array
    for ((i=0; i<$length; i++)); do
        # Extract the 'id' and 'description' of the current menu
        id=$(echo "$json" | jq -r ".menu[$i].id")
        description=$(echo "$json" | jq -r ".menu[$i].description")

        echo "Menu ID: $id"
        echo "Menu Description: $description"

        # Get the length of the 'sub' array of the current menu
        sub_length=$(echo "$json" | jq ".menu[$i].sub | length")

        # Iterate over each element in the 'sub' array
        for ((j=0; j<$sub_length; j++)); do
            # Extract the 'id', 'description', 'show', 'network', and 'requirements' of the current submenu
            sub_id=$(echo "$json" | jq -r ".menu[$i].sub[$j].id")
            sub_description=$(echo "$json" | jq -r ".menu[$i].sub[$j].description")
            sub_show=$(echo "$json" | jq -r ".menu[$i].sub[$j].show")
            sub_network=$(echo "$json" | jq -r ".menu[$i].sub[$j].network")
            sub_requirements=$(echo "$json" | jq -r ".menu[$i].sub[$j].requirements[]")

            # Get the length of the 'command' array of the current submenu
            command_length=$(echo "$json" | jq ".menu[$i].sub[$j].command | length")

            # Iterate over each element in the 'command' array
            for ((k=0; k<$command_length; k++)); do
                # Extract the 'command' of the current submenu
                sub_command=$(echo "$json" | jq -r ".menu[$i].sub[$j].command[$k]")
                echo "  Submenu Command: $sub_command"
            done

            echo "  Submenu ID: $sub_id"
            echo "  Submenu Description: $sub_description"
            echo "  Submenu Show: $sub_show"
            echo "  Submenu Network: $sub_network"
            echo "  Submenu Requirements: $sub_requirements"
            echo
        done
    done
}

