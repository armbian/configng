#!/bin/bash


set_colors 1

#get_user_continue "Disclaimer:\nSystem administration tool\nUnderstand these implications before proceeding.\nDo you wish to continue?" process_input ;

#
# SET the TUI to whiptail 
#
[[ -x "$(command -v whiptail)" ]] && DIALOG="whiptail" 


# So called runtime checks 
#

# Append Items to menu descriptions 
json_data=$(echo "$json_data" | jq --arg str "$testing"      '(.menu[] | select(.id == "Testing"      ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$system"       '(.menu[] | select(.id == "System"       ) .description) += " (" + $str + ")"')  
json_data=$(echo "$json_data" | jq --arg str "$DEFAULT_ADAPTER"      '(.menu[] | select(.id == "Network"      ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$localisation" '(.menu[] | select(.id == "Localisation" ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install"      '(.menu[] | select(.id == "Software"      ) .description) += " (" + $str + ")"')

#
# Append Items to Sub menu descriptions 
json_data=$(echo "$json_data" | jq --arg str "$network" '(.menu[] | select(.id=="Testing").sub[] | select(.id == "T2").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Testing").sub[] | select(.id == "T1").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Install").sub[] | select(.id == "I0").description) += " (" + $str + ")"')

# Show or hide Sub menu items dynamicly
bluetooth_installed=$(dpkg -s bluetooth &> /dev/null && echo true || echo false)
bluez_installed=$(dpkg -s bluez &> /dev/null && echo true || echo false)
bluez_tools_installed=$(dpkg -s bluez-tools &> /dev/null && echo true || echo false)

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


