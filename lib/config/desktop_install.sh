#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  CPU related functions. See https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt for more info.

# @description Return policy as int based on original armbian-config logic.
#
# @example
#   cpu::get_policy
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout Policy as integer.
desk_setup::see_desktops(){

	apt-cache search armbian-$(grep VERSION_CODENAME /etc/os-release | cut -d"=" -f2)-desktop- | cut -d" " -f1

	}