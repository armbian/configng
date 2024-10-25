module_options+=(
	["Headers_remove,author"]="@Tearran"
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

