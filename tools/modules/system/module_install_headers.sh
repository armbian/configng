module_options+=(
	["module_headers,author"]="@armbian"
	["module_headers,maintainer"]="@igorpecovnik"
	["module_headers,feature"]="module_headers"
	["module_headers,desc"]="Install kernel headers for building kernel modules"
	["module_headers,example"]="install remove status help"
	["module_headers,port"]=""
	["module_headers,status"]="Active"
	["module_headers,arch"]=""
	["module_headers,doc_link"]="https://www.kernel.org/doc/html/latest/"
	["module_headers,group"]="System"
)
#
# Module Headers
#
function module_headers () {
	local title="headers"
	local install_pkg=""

	# Determine the correct headers package to install
	if [[ -f /etc/armbian-release ]]; then
		source /etc/armbian-release
		# Branch information is stored in armbian-release at boot time.
		# When we change kernel branches, we need to re-read this and update it
		update_kernel_env
		if [[ -n "${BRANCH}" && -n "${LINUXFAMILY}" ]]; then
			install_pkg="linux-headers-${BRANCH}-${LINUXFAMILY}"
		fi
	fi
	if [[ -z "${install_pkg}" ]]; then
		local arch
		arch="$(dpkg --print-architecture)" || return 1
		local kernel_release
		kernel_release="$(uname -r)" || return 1
		# Remove architecture suffix from kernel release if present
		install_pkg="linux-headers-$(echo "${kernel_release}" | sed "s/-${arch}//")"
	fi

	# Validate we determined a package name
	if [[ -z "${install_pkg}" ]]; then
		echo "Error: Unable to determine kernel headers package name"
		return 1
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_headers,example"]}"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			if pkg_installed "${install_pkg}"; then
				echo "Kernel headers are already installed: ${install_pkg}"
				return 0
			fi

			echo "Installing kernel headers: ${install_pkg}"
			pkg_update
			pkg_install "${install_pkg}" build-essential git || return 1
			echo "Kernel headers installed successfully"
		;;
		"${commands[1]}")
			echo "Removing kernel headers: ${install_pkg}"
			pkg_remove "${install_pkg}" build-essential || return 1
			# Safely remove header directories
			if compgen -G "/usr/src/linux-headers*" > /dev/null; then
				rm -rf /usr/src/linux-headers*
				echo "Kernel headers removed successfully"
			fi
		;;
		"${commands[2]}")
			if pkg_installed "${install_pkg}"; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_headers,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_headers,example"]}"
			echo "Available commands:"
			echo -e "  install  - Install $title."
			echo -e "  status  - Installation status $title."
			echo -e "  remove  - Remove $title."
			echo
		;;
		*)
			${module_options["module_headers,feature"]} ${commands[3]}
		;;
	esac
}
