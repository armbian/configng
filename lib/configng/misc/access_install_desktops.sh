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
# @exitcode 0  If successful.
#
# @options none
function desktops::see_list(){

	echo "One moment please, searching for Desktops." ;
	apt-cache search armbian desktop ;

	return 0
	
	}
