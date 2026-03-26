module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,maintainer"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install ZFS filesystem support"
	["module_zfs,example"]="install remove status tune scan import kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
	["module_zfs,doc_link"]="https://openzfs.github.io/openzfs-docs/"
	["module_zfs,group"]="System"
	["module_zfs,config_file"]="/etc/modprobe.d/zfs.conf"
	# Custom command help descriptions
	["module_zfs,help_tune"]="Fine-tune ZFS performance parameters (ARC, dirty data, TXG, compression)"
	["module_zfs,help_scan"]="Scan for ZFS pools that can be imported"
	["module_zfs,help_import"]="Import a selected ZFS pool with optional alternate mount point"
	["module_zfs,help_kernel_max"]="Determine maximum supported kernel version for ZFS"
	["module_zfs,help_zfs_version"]="Get ZFS version from DKMS"
	["module_zfs,help_zfs_installed_version"]="Read installed ZFS version"
)
#
# Module OpenZFS
#
function module_zfs () {
	local title="zfs"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	case "$1" in
		"${commands[0]}") # install
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
		;;
		"${commands[1]}") # remove
			echo "Removing ZFS packages..."
			pkg_remove zfsutils-linux zfs-dkms
			# Note: We don't remove kernel headers as they may be needed by other modules
		;;
		"${commands[2]}") # status
			if pkg_installed zfsutils-linux; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}") # tune
			# Check if ZFS is installed
			if ! pkg_installed zfsutils-linux; then
				dialog_msgbox "ZFS Not Installed" \
					"ZFS is not installed. Please install ZFS first before tuning parameters."
				return 1
			fi

			# Check if ZFS module is loaded
			if ! lsmod | grep -q "^zfs "; then
				dialog_msgbox "ZFS Not Loaded" \
					"ZFS kernel module is not loaded. Loading module now..."
				modprobe zfs 2>/dev/null || {
					dialog_msgbox "Failed to Load ZFS" \
						"Failed to load ZFS kernel module. Please check your installation."
					return 1
				}
			fi

			local config_file="${module_options["module_zfs,config_file"]}"
			local backup_file="${config_file}.bak"

			# Get current system memory in MB
			local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
			local total_mem_mb=$((total_mem_kb / 1024))
			local total_mem_gb=$((total_mem_mb / 1024))

			# Calculate recommended values based on system memory
			local recommended_arc_min=$((total_mem_mb / 8))
			local recommended_arc_max=$((total_mem_mb / 2))
			local recommended_dirty=$((total_mem_mb / 25))  # 4% of RAM

			# Get current ARC settings
			local arc_min_current=$(cat /sys/module/zfs/parameters/zfs_arc_min 2>/dev/null || echo "0")
			local arc_max_current=$(cat /sys/module/zfs/parameters/zfs_arc_max 2>/dev/null || echo "0")
			local arc_min_mb=$((arc_min_current / 1024 / 1024))
			local arc_max_mb=$((arc_max_current / 1024 / 1024))

			# Convert to readable format
			local arc_max_display="${arc_max_mb} MB"
			if [[ $arc_max_mb -eq 0 ]]; then
				arc_max_display="Default (all RAM)"
			fi

			# Get current dirty data settings
			local dirty_max_current=$(cat /sys/module/zfs/parameters/zfs_dirty_data_max 2>/dev/null || echo "0")
			local dirty_max_mb=$((dirty_max_current / 1024 / 1024))

			# Get TXG timeout
			local txg_timeout=$(cat /sys/module/zfs/parameters/zfs_txg_timeout 2>/dev/null || echo "5")

			# Create tuning menu
			while true; do
				local menu_text="System Memory: ${total_mem_mb} MB (${total_mem_gb} GB)\n\n"
				menu_text+="Current Settings:\n"
				menu_text+="ARC Min: ${arc_min_mb} MB\n"
				menu_text+="ARC Max: ${arc_max_display}\n"
				menu_text+="Dirty Data Max: ${dirty_max_mb} MB\n"
				menu_text+="TXG Timeout: ${txg_timeout} sec\n\n"
				menu_text+="Select a parameter to tune:"

				local choice=$(dialog_menu "ZFS Performance Tuning" "$menu_text" 23 80 7 \
					"1" "ARC Cache Size (zfs_arc_min/max)" \
					"2" "Dirty Data Limits (zfs_dirty_data_max)" \
					"3" "TXG Timeout (zfs_txg_timeout)" \
					"4" "Advanced Settings" \
					"5" "Reset to Defaults" \
					"6" "Save & Apply Configuration" \
					"7" "Show Current Configuration")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # ARC Cache Size Tuning
						dialog_msgbox "ARC Cache Size Tuning" \
							"The ARC (Adaptive Replacement Cache) is ZFS's intelligent cache.\n\nRecommended Settings:\n- zfs_arc_min: ${recommended_arc_min} MB (1/8 of RAM)\n- zfs_arc_max: ${recommended_arc_max} MB (1/2 of RAM)\n\nCurrent: ${arc_min_mb} MB / ${arc_max_display}" 16 80

						local new_arc_min_mb=$(dialog_inputbox "ARC Min Size" \
							"Enter ARC Min Size in MB:\n\n  Recommended: ${recommended_arc_min} MB\n  Existing value: ${arc_min_mb} MB\n\nPress OK to accept or change value:" \
							"${arc_min_mb}" 11 70)
						[[ -z "$new_arc_min_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_arc_min_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "ARC Min must be a positive number!" 8 60
							continue
						fi

						local new_arc_max_mb=$(dialog_inputbox "ARC Max Size" \
							"Enter ARC Max Size in MB:\n\n  Recommended: ${recommended_arc_max} MB (0 = all RAM)\n  Existing value: ${arc_max_mb} MB\n\nPress OK to accept or change value:" \
							"${arc_max_mb}" 11 70)
						[[ -z "$new_arc_max_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_arc_max_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "ARC Max must be a positive number (or 0)!" 8 60
							continue
						fi

						# Validate relationship
						if [[ $new_arc_min_mb -gt $new_arc_max_mb ]] && [[ $new_arc_max_mb -ne 0 ]]; then
							dialog_msgbox "Invalid Values" "ARC Min cannot be greater than ARC Max!" 10 65
							continue
						fi

						arc_min_mb=$new_arc_min_mb
						arc_max_mb=$new_arc_max_mb

						# Update display
						arc_max_display="${arc_max_mb} MB"
						[[ $arc_max_mb -eq 0 ]] && arc_max_display="Default (all RAM)"

						dialog_msgbox "Values Updated" "ARC settings updated.\n\nApply changes to take effect." 10 65
						;;

					2) # Dirty Data Limits
						dialog_msgbox "Dirty Data Limits" \
							"Dirty data is data that has been changed but not yet written to disk.\n\nRecommended: ${recommended_dirty} MB (4% of RAM)\n\nHigher values = better performance but more data loss risk on power failure." 14 75

						local new_dirty_max_mb=$(dialog_inputbox "Dirty Data Max" \
							"Enter Dirty Data Max in MB:\n\n  Recommended: ${recommended_dirty} MB\n  Existing value: ${dirty_max_mb} MB\n\nPress OK to accept or change value:" \
							"${dirty_max_mb}" 11 70)
						[[ -z "$new_dirty_max_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_dirty_max_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "Dirty Data Max must be a positive number!" 8 60
							continue
						fi

						dirty_max_mb=$new_dirty_max_mb

						dialog_msgbox "Value Updated" "Dirty data max updated.\n\nApply changes to take effect." 10 65
						;;

					3) # TXG Timeout
						dialog_msgbox "TXG (Transaction Group) Timeout" \
							"Controls how often ZFS writes dirty data to disk.\n\nDefault: 5 seconds\n\nLower values = more frequent writes, better data safety, lower performance\nHigher values = less frequent writes, better performance, more data loss risk" 15 75

						local new_txg_timeout=$(dialog_inputbox "TXG Timeout" \
							"Enter TXG Timeout in seconds (1-30):\n\n  Recommended: 5 seconds\n  Existing value: ${txg_timeout} seconds\n\nPress OK to accept or change value:" \
							"${txg_timeout}" 11 70)
						[[ -z "$new_txg_timeout" ]] && continue

						# Validate numeric input
						if ! [[ "$new_txg_timeout" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "TXG timeout must be a positive number!" 8 60
							continue
						fi

						# Validate range
						if [[ $new_txg_timeout -lt 1 ]] || [[ $new_txg_timeout -gt 30 ]]; then
							dialog_msgbox "Invalid Value" "TXG timeout must be between 1 and 30 seconds!" 10 65
							continue
						fi

						txg_timeout=$new_txg_timeout

						dialog_msgbox "Value Updated" "TXG timeout updated.\n\nApply changes to take effect." 10 65
						;;

					4) # Advanced Settings
						local adv_choice=$(dialog_menu "Advanced ZFS Tuning" \
							"WARNING: Only change these if you know what you're doing!" 20 80 6 \
							"1" "Prefetch Settings" \
							"2" "Sync Settings" \
							"3" "VDEV Settings" \
							"4" "Debug & Logging" \
							"5" "View Current module parameters" \
							"6" "Back")

						[[ -z "$adv_choice" ]] && continue

						case $adv_choice in
							1)
								local prefetch_current=$(cat /sys/module/zfs/parameters/zfs_prefetch_disable 2>/dev/null || echo "0")
								local prefetch_status="Enabled"
								[[ $prefetch_current -eq 1 ]] && prefetch_status="Disabled"

								if dialog_yesno "Disable ZFS Prefetch?" \
									"Current: ${prefetch_status}\n\nDisabling can help with certain workloads but usually hurts performance.\n\nDisable prefetch?"; then
									dialog_msgbox "Info" "Prefetch settings can be manually added to the config.\n\nEdit: ${config_file}\n\nAdd: options zfs zfs_prefetch_disable=1" 13 75
								else
									dialog_msgbox "Info" "Prefetch will remain enabled.\n\nCurrent default: enabled" 11 70
								fi
								;;
							2)
								dialog_msgbox "Sync Settings" \
									"zfs_sync_taskq_batch_pct controls sync task batching.\n\nDefault: Auto-tuned\n\nIncreasing can improve sync-heavy workloads (databases).\n\nCan be manually set in: ${config_file}" 13 70
								;;
							3)
								dialog_msgbox "VDEV Settings" \
									"zfs_vdev_* parameters control VDEV behavior.\n\nMost are auto-tuned. Manual tuning rarely needed.\n\nCommon parameters:\n- zfs_vdev_async_write_min_active\n- zfs_vdev_max_active\n- zfs_vdev_open_max_ms" 14 70
								;;
							4)
								dialog_msgbox "Debug & Logging" \
									"zfs_deadman_enabled, zfs_flags, etc.\n\nOnly enable for debugging purposes.\n\nWARNING: Can significantly impact performance.\n\nAdd to config manually if needed." 13 70
								;;
							5)
								if [[ -d /sys/module/zfs/parameters ]]; then
									local params_text="Current ZFS module parameters:\n\n"
									# Use ls to get parameter files safely
									for param_file in /sys/module/zfs/parameters/*; do
										if [[ -f "$param_file" ]]; then
											local name=$(basename "$param_file")
											local value
											value=$(cat "$param_file" 2>/dev/null || echo "N/A")
											# Truncate long values for display
											if [[ ${#value} -gt 50 ]]; then
												value="${value:0:47}..."
											fi
											params_text+="${name} = ${value}\n"
										fi
									done
									# Count total parameters
									local param_count=$(ls -1 /sys/module/zfs/parameters/* 2>/dev/null | wc -l)
									params_text+="\nTotal: ${param_count} parameters"
									dialog_msgbox "ZFS Module Parameters" "$params_text" 20 75
								else
									dialog_msgbox "Not Available" "ZFS module parameters not available.\n\nEnsure ZFS module is loaded."
								fi
								;;
						esac
						;;

					5) # Reset to defaults
						if dialog_yesno "Reset to Defaults" \
							"Reset all ZFS parameters to defaults?\n\nThis will remove any custom tuning."; then
							arc_min_mb=0
							arc_max_mb=0
							dirty_max_mb=$recommended_dirty
							txg_timeout=5
							# Update display
							arc_max_display="Default (all RAM)"
							dialog_msgbox "Reset Complete" "Parameters reset to defaults.\n\nApply changes to take effect." 11 70
						fi
						;;

					6) # Save & Apply
						local config_preview="The following settings will be saved to:\n${config_file}\n\n"
						if [[ $arc_min_mb -gt 0 ]]; then
							config_preview+="zfs_arc_min=$((arc_min_mb * 1024 * 1024)) bytes\n"
						fi
						if [[ $arc_max_mb -gt 0 ]]; then
							config_preview+="zfs_arc_max=$((arc_max_mb * 1024 * 1024)) bytes\n"
						else
							config_preview+="# zfs_arc_max=0  (use all RAM, default)\n"
						fi
						config_preview+="zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024)) bytes\n"
						config_preview+="zfs_txg_timeout=${txg_timeout} seconds\n"

						dialog_msgbox "Saving ZFS Configuration" "$config_preview"

						# Backup existing config if it exists
						if [[ -f "$config_file" ]]; then
							cp "$config_file" "$backup_file" || {
								dialog_msgbox "Backup Failed" "Failed to backup existing configuration.\n\nContinuing without backup."
							}
						fi

						# Build configuration file
						{
							echo "# ZFS Performance Tuning Configuration"
							echo "# Generated by Armbian config on $(date)"
							echo ""
							echo "# ARC Cache Settings"
							if [[ $arc_min_mb -gt 0 ]]; then
								echo "options zfs zfs_arc_min=$((arc_min_mb * 1024 * 1024))"
							fi
							if [[ $arc_max_mb -gt 0 ]]; then
								echo "options zfs zfs_arc_max=$((arc_max_mb * 1024 * 1024))"
							else
								echo "# options zfs zfs_arc_max=0  # 0 = use all RAM (default)"
							fi
							echo ""
							echo "# Dirty Data Settings"
							echo "options zfs zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024))"
							echo ""
							echo "# Transaction Group Settings"
							echo "options zfs zfs_txg_timeout=${txg_timeout}"
						} > "$config_file"

						# Notify about backup
						if [[ -f "$backup_file" ]]; then
							dialog_msgbox "Configuration Saved" \
								"Configuration saved successfully.\n\nPrevious configuration backed up to:\n${backup_file}\n\nYou can restore it manually if needed." 12 70
						fi

						# Apply changes
						dialog_msgbox "Applying Changes" \
							"Configuration saved.\n\nTo apply changes, ZFS module must be reloaded.\n\nThis requires either:\n1. Reboot\n2. Manual: rmmod zfs && modprobe zfs\n\nWARNING: Unloading ZFS requires exporting all pools first." 16 75

						if dialog_yesno "Reload ZFS Module" \
							"WARNING: All ZFS pools must be exported first!\n\nContinue?"; then
							if [[ -n "$(zpool list -H 2>/dev/null)" ]]; then
								dialog_msgbox "Cannot Reload" \
									"ZFS pools are imported.\n\nPlease export all pools first:\nzpool export -a" 11 70
							else
								# Try to unload ZFS module
								if rmmod zfs 2>/dev/null; then
									# rmmod succeeded, now try to load ZFS module
									if modprobe zfs 2>/dev/null; then
										# Success
										dialog_msgbox "Success" \
											"ZFS module reloaded successfully.\n\nNew settings are now active." 11 70
									else
										# modprobe failed - system without ZFS!
										# Try retry
										if modprobe zfs 2>/dev/null; then
											dialog_msgbox "Success" \
												"ZFS module reloaded after retry.\n\nNew settings are now active." 11 70
										else
											# Recovery failed - show dmesg and recovery instructions
											local dmesg_output
											dmesg_output=$(dmesg | tail -20 2>/dev/null || echo "Cannot retrieve dmesg output")
											dialog_msgbox "Critical Error" \
												"ZFS module unload succeeded but reload FAILED!\n\nSystem is running without ZFS support.\n\nLast dmesg entries:\n${dmesg_output}\n\nRecovery:\n1. Reboot to restore ZFS\n2. Or try manually: modprobe zfs" 18 75
										fi
									fi
								else
									# rmmod failed - module probably in use
									dialog_msgbox "Unload Failed" \
										"Failed to unload ZFS module.\n\nModule may be in use.\n\nTry rebooting to apply new settings." 11 70
								fi
							fi
						fi

						break
						;;

					7) # Show current configuration
						local show_text="Current ZFS Configuration:\n\n"
						if [[ $arc_min_mb -gt 0 ]]; then
							show_text+="ARC Min: ${arc_min_mb} MB ($((arc_min_mb * 1024 * 1024)) bytes)\n"
						else
							show_text+="ARC Min: (not set, using default)\n"
						fi
						if [[ $arc_max_mb -gt 0 ]]; then
							show_text+="ARC Max: ${arc_max_mb} MB ($((arc_max_mb * 1024 * 1024)) bytes)\n"
						else
							show_text+="ARC Max: (not set, will use all RAM)\n"
						fi
						show_text+="Dirty Data Max: ${dirty_max_mb} MB ($((dirty_max_mb * 1024 * 1024)) bytes)\n"
						show_text+="TXG Timeout: ${txg_timeout} seconds\n\n"
						show_text+="Configuration file: ${config_file}\n\n"
						if [[ -f "$config_file" ]]; then
							show_text+="Current file contents:\n\n"
							# Append file contents, converting actual newlines to \n escape sequences
							local file_contents
							file_contents=$(cat "$config_file" 2>/dev/null)
							if [[ -n "$file_contents" ]]; then
								while IFS= read -r line; do
									show_text+="${line}\\n"
								done <<< "$file_contents"
							fi
						else
							show_text+="(No custom configuration file yet)"
						fi
						dialog_msgbox "Current ZFS Configuration" "$show_text" 22 80
						;;
				esac
			done
			;;
		"${commands[4]}") # scan
			# Check if ZFS is installed
			if ! pkg_installed zfsutils-linux; then
				return 1
			fi

			# Check if ZFS module is loaded
			if ! lsmod | grep -q "^zfs "; then
				modprobe zfs 2>/dev/null || return 1
			fi

			# Get list of pools that can be imported
			pool_list=$(zpool import 2>/dev/null)

			if [[ -z "$pool_list" ]]; then
				return 1
			fi

			# Parse pool list to extract pool names and info
			declare -A pool_altroot  # Store original altroot for each pool
			pools=()
			current_pool=""
			while IFS= read -r line; do
				# Lines starting with "pool:" indicate pool names
				if [[ "$line" =~ ^[[:space:]]*pool:[[:space:]]+(.+)$ ]]; then
					current_pool="${BASH_REMATCH[1]}"
					pools+=("$current_pool")
					pool_altroot["$current_pool"]=""
				# Extract altroot if present
				elif [[ "$line" =~ ^[[:space:]]*altroot:[[:space:]]+(.+)$ ]]; then
					altroot_value="${BASH_REMATCH[1]}"
					# Clean up the altroot value
					altroot_value=$(echo "$altroot_value" | sed 's/[[:space:]]*$//')
					pool_altroot["$current_pool"]="$altroot_value"
				fi
			done <<< "$pool_list"
			if [[ ${#pools[@]} -eq 0 ]]; then
				return 1
				else
				export POOLS=${#pools[@]}
			fi
			;;
		"${commands[5]}") # import

			if ! ${module_options["module_zfs,feature"]} ${commands[4]}; then
				return 1
			fi

			# Show pool selection menu
			# Build radiolist arguments - pool names as both tag and description
			local radiolist_args=()
			for pool in "${pools[@]}"; do
				radiolist_args+=("$pool" "$pool" "off")
			done

			local selected_pool
			selected_pool=$(dialog_radiolist "Import ZFS Pool" \
				"Select a ZFS pool to import:\n\nFound ${#pools[@]} pool(s) available for import." \
				18 80 8 -- "${radiolist_args[@]}")

			if [[ -z "$selected_pool" ]]; then
				return 0
			fi

			# Ask for alternate mount point (optional)
			local alt_root=""
			if dialog_yesno "Alternate Mount Point" \
				"Import pool '${selected_pool}' at an alternate mount point?\n\n- Yes: Specify custom mount path\n- No: Use pool's original mount points" "Yes" "No" 10 70 --defaultno; then
				# User wants custom mount point
				alt_root=$(dialog_inputbox "Alternate Mount Point" \
					"Enter alternate root mount point:\n\nExample: /mnt/pool\n\nPool datasets will be mounted under this path." \
					"/mnt/${selected_pool}" 12 70)

				if [[ -n "$alt_root" ]]; then
					# Validate the path
					if [[ ! "$alt_root" =~ ^/ ]]; then
						dialog_msgbox "Invalid Path" \
							"Mount point must be an absolute path (starting with /)." 8 50
						return 1
					fi

					# Create the directory if it doesn't exist
					if [[ ! -d "$alt_root" ]]; then
						mkdir -p "$alt_root" 2>/dev/null || {
							dialog_msgbox "Cannot Create Directory" \
								"Failed to create directory: ${alt_root}\n\nCheck permissions and try again." 9 60
							return 1
						}
					fi
				fi
			fi

			# selected_pool contains the pool name directly from the radiolist

			# Confirm import
			local confirm_msg="Import pool '${selected_pool}'?"
			if [[ -n "$alt_root" ]]; then
				confirm_msg+="\n\nMount point: ${alt_root}"
			else
				confirm_msg+="\n\nMount point: Pool's original mount points"
			fi
			confirm_msg+="\n\nNote: Force import (-f) will be used to ensure pool can be imported."

			if dialog_yesno "Confirm Import" "$confirm_msg"; then
				# Import the pool with -f flag to force import
				# Use altroot if specified and different from original
				local import_output
				local original_altroot="${pool_altroot[$selected_pool]}"

				# Check if user-provided altroot matches the pool's original
				if [[ -n "$alt_root" && "$alt_root" == "$original_altroot" ]]; then
					# Altroot matches original - import without altroot parameter
					dialog_msgbox "Using Original Mount Point" \
						"The specified mount point matches the pool's original altroot.\n\nImporting with original mount points." 10 70
					alt_root=""
				fi

				if [[ -n "$alt_root" ]]; then
					import_output=$(zpool import -f -o altroot="$alt_root" "$selected_pool" 2>&1)
				else
					import_output=$(zpool import -f "$selected_pool" 2>&1)
				fi

				if [[ $? -eq 0 ]]; then
					dialog_msgbox "Import Successful" \
						"Pool '${selected_pool}' imported successfully!" 8 50
				else
					dialog_msgbox "Import Failed" \
						"Failed to import pool '${selected_pool}'.\n\nError:\n${import_output}\n\nCheck 'dmesg' for more details." 14 70
					return 1
				fi
			fi
			;;
		"${commands[6]}") # kernel_max
			echo "${ZFS_KERNEL_MAX:-<not set>}"
		;;
		"${commands[7]}") # zfs_version
			if [[ -n "${ZFS_DKMS_VERSION}" ]]; then
				echo "v${ZFS_DKMS_VERSION}"
			else
				echo "<version not available>"
			fi
		;;
		"${commands[8]}") # zfs_installed_version
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null | head -1 | cut -d"-" -f2
			else
				echo "ZFS is not installed"
				return 1
			fi
		;;
		"${commands[9]}") # help
			show_module_help "module_zfs" "ZFS" "Configuration file: ${module_options["module_zfs,config_file"]}" "native"
		;;
		*) # default - show help
			${module_options["module_zfs,feature"]} ${commands[9]}
		;;
	esac
}
