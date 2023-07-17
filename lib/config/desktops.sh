#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  Desktop setup related functions. See *(todo)* for more info.

# @description Display a list of avalible desktops to install.
#
# @example
#   desk_setup::see_desktops
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout list of avalible desktops.
desk_setup::see_desktops(){

	apt-cache search armbian-$(grep VERSION_CODENAME /etc/os-release | cut -d"=" -f2)-desktop- | cut -d" " -f1

	}