#!/bin/bash


module_options+=(
["install_de,author"]="Igor Pecovnik"
["install_de,ref_link"]=""
["install_de,feature"]="install_de"
["install_de,desc"]="Install DE"
["install_de,example"]="install_de"
["install_de,status"]="Active"
)
#
# Install desktop
#
function install_de (){

	# get user who executed this script
	if [ $SUDO_USER ]; then local user=$SUDO_USER; else local user=`whoami`; fi

	#debconf-apt-progress -- 
	apt-get update
	#debconf-apt-progress -- 
	apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends install armbian-${DISTROID}-desktop-$1 # armbian-bsp-desktop-${BOARD}-${BRANCH}

	# clean apt cache
	apt-get -y clean

	# add user to groups
	for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
			usermod -aG ${additionalgroup} ${user} 2>/dev/null
	done

	# set up profile sync daemon on desktop systems
	which psd >/dev/null 2>&1
	if [[ $? -eq 0 && -z $(grep overlay-helper /etc/sudoers) ]]; then
		echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
		touch /home/${user}/.activate_psd
	fi

	# update skel
	update_skel

	# desktops has different default login managers
    case "$1" in
        gnome)
		# gdm3
		;;
    *)
		# lightdm
		mkdir -p /etc/lightdm/lightdm.conf.d
		echo "[Seat:*]" > /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		echo "autologin-user=${username}" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		echo "autologin-user-timeout=0" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		echo "user-session=xfce" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service >/dev/null 2>&1
		service lightdm start >/dev/null 2>&1
	;;
    esac
exit
}


module_options+=(
["update_skel,author"]="Igor Pecovnik"
["update_skel,ref_link"]=""
["update_skel,feature"]="update_skel"
["update_skel,desc"]="Update the /etc/skel files in users directories"
["update_skel,example"]="update_skel"
["update_skel,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function update_skel (){

	getent passwd |
	while IFS=: read -r username x uid gid gecos home shell
	do
	if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ]
	then
		continue
	fi
        tar -C /etc/skel/ -cf - . | su - "$username" -c "tar --skip-old-files -xf -"
	done

}


module_options+=(
["qr_code,author"]="Igor Pecovnik"
["qr_code,ref_link"]=""
["qr_code,feature"]="qr_code"
["qr_code,desc"]="Show or generate QR code for Google OTP"
["qr_code,example"]="qr_code generate"
["qr_code,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function qr_code (){

	clear
	if [[ "$1" == "generate" ]]; then
		google-authenticator -t -d -f -r 3 -R 30 -W -q
		cp /root/.google_authenticator /etc/skel
		update_skel
	fi
	export TOP_SECRET=$(head -1 /root/.google_authenticator)
	qrencode -m 2 -d 9 -8 -t ANSI256 "otpauth://totp/test?secret=$TOP_SECRET"
	echo -e '\nScan QR code with your OTP application on mobile phone\n'
	read -n 1 -s -r -p "Press any key to continue"

}


module_options+=(
["set_stable,author"]="Tearran"
["set_stable,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
["set_stable,feature"]="set_stable"
["set_stable,desc"]="Set Armbian to stable release"
["set_stable,example"]="set_stable"
["set_stable,status"]="Active"
)
#
# @description Set Armbian to stable release
#
function set_stable () {

if ! grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
    sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
	armbian_fw_manipulate "reinstall"
fi
}

module_options+=(
["set_rolling,author"]="Tearran"
["set_rolling,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
["set_rolling,feature"]="set_rolling"
["set_rolling,desc"]="Set Armbian to rolling release"
["set_rolling,example"]="set_rolling"
["set_rolling,status"]="Active"
)
#
# @description Set Armbian to rolling release
#
function set_rolling () {

if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
	sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
	armbian_fw_manipulate "reinstall"
fi
}