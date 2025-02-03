module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install zfs filesystem support"
	["module_zfs,example"]="install remove status kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
)
#
# Module OpenZFS
#
function module_zfs () {
	local title="zfs"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	case "$1" in
		"${commands[0]}")
			# headers are needed, lets install then if they are not there already
			if ! module_armbian_firmware headers status; then
				module_armbian_firmware headers install
			fi
			pkg_install zfsutils-linux zfs-dkms
		;;
		"${commands[1]}")
			module_armbian_firmware headers remove
			pkg_remove zfsutils-linux zfs-dkms
		;;
		"${commands[2]}")
			pkg_installed zfsutils-linux
		;;
		"${commands[3]}")
			echo "${ZFS_KERNEL_MAX}"
		;;
		"${commands[4]}")
			echo "v${ZFS_DKMS_VERSION}"
		;;
		"${commands[5]}")
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null| head -1 | cut -d"-" -f2
			fi
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_zfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\kernel_max\t- Determine maximum version of kernel to support $title."
			echo -e "\zfs_version\t- Gets $title version from Git."
			echo -e "\zfs_installed_version\t- Read $title module info."
			echo
		;;
		*)
			${module_options["module_zfs,feature"]} ${commands[6]}
		;;
	esac
}
