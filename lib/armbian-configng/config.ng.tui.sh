#!/bin/bash




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
[[ -x "$(command -v whiptail)" ]] && DIALOG="whiptail" ||  exit 1 ;

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
        [[ -n "$debug" ]] && echo "$OPTION"
        generate_menu "$OPTION"
    fi

#    echo "Menu options: ${menu_options[@]}"

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
            [[ -n "$debug" ]] && echo "$OPTION"
            generate_menu "$OPTION"
        else
            # If it doesn't, execute the command
            [[ -n "$debug" ]] &&  echo "$OPTION"
            execute_command "$OPTION"
            #show_message <<< "$OPTION"
        fi
    fi

           # echo "Submenu options: ${submenu_options[@]}"

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
    local commands=$(jq -r --arg id "$id" '.menu[] | .. | objects | select(.id==$id) | .command[]' "$json_file")
    for command in "${commands[@]}"; do
        # Check if the command is not in the list of restricted commands       
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
        $DIALOG  --title "$BACKTITLE"  --msgbox "$input" 0 0
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

            TERM=ansi $DIALOG --title "$BACKTITLE" --infobox "$(printf "%s\n" "${buffer[@]}" )" 16 90
            sleep 0.5
        done
    else
        
        input="$1"
        TERM=ansi $DIALOG --title "$BACKTITLE" --infobox "$input" 6 80
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
