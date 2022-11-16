#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  CPU related functions. See https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt for more info.

function generic_select()
{
        IFS=$' '
        PARAMETER=($1)
        local LIST=()
        for i in "${PARAMETER[@]}"
        do
                if [[ -n $3 ]]; then
                        [[ ${i[0]} -ge $3 ]] && \
                        LIST+=( "${i[0]//[[:blank:]]/}" "" )
                else
                LIST+=( "${i[0]//[[:blank:]]/}" "" )
                fi
        done
        LIST_LENGTH=$((${#LIST[@]}/2));
        if [ "$LIST_LENGTH" -eq 1 ]; then
                PARAMETER=${LIST[0]}
        else
                exec 3>&1
                PARAMETER=$(dialog --nocancel --backtitle "$BACKTITLE" --no-collapse \
                --title "$2" --clear --menu "" $((6+${LIST_LENGTH})) 0 $((1+${LIST_LENGTH})) "${LIST[@]}" 2>&1 1>&3)
                exec 3>&-
        fi
}
