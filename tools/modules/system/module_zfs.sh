module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,maintainer"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install ZFS filesystem support"
	["module_zfs,example"]="install remove status kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
	["module_zfs,doc_link"]="https://openzfs.github.io/openzfs-docs/"
	["module_zfs,group"]="System"
)
#
# Module OpenZFS
#
function module_zfs () {
	local title="zfs"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			if pkg_installed zfsutils-linux; then
				echo "ZFS is already installed."
				return 0
			fi

			# Headers are needed, install them if not already present
			if ! module_headers status >/dev/null 2>&1; then
				echo "Installing kernel headers (required for ZFS)..."
				module_headers install
			fi

			echo "Installing ZFS packages..."
			# Suppress DKMS license prompt during ZFS compilation
			pkg_install zfsutils-linux zfs-dkms || return 1
			echo "✅ ZFS installed successfully"
		;;
		"${commands[1]}")
			echo "Removing ZFS packages..."
			pkg_remove zfsutils-linux zfs-dkms
			# Note: We don't remove kernel headers as they may be needed by other modules
			echo "✅ ZFS removed successfully"
		;;
		"${commands[2]}")
			if pkg_installed zfsutils-linux; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo "${ZFS_KERNEL_MAX:-<not set>}"
		;;
		"${commands[4]}")
			if [[ -n "${ZFS_DKMS_VERSION}" ]]; then
				echo "v${ZFS_DKMS_VERSION}"
			else
				echo "<version not available>"
			fi
		;;
		"${commands[5]}")
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null | head -1 | cut -d"-" -f2
			else
				echo "ZFS is not installed"
				return 1
			fi
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_zfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zfs,example"]}"
			echo "Available commands:"
			echo -e "  install              - Install $title."
			echo -e "  remove               - Remove $title."
			echo -e "  status               - Installation status $title."
			echo -e "  kernel_max           - Determine maximum version of kernel to support $title."
			echo -e "  zfs_version          - Gets $title version from DKMS."
			echo -e "  zfs_installed_version - Read $title module info."
			echo
		;;
		*)
			${module_options["module_zfs,feature"]} ${commands[6]}
		;;
	esac
}
