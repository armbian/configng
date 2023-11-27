#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
reset > /dev/null 2>&1
#set -x
check_install() {
    local cmd=$1
    local package=$2

    # Check if the command is available
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd could not be found, installing..."
         apt-get install -y $package
    else
        echo "$cmd is already installed." 
    fi
}

#
# @description This will process the output and display it in a dialog box.
function process_output() {

    while IFS= read -r line; do
             clear
        if [[ $line == I:* || $line == "Get:*" || $line == "Hit:*" ]]; then
            echo -e "100\n$line" 
            sleep 0.1
            echo -e "0\n$line" 
        fi | dialog --gauge "$line" 6 60 0       
        # if the line starts with W: then it's a warning

        if [[ $line == W:* ]]; then
            dialog --title "Question" --yesno "Warning: $line Are you sure you want to proceed?" 7 60
            response=$?
            case $response in
            0) echo "You chose Yes.";;
            1) echo "You chose No.";;
            255) echo "You chose Cancel.";;
            esac    
        # if the line starts with O: then it's a success
        elif [[ $line == O:* ]]; then
            echo -e "Complete: $line" | armbian-interface -o 
        # if the line starts with E: then it's an error
        elif [[ $line == E:* ]]; then
            dialog --title "Question" --yesno "Warning: $line Are you sure you want to proceed?" 7 60   
            response=$?
            case $response in
            0) echo "You chose Yes.";;
            1) echo "You chose No.";;
            255) echo "You chose Cancel." ; exit 0 ;;
            esac    
        fi
   
    done 
}
# This will setup a chroot development environment.
function setup_chroot() {
    
{
    local config_repo="https://github.com/Tearran/configng.git"
    local debootstrap_reliase="jammy"
    local debootstrap_url="http://ports.ubuntu.com/ubuntu-ports"
    local chroot_dir=/opt/armbian
    echo "I: Setting up chroot environment..."
    [[ -d $chroot_dir ]] && echo "W: Found Yes to remove and continue" && sudo rm -rf $chroot_dir ; sleep 1   
    sudo mkdir -p $chroot_dir
    echo "I: Installing debootstrap..."
    sudo debootstrap --variant=buildd jammy $chroot_dir $debootstrap_url 
    #mount -t proc proc $chroot_dir/proc   
    echo "I: echo 'I: Installing git" ; 
    sudo chroot $chroot_dir apt update 

    echo "I: echo 'I: Installing git, this may take a while..." 
    sudo chroot $chroot_dir apt install -y git 
    echo "I: Cloning ConfigNG repository into chroot directory..." 
    sudo chroot $chroot_dir git clone $config_repo /opt/configng  
} | process_output

echo "O: Chroot environment setup complete." | process_output

}

#
# @description THis will setup a chroot development enviroment .
# @exitcode 0  If successful.
#
# @options none.
#
function chroot::setup(){
    # Set the directory for the container's root file system
    setup_chroot
    return 0
}