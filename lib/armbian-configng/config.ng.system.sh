#!/bin/bash

module_options+=(
	["apt_install_wrapper,author"]="igorpecovnik"
	["apt_install_wrapper,ref_link"]=""
	["apt_install_wrapper,feature"]="Install wrapper"
	["apt_install_wrapper,desc"]="Install wrapper"
	["apt_install_wrapper,example"]="apt_install_wrapper apt-get -y purge armbian-zsh"
	["apt_install_wrapper,status"]="Active"
)
#
# @description Use TUI / GUI for apt install if exists
#
function apt_install_wrapper() {

	if [ -t 0 ]; then
		debconf-apt-progress -- "$@"
	else
		# Terminal not defined - proceed without TUI
		"$@"
	fi
}

module_options+=(
	["release_upgrade,author"]="Igor Pecovnik"
	["release_upgrade,ref_link"]=""
	["release_upgrade,feature"]="Upgrade upstream distribution release"
	["release_upgrade,desc"]="Upgrade to next stable or rolling release"
	["release_upgrade,example"]="release_upgrade stable verify"
	["release_upgrade,status"]="Active"
)
#
# Upgrade distribution
#
release_upgrade(){

	local upgrade_type=$1
	local verify=$2

	local distroid=${DISTROID}

	if [[ "${upgrade_type}" == stable ]]; then
		local filter=$(grep "supported" /etc/armbian-distribution-status | cut -d"=" -f1)
	elif [[ "${upgrade_type}" == rolling ]]; then
		local filter=$(grep "eos\|csc" /etc/armbian-distribution-status | cut -d"=" -f1 | sed "s/sid/testing/g")
	else
		local filter=$(cat /etc/armbian-distribution-status | cut -d"=" -f1)
	fi

	local upgrade=$(for j in $filter; do
		for i in $(grep "^${distroid}" /etc/armbian-distribution-status | cut -d";" -f2 | cut -d"=" -f2 | sed "s/,/ /g"); do
			if [[ $i == $j ]]; then
				echo $i
			fi
		done
	done | tail -1)

	if [[ -z "${upgrade}" ]]; then
		return 1;
	elif [[ -z "${verify}" ]]; then
		[[ -f /etc/apt/sources.list.d/ubuntu.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/ubuntu.sources
		[[ -f /etc/apt/sources.list.d/debian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/debian.sources
		[[ -f /etc/apt/sources.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list
		[[ "${upgrade}" == "testing" ]] && upgrade="sid" # our repo and everything is tied to sid
		[[ -f /etc/apt/sources.list.d/armbian.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get -y update
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" upgrade --without-new-pkgs
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade
		apt_install_wrapper apt-get -y --purge autoremove
	fi
}

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
function install_de() {

	# get user who executed this script
	if [ $SUDO_USER ]; then local user=$SUDO_USER; else local user=$(whoami); fi

	#debconf-apt-progress --
	apt-get update
	#debconf-apt-progress --
	apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends install armbian-${DISTROID}-desktop-$1 # armbian-bsp-desktop-${BOARD}-${BRANCH}

	# clean apt cache
	apt-get -y clean

	# add user to groups
	for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
		usermod -aG ${additionalgroup} ${user} 2> /dev/null
	done

	# Recreating Synaptic search index
	update-apt-xapian-index -u

	# set up profile sync daemon on desktop systems
	which psd > /dev/null 2>&1
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
			ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service > /dev/null 2>&1
			service lightdm start > /dev/null 2>&1
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
function update_skel() {

	getent passwd |
		while IFS=: read -r username x uid gid gecos home shell; do
			if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ]; then
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
function qr_code() {

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
function set_stable() {

	if ! grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
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
function set_rolling() {

	if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}

module_options+=(
	["manage_overlayfs,author"]="igorpecovnik"
	["manage_overlayfs,ref_link"]=""
	["manage_overlayfs,feature"]="overlayfs"
	["manage_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["manage_overlayfs,example"]="manage_overlayfs enable|disable"
	["manage_overlayfs,status"]="Active"
)
#
# @description set/unset Armbian root filesystem to read only
#
function manage_overlayfs() {

	if [[ "$1" == "enable" ]]; then
		debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confold" -y install overlayroot cryptsetup cryptsetup-bin
		[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
		sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
		sed -i "s/^overlayroot_cfgdisk=.*/overlayroot_cfgdisk=\"enabled\"/" /etc/overlayroot.conf
	else
		overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
		debconf-apt-progress -- apt-get -y purge overlayroot cryptsetup cryptsetup-bin
	fi
	# reboot is mandatory
	reboot
}

module_options+=(
	["toggle_ssh_lastlog,author"]="tearran"
	["toggle_ssh_lastlog,ref_link"]=""
	["toggle_ssh_lastlog,feature"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,desc"]="Toggle SSH lastlog"
	["toggle_ssh_lastlog,example"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,status"]="Active"
)
#
# @description Toggle SSH lastlog
#
function toggle_ssh_lastlog() {

	if ! grep -q '^#\?PrintLastLog ' "${SDCARD}/etc/ssh/sshd_config"; then
		# If PrintLastLog is not found, append it with the value 'yes'
		echo 'PrintLastLog no' >> "${SDCARD}/etc/ssh/sshd_config"
		sudo service ssh restart
	else
		# If PrintLastLog is found, toggle between 'yes' and 'no'
		sed -i '/^#\?PrintLastLog /
{
	s/PrintLastLog yes/PrintLastLog no/;
	t;
	s/PrintLastLog no/PrintLastLog yes/
}' "${SDCARD}/etc/ssh/sshd_config"
		sudo service ssh restart
	fi

}

module_options+=(
	["adjust_motd,author"]="igorpecovnik"
	["adjust_motd,ref_link"]=""
	["adjust_motd,feature"]="Adjust motd"
	["adjust_motd,desc"]="Adjust welcome screen (motd)"
	["adjust_motd,example"]=""
	["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear)
				echo "Clear screen on login"
				;;
			header)
				echo "Show header with logo"
				;;
			sysinfo)
				echo "Display system information"
				;;
			tips)
				echo "Show Armbian team tips"
				;;
			commands)
				echo "Show recommended commands"
				;;
			*)
				echo "No description"
				;;
		esac
	}

	# read status
	function motd_status() {
		source /etc/default/armbian-motd
		if [[ $MOTD_DISABLE == *$1* ]]; then
			echo "OFF"
		else
			echo "ON"
		fi
	}

	LIST=()
	for v in $(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"); do
		LIST+=("$v" "$(motd_desc $v)" "$(motd_status $v)")
	done

	INLIST=($(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"))
	CHOICES=$(whiptail --separate-output --nocancel --title "Adjust welcome screen" --checklist "" 11 50 5 "${LIST[@]}" 3>&1 1>&2 2>&3)
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
}

module_options+=(
["manage_dtoverlays,author"]="Gunjan Gupta"
["manage_dtoverlays,ref_link"]=""
["manage_dtoverlays,feature"]="dtoverlays"
["manage_dtoverlays,desc"]="Enable/disable device tree overlays"
["manage_dtoverlays,example"]="manage_dtoverlays"
["manage_dtoverlays,status"]="Active"
)
#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	while true; do
		local options=()
		j=0
		available_overlays=$(ls -1 ${OVERLAYDIR}/*.dtbo | sed "s#^${OVERLAYDIR}/##" | sed 's/.dtbo//g' | grep $BOOT_SOC | tr '\n' ' ')
		for overlay in ${available_overlays}; do
			local status="OFF"
			grep '^fdt_overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$(whiptail --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "\nUse <space> to toggle functions and save them.\nExit when you are done.\n " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				sed -i "s/^fdt_overlays=.*/fdt_overlays=$newoverlays/" ${overlayconf}
				if ! grep -q "^fdt_overlays" ${overlayconf}; then echo "fdt_overlays=$newoverlays" >> ${overlayconf}; fi
				sync
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					whiptail --title " Reboot required " --yes-button "Reboot" \
						--no-button "Cancel" --yesno "A reboot is required to apply the changes. Shall we reboot now?" 7 34
					if [[ $? = 0 ]]; then
						reboot
					fi
				fi
				break
				;;
			255)
				;;
		esac
	done
}
