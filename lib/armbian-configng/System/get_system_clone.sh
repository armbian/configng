#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


# @description Armbian installer
# @requirments armbian-install
# @exitcode 0  If successful
# @default sdcard
# @options [sdcard] [emmc] [usb]
function placeholder::Install(){
    see_get_dependencies armbian-install
    [[ -f "/usr/sbin/armbian-install" ]] && armbian-install
    return 0
}

