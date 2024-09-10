#!/bin/bash

# This script is used to dynamically modify a JSON structure that represents a menu in the Armbian configuration tool.
# It performs several checks, such as checking if certain packages are installed and determining the network protocol used.
# Based on these checks, it appends information to the descriptions of menu and submenu items, and shows or hides certain submenu items.
# The modified JSON structure is stored in the variable 'json_data'.

set_colors 2 # Set the color to green

# Dynamically updates a JSON menu structure based on system checks.

#
# Initialize variables
system_info="$(uname -m)"
locale_setting="$LANG"
installed_software="$(see_current_apt)"
held_packages=$(apt-mark showhold)


module_options+=(
    ["update_json_data,author"]="Joey Turner"
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
    ["update_submenu_data,author"]="Joey Turner"
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

#
# Check if network adapter is IPv6 or IPv4
network_adapter="$DEFAULT_ADAPTER"

#
# Main menu updates
update_json_data "System" "$system_info"
update_json_data "Network" "$network_adapter"
update_json_data "Localisation" "$locale_setting"
update_json_data "Software" "$installed_software"

# Conditional submenu updates based on network type
if [ "$network_adapter" = "IPv6" ]; then
    update_submenu_data "Network" "N08" "IPV6"
else
    update_submenu_data "Network" "N08" "IPV4"
fi
