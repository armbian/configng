module_options+=(
	["module_luks_rekey,author"]="@igorpecovnik"
	["module_luks_rekey,maintainer"]="@igorpecovnik"
	["module_luks_rekey,feature"]="module_luks_rekey"
	["module_luks_rekey,example"]="run status progress help"
	["module_luks_rekey,desc"]="Give the encrypted root its own LUKS keys"
	["module_luks_rekey,status"]="Active"
	["module_luks_rekey,doc_link"]=""
	["module_luks_rekey,group"]="System"
	["module_luks_rekey,port"]=""
	["module_luks_rekey,arch"]=""
)
#
# An autounlock image (CRYPTROOT_AUTOUNLOCK=yes) ships one keyfile and one
# volume key. All copies of the image share them. armbian-luks-rekey (BSP)
# makes new ones. It re-encrypts the whole root, which takes long on slow
# storage, so the user starts it.
#
function module_luks_rekey() {
	local title="LUKS re-key"
	local script=/usr/lib/armbian/armbian-luks-rekey
	local log=/var/log/armbian-luks-rekey.log

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_luks_rekey,example"]}"

	case "$1" in
		"${commands[0]}")
			if ! module_luks_rekey status; then
				dialog_msgbox " $title " "This system has no root that unlocks with the image key." 7 60
				return 1
			fi
			local dev size
			dev=$(cryptsetup status "$(awk '$3 == "/etc/rootfs.key" { print $1; exit }' /etc/crypttab)" 2> /dev/null | awk '/device:/ { print $2 }')
			size=$(lsblk -bdno SIZE "$dev" 2> /dev/null)
			if ! dialog_yesno " $title " "All copies of this image share one LUKS key.\n\nThis makes a new keyfile and re-encrypts the root ($((size / 1073741824)) GiB) with a new volume key. It runs in the background. The system stays usable, but disk access is slow until it is done. On an SD card, allow about 2 minutes per GiB.\n\nA reboot pauses the job. The next boot continues it.\n\nStart now?" "Start" "Cancel" 16 70; then
				return 0
			fi
			# Enabled, so that a reboot continues the job. The script disables the unit when done.
			systemctl enable --now --no-block armbian-luks-rekey
			dialog_msgbox " $title " "Started. Check the progress here, or in $log." 7 60
		;;
		"${commands[1]}")
			# Available: the root unlocks with the image keyfile and the job is not done.
			[[ -x $script && -f /etc/rootfs.key ]] || return 1
			systemctl -q is-active armbian-luks-rekey && return 1
			awk '$3 == "/etc/rootfs.key"' /etc/crypttab 2> /dev/null | grep -q . || return 1
			grep -q '| done$' "$log" 2> /dev/null && return 1
			return 0
		;;
		"${commands[2]}")
			if systemctl -q is-active armbian-luks-rekey; then
				local pct
				pct=$(grep -o 'Progress: *[0-9.]*' "$log" 2> /dev/null | tail -n 1 | grep -o '[0-9.]*$')
				dialog_msgbox " $title " "Re-encryption runs: ${pct:-0}% done." 7 50
			elif grep -q '| done$' "$log" 2> /dev/null; then
				dialog_msgbox " $title " "Done. The root has its own keys." 7 50
			else
				dialog_msgbox " $title " "Not running. See $log." 7 50
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_luks_rekey,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_luks_rekey,example"]}"
			echo "Available commands:"
			echo -e "\trun\t- Make new LUKS keys and re-encrypt the root."
			echo -e "\tstatus\t- Return 0 if the root still uses the image key."
			echo -e "\tprogress\t- Show the re-encryption progress."
			echo
		;;
		*)
			${module_options["module_luks_rekey,feature"]} ${commands[3]}
		;;
	esac
}
