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
function testing::Kernel_hold(){
# Read the /etc/armbian-release file

# Populate the packages array
packages=("linux-image-current-$LINUXFAMILY" "linux-u-boot-$BOARD-$BRANCH" "u-boot-tools")

for pkg in "${packages[@]}"; do
    # Check if the package is currently held
    if apt-mark showhold | grep -q "^$pkg$"; then
        # If the package is held, unhold it
        sudo apt-mark unhold "$pkg"
        echo "Unheld $pkg"
    else
        # If the package is not held, hold it
        sudo apt-mark hold "$pkg"
        echo "Held $pkg"
    fi
done

}
