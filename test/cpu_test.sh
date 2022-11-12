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
source "$cur_dir/../functions/cpu.sh"

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

# Get policy
declare -i  policy=$(cpu::get_policy)
printf 'Policy = %d\n' "$policy"
declare -i  min_freq=$(cpu::get_min_freq $policy)
check_return
printf 'Minimum frequency = %d\n' "$min_freq"
declare -i  max_freq=$(cpu::get_max_freq $policy)
check_return
printf 'Maximum frequency = %d\n' "$max_freq"
governor=$(cpu::get_governor $policy)
check_return
printf 'Governor = %s\n' "$governor"
# Return frequencies as array
declare -a freqs=( $(string::split "$(cpu::get_freqs $policy)" " ") )
check_return
printf "\nAll frequencies\n"
# Print all values in collection
printf "%s\n" "${freqs[@]}" | collection::each "print_func"
declare -a governors=( $(string::split "$(cpu::get_governors $policy)" " ") )
check_return
printf "\nAll governors\n"
# Print all values in collection
printf "%s\n" "${governors[@]}" | collection::each "print_func"
# Are we running as sudo?
[[ "$EUID" != 0 ]] && printf "Must call cpu::set_freq as sudo\n" && exit 1
# Before
printf "\nBefore\n"
cat /etc/default/cpufrequtils
cpu::set_freq $policy "$min_freq" "$max_freq" performance
# After
printf "\nAfter\n"
cat /etc/default/cpufrequtils

