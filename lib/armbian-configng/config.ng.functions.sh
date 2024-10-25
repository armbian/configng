#!/bin/bash



module_options+=(
	["check_if_installed,author"]="Igor Pecovnik"
	["check_if_installed,ref_link"]=""
	["check_if_installed,feature"]="check_if_installed"
	["check_if_installed,desc"]="Migrated procedures from Armbian config."
	["check_if_installed,example"]="check_if_installed nano"
	["check_if_installed,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function check_if_installed() {

	local DPKG_Status="$(dpkg -s "$1" 2> /dev/null | awk -F": " '/^Status/ {print $2}')"
	if [[ "X${DPKG_Status}" = "X" || "${DPKG_Status}" = *deinstall* || "${DPKG_Status}" = *not-installed* ]]; then
		return 1
	else
		return 0
	fi

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
	["is_package_manager_running,author"]="Igor Pecovnik"
	["is_package_manager_running,ref_link"]=""
	["is_package_manager_running,feature"]="is_package_manager_running"
	["is_package_manager_running,desc"]="Migrated procedures from Armbian config."
	["is_package_manager_running,example"]="is_package_manager_running"
	["is_package_manager_running,status"]="Active"
)
#
# check if package manager is doing something
#
function is_package_manager_running() {

	if ps -C apt-get,apt,dpkg > /dev/null; then
		[[ -z $scripted ]] && echo -e "\nPackage manager is running in the background. \n\nCan't install dependencies. Try again later." | show_infobox
		return 0
	else
		return 1
	fi

}

module_options+=(
	["set_runtime_variables,author"]="Igor Pecovnik"
	["set_runtime_variables,ref_link"]=""
	["set_runtime_variables,feature"]="set_runtime_variables"
	["set_runtime_variables,desc"]="Run time variables Migrated procedures from Armbian config."
	["set_runtime_variables,example"]="set_runtime_variables"
	["set_runtime_variables,status"]="Active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables() {

	missing_dependencies=()

	# Check if whiptail is available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		missing_dependencies+=("whiptail")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# If any dependencies are missing, print a combined message and exit
	if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
		if is_package_manager_running; then
			sudo apt install ${missing_dependencies[*]}
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if systemctl is-active NetworkManager 1> /dev/null; then
		NETWORK_RENDERER=NetworkManager
	else
		NETWORK_RENDERER=networkd
	fi

	DIALOG_CANCEL=1
	DIALOG_ESC=255

	# we have our own lsb_release which does not use Python. Others shell install it here
	if [[ ! -f /usr/bin/lsb_release ]]; then
		if is_package_manager_running; then
			sleep 3
		fi
		debconf-apt-progress -- apt-get update
		debconf-apt-progress -- apt -y -qq --allow-downgrades --no-install-recommends install lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc)
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	BACKTITLE="Contribute: https://github.com/armbian/configng"
	TITLE="Armbian configuration utility"
	[[ -z "${DEFAULT_ADAPTER// /}" ]] && DEFAULT_ADAPTER="lo"

	# detect desktop
	check_desktop

}

module_options+=(
	["armbian_fw_manipulate,author"]="Igor Pecovnik"
	["armbian_fw_manipulate,ref_link"]=""
	["armbian_fw_manipulate,feature"]="armbian_fw_manipulate"
	["armbian_fw_manipulate,desc"]="freeze/unhold/reinstall armbian related packages."
	["armbian_fw_manipulate,example"]="armbian_fw_manipulate unhold|freeze|reinstall"
	["armbian_fw_manipulate,status"]="Active"
)
#
# freeze/unhold/reinstall armbian firmware packages
#
armbian_fw_manipulate() {

	local function=$1
	local version=$2
	local branch=$3

	[[ -n $version ]] && local version="=${version}"

	# fallback to $BRANCH
	[[ -z "${branch}" ]] && branch="${BRANCH}"
	[[ -z "${branch}" ]] && branch="current" # fallback in case we switch to very old BSP that have no such info

	# packages to install
	local armbian_packages=(
		"linux-u-boot-${BOARD}-${branch}"
		"linux-image-${branch}-${LINUXFAMILY}"
		"linux-dtb-${branch}-${LINUXFAMILY}"
		"armbian-zsh"
		"armbian-bsp-cli-${BOARD}-${branch}"
	)

	# reinstall headers only if they were previously installed
	if are_headers_installed; then
		local armbian_packages+="linux-headers-${branch}-${LINUXFAMILY}"
	fi

	local packages=""
	for pkg in "${armbian_packages[@]}"; do
		if [[ "${function}" == reinstall ]]; then
			local pkg_search=$(apt search "$pkg" 2> /dev/null | grep "^$pkg")
			if [[ $? -eq 0 && -n "${pkg_search}" ]]; then
				if [[ "${pkg_search}" == *$version* ]] ; then
				packages+="$pkg${version} ";
				else
				packages+="$pkg ";
				fi
			fi
		else
			if check_if_installed $pkg; then
				packages+="$pkg${version} "
			fi
		fi
	done
	for pkg in "${packages[@]}"; do
		case $function in
			unhold) apt-mark unhold ${pkg} | show_infobox ;;
			hold) apt-mark hold ${pkg} | show_infobox ;;
			reinstall)
				apt_install_wrapper apt-get -y --simulate --download-only --allow-change-held-packages --allow-downgrades install ${pkg}
				if [[ $? == 0 ]]; then
					apt_install_wrapper apt-get -y purge "linux-u-boot-*" "linux-image-*" "linux-dtb-*" "linux-headers-*" "armbian-zsh-*" "armbian-bsp-cli-*" # remove all branches
					apt_install_wrapper apt-get -y --allow-change-held-packages install ${pkg}
					apt_install_wrapper apt-get -y autoremove
					apt_install_wrapper apt-get -y clean
				else
					exit 1
				fi


				;;
			*) return ;;
		esac
	done
}

