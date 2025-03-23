module_options+=(
	["module_headers,author"]="@armbian"
	["module_headers,feature"]="module_headers"
	["module_headers,desc"]="Install headers container"
	["module_headers,example"]="install remove status help"
	["module_headers,port"]=""
	["module_headers,status"]="Active"
	["module_headers,arch"]=""
)
#
# Mmodule_headers
#
function module_headers () {
	local title="headers"
	local condition=$(which "$title" 2>/dev/null)

	pkg_update

	if [[ -f /etc/armbian-release ]]; then
		source /etc/armbian-release
		# branch information is stored in armbian-release at boot time. When we change kernel branches, we need to re-read this and add it
		update_kernel_env
		local install_pkg="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		local install_pkg="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_headers,example"]}"

	case "$1" in
		"${commands[0]}")
			pkg_install ${install_pkg} build-essential git || exit 1
		;;
		"${commands[1]}")
			pkg_remove ${install_pkg} build-essential || exit 1
			rm -rf /usr/src/linux-headers*
		;;
		"${commands[2]}")
			pkg_installed ${install_pkg}
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_headers,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_headers,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_headers,feature"]} ${commands[3]}
		;;
	esac
}
