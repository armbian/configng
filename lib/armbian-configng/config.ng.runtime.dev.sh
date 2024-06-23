#!/bin/bash


if [[ "$1" == "dev" || "$1" == "--dev" ]]; then
    shift
    get_user_continue "Development Mode:\n\nYou are entering development mode. System Administration features will be unavailable. Do you wish to continue?" process_input
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Development") .show) |= true')

    # sets backgrount to black
    set_colors 0

    # Append Items to main menu descriptions
    json_data=$(echo "$json_data" | jq --arg str "$localisation" '(.menu[] | select(.id == "Personalisation"   ) .description) += " (" + $str + ")"')
    json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id == "Downloads"   ) .description) += " (" + $str + ")"')

    
    # Append Items to Sub menu descriptions 
    json_data=$(echo "$json_data" | jq --arg str "$network" '(.menu[] | select(.id=="Development").sub[] | select(.id == "T2").description) += " (" + $str + ")"')
    json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Development").sub[] | select(.id == "T1").description) += " (" + $str + ")"')
    json_data=$(echo "$json_data" | jq --arg str "$install" '(.menu[] | select(.id=="Downloads").sub[] | select(.id == "I0").description) += " (" + $str + ")"')
 

    # hide sys admin items from user menu
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="System") .show) |= false') ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Localisation") .show) |= false') ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Network") .show) |= false') ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Software") .show) |= false') ;


    # show menu user level menu items
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Personalisation") .show) |= true') ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Help") .show) |= true') ;
    json_data=$(echo "$json_data" | jq '(.menu[] | select(.id=="Downloads") .show) |= true') ;

elif [[ "$1" == "--docs" ]]; then
    generate_readme
    exit 0
fi
