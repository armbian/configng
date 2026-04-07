
module_options+=(
	["module_devicetree_edit,author"]="@igorpecovnik"
	["module_devicetree_edit,maintainer"]="@igorpecovnik"
	["module_devicetree_edit,feature"]="module_devicetree_edit"
	["module_devicetree_edit,desc"]="Edit device tree source and compile"
	["module_devicetree_edit,example"]="install remove status edit help"
	["module_devicetree_edit,port"]=""
	["module_devicetree_edit,status"]="Active"
	["module_devicetree_edit,arch"]="aarch64 armhf"
	["module_devicetree_edit,doc_link"]="https://docs.kernel.org/devicetree/usage-model.html"
	["module_devicetree_edit,group"]="Kernel"
)
#
# @description Edit device tree blob: decompile, edit, recompile
#
function module_devicetree_edit() {
	local title="Device Tree Editor"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_devicetree_edit,example"]}"

	case "$1" in
		"${commands[0]}") # install
			if module_devicetree_edit status >/dev/null 2>&1; then
				echo "Device tree compiler is already installed."
				return 0
			fi
			echo "Installing device tree compiler..."
			pkg_install device-tree-compiler || {
				echo "Failed to install device tree compiler."
				return 1
			}
			echo "Device tree compiler installed successfully."
		;;

		"${commands[1]}") # remove
			if ! module_devicetree_edit status >/dev/null 2>&1; then
				echo "Device tree compiler is not installed."
				return 0
			fi
			pkg_remove device-tree-compiler
			echo "Device tree compiler removed."
		;;

		"${commands[2]}") # status
			if pkg_installed device-tree-compiler; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # edit
			# Ensure dtc is available
			if ! command -v dtc >/dev/null 2>&1; then
				if dialog_yesno "Missing Dependency" \
					"The device tree compiler (dtc) is not installed.\n\nInstall it now?" "Install" "Cancel"; then
					pkg_install device-tree-compiler || {
						dialog_msgbox "Error" "Failed to install device tree compiler." 8 50
						return 1
					}
				else
					return 1
				fi
			fi

			# Find DTB directory
			local dtb_dir
			dtb_dir=$(find /boot/dtb/ -maxdepth 1 -type d ! -name dtb ! -name overlay ! -name overlays 2>/dev/null | head -n1)
			[[ -z "$dtb_dir" ]] && dtb_dir="/boot/dtb"

			if [[ ! -d "$dtb_dir" ]]; then
				dialog_msgbox "Error" "Device tree directory not found.\n\n/boot/dtb/ does not exist." 9 50
				return 1
			fi

			# Determine currently active DTB from /proc/device-tree/model or fdtfile
			local active_dtb=""
			if [[ -f /boot/armbianEnv.txt ]]; then
				active_dtb=$(awk -F'=' '/^fdtfile/ {print $2}' /boot/armbianEnv.txt)
			fi

			local backup_dir="/boot/dtb/backup"

			while true; do
				# Build menu
				local menu_items=()
				menu_items+=("1" "Select and edit a device tree blob")
				if [[ -n "$active_dtb" ]]; then
					menu_items+=("2" "Edit active DTB: ${active_dtb}")
				fi
				menu_items+=("3" "Restore DTB from backup")
				menu_items+=("4" "View current device tree info")

				local choice
				choice=$(dialog_menu "$title" \
					"\nEdit device tree blobs: decompile to source,\nedit with a text editor, and recompile.\n\nDTB directory: ${dtb_dir}\n" \
					0 0 0 "${menu_items[@]}")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # Select DTB file
						local dtb_files=()
						while IFS= read -r -d '' dtb_file; do
							local basename="${dtb_file##*/}"
							dtb_files+=("$basename" "")
						done < <(find "$dtb_dir" -maxdepth 1 -name '*.dtb' -print0 | sort -z)

						if [[ ${#dtb_files[@]} -eq 0 ]]; then
							dialog_msgbox "No DTB Files" "No .dtb files found in ${dtb_dir}" 8 50
							continue
						fi

						local selected
						selected=$(dialog_menu "Select Device Tree" \
							"\nChoose a DTB file to edit:\n" \
							0 0 0 "${dtb_files[@]}")

						[[ -z "$selected" ]] && continue
						_devicetree_edit_dtb "${dtb_dir}/${selected}" "$backup_dir"
						;;
					2) # Edit active DTB
						if [[ -n "$active_dtb" ]]; then
							local dtb_path="/boot/dtb/${active_dtb}"
							if [[ -f "$dtb_path" ]]; then
								_devicetree_edit_dtb "$dtb_path" "$backup_dir"
							else
								dialog_msgbox "Error" "Active DTB file not found:\n${active_dtb}" 9 50
							fi
						fi
						;;
					3) # Restore from backup
						_devicetree_restore_backup "$backup_dir" "$dtb_dir"
						;;
					4) # View device tree info
						_devicetree_show_info "$dtb_dir"
						;;
				esac
			done
		;;

		"${commands[4]}") # help
			show_module_help "module_devicetree_edit" "$title" \
				"Edit device tree blobs by decompiling to source,\nediting with a text editor, and recompiling.\n\nRequires: device-tree-compiler (dtc)"
		;;

		*)
			${module_options["module_devicetree_edit,feature"]} ${commands[4]}
		;;
	esac
}

