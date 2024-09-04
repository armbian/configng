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

function set_rolling () {

        # Set rolling release if not already set
        if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
            sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
        fi
}

module_options+=(
["set_stable,author"]="Igor Pecovnik"
["set_stable,ref_link"]=""
["set_stable,feature"]="set_stable"
["set_stable,desc"]="Set Armbian to stable release"
["set_stable,example"]="set_stable"
["set_stable,status"]="Active"
)
#
# @description Set Armbian to stable release
#
function set_stable () {

if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
    sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
fi

}