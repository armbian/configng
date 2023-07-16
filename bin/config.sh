#!/bin/bash

#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#

directory="$(dirname "$(readlink -f "$0")")"
filename=$(basename "${BASH_SOURCE[0]}")

libpath="$directory/../lib"

if [[ -d "$directory/../lib" ]]; then
    libpath="$directory"/../lib
# installed option todo change when lib location determined
#elif [[ ! -d "$directory/../lib" && -d "/usr/lib/bash-utility/" && -d "/usr/lib/config/" ]]; then
#    libpath="/usr/lib"
else
    echo "Libraries not found"
    exit 0
fi

# Source the files relative to the script location
for file in "$libpath"/bash-utility/*; do
    source "$file"
done
for file in "$libpath"/config/*; do
    source "$file"
done

functionarray=()
funnamearray=()
catagoryarray=()
descriptionarray=()

for file in "$libpath"/config/*.sh; do
    mapfile -t temp_functionarray < <(grep -oP '^\w+::\w+' "$file")
    functionarray+=("${temp_functionarray[@]}")

    mapfile -t temp_funnamearray < <(grep -oP '^\w+::\w+' "$file" | sed 's/.*:://')
    funnamearray+=("${temp_funnamearray[@]}")

    mapfile -t temp_catagoryarray < <(grep -oP '^\w+::\w+' "$file" | sed 's/::.*//')
    catagoryarray+=("${temp_catagoryarray[@]}")

    mapfile -t temp_descriptionarray < <(grep -oP '^# @description.*' "$file" | sed 's/^# @description //')
    descriptionarray+=("${temp_descriptionarray[@]}")
done

  see_help_dev(){
    # Extract unique prefixes
    declare -A prefixes
    for i in "${!functionarray[@]}"; do
        prefix="${functionarray[i]%%::*}"
        prefixes["$prefix"]=1
    done

    # Construct usage line
    usage=""
    for prefix in "${!prefixes[@]}"; do
        usage+="[ $prefix::options ]"
    done

  
#    echo "$usage"
    echo "Usage: ${filename%.*} [ -h | foo ]"
    echo ""
    echo -e "Options:"
    echo -e " -h)  Print this help."
    echo -e ""
    echo -e " foo)  Usage: ${filename%.*} foo $usage:: "
    echo ""

    # Group options by prefix
    declare -A groups
    for i in "${!functionarray[@]}"; do
        prefix="${functionarray[i]%%::*}"
        suffix="${functionarray[i]#*::}"
        groups["$prefix"]+=$'\t\t'"$suffix\t${descriptionarray[i]}"$'\n'
    done

    # Print grouped options
    for group in "${!groups[@]}"; do
        echo -e "	$group::options"
        echo -e "${groups[$group]}"
    done
}


# TEST 7
# check for -h -dev @ $1
# if -dev check @ $1 remove and shift $1 to check for x
check_opts() {
  if [ "$1" == "foo" ]; then
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
      see_help_dev
      exit 1

    fi

  elif [[ "$1" == "foo" && "$2" == "cpu::set_freq" ]]; then
    # Disabled till understood.
    echo "cpu::set_freq policy min_freq max_freq performance"
    echo "Disabled durring current testing"

  else
    see_help_dev
  fi
}

check_opts "$@"
