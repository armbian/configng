#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  utility_install_desktops related functions. See *(todo)* for more info.

# @description Display a list of avalible desktops to install.
#
# @example
#   see_desktops
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout list of avalible desktops.
utility_install_desktops::see_desktops(){

	apt-cache search desktop | grep -i -e "\-desktop-full " -e "\-desktop-environment " | awk -F "- " '{print $1, $2}'

	}