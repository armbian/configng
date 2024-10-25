
menu_options+=(
	["get_headers_kernel,author"]="@igorpecovnik"
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
