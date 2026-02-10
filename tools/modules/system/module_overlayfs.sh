module_options+=(
	["module_overlayfs,author"]="@igorpecovnik"
	["module_overlayfs,maintainer"]="@igorpecovnik"
	["module_overlayfs,feature"]="module_overlayfs"
	["module_overlayfs,example"]="install remove status help"
	["module_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["module_overlayfs,status"]="Active"
	["module_overlayfs,doc_link"]="https://docs.kernel.org/filesystems/overlayfs.html"
	["module_overlayfs,group"]="System"
	["module_overlayfs,port"]=""
	["module_overlayfs,arch"]=""
)
#
# Install overlayroot for read-only root filesystem
#
function module_overlayfs() {
	local title="overlayfs"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_overlayfs,example"]}"

	OVERLAYFS_BASE="${SOFTWARE_FOLDER}/overlayfs"

	case "$1" in
		"${commands[0]}")
			pkg_install --reinstall -o Dpkg::Options::="--force-confold" overlayroot
			cat > /etc/overlayroot.conf <<-EOT
			# overlayroot config - managed by configng
			overlayroot_cfgdisk="disabled"
			overlayroot="tmpfs"
			EOT
			rm -f /etc/update-motd.d/97-overlayroot

			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[1]}")
			overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[2]}")
			overlayroot-chroot true > /dev/null 2>&1
			case $? in
				0) return 0 ;;
				*) return 1 ;;
			esac
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_overlayfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_overlayfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;
		*)
			${module_options["module_overlayfs,feature"]} ${commands[3]}
		;;
	esac
}
