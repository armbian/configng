#!/bin/bash

function set_config() {
    CONFIG_FILE="/etc/armbian/configng.sh"

    echo "Creating $CONFIG_FILE with example key pair."

    # Create the directory if it doesn't exist
    mkdir -p $(dirname "$CONFIG_FILE")

    # Write the example key pair to the file
    echo "example[KEY]=\"example_key\"" > "$CONFIG_FILE"
    echo "example[SECRET]=\"example_secret\"" >> "$CONFIG_FILE"
}

function get_config() {
    CONFIG_FILE="/etc/armbian/configng.sh"

    if [[ -f "$CONFIG_FILE" ]]; then

        echo "System Checks."  
        echo -e "\e[5;33mINFORMATION:\e[0m"
        echo "  Checking for CONFIG_FILE."
        echo "    found $CONFIG_FILE, sourcing it."
    
        source "$CONFIG_FILE"

        echo ""
    else
        echo "System Checks."  
        echo "  Checking for $CONFIG_FILE."
        echo "    $CONFIG_FILE does not exist."
        echo "     Setting example configuration using"
                set_config
        echo "     set_config function."
        echo ""

    fi
}



function see_ping() {
    # List of servers to ping
    servers=("1.1.1.1" "8.8.8.8")

    # Check for internet connection
    for server in "${servers[@]}"; do
        if ping -q -c 1 -W 1 $server >/dev/null; then
            #echo -e "\e[5;31mWARNING:\e[0m"
            echo -e "\e[5;33mINFORMATION:\e[0m"
            echo "  Checking for Network "
            echo "     Internet connection is present."
            echo ""
            return
        else 
            echo -e "\e[5;31mWARNING: Internet Not available.\e[0m"
            echo "  Checking for Network - times."
            echo "    This app has been disabled? eixt"
            echo ""
            exit 1
        fi
    done
}

function is_apt_list_current() {
    # Number of seconds in a day
    local day=86400

    # Get the current date as a Unix timestamp
    local now=$(date +%s)

    # Get the last start time of apt-daily.service as a Unix timestamp
    local update=$(date -d "$(systemctl show -p ActiveEnterTimestamp apt-daily.service | cut -d'=' -f2)" +%s)

    # Calculate the number of seconds since the last update
    local elapsed=$(( now - update ))

    # Check if the package list is up-to-date
    if (( elapsed < day )); then
        echo -e "\e[5;33mINFORMATION:\e[0m"
        echo "  Checking for apt-daily.service"
        echo "    The package lists are up-to-date."
        return 0  # The package lists are up-to-date
    else
        echo -e "\e[5;31mWARNING:\e[0m"
        echo "  Checking for apt-daily.service"
        echo "    The package lists are not up-to-date."
        return 1  # The package lists are not up-to-date
    fi
}
