module_options+=(
	["module_zfs,author"]="@armbian"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install zfs filesystem support"
	["module_zfs,example"]="install remove status kernel_max zfs_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]=""
)
#
# Mmodule_zfs
#
function module_zfs () {
	local title="zfs"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	# determine if our kernel is not too recent
	local zfs_dkms=$(LC_ALL=C apt-cache policy zfs-dkms | grep Candidate | xargs | cut -d" " -f2 | cut -c-5)
	local kernel_max=$(wget -qO- https://github.com/openzfs/zfs/raw/refs/tags/zfs-${zfs_dkms}/META | grep Maximum | cut -d" " -f2)

	case "$1" in
		"${commands[0]}")
			module_headers install
			apt_install_wrapper apt-get -y install zfsutils-linux zfs-dkms || exit 1
		;;
		"${commands[1]}")
			module_headers remove
			apt_install_wrapper apt-get -y autopurge zfsutils-linux zfs-dkms || exit 1
		;;
		"${commands[2]}")
			if check_if_installed zfsutils-linux; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo "${kernel_max}"
		;;
		"${commands[4]}")
			echo "v${zfs_dkms}"
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_zfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_zfs,feature"]} ${commands[3]}
		;;
	esac
}
