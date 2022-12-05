#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  CPU related functions. See https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt for more info.
#

# @description Return list of available desktops
#
# @example
#   desktop::get_variants
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout Space delimited string of virtual desktop packages.
desktop::get_variants(){
	printf '%s\n' "$(apt list 2>/dev/null | grep armbian | grep desktop | grep -v bsp | cut -d" " -f1 | cut -d"/" -f1)"
}

# @description Install desktop environment 
#
# @arg $1 string desktop [xfce,cinnamon,budgie,...]
# @arg $2 string username

desktop::set_de(){

	# Check number of arguments
	[[ $# -lt 1 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2

	# Read arguments and get os codename
	local de="armbian-$(os::detect_linux_codename)-desktop-$1"
        local username=$2

	# Return desktops as array
	declare -a desktops=( $(string::split "$(desktop::get_variants)" " ") )

	# Validate parameter
	array::contains "$de" ${desktops[@]}
	[[ $? != 0 ]] && printf "%s: Invalid desktop\n" "${FUNCNAME[0]}" && return 3

	# Install desktop
	apt-get install -y --reinstall -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends $de lightdm lightdm-gtk-greeter

	# in case previous install was interrupted
	[[ $? -eq 130 ]] && dpkg --configure -a

	# clean apt cache
	apt-get -y clean

	# add user to groups
	for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
			usermod -aG ${additionalgroup} ${username} 2>/dev/null
	done

	# set up profile sync daemon on desktop systems
	which psd >/dev/null 2>&1
	if [[ $? -eq 0 && -z $(grep overlay-helper /etc/sudoers) ]]; then
		echo "${username} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
		touch /home/${username}/.activate_psd
	fi

	# configure login manager
	mkdir -p /etc/lightdm/lightdm.conf.d
	echo "[Seat:*]" > /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
	echo "autologin-user=${username}" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
	echo "autologin-user-timeout=0" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
	echo "user-session=xfce" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
	ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service >/dev/null 2>&1
	service lightdm start >/dev/null 2>&1

}
