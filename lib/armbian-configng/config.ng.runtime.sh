#!/bin/bash

# This script is used to dynamically modify a JSON structure that represents a menu in the Armbian configuration tool.
# It performs several checks, such as checking if certain packages are installed and determining the network protocol used.
# Based on these checks, it appends information to the descriptions of menu and submenu items, and shows or hides certain submenu items.
# The modified JSON structure is stored in the variable 'json_data'.

set_colors 2 # Set the color to green

# Main menu items
system="$(uname -m)"
network="$(echo "$DEFAULT_ADAPTER")"
localisation="$LANG"
software="$(see_current_apt)"


# Sub menu items
bluetooth_installed=$(dpkg -s bluetooth &> /dev/null && echo true || echo false)
bluez_installed=$(dpkg -s bluez &> /dev/null && echo true || echo false)
bluez_tools_installed=$(dpkg -s bluez-tools &> /dev/null && echo true || echo false)
#check_hold=$(apt-mark showhold)

# Append Items to menu descriptions 
json_data=$(echo "$json_data" | jq --arg str "$system"       '(.menu[] | select(.id == "System"       ) .description) += " (" + $str + ")"')  
json_data=$(echo "$json_data" | jq --arg str "$network"      '(.menu[] | select(.id == "Network"      ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$localisation" '(.menu[] | select(.id == "Localisation" ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$software"      '(.menu[] | select(.id == "Software"      ) .description) += " (" + $str + ")"')

#
# Append Items to Sub menu descriptions 
json_data=$(echo "$json_data" | jq --arg str "$network" '(.menu[] | select(.id=="Testing").sub[] | select(.id == "T2").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$software" '(.menu[] | select(.id=="Testing").sub[] | select(.id == "T1").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$software" '(.menu[] | select(.id=="Install").sub[] | select(.id == "I0").description) += " (" + $str + ")"')

# Show or hide Sub menu items dynamicly

if [ "$network" = "IPv6" ]; then
    # If IPv6 is being used, do something
    json_data=$(echo "$json_data" | jq --arg str "IPV6" '(.menu[] | select(.id=="Network").sub[] | select(.id == "N03").description) += " (" + $str + ")"')
else
    # If IPv4 is being used or the domain is unreachable, do something else
    json_data=$(echo "$json_data" | jq --arg str "IPV4" '(.menu[] | select(.id=="Network").sub[] | select(.id == "N03").description) += " (" + $str + ")"')
fi

if [ "$bluetooth_installed" = false ] || [ "$bluez_installed" = false ] || [ "$bluez_tools_installed" = false ]; then
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network").sub[] | select(.id == "BT0").show) |= true')
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network").sub[] | select(.id == "BT3").show) |= false')

else
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network").sub[] | select(.id == "BT1").show) |= true')
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network").sub[] | select(.id == "BT3").show) |= true')
fi

# Show or hide Sub menu items dynamicly
#

[[ -n "$check_hold" ]] &&  json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="System").sub[] | select(.id == "S03").show) |= true')
[[ -z "$check_hold" ]] &&  json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="System").sub[] | select(.id == "S04").show) |= true')


