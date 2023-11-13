#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


# @description Dowload BUILD System.
#
# @exitcode 0  If successful.
#
# @options none
function armbian::get_build(){

	see_warning
    return 0
}



see_warning(){
# Display a warning message
echo "Warning: The option you have chosen will require rebuilding the systems iso."
echo "The process may take a long time."

# Ask for user confirmation
read -p "Do you want to continue? (y/n): " choice

# Check the user's choice
if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
    # Continue with the operation
    echo "Continuing with the operation..."
    # Add your code for rebuilding the system here
    get_armbian
    # For demonstration purposes, let's simulate a long process
    sleep 5
    echo "System rebuilt successfully!"
else
    # User chose not to continue
    echo "Operation canceled by the user. Exiting..."
fi
}

get_armbian(){
# Define the directory
local dir="/opt/armbian_builds"
# Check if the directory exists
if [ ! -d "$dir" ]; then
  # If not, create the directory
  sudo mkdir "$dir"
  # Set the permission so that all users can access it
  sudo chmod -R 755 "$dir"
fi

# Change to the directory

# Now we'll clone the Armbian build system
if [ ! -d "$dir/build" ]; then
	cd "$dir"
	git clone https://github.com/armbian/build
else
	echo "Armbian build system already cloned."
    run_build ;
fi
}

run_build(){

    ~/.local/bin/armbian-build -t

}
