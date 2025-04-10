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
# Armbian root filesystem to read only
#
function module_overlayfs() {
	local title="overlayfs"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_overlayfs,example"]}"

	case "$1" in
		"${commands[0]}")
			pkg_install -o Dpkg::Options::="--force-confold" overlayroot cryptsetup cryptsetup-bin
			[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
			sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[1]}")
			overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
			pkg_remove overlayroot cryptsetup cryptsetup-bin
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[2]}")
			if command -v overlayroot-chroot > /dev/null 2>&1; then
				return 1
			else
				return 0
			fi
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
