#!/bin/bash


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
["set_safe_boot,author"]="Igor Pecovnik"
["set_safe_boot,ref_link"]=""
["set_safe_boot,feature"]="set_safe_boot"
["set_safe_boot,desc"]="Freeze/unhold Migrated procedures from Armbian config."
["set_safe_boot,example"]="set_safe_boot unhold or set_safe_boot freeze"
["set_safe_boot,status"]="Active"
)
#
# freeze/unhold packages
#
set_safe_boot() {

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
	IFS=" "
	[[ "$1" == "unhold" ]] && local command="apt-mark unhold" && for word in $PACKAGE_LIST; do $command $word; done | show_infobox

	[[ "$1" == "freeze" ]] && local command="apt-mark hold" && for word in $PACKAGE_LIST; do $command $word; done | show_infobox

}


module_options+=(
["are_headers_installed,author"]="Gunjan Gupta"
["are_headers_installed,ref_link"]=""
["are_headers_installed,feature"]="are_headers_installed"
["are_headers_installed,desc"]="Check if kernel headers are installed"
["are_headers_installed,example"]="are_headers_installed"
["are_headers_installed,status"]="Pending Review"
["are_headers_installed,doc_link"]=""
)
#
# @description Install kernel headers
#
function are_headers_installed () {
    if [[ -f /etc/armbian-release ]]; then
        PKG_NAME="linux-headers-${BRANCH}-${LINUXFAMILY}";
    else
        PKG_NAME="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
    fi

    check_if_installed ${PKG_NAME}
    return $?
}


module_options+=(
["Headers_install,author"]="Joey Turner"
["Headers_install,ref_link"]=""
["Headers_install,feature"]="Headers_install"
["Headers_install,desc"]="Install kernel headers"
["Headers_install,example"]="is_package_manager_running"
["Headers_install,status"]="Pending Review"
["Headers_install,doc_link"]=""
)
#
# @description Install kernel headers
#
function Headers_install () {
	if ! is_package_manager_running; then
	  if [[ -f /etc/armbian-release ]]; then
	    INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}";
	    else
	    INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
	  fi
	  debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
}


module_options+=(
["Headers_remove,author"]="Joey Turner"
["Headers_remove,ref_link"]=""
["Headers_remove,feature"]="Headers_remove"
["Headers_remove,desc"]="Remove Linux headers"
["Headers_remove,example"]="Headers_remove"
["Headers_remove,status"]="Pending Review"
["Headers_remove,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Linux headers
#
function Headers_remove () {
	if ! is_package_manager_running; then
		REMOVE_PKG="linux-headers-*"
		if [[ -n $(dpkg -l | grep linux-headers) ]]; then
			debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
			rm -rf /usr/src/linux-headers*
		else
			debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
		fi
		# cleanup
		apt clean
		debconf-apt-progress -- apt -y autoremove
	fi
}


module_options+=(
	["setup_google_authenticator,author"]="Igor"
	["setup_google_authenticator,ref_link"]=""
	["setup_google_authenticator,feature"]="setup_google_authenticator"
	["setup_google_authenticator,desc"]="Setup Google Authenticator and configure SSH"
	["setup_google_authenticator,example"]="setup_google_authenticator"
	["setup_google_authenticator,status"]="Pending Review"
	["setup_google_authenticator,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Setup Google Authenticator and configure SSH
#
setup_google_authenticator() {
	clear
    # Check and install libpam-google-authenticator if not installed
    check_if_installed libpam-google-authenticator || debconf-apt-progress -- apt-get -y install libpam-google-authenticator

    # Check and install qrencode if not installed
    check_if_installed qrencode || debconf-apt-progress -- apt-get -y install qrencode

    # Enable ChallengeResponseAuthentication in sshd_config
    sed -i "s/^#\\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config

    # Update sshd_config and pam.d/sshd for Google Authenticator
    sed -i $'/KbdInteractiveAuthentication/{iChallengeResponseAuthentication yes\\n:a;n;ba}' /etc/ssh/sshd_config || \
    sed -n -i '/password updating/{p;:a;N;/@include common-password/!ba;s/.*\\n/auth required pam_google_authenticator.so nullok\\nauth required pam_permit.so\\n/};p' /etc/pam.d/sshd

    # Generate QR code if .google_authenticator file does not exist
    [ ! -f /root/.google_authenticator ] && qr_code generate

    # Restart sshd service
    systemctl restart sshd.service
}

module_options+=(
    ["clear_google_authenticator,author"]="Igor"
    ["clear_google_authenticator,ref_link"]=""
    ["clear_google_authenticator,feature"]="clear_google_authenticator"
    ["clear_google_authenticator,desc"]="Remove Google Authenticator and revert SSH configuration"
    ["clear_google_authenticator,example"]="clear_google_authenticator"
    ["clear_google_authenticator,status"]="Pending Review"
    ["clear_google_authenticator,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Google Authenticator and revert SSH configuration
#
clear_google_authenticator() {
	clear
    # Purge libpam-google-authenticator and qrencode if installed
    ! check_if_installed libpam-google-authenticator && ! check_if_installed qrencode || debconf-apt-progress -- apt-get -y purge libpam-google-authenticator qrencode

    # Disable ChallengeResponseAuthentication in sshd_config
    sed -i "s/^#\\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config || \
    sed -i "0,/KbdInteractiveAuthentication/s//ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config

    # Remove Google Authenticator configuration from pam.d/sshd
    sed -i '/^auth required pam_google_authenticator.so nullok/ d' /etc/pam.d/sshd

    # Restart sshd service
    systemctl restart sshd.service
}