#
# @description Decompile, edit, and recompile a DTB file
# @param $1 Full path to the DTB file
# @param $2 Backup directory
#
function _devicetree_edit_dtb() {
	local dtb_path="$1"
	local backup_dir="$2"
	local dtb_name="${dtb_path##*/}"
	local tmp_dts
	tmp_dts=$(mktemp /tmp/devicetree-XXXXXX.dts)

	# Decompile DTB to DTS
	if ! dtc -I dtb -O dts -o "$tmp_dts" "$dtb_path" 2>/dev/null; then
		dialog_msgbox "Error" "Failed to decompile ${dtb_name}\n\nThe file may be corrupted or not a valid DTB." 10 60
		rm -f "$tmp_dts"
		return 1
	fi

	# Record checksum before editing
	local checksum_before
	checksum_before=$(md5sum "$tmp_dts" | awk '{print $1}')

	# Open editor
	${EDITOR:-nano} "$tmp_dts"

	# Check if file was modified
	local checksum_after
	checksum_after=$(md5sum "$tmp_dts" | awk '{print $1}')

	if [[ "$checksum_before" == "$checksum_after" ]]; then
		dialog_msgbox "No Changes" "No modifications were made to ${dtb_name}" 8 50
		rm -f "$tmp_dts"
		return 0
	fi

	# Validate the edited DTS by attempting to compile
	local tmp_dtb
	tmp_dtb=$(mktemp /tmp/devicetree-XXXXXX.dtb)

	if ! dtc -I dts -O dtb -o "$tmp_dtb" "$tmp_dts" 2>/tmp/dtc_errors.txt; then
		local errors
		errors=$(cat /tmp/dtc_errors.txt)
		dialog_msgbox "Compilation Error" \
			"The edited device tree source has errors:\n\n${errors}\n\nNo changes were applied." 18 70
		rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
		return 1
	fi

	# Confirm before applying
	if dialog_yesno "Apply Changes" \
		"Device tree compiled successfully.\n\nApply changes to:\n${dtb_path}\n\nA backup will be created automatically." \
		"Apply" "Cancel" 13 65; then

		# Create backup
		mkdir -p "$backup_dir"
		local timestamp
		timestamp=$(date +%Y%m%d_%H%M%S)
		if ! cp "$dtb_path" "${backup_dir}/${dtb_name}.${timestamp}.bak" || \
			[[ ! -r "${backup_dir}/${dtb_name}.${timestamp}.bak" ]]; then
			dialog_msgbox "Error" "Failed to create backup of ${dtb_name}.\n\nChanges were NOT applied." 10 60
			rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
			return 1
		fi

		# Install the new DTB
		cp "$tmp_dtb" "$dtb_path"

		dialog_msgbox "Success" \
			"Device tree updated successfully.\n\nBackup saved to:\n${backup_dir}/${dtb_name}.${timestamp}.bak\n\nA reboot is required for changes to take effect." 13 65

		if dialog_yesno "Reboot Required" \
			"A reboot is required to apply the changes.\nShall we reboot now?" "Reboot" "Cancel" 9 50; then
			reboot
		fi
	fi

	rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
}

