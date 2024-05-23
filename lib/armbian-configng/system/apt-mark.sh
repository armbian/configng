#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


# @description Freeze system packages
#
# @exitcode 0  If successful.
#
# @options none.
#


function system::Aptmark(){


		  if ! is_package_manager_running; then
                if [[ -z $scripted ]]; then dialog --title " Updating " --backtitle "$BACKTITLE" --yes-label "$1" --no-label "Cancel" --yesno \
                "\nDo you want to ${1,,} Armbian firmware updates?" 7 54
                fi
                if [[ $? -eq 0 ]]; then

                        unset PACKAGE_LIST

                        # basic packages

                        check_if_installed linux-u-boot-${BOARD}-${BRANCH} && PACKAGE_LIST+=" linux-u-boot-${BOARD}-${BRANCH}"
                        check_if_installed linux-image-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-image-${BRANCH}-${LINUXFAMILY}"
                        check_if_installed linux-dtb-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-dtb-${BRANCH}-${LINUXFAMILY}"
                        check_if_installed linux-headers-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-headers-${BRANCH}-${LINUXFAMILY}"

                        # new BSP
                        check_if_installed armbian-${LINUXFAMILY} && PACKAGE_LIST+=" armbian-${LINUXFAMILY}"
                        check_if_installed armbian-${BOARD} && PACKAGE_LIST+=" armbian-${BOARD}"
                        check_if_installed armbian-${DISTROID} && PACKAGE_LIST+=" armbian-${DISTROID}"
                        check_if_installed armbian-bsp-cli-${BOARD} && PACKAGE_LIST+=" armbian-bsp-cli-${BOARD}"
                        check_if_installed armbian-${DISTROID}-desktop-xfce && PACKAGE_LIST+=" armbian-${DISTROID}-desktop-xfce"
                        check_if_installed armbian-firmware && PACKAGE_LIST+=" armbian-firmware"
                        check_if_installed armbian-firmware-full && PACKAGE_LIST+=" armbian-firmware-full"

                        local words=( $PACKAGE_LIST )
                        local command="unhold"
                        IFS=" "
                        [[ $1 == "Freeze" ]] && local command="hold"
                        for word in $PACKAGE_LIST; do apt-mark $command $word; done | dialog --backtitle "$BACKTITLE" --title "Packages ${1,,}" --progressbox $((${#words[@]}+2)) 64
                        fi
                fi





    return 0
}

