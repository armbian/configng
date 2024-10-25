module_options+=(
	["Headers_install,author"]="@Tearran"
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

