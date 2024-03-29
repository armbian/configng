#!/bin/bash

#
# sets backgrount to black
set_colors 0


#
# Append Items to main menu descriptions
json_data=$(echo "$json_data" | jq --arg str "$localisation" '(.menu[] | select(.id == "Personalisation"   ) .description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id == "Downloads"   ) .description) += " (" + $str + ")"')

#
# Append Items to Sub menu descriptions 
json_data=$(echo "$json_data" | jq --arg str "$network" '(.menu[] | select(.id=="Development").sub[] | select(.id == "T2").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Development").sub[] | select(.id == "T1").description) += " (" + $str + ")"')
json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Downloads").sub[] | select(.id == "I0").description) += " (" + $str + ")"')


#
# hide sys admin items from user menu
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="System") .show) |= false') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Localisation") .show) |= false') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Install") .show) |= false') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network") .show) |= false') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Software") .show) |= false') ;

#
# show menu user level menu items
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Personalisation") .show) |= true') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Help") .show) |= true') ;
json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Downloads") .show) |= true') ;


case "$1" in
    "--dev")
    get_user_continue "User Mode:\n\nSystem Administration features unavalible\nWould you like to Continue?" process_input ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Development") .show) |= true') ;
    ;;

    "--gui")
        # Desktop keyboard job
        desktop_keyboard
        exit 0
        ;;
    "--json")
        # Generate the EXAMPLES.md file from json job
        generate_json
        exit 0
        ;;
    "--readme")
        # Generate the README.md file job
        generate_readme
        exit 0
        ;;
    "--help")
        # help tests
        see_use
        exit 0
        ;;
        *)
        get_user_continue "User Mode:\n\nSystem Administration features unavalible\nWould you like to Continue?" process_input ;
        ;;
esac
