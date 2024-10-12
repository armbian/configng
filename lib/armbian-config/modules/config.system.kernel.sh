#!/bin/bash



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
function are_headers_installed() {
	if [[ -f /etc/armbian-release ]]; then
		PKG_NAME="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		PKG_NAME="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	check_if_installed ${PKG_NAME}
	return $?
}

menu_options+=(
	["get_headers_kernel,author"]="Igor Pecovnik"
	["get_headers_kernel,ref_link"]=""
	["get_headers_kernel,feature"]="get_headers_install"
	["get_headers_kernel,desc"]="Migrated procedures from Armbian config."
	["get_headers_kernel,example"]="get_headers_install"
	["get_headers_kernel,status"]="Active"
	["get_headers_kernel,doc_link"]=""
)
#
# install kernel headers
#
function get_headers_install() {

	if [[ -f /etc/armbian-release ]]; then
		INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	debconf-apt-progress -- apt-get -y install ${INSTALL_PKG} || exit 1

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
function Headers_install() {
	if ! is_package_manager_running; then
		if [[ -f /etc/armbian-release ]]; then
			INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
		else
			INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
		fi
		debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
}


module_options+=(
	["set_header_remove,author"]="Igor Pecovnik"
	["set_header_remove,ref_link"]=""
	["set_header_remove,feature"]="set_header_remove"
	["set_header_remove,desc"]="Migrated procedures from Armbian config."
	["set_header_remove,example"]="set_header_remove"
	["set_header_remove,doc_link"]=""
	["set_header_remove,status"]="Active"
	["set_header_remove,doc_ink"]=""
)
#
# remove kernel headers
#
function set_header_remove() {

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

}


module_options+=(
	["Headers_remove,author"]="Joey Turner"
	["Headers_remove,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L160"
	["Headers_remove,feature"]="Headers_remove"
	["Headers_remove,desc"]="Remove Linux headers"
	["Headers_remove,example"]="Headers_remove"
	["Headers_remove,status"]="Pending Review"
	["Headers_remove,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Linux headers
#
function Headers_remove() {
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

