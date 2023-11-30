#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
reset > /dev/null 2>&1
[[ "$dev" == "0" ]] && echo "E: This function is not available in the live environment." && exit 1 
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
        # if the line starts with O: then it's a success
        if [[ $line == O:* ]]; then
            echo -e "Complete: $line" | armbian-interface -o 
        fi
        
        if [[ $line == I:* ]]; then
            echo -e "100\n$line" 
            sleep 0.25
            echo -e "0\n$line" 
        fi | dialog --gauge "$line" 6 60 0        
    done 
}

# This will setup a chroot development environment.
# work in progress
function setup_chroot() {

    local config_repo="https://github.com/Tearran/configng.git"
    local debootstrap_reliase="jammy"
    local debootstrap_url="http://ports.ubuntu.com/ubuntu-ports"
    local chroot_dir=/opt/armbian
    [[ -d $chroot_dir ]] && echo "E: Found $chroot_dir Remove it first" ; sudo rm -rf $chroot_dir/   
    [[ ! -d "$chroot_dir" ]] && sudo mkdir -p "$chroot_dir" 
    [[ ! -d "$chroot_dir" ]] && echo "I: Installing debootstrap..." 
    sudo debootstrap --variant=buildd jammy $chroot_dir $debootstrap_url    

	mount -t proc proc $chroot_dir/proc   
    mount --bind /dev $chroot_dir/dev

    echo "I: Installing ubuntu-keyring..." 
    sudo chroot $chroot_dir apt install -y ubuntu-keyring
    echo "I: echo 'I: Installing git" 
    sudo chroot $chroot_dir apt update 

    echo "I: echo 'I: Installing git, this may take a while..." 
    sudo chroot $chroot_dir apt install -y git 
    sudo chroot $chroot_dir apt install -y whiptail
    sudo chroot $chroot_dir /bin/bash -c "apt-get install -y locales"
    sudo chroot $chroot_dir /bin/bash -c "sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen"
    sudo chroot $chroot_dir /bin/bash -c "dpkg-reconfigure --frontend=noninteractive locales"
    sudo chroot $chroot_dir /bin/bash -c "update-locale LANG=en_US.UTF-8"

    echo "I: Cloning ConfigNG repository into chroot directory..." 
    sudo chroot $chroot_dir git clone $config_repo /opt/configng  
    echo "O: Chroot environment setup complete."
    sudo chroot $chroot_dir 

}

#
# @description WIP: Setup a non destructive Test enviroment.
#
# @exitcode 0  If successful.
#
# @options none.
#
function chroot::setup(){
    # Set the directory for the container's root file system
    setup_chroot
    return 0
    reset > /dev/null 2>&1
}