#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


# @description Banding With Softlinks .
#
# @exitcode 0  If successful.
#
# @options none.
#
function setup::Branding(){

    # Get the directory of the script
    script_dir=$(dirname "$(readlink -f "$0")")
    config_legacy="/usr/sbin/armbian-config"

    [[ -f "$config_legacy" && ! -f "$script_dir/armbian-configlg" ]] && ln - "$config_legacy" "$script_dir/armbian-configlg"
    [[ ! -f "$script_dir/branded-config" ]] && ln -s "$script_dir/armbian-configng" "$script_dir/branded-config" 
    [[ ! -f "$script_dir/armbian-configng" ]] && ln -s "$script_dir/armbian-config-dev" "$script_dir/armbian-configng"
    
    return 0
}

