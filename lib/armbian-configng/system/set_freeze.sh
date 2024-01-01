#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# @description U-boot update Freeze
# @requirments none
# @exitcode 0  If successful
# @default freeze
# @options freeze unfreeze
function status::Uboot(){
    if apt-mark showhold | grep -q "^u-boot$"; then
        echo "U-Boot is currently frozen."

    else
        echo "U-Boot is not frozen."
    fi

    return 0 ;
}

freeze::uboot() {
    echo "Freezing U-Boot..."
    # Add your commands to freeze U-Boot here
    sudo apt-mark hold u-boot
}

group_name::uboot-unfreeze() {
    echo "Unfreezing U-Boot..."
    # Add your commands to unfreeze U-Boot here
    sudo apt-mark unhold u-boot
}


group_name::handle_uboot() {
    local command=$1
    case $command in
        freeze)
            freeze::uboot
            ;;
        unfreeze)
            group_name::uboot-unfreeze
            ;;
        *)
            echo "Invalid command. Please use 'freeze' or 'unfreeze'."
            ;;
    esac
}