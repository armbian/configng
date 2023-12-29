

# This function is used to generate a text-based user interface (TUI) for navigating the menus.
generate_tui() {
    local options=()
    local i=0
    declare -A categories_array
    for category in "${categories[@]}"; do
        local category_name="${category##*/}"
        local category_description=""
        local category_file="$category/readme.md"

        if [[ -f "$category_file" ]]; then
            category_description=$(grep -oP "(?<=# @description ).*" "$category_file")
        fi

        categories_array["$i"]="$category_name"
        description_array["$i"]="$category_description"
        options+=("$i" "$(printf '%-7s - %-8s' "${categories_array[$i]}" "${description_array[$i]}")")
        #options+=("$i" "${categories_array[$i]} - ${description_array[$i]}")
        ((++i))
    done
      [[ -f /sbin/armbian-config ]] && options+=("$i" "$(printf '%-7s - %-8s' "Legacy" "Run Legacy configuration")") ; ((++i)) ;
      [[ ! -d "$libpath/help" ]] && options+=("$i" "$(printf '%-7s - %-8s' "Help" "Documentation, support, sources")") ; ((++i)) ;

    local choice
    
    choice=$($dialogue --menu "Select a category:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)
    
   if [[ -n $choice ]]; then
        
        if ((choice == "$i - 1")); then
            generate_help #| armbian-interface -o
            exit ;
        elif ((choice == "$i - 2")); then
            armbian-config
            exit ;
        else
            generate_sub_tui "${categories_array[$choice]}"
        fi
    fi
}

# This function is used to generate a text-based user interface (TUI) for navigating the menus.
generate_sub_tui() {
    local category="$1"
    local options=()
    local i=0
    declare -A functions_array
    for file in "$libpath/$category"/*.sh; do
        mapfile -t functions_in_file < <(grep -oP '(?<=function\s)\w+::\w+' "$file")
        for function in "${functions_in_file[@]}"; do
            key="${category##*/}:${file##*/}:${function}"
            functions_array["$i"]="$function"
            options+=("$i" "${functions["$key,function_name"]} - ${functions["$key,description"]}")
            ((++i))
        done
    done

    local choice
    
    choice=$($dialogue --menu "Select a function:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)
    
    if [[ -n $choice ]]; then
        generate_action "${functions_array[$choice]}"
    fi

}

# This function is used to generate a whiptail/dialog text-based user interface (TUI) for navigating the menus.
generate_action() {
    local function_name="$1"
            ${function_name}
}

# This function is used to generate a bash text-based user interface (TUI) for navigating the menus.
generate_read() {
    echo
    echo "Please select an action:"
    echo
    # Initialize an empty array to store the function keys
    declare -a function_keys

    # Loop through each key in the functions array
    local i=1
    local current_category=""
    for key in "${!functions[@]}"; do
        if [[ $key == *",function_name" ]]; then
            # Add the key to the function_keys array
            function_keys[i]="${key%,function_name}"

            # Check if the category has changed and display it if so
            local category="${functions["${function_keys[i]},category"]}" # < editor"
            if [[ "$category" != "$current_category" ]]; then
                echo "Category: $category"
                current_category="$category"
            fi

            # Display the function and its description as an option in the menu
            echo "  $i. ${functions["${function_keys[i]},group_name"]} ${functions[$key]}  - ${functions["${function_keys[i]},description"]}" #" < for my editor
            ((i++))
        fi
    done

    echo
    echo "$i. Show help"
    ((i++))
    echo "$i. Exit"

    read -p "Enter your choice: " choice

    if ((choice == i-1)); then
        generate_help
    elif ((choice == i)); then
        exit 0
    elif ((choice >= 1 && choice <= ${#function_keys[@]})); then
        # Call the selected function using variable indirection
        eval "${functions["${function_keys[choice]},group_name"]}::${functions["${function_keys[choice]},function_name"]}" #" < for my editor
    else
        echo "Invalid choice"
    fi
}

# This function is used to parse the action name and return the full function name.
parse_action() {
    local group=$1
    local action=$2

    # Construct the full function name
    local function_name="${group}::${action}"

    # Check if the function exists
    if declare -f "$function_name" > /dev/null; then
        # Return the function name
        echo "$function_name"
    else
        echo "Error: Unknown action '$action' for group '$group'"
        return 1
    fi
}