module_options+=(
	["switch_kernels,author"]="Igor"
	["switch_kernels,ref_link"]=""
	["switch_kernels,feature"]=""
	["switch_kernels,desc"]="Switching to alternative kernels"
	["switch_kernels,example"]=""
	["switch_kernels,status"]="Active"
)
#
# @description Switch between alternative kernels
#
function switch_kernels() {

	# we only allow switching kerneles that are in the test pool
	[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,current,edge"
	local kernel_test_target=$(for x in ${KERNEL_TEST_TARGET//,/ }; do echo "linux-image-$x-${LINUXFAMILY}"; done;)
	local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}')
	# just in case current is not installed
	[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"
	local search_exec="apt-cache show ${kernel_test_target} | grep -E \"Package:|Version:|version:|family\" | grep -v \"Config-Version\" | sed -n -e 's/^.*: //p' | sed 's/\.$//g' | xargs -n3 -d'\n' | sed \"s/ /=/\" $grep_current_kernel"
	IFS=$'\n'
	local LIST=()
	for line in $(eval ${search_exec}); do
		LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
	done
	unset IFS
	local list_length=$((${#LIST[@]} / 2))
	if [ "$list_length" -eq 0 ]; then
		dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "\nNo other kernels available!" 7 32
	else
		local target_version=$(whiptail --separate-output --title "Select kernel" --menu "ed" $((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ -n "${target_version}" ]; then
			local branch=${target_version##*image-}
			armbian_fw_manipulate "reinstall" "${target_version/*=/}" "${branch%%-*}"
		fi
	fi
}

module_options+=(
	["connect_bt_interface,author"]="Igor Pecovnik"
	["connect_bt_interface,ref_link"]=""
	["connect_bt_interface,feature"]="connect_bt_interface"
	["connect_bt_interface,desc"]="Migrated procedures from Armbian config."
	["connect_bt_interface,example"]="connect_bt_interface"
	["connect_bt_interface,status"]="Active"
)
#
# connect to bluetooth device
#
function connect_bt_interface() {

	IFS=$'\r\n'
	GLOBIGNORE='*'
	show_infobox <<< "\nDiscovering Bluetooth devices ... "
	BT_INTERFACES=($(hcitool scan | sed '1d'))

	local LIST=()
	for i in "${BT_INTERFACES[@]}"; do
		local a=$(echo ${i[0]//[[:blank:]]/} | sed -e 's/^\(.\{17\}\).*/\1/')
		local b=${i[0]//$a/}
		local b=$(echo $b | sed -e 's/^[ \t]*//')
		LIST+=("$a" "$b")
	done

	LIST_LENGTH=$((${#LIST[@]} / 2))
	if [ "$LIST_LENGTH" -eq 0 ]; then
		BT_ADAPTER=${WLAN_INTERFACES[0]}
		show_message <<< "\nNo nearby Bluetooth devices were found!"
	else
		exec 3>&1
		BT_ADAPTER=$(whiptail --title "Select interface" \
			--clear --menu "" $((6 + ${LIST_LENGTH})) 50 $LIST_LENGTH "${LIST[@]}" 2>&1 1>&3)
		exec 3>&-
		if [[ $BT_ADAPTER != "" ]]; then
			show_infobox <<< "\nConnecting to $BT_ADAPTER "
			BT_EXEC=$(
				expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address\r";
			sleep 1;send "remove $address\r";sleep 1;expect -re $prompt;send "scan on\r";sleep 8;send "scan off\r";
			expect "Controller";send "trust $address\r";sleep 2;send "pair $address\r";sleep 2;send "connect $address\r";
			send_user "\nShould be paired now.\r";sleep 2;send "quit\r";expect eof'
			)
			echo "$BT_EXEC" > /tmp/bt-connect-debug.log
			if [[ $(echo "$BT_EXEC" | grep "Connection successful") != "" ]]; then
				show_message <<< "\nYour device is ready to use!"
			else
				show_message <<< "\nError connecting. Try again!"
			fi
		fi
	fi

}
