module_options+=(
	["set_stable,author"]="@Tearran"
	["set_stable,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_stable,feature"]="set_stable"
	["set_stable,desc"]="Set Armbian to stable release"
	["set_stable,example"]="set_stable"
	["set_stable,status"]="Active"
)
#
# @description Set Armbian to stable release
#
function set_stable() {

	if ! grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}

