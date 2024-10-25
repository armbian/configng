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


