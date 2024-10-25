module_options+=(
	["set_rolling,author"]="@Tearran"
	["set_rolling,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_rolling,feature"]="set_rolling"
	["set_rolling,desc"]="Set Armbian to rolling release"
	["set_rolling,example"]="set_rolling"
	["set_rolling,status"]="Active"
)
#
# @description Set Armbian to rolling release
#
function set_rolling() {

	if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}

