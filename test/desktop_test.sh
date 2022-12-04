#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  CPU related tests.
#

cur_dir=$(pwd)
# Source bash-utility and cpu functions (this will word under sudo)
source "$cur_dir/../functions/bash-utility-master/src/string.sh"
source "$cur_dir/../functions/bash-utility-master/src/collection.sh"
source "$cur_dir/../functions/bash-utility-master/src/array.sh"
source "$cur_dir/../functions/bash-utility-master/src/check.sh"
source "$cur_dir/../functions/bash-utility-master/src/os.sh"
source "$cur_dir/../functions/desktop.sh"

# @description Print value from collection.
#
# @example
#   collection::each "print_func"
#   #Output
#   Value in collection
print_func(){
   printf "%s\n" "$1"
   return 0
 }

# @description Check function exit code and exit script if != 0.
#
# @example
#   check_return
#   #Output
#  Nothing
check_return(){
	if [ "$?" -ne 0 ]; then
		exit 1
	fi
 }

# Get desktops
#declare -i  variants=$(desktop::get_variants)
#check_return
#printf 'Desktop variants = %d\n' "$variants"
#os::detect_linux_version
declare -a desktops=( $(string::split "$(desktop::get_variants)" " ") )
check_return
printf "\nAll desktops\n"
# Print all values in collection
printf "%s\n" "${desktops[@]}" | collection::each "print_func"

# Are we running as sudo?
[[ "$EUID" != 0 ]] && printf "Must call desktop::set_de as sudo\n" && exit 1
# Before
printf "\nBefore\n"
#cat /etc/default/cpufrequtils
desktop::set_de "xfce"
# After
printf "\nAfter\n"
#cat /etc/default/cpufrequtils
