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

#cur_dir=$(pwd)
cur_dir="modules"
# Source bash-utility and cpu functions (this will word under sudo)
source "$cur_dir/../functions/bash-utility-master/src/string.sh"
source "$cur_dir/../functions/bash-utility-master/src/collection.sh"
source "$cur_dir/../functions/bash-utility-master/src/array.sh"
source "$cur_dir/../functions/bash-utility-master/src/check.sh"
source "$cur_dir/../functions/cpu.sh"
source "$cur_dir/../functions/general.sh"

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

freq(){
  policy=$(cpu::get_policy)

if [ "$1" == "list" ]; then
  freqs_list=( $(string::split "$(cpu::get_freqs $policy)" " ") )
  check_return
  printf "\nAll frequencies\n"
  # Print all values in collection
  printf "%s\n" "${freqs_list[@]}" | collection::each "print_func"

  governors_list=( $(string::split "$(cpu::get_governors $policy)" " ") )
  check_return
  printf "\nAll governors\n"
  # Print all values in collection
  printf "%s\n" "${governors_list[@]}" | collection::each "print_func"
  exit 0;
fi

if [ "$1" == "set" ] || [ "$1" == "--help" ]; then
  if [ -z $2 ]; then
    echo "'armbian-config cli cpufreq set' or 'armbian-config cli cpufreq --help' for this help."
    echo "You must provide settings 'armbian-config cli cpufreq set <min> <max> <governor>'"
    echo "Use 'armbian-config cli cpufreq list' to list frequencies and governors"
    echo "Use 'armbian-config cli cpufreq show' to show current settings"
    exit 0
  else
    cpu::set_freq "$policy" "$2" "$3" "$4" "$cli"
    cat /etc/default/cpufrequtils
    read -p "Press any key to continue"
    exit 0
  fi
fi

if [ "$1" == "show" ]; then
    cat /etc/default/cpufrequtils
    read -p "Press any key to continue"
    exit 0
fi

governors1=( $(string::split "$(cpu::get_governors $policy)" " ") )
freqs1=( $(string::split "$(cpu::get_freqs $policy)" " ") )
generic_select "$(printf '%s\n' "${freqs1[@]}" | paste -sd ' ')" "Select minimum CPU speed"
MIN_SPEED=$PARAMETER
generic_select "$(printf '%s\n' "${freqs1[@]}" | paste -sd ' ')" "Select maximum CPU speed" "$PARAMETER"
MAX_SPEED=$PARAMETER
generic_select "$(printf '%s\n' "${governors1[@]}" | paste -sd ' ')" "Select CPU governor"
GOVERNOR=$PARAMETER

dialog --colors --title " Apply and save changes " --backtitle "$BACKTITLE" --yes-label "OK" --no-label "Cancel" --yesno \
                        "\nCPU frequency will be within \Z1$(($MIN_SPEED / 1000 ))\Z0 and \Z1$(($MAX_SPEED / 1000 )) MHz\Z0. The governor \Z1$GOVERNOR\Z0 will decide which speed to use within this range." 9 58

cpu::set_freq "$policy" "$MIN_SPEED" "$MAX_SPEED" "$GOVERNOR"
unset main
}
