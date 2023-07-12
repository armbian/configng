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


directory="$(dirname "$(readlink -f "$0")")"
filename=$(basename "${BASH_SOURCE[0]}")

#libpath="$directory/../lib"
#selfpath="$libpath/configng/cpu.sh"

if [[ -d "$directory/../lib" ]]; then
    libpath="$directory"/../lib
elif [[ -d "/usr/lib/bash-utility" && -d "/usr/lib/configng" ]]; then
    libpath="/usr/lib"
elif [[ -d "/../functions/bash-utility-master/src" ]] ; then
    libpath="$directory"/../functions/bash-utility-master/src
else
    echo "Libraries not found"
    exit 0
fi

# Source the files relative to the script location
source "$libpath/bash-utility/string.sh"
source "$libpath/bash-utility/collection.sh"
source "$libpath/bash-utility/array.sh"
source "$libpath/bash-utility/check.sh"
source "$libpath/configng/cpu.sh"

# Rest of the script...
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

see_cpu(){
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

}

readarray -t functionarray < <(grep -oP '^\w+::\w+' "$libpath/configng/cpu.sh")
readarray -t funnamearray < <(grep -oP '^\w+::\w+' "$libpath/configng/cpu.sh" | sed 's/.*:://')
readarray -t catagoryarray < <(grep -oP '^\w+::\w+' "$libpat/configng/cpu.sh" | sed 's/::.*//')
readarray -t descriptionarray < <(grep -oP '^# @description.*' "$libpath/configng/cpu.sh" | sed 's/^# @description //')

#printf '%s\n' "${functionarray[@]}"
#exit 0
see_help(){

	echo ""
	echo "Usage: ${filename%.*} [ -h | -dev | ]"
	echo -e "Options:"
	echo -e "	-h  Print this help."
	echo -e "	-dev Options:"
    for i in "${!functionarray[@]}"; do
		printf '\t\t%s\t%s\n' "${functionarray[i]}" "${descriptionarray[i]}"
	done
	echo -e "	-cpu Options:"
    for i in "${!functionarray[@]}"; do
		printf '\t\t%s\t%s\n' "${funnamearray[i]}" "${descriptionarray[i]}"
	done

	}
# check for -dev -h options 
check_opts_test1()
{
    if [[ "$1" == -dev ]] ; then
        default="bash"
        local found=false
        for i in "${!functionarray[@]}"; do
            if [ "$2" == "${functionarray[i]}" ]; then
                "${functionarray[i]}"
                found=true
                break
            fi
        done
        if ! $found; then
            see_help
            exit 0
        fi
	elif [[ "$1" == "-cpu" ]] ; then
        echo -e "   "
		echo -e " TODO:"
        for i in "${!functionarray[@]}"; do
			
			printf '\t\t%s\t%s \n' "${functionarray[i]}" "${descriptions[i]}"
		done

    elif [[ "$1" == -h ]] ; then
        see_help
    else
        see_cpu
    fi
}

# check for -h -dev 
# if -dev check for number
check_opts_test2(){

if [ "$1" == "-dev" ]; then
  shift  # Shifts the arguments to the left, excluding the first argument ("-dev")
  function_name="$1"  # Assigns the next argument as the function name
  shift  # Shifts the arguments again to exclude the function name

  case "$function_name" in
    0) echo "Calling function 0 with arguments: $@" ;;
    1) echo "Calling function 1 with arguments: $@" ;;
    2) echo "Calling function 2 with arguments: $@" ;;
    3) echo "Calling function 3 with arguments: $@" ;;
    4) echo "Calling function 4 with arguments: $@" ;;
    *) echo "Invalid function name" ;;
  esac
else
  echo "No -dev flag found"
fi

}
# check for -h -dev @ $1
# if -dev check @ $1 remove and shift $1 to check for x
check_opts() {
  if [ "$1" == "-dev" ]; then
    shift  # Shifts the arguments to the left, excluding the first argument ("-dev")
    function_name="$1"  # Assigns the next argument as the function name
    shift  # Shifts the arguments again to exclude the function name

    found=false

    for ((i=0; i<${#functionarray[@]}; i++)); do
      if [ "$function_name" == "${functionarray[i]}" ]; then
        found=true
        ${functionarray[i]} "$@"
        break
      fi
    done

    if [ "$found" == false ]; then
      echo "Invalid function name"
    fi

  elif [ "$1" == "-h" ]; then
    see_help
  else
    see_cpu
  fi
}

#check_opts_test1 "$@"
check_opts "$@"

#cpu::set_freq $policy "$min_freq" "$max_freq" performance
