#!/bin/bash




module_options+=(
["check_desktop,author"]="Igor Pecovnik"
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

	DISPLAY_MANAGER=""; DESKTOP_INSTALLED=""
	check_if_installed nodm && DESKTOP_INSTALLED="nodm";
	check_if_installed lightdm && DESKTOP_INSTALLED="lightdm";
	check_if_installed lightdm && DESKTOP_INSTALLED="gnome";
	[[ -n $(service lightdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="lightdm"
	[[ -n $(service nodm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="nodm"
	[[ -n $(service gdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="gdm"

}



menu_options+=(
["get_headers_kernel,author"]="Igor Pecovnik"
["get_headers_kernel,ref_link"]=""
["get_headers_kernel,feature"]="get_headers_install"
["get_headers_kernel,desc"]="Migrated procedures from Armbian config."
["get_headers_kernel,example"]="get_headers_install"
["get_headers_kernel,status"]="Active"
["get_headers_kernel,doc_link"]=""
)
#
# install kernel headers
#
function get_headers_install() {

    if [[ -f /etc/armbian-release ]]; then
        INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}";
    else
        INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
    fi

    debconf-apt-progress -- apt-get -y install ${INSTALL_PKG} || exit 1

}

module_options+=(
["set_header_remove,author"]="Igor Pecovnik"
["set_header_remove,ref_link"]=""
["set_header_remove,feature"]="set_header_remove"
["set_header_remove,desc"]="Migrated procedures from Armbian config."
["set_header_remove,example"]="set_header_remove"
["set_header_remove,doc_link"]=""
["set_header_remove,status"]="Active"
["set_header_remove,doc_ink"]=""
)
#
# remove kernel headers
#
function set_header_remove() {

    REMOVE_PKG="linux-headers-*"
    if [[ -n $(dpkg -l | grep linux-headers) ]]; then
        debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
        rm -rf /usr/src/linux-headers*
    else
        debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
    fi
    # cleanup
    apt clean
    debconf-apt-progress -- apt -y autoremove

}

module_options+=(
["check_if_installed,author"]="Igor Pecovnik"
["check_if_installed,ref_link"]=""
["check_if_installed,feature"]="check_if_installed"
["check_if_installed,desc"]="Migrated procedures from Armbian config."
["check_if_installed,example"]="check_if_installed nano"
["check_if_installed,status"]="Active"
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
["update_skel,author"]="Igor Pecovnik"
["update_skel,ref_link"]=""
["update_skel,feature"]="update_skel"
["update_skel,desc"]="Update the /etc/skel files in users directories"
["update_skel,example"]="update_skel"
["update_skel,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function update_skel (){

	getent passwd |
	while IFS=: read -r username x uid gid gecos home shell
	do
	if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ]
	then
		continue
	fi
        tar -C /etc/skel/ -cf - . | su - "$username" -c "tar --skip-old-files -xf -"
	done

}


module_options+=(
["qr_code,author"]="Igor Pecovnik"
["qr_code,ref_link"]=""
["qr_code,feature"]="qr_code"
["qr_code,desc"]="Show or generate QR code for Google OTP"
["qr_code,example"]="qr_code generate"
["qr_code,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function qr_code (){

	clear
	if [[ "$1" == "generate" ]]; then
		google-authenticator -t -d -f -r 3 -R 30 -W -q
		cp /root/.google_authenticator /etc/skel
		update_skel
	fi
	export TOP_SECRET=$(head -1 /root/.google_authenticator)
	qrencode -m 2 -d 9 -8 -t ANSI256 "otpauth://totp/test?secret=$TOP_SECRET"
	echo -e '\nScan QR code with your OTP application on mobile phone\n'
	read -n 1 -s -r -p "Press any key to continue"

}


module_options+=(
["is_package_manager_running,author"]="Igor Pecovnik"
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

	if ps -C apt-get,apt,dpkg >/dev/null ; then
		[[ -z $scripted ]] && echo -e "\nPackage manager is running in the background. \n\nCan't install dependencies. Try again later." | show_infobox
		return 0
	else
		return 1
	fi

}


module_options+=(
["set_runtime_variables,author"]="Igor Pecovnik"
["set_runtime_variables,ref_link"]=""
["set_runtime_variables,feature"]="set_runtime_variables"
["set_runtime_variables,desc"]="Run time variables Migrated procedures from Armbian config."
["set_runtime_variables,example"]="set_runtime_variables"
["set_runtime_variables,status"]="Active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables(){

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
    if systemctl is-active systemd-networkd 1>/dev/null; then
        renderer=networkd
    else
        renderer=NetworkManager
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

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE";
	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc)
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// }" ]] && ARMBIAN="$DISTRO $DISTROID"
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	BACKTITLE="\n    Contribute: https://github.com/armbian/configng\n"
	TITLE="Armbian configuration utility"
	[[ -z "${DEFAULT_ADAPTER// }" ]] && DEFAULT_ADAPTER="lo"

	# detect desktop
	check_desktop

}


module_options+=(
["armbian_fw_manipulate,author"]="Igor Pecovnik"
["armbian_fw_manipulate,ref_link"]=""
["armbian_fw_manipulate,feature"]="armbian_fw_manipulate"
["armbian_fw_manipulate,desc"]="freeze/unhold/reinstall armbian related packages."
["armbian_fw_manipulate,example"]="armbian_fw_manipulate unhold|freeze|reinstall"
["armbian_fw_manipulate,status"]="Active"
)
#
# freeze/unhold/reinstall armbian firmware packages
#
armbian_fw_manipulate() {

    local function=$1
    local version=$2

    [[ -n $version ]] && local version="=${version}"

	# fallback to current
	[[ -z $BRANCH ]] && BRANCH="current"

	# packages to install
	local armbian_packages=(
	    "linux-u-boot-${BOARD}-${BRANCH}"
	    "linux-image-${BRANCH}-${LINUXFAMILY}"
	    "linux-dtb-${BRANCH}-${LINUXFAMILY}"
	    "armbian-config"
        "armbian-zsh"
	)

	# reinstall headers only if they were previously installed
	if are_headers_installed; then
		local armbian_packages+="linux-headers-${BRANCH}-${LINUXFAMILY}"
	fi

	local packages=""
	for pkg in "${armbian_packages[@]}"
	do
			if [[ "${function}" == reinstall ]]; then
				apt search "$pkg" 2>/dev/null | grep "^$pkg" >/dev/null
				if [[ $? -eq 0 ]]; then packages+="$pkg${version} "; fi
			else
				if check_if_installed $pkg; then
				packages+="$pkg${version} "
				fi
			fi
	done

	for pkg in "${packages[@]}"
	do
		case $function in
			unhold)            apt-mark unhold ${pkg} | show_infobox ;;
			hold)              apt-mark hold ${pkg} | show_infobox ;;
			reinstall)
						apt_install_wrapper apt-get -y --download-only --allow-change-held-packages --allow-downgrades install "${pkg}"
						apt_install_wrapper apt-get -y purge "${pkg}"
						apt_install_wrapper apt-get -y --allow-change-held-packages --allow-downgrades install "${pkg}"
						apt_install_wrapper apt-get -y autoremove
			;;
			*) return ;;
		esac
	done
}


module_options+=(
["switch_kernels,author"]="Igor"
["switch_kernels,ref_link"]=""
["switch_kernels,feature"]=""
["switch_kernels,desc"]="Switching to alternative kernels"
["switch_kernels,example"]=""
["switch_kernels,status"]="Active"
)
#
# @description Switch between alternative kernels
#
function switch_kernels () {

	# we only allow switching kerneles that are in the test pool
	[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,current,edge"
	local kernel_test_target="("$(echo $KERNEL_TEST_TARGET | sed "s/,/|/g")")"
	local current_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}')

	IFS=$'\n'
	local LIST=()
	for line in $(\
		apt-cache show "linux-image-${kernel_test_target}-${LINUXFAMILY}" | grep -E  "Package:|Version:|version:|family" \
		| grep -v "Config-Version" | sed -n -e 's/^.*: //p' | sed 's/\.$//g' | xargs -n3 -d'\n' | sed "s/ /=/" \
		| grep -v ${current_kernel_version}); do
		LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
	done
	unset IFS
	local list_length=$((${#LIST[@]}/2));
	if [ "$list_length" -eq 0 ]; then
		dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox  "\nNo other kernels available!" 7 32
	else
		local target_version=$(whiptail --separate-output --title "Select kernel" --menu "ed" $((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ -n "${target_version}" ]; then
			armbian_fw_manipulate "reinstall" "${target_version/*=/}"
		fi
	fi
}


module_options+=(
["connect_bt_interface,author"]="Igor Pecovnik"
["connect_bt_interface,ref_link"]=""
["connect_bt_interface,feature"]="connect_bt_interface"
["connect_bt_interface,desc"]="Migrated procedures from Armbian config."
["connect_bt_interface,example"]="connect_bt_interface"
["connect_bt_interface,status"]="Active"
)
#
# connect to bluetooth device
#
function connect_bt_interface(){

	IFS=$'\r\n'
	GLOBIGNORE='*'
	show_infobox <<< "\nDiscovering Bluetooth devices ... "
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
		show_message <<< "\nNo nearby Bluetooth devices were found!"
	else
		exec 3>&1
		BT_ADAPTER=$(whiptail --title "Select interface" \
		--clear --menu "" $((6+${LIST_LENGTH})) 50 $LIST_LENGTH "${LIST[@]}" 2>&1 1>&3)
		exec 3>&-
		if [[ $BT_ADAPTER != "" ]]; then
			show_infobox <<< "\nConnecting to $BT_ADAPTER "
			BT_EXEC=$(
			expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address\r";
			sleep 1;send "remove $address\r";sleep 1;expect -re $prompt;send "scan on\r";sleep 8;send "scan off\r";
			expect "Controller";send "trust $address\r";sleep 2;send "pair $address\r";sleep 2;send "connect $address\r";
			send_user "\nShould be paired now.\r";sleep 2;send "quit\r";expect eof')
			echo "$BT_EXEC" > /tmp/bt-connect-debug.log
				if [[ $(echo "$BT_EXEC" | grep "Connection successful" ) != "" ]]; then
					show_message <<< "\nYour device is ready to use!"
				else
					show_message <<< "\nError connecting. Try again!"
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


module_options+=(
["parse_menu_items,author"]="Gunjan Gupta"
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
    while IFS= read -r id
    do
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
    done < <(echo "$json_data" | jq -r '.menu[] | '${parent_id:+".. | objects | select(.id==\"$parent_id\") | .sub[]? |"}' select(.disabled|not) | "\(.id)\n\(.description)\n\(.condition)"' || exit 1 )
}


module_options+=(
["generate_top_menu,author"]="Joey Turner"
["generate_top_menu,ref_link"]=""
["generate_top_menu,feature"]="generate_top_menu"
["generate_top_menu,desc"]="Build the main menu from a object"
["generate_top_menu,example"]="generate_top_menu 'json_data'"
["generate_top_menu,doc_link"]=""
["generate_top_menu,status"]="Active"
)
#
# Function to generate the main menu from a JSON object
#
generate_top_menu() {
    local json_data=$1

    while true; do
        local menu_options=()

        parse_menu_items menu_options

        local OPTION=$($DIALOG --title "$TITLE"  --menu "$BACKTITLE" 0 80 9 "${menu_options[@]}" \
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
["generate_menu,author"]="Joey Turner"
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
    local parent_id=$1

    while true; do
        # Get the submenu options for the current parent_id
        local submenu_options=()
        parse_menu_items submenu_options

        local OPTION=$($DIALOG --title "$TITLE"  --menu "$BACKTITLE" 0 80 9 "${submenu_options[@]}" \
                                --ok-button Select --cancel-button Back 3>&1 1>&2 2>&3)

        local exitstatus=$?

        if [ $exitstatus = 0 ]; then
            [ -z "$OPTION" ] && break

            # Check if the selected option has a submenu
            local submenu_count=$(jq -r --arg id "$OPTION" '.menu[] | .. | objects | select(.id==$id) | .sub? | length' "$json_file")
            submenu_count=${submenu_count:-0}  # If submenu_count is null or empty, set it to 0
            if [ "$submenu_count" -gt 0 ]; then
                # If it does, generate a new menu for the submenu
                [[ -n "$debug" ]] && echo "$OPTION"
                generate_menu "$OPTION"
            else
                # If it doesn't, execute the command
                [[ -n "$debug" ]] &&  echo "$OPTION"
                execute_command "$OPTION"
            fi
        fi
    done
}


module_options+=(
["execute_command,author"]="Joey Turner"
["execute_command,ref_link"]=""
["execute_command,feature"]="execute_command"
["execute_command,desc"]="Needed by generate_menu"
["execute_command,example"]=""
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

    # Check if a prompt exists
    local prompt=$(jq -r --arg id "$id" '
      .menu[] |
      .. |
      objects |
      select(.id == $id) |
      .prompt?' "$json_file")

    # If a prompt exists, display it and wait for user confirmation
    if [[ "$prompt" != "null" && $INPUTMODE != "cmd" ]]; then
        get_user_continue "$prompt" process_input
    fi

    # Execute each command
    for command in "${commands[@]}"; do
        [[ -n "$debug" ]] && echo "$command"
        eval "$command"
    done
}

module_options+=(
["show_message,author"]="Joey Turner"
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
        $DIALOG  --title "$TITLE"  --msgbox "$input" 0 0
    else
        echo -e "$input"
        read -p -r "Press [Enter] to continue..."
    fi
}


module_options+=(
["show_infobox,author"]="Joey Turner"
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
    local -a buffer  # Declare buffer as an array
    if [ -p /dev/stdin ]; then
        while IFS= read -r line; do
            buffer+=("$line")  # Add the line to the buffer
            # If the buffer has more than 10 lines, remove the oldest line
            if (( ${#buffer[@]} > 18 )); then
                buffer=("${buffer[@]:1}")
            fi
            # Display the lines in the buffer in the infobox

            TERM=ansi $DIALOG --title "$TITLE" --infobox "$(printf "%s\n" "${buffer[@]}" )" 16 90
            sleep 0.5
        done
    else

        input="$1"
        TERM=ansi $DIALOG --title "$TITLE" --infobox "$input" 6 80
    fi
        echo -ne '\033[3J' # clear the screen
}


module_options+=(
["show_menu,author"]="Joey Turner"
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
show_menu(){

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

    if $($DIALOG --yesno "$message" 10 80 3>&1 1>&2 2>&3); then
        $next_action
    else
        $next_action "No"
    fi
}


menu_options+=(
["get_user_continue,author"]="Joey Turner"
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
        exit 1
   fi
}


module_options+=(
["get_user_continue_secure,author"]="Joey Turner"
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
["see_ping,author"]="Joey Turner"
["see_ping,ref_link"]=""
["see_ping,feature"]="see_ping"
["see_ping,desc"]="Check the internet connection with fallback DNS"
["see_ping,example"]="see_ping"
["see_ping,doc_link"]=""
["see_ping,status"]="Active"
)
#
# Function to check the internet connection
#
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
		read -n -r 1 -s -p "Warning: Configuration cannot work properly without a working internet connection. \
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
["see_current_apt,status"]="Active"
)
#
# Function to check when the package list was last updated
#
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
["are_headers_installed,author"]="Gunjan Gupta"
["are_headers_installed,ref_link"]=""
["are_headers_installed,feature"]="are_headers_installed"
["are_headers_installed,desc"]="Check if kernel headers are installed"
["are_headers_installed,example"]="are_headers_installed"
["are_headers_installed,status"]="Pending Review"
["are_headers_installed,doc_link"]=""
)
#
# @description Install kernel headers
#
function are_headers_installed () {
    if [[ -f /etc/armbian-release ]]; then
        PKG_NAME="linux-headers-${BRANCH}-${LINUXFAMILY}";
    else
        PKG_NAME="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
    fi

    check_if_installed ${PKG_NAME}
    return $?
}


module_options+=(
["Headers_install,author"]="Joey Turner"
["Headers_install,ref_link"]=""
["Headers_install,feature"]="Headers_install"
["Headers_install,desc"]="Install kernel headers"
["Headers_install,example"]="is_package_manager_running"
["Headers_install,status"]="Pending Review"
["Headers_install,doc_link"]=""
)
#
# @description Install kernel headers
#
function Headers_install () {
	if ! is_package_manager_running; then
	  if [[ -f /etc/armbian-release ]]; then
	    INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}";
	    else
	    INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
	  fi
	  debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
}

module_options+=(
["Headers_remove,author"]="Joey Turner"
["Headers_remove,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L160"
["Headers_remove,feature"]="Headers_remove"
["Headers_remove,desc"]="Remove Linux headers"
["Headers_remove,example"]="Headers_remove"
["Headers_remove,status"]="Pending Review"
["Headers_remove,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Linux headers
#
function Headers_remove () {
	if ! is_package_manager_running; then
		REMOVE_PKG="linux-headers-*"
		if [[ -n $(dpkg -l | grep linux-headers) ]]; then
			debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
			rm -rf /usr/src/linux-headers*
		else
			debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
		fi
		# cleanup
		apt clean
		debconf-apt-progress -- apt -y autoremove
	fi
}

module_options+=(
["sanitize_input,author"]=""
["sanitize_input,ref_link"]=""
["sanitize_input,feature"]="sanitize_input"
["sanitize_input,desc"]="sanitize input cli"
["sanitize_input,example"]="sanitize_input"
["sanitize_input,status"]="Pending Review"
["sanitize_input,doc_link"]=""
)
#
# sanitize input cli
#
sanitize_input() {
    local sanitized_input=()
    for arg in "$@"; do
        if [[ $arg =~ ^[a-zA-Z0-9_=]+$ ]]; then
            sanitized_input+=("$arg")
        else
            echo "Invalid argument: $arg"
            exit 1
        fi
    done
    echo "${sanitized_input[@]}"
}
