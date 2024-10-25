module_options+=(
	["are_headers_installed,author"]="@viraniac"
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

