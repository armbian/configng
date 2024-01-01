#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# @description Kernal U-boot update Hold/Unhold.
# @requirments none
# @exitcode 0  If successful
# @default unfrozen
# @options [frozen] [unfrozen]
function status::Kernel(){
    if apt-mark showhold | grep -q "^u-boot$"; then   
            echo "uboot_package=frozen" > "$etcpath"/"$filename".sh
    else 
            echo "uboot_package=unfrozen" > "$etcpath"/"$filename".sh
    fi
    if apt-mark showhold | grep -q "^linux-image$"; then   
            echo "kernel_package=frozen" > "$etcpath"/"$filename".sh
    else 
            echo "kernel_package=unfrozen" > "$etcpath"/"$filename".sh
    fi

    return 0 ;
}

freeze::uboot() {
# Bash

# Get the current kernel package
kernel_package=$(dpkg --list | grep linux-image | awk '{print $2}')

# Get the U-Boot package
uboot_package=$(dpkg --list | grep u-boot | awk '{print $2}')

# Check if the packages are installed
if [ -z "$kernel_package" ]; then
    echo "Kernel package not found."
else
    echo "Kernel package: $kernel_package"
   
fi

if [ -z "$uboot_package" ]; then
    echo "U-Boot package not found."
   
else
    echo "U-Boot package: $uboot_package"
  
fi

# Freeze the packages
if [ -n "$kernel_package" ]; then
    sudo apt-mark hold $kernel_package
    echo "kernel_package=frozen" 
fi

if [ -n "$uboot_package" ]; then
    sudo apt-mark hold $uboot_package
    echo "uboot_package=frozen" 
fi
}

unfreeze::uboot() {
    echo "Unfreezing U-Boot and Kernel..."

    # Get the current kernel package
    kernel_package=$(dpkg --list | grep linux-image | awk '{print $2}')

    # Get the U-Boot package
    uboot_package=$(dpkg --list | grep u-boot | awk '{print $2}')

    # Unfreeze the packages
    if [ -n "$kernel_package" ]; then
        sudo apt-mark unhold $kernel_package
        echo "kernel_package=unfrozen" 
    fi

    if [ -n "$uboot_package" ]; then
        sudo apt-mark unhold $uboot_package
        echo "uboot_package=unfrozen" 
    fi
}


handeling::Kernal-freeze() {
    local command=$1
    case $command in
        freeze)
            freeze::uboot
            ;;
        unfreeze)
            unfreeze::uboot
            ;;
        *)
            echo "Invalid command. Please use 'freeze' or 'unfreeze'."
            ;;
    esac
}