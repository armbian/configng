

module_options+=(
	["set_header_remove,author"]="@igorpecovnik"
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