#
# @description Restore a DTB from backup
# @param $1 Backup directory
# @param $2 DTB directory
#
function _devicetree_restore_backup() {
	local backup_dir="$1"
	local dtb_dir="$2"

	if [[ ! -d "$backup_dir" ]] || [[ -z $(ls "$backup_dir"/*.bak 2>/dev/null) ]]; then
		dialog_msgbox "No Backups" "No device tree backups found in:\n${backup_dir}" 8 55
		return 1
	fi

	local backup_files=()
	while IFS= read -r -d '' bak_file; do
		local basename="${bak_file##*/}"
		# Extract original name and timestamp from backup filename
		local display="${basename%.bak}"
		backup_files+=("$basename" "$display")
	done < <(find "$backup_dir" -maxdepth 1 -name '*.bak' -print0 | sort -rz)

	local selected
	selected=$(dialog_menu "Restore Device Tree Backup" \
		"\nSelect a backup to restore:\n" \
		0 0 0 "${backup_files[@]}")

	[[ -z "$selected" ]] && return 0

	# Extract original DTB name (everything before the timestamp)
	local original_name="${selected%%.[0-9]*}"

	# Find where to restore
	local restore_path
	restore_path=$(find "$dtb_dir" -maxdepth 2 -name "$original_name" 2>/dev/null | head -n1)

	if [[ -z "$restore_path" ]]; then
		# If can't auto-detect, ask for confirmation with default path
		restore_path="${dtb_dir}/${original_name}"
	fi

	if dialog_yesno "Confirm Restore" \
		"Restore backup:\n${selected}\n\nTo:\n${restore_path}" "Restore" "Cancel"; then
		if cp "${backup_dir}/${selected}" "$restore_path"; then
			dialog_msgbox "Restored" \
				"Device tree restored successfully.\n\nA reboot is required for changes to take effect." 10 60

			if dialog_yesno "Reboot Required" \
				"A reboot is required to apply the changes.\nShall we reboot now?" "Reboot" "Cancel" 9 50; then
				reboot
			fi
		else
			dialog_msgbox "Restore Failed" \
				"Failed to restore backup.\n\nSource: ${backup_dir}/${selected}\nDestination: ${restore_path}" 10 65
		fi
	fi
}

#
# @description Show current device tree information
# @param $1 DTB directory
#
function _devicetree_show_info() {
	local dtb_dir="$1"
	local info_text=""

	# Device model
	if [[ -f /proc/device-tree/model ]]; then
		info_text+="Model: $(tr -d '\0' < /proc/device-tree/model 2>/dev/null)\n"
	fi

	# Compatible strings
	if [[ -f /proc/device-tree/compatible ]]; then
		info_text+="Compatible: $(tr '\0' ', ' < /proc/device-tree/compatible 2>/dev/null)\n"
	fi

	# Active DTB from armbianEnv
	if [[ -f /boot/armbianEnv.txt ]]; then
		local fdtfile
		fdtfile=$(awk -F'=' '/^fdtfile/ {print $2}' /boot/armbianEnv.txt)
		[[ -n "$fdtfile" ]] && info_text+="Active DTB: ${fdtfile}\n"
	fi

	# DTB directory contents
	local dtb_count
	dtb_count=$(find "$dtb_dir" -maxdepth 1 -name '*.dtb' 2>/dev/null | wc -l)
	info_text+="\nDTB Directory: ${dtb_dir}\n"
	info_text+="DTB Files: ${dtb_count}\n"

	# Backup status
	if [[ -d /boot/dtb/backup ]]; then
		local backup_count
		backup_count=$(find /boot/dtb/backup -name '*.bak' 2>/dev/null | wc -l)
		info_text+="Backups: ${backup_count}\n"
	else
		info_text+="Backups: none\n"
	fi

	# DTC version
	if command -v dtc >/dev/null 2>&1; then
		info_text+="\nDTC Version: $(dtc --version 2>&1 | head -n1)\n"
	else
		info_text+="\nDTC: not installed\n"
	fi

	dialog_msgbox "Device Tree Information" "$info_text" 20 70
}
