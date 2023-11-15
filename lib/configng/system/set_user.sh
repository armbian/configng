#!/bin/bash

# @description Setup a new sudo user account.
#
# @exitcode 0  If successful.
#
# @options Prompt for the new username.
function enduser::set_new(){

    # Prompt the user for the new username
    read -p "Please enter the new username: " username

    # Create a new user
    sudo adduser $username

    # Prompt the user for the new user's password
    read -s -p "Please enter the password for the new user: " password

    # Set a password for the new user
    echo "$username:$password" | sudo chpasswd

    # Add the new user to the sudo group
    sudo usermod -aG sudo $username 
    return 0 ;
    }