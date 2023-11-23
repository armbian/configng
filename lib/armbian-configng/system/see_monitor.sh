#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


# @description Armbian Monitor and Bencharking.
#
# @exitcode 0  If successful.
#
# @options none
function monitor::Bencharking(){
	see_menu
	return 0 ; 
}

see_menu(){
	# Define the script
	script="armbianmonitor"


	# Run the script with the -h option and save the output to a variable
	help_message=$("$script" -h || "$script" -h ) || exit 2

	# Reformat the help message into an array line by line
	readarray -t script_launcher < <(echo "$help_message" | sed 's/-\([a-zA-Z]\)/\1/' | grep '^  [a-zA-Z] ' | grep -v '\[')

	# Loop through each line in the array and create a menu string
	menu_string=""
	for line in "${script_launcher[@]}"; do
	  # Append the formatted line to the menu string
	  menu_string+="$line\n"
	done

	# Use the get_help_msg function and pipe its output into configng-interface -m
	selected_option=$(echo -e "$menu_string" | ./armbian-interface -m)

	# Run the armbian-monitor script with the selected option
	[[ -n "$selected_option" ]] && "$script" -"$selected_option" | ./armbian-interface -o ;

	}

