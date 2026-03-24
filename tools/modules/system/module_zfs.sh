module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,maintainer"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install ZFS filesystem support"
	["module_zfs,example"]="install remove status tune kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
	["module_zfs,doc_link"]="https://openzfs.github.io/openzfs-docs/"
	["module_zfs,group"]="System"
	["module_zfs,config_file"]="/etc/modprobe.d/zfs.conf"
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
			local temp_file="/tmp/zfs_tuning_$$.txt"

			# Get current system memory in MB
			local total_mem_mb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))
			local total_mem_gb=$((total_mem_mb / 1024))

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

			# Get current compression
			local current_compression=$(cat /sys/module/zfs/parameters/zfs_compression 2>/dev/null || echo "zstd")

			# Create tuning menu
			while true; do
				local menu_text="System Memory: ${total_mem_mb} MB (${total_mem_gb} GB)\n\n"
				menu_text+="Current Settings:\n"
				menu_text+="ARC Min: ${arc_min_mb} MB\n"
				menu_text+="ARC Max: ${arc_max_display}\n"
				menu_text+="Dirty Data Max: ${dirty_max_mb} MB\n"
				menu_text+="TXG Timeout: ${txg_timeout} sec\n"
				menu_text+="Compression: ${current_compression}\n\n"
				menu_text+="Select a parameter to tune:"

				local choice=$(dialog_menu "ZFS Performance Tuning" "$menu_text" 22 70 8 \
					"1" "ARC Cache Size (zfs_arc_min/max)" \
					"2" "Dirty Data Limits (zfs_dirty_data_max)" \
					"3" "TXG Timeout (zfs_txg_timeout)" \
					"4" "Compression (zfs_compression)" \
					"5" "Advanced Settings" \
					"6" "Reset to Defaults" \
					"7" "Save & Apply Configuration" \
					"8" "Show Current Configuration")

				[[ -z "$choice" ]] && break

				case $choice in
					1)
						# ARC Cache Size Tuning
						dialog_msgbox "ARC Cache Size Tuning" \
							"The ARC (Adaptive Replacement Cache) is ZFS's intelligent cache.\n\nRecommended Settings:\n- zfs_arc_min: 1/8 of RAM (minimum cache)\n- zfs_arc_max: 1/2 of RAM (maximum cache)\n\nCurrent: ${arc_min_mb} MB / ${arc_max_display}"

						local recommended_arc_min=$((total_mem_mb / 8))
						local recommended_arc_max=$((total_mem_mb / 2))

						local new_arc_min_mb=$(dialog_inputbox "ARC Min Size" \
							"Enter ARC Min Size in MB:\n(Recommended: ${recommended_arc_min} MB)\nCurrent: ${arc_min_mb} MB" \
							12 60 "${arc_min_mb}")
						[[ -z "$new_arc_min_mb" ]] && continue

						local new_arc_max_mb=$(dialog_inputbox "ARC Max Size" \
							"Enter ARC Max Size in MB:\n(Recommended: ${recommended_arc_max} MB, 0 = all RAM)\nCurrent: ${arc_max_mb} MB" \
							12 60 "${arc_max_mb}")
						[[ -z "$new_arc_max_mb" ]] && continue

						# Validate
						if [[ $new_arc_min_mb -gt $new_arc_max_mb ]] && [[ $new_arc_max_mb -ne 0 ]]; then
							dialog_msgbox "Invalid Values" "ARC Min cannot be greater than ARC Max!"
							continue
						fi

						arc_min_mb=$new_arc_min_mb
						arc_max_mb=$new_arc_max_mb

						dialog_msgbox "Values Updated" "ARC settings updated.\n\nApply changes to take effect."
						;;

					2)
						# Dirty Data Limits
						local recommended_dirty=$((total_mem_mb / 25))
						dialog_msgbox "Dirty Data Limits" \
							"Dirty data is data that has been changed but not yet written to disk.\n\nRecommended: ${recommended_dirty} MB (4% of RAM)\n\nHigher values = better performance but more data loss risk on power failure."

						local new_dirty_max_mb=$(dialog_inputbox "Dirty Data Max" \
							"Enter Dirty Data Max in MB:\n(Recommended: ${recommended_dirty} MB)\nCurrent: ${dirty_max_mb} MB" \
							10 60 "${dirty_max_mb}")
						[[ -z "$new_dirty_max_mb" ]] && continue

						dirty_max_mb=$new_dirty_max_mb

						dialog_msgbox "Value Updated" "Dirty data max updated.\n\nApply changes to take effect."
						;;

					3)
						# TXG Timeout
						dialog_msgbox "TXG (Transaction Group) Timeout" \
							"Controls how often ZFS writes dirty data to disk.\n\nDefault: 5 seconds\n\nLower values = more frequent writes, better data safety, lower performance\nHigher values = less frequent writes, better performance, more data loss risk"

						local new_txg_timeout=$(dialog_inputbox "TXG Timeout" \
							"Enter TXG Timeout in seconds:\n(Range: 1-30, Recommended: 5)\nCurrent: ${txg_timeout} sec" \
							11 60 "${txg_timeout}")
						[[ -z "$new_txg_timeout" ]] && continue

						# Validate
						if [[ $new_txg_timeout -lt 1 ]] || [[ $new_txg_timeout -gt 30 ]]; then
							dialog_msgbox "Invalid Value" "TXG timeout must be between 1 and 30 seconds!"
							continue
						fi

						txg_timeout=$new_txg_timeout

						dialog_msgbox "Value Updated" "TXG timeout updated.\n\nApply changes to take effect."
						;;

					4)
						# Compression
						dialog_msgbox "ZFS Compression" \
							"Compression is transparent and CPU-efficient.\n\nOptions:\n- lz4: Fast, good compression (recommended)\n- zstd: Better compression, slightly slower\n- gzip: Max compression, slowest\n- off: Disable compression\n\nCurrent: ${current_compression}\n\nNote: This is the default for new datasets only."

						local compression_choice=$(dialog_radiolist "Select Default Compression Algorithm" \
							"Choose the default compression algorithm for new ZFS datasets:" 15 70 4 \
							"lz4" "LZ4 - Fast & efficient (recommended)" "lz4" \
							"zstd" "ZSTD - Better compression" "" \
							"gzip" "GZIP - Maximum compression" "" \
							"off" "Disable compression" "")

						[[ -z "$compression_choice" ]] && continue

						# Update compression preference
						echo "options zfs zfs_compression=${compression_choice}" > "$temp_file"
						current_compression=$compression_choice

						dialog_msgbox "Compression Updated" "Default compression set to: ${compression_choice}\n\nApply changes to take effect."
						;;

					5)
						# Advanced Settings
						local adv_choice=$(dialog_menu "Advanced ZFS Tuning" \
							"WARNING: Only change these if you know what you're doing!" 18 70 6 \
							"1" "Prefetch Settings" \
							"2" "Sync Settings" \
							"3" "VDEV Settings" \
							"4" "Debug & Logging" \
							"5" "View Current sysctl settings" \
							"6" "Back")

						[[ -z "$adv_choice" ]] && continue

						case $adv_choice in
							1)
								local prefetch_current=$(cat /sys/module/zfs/parameters/zfs_prefetch_disable 2>/dev/null || echo "0")
								local prefetch_status="Enabled"
								[[ $prefetch_current -eq 1 ]] && prefetch_status="Disabled"

								if dialog_yesno "Disable ZFS Prefetch?" \
									"Current: ${prefetch_status}\n\nDisabling can help with certain workloads but usually hurts performance.\n\nDisable prefetch?"; then
									dialog_msgbox "Info" "Prefetch will be disabled.\n\nSave configuration to apply."
								else
									dialog_msgbox "Info" "Prefetch will remain enabled.\n\nSave configuration to apply."
								fi
								;;
							2)
								dialog_msgbox "Sync Settings" \
									"zfs_sync_taskq_batch_pct controls sync task batching.\n\nDefault: Auto-tuned\n\nIncreasing can improve sync-heavy workloads (databases)."
								;;
							3)
								dialog_msgbox "VDEV Settings" \
									"zfs_vdev_* parameters control VDEV behavior.\n\nMost are auto-tuned. Manual tuning rarely needed."
								;;
							4)
								dialog_msgbox "Debug & Logging" \
									"zfs_deadman_enabled, zfs_flags, etc.\n\nOnly enable for debugging purposes.\n\nWARNING: Can significantly impact performance."
								;;
							5)
								if [[ -d /sys/module/zfs/parameters ]]; then
									local params_text="Current ZFS module parameters:\n\n"
									for param in /sys/module/zfs/parameters/*; do
										local name=$(basename "$param")
										local value=$(cat "$param" 2>/dev/null || echo "N/A")
										params_text+="${name} = ${value}\n"
									done
									dialog_msgbox "ZFS Parameters" "$params_text"
								else
									dialog_msgbox "Not Available" "ZFS module parameters not available."
								fi
								;;
						esac
						;;

					6)
						# Reset to defaults
						if dialog_yesno "Reset to Defaults" \
							"Reset all ZFS parameters to defaults?\n\nThis will remove any custom tuning."; then
							> "$temp_file"
							arc_min_mb=0
							arc_max_mb=0
							dirty_max_mb=$((total_mem_mb / 25))
							txg_timeout=5
							current_compression="zstd"
							dialog_msgbox "Reset Complete" "Parameters reset to defaults.\n\nApply changes to take effect."
						fi
						;;

					7)
						# Save & Apply
						local config_preview="The following settings will be saved to:\n${config_file}\n\n"
						config_preview+="zfs_arc_min=$((arc_min_mb * 1024 * 1024))\n"
						config_preview+="zfs_arc_max=$((arc_max_mb * 1024 * 1024))\n"
						config_preview+="zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024))\n"
						config_preview+="zfs_txg_timeout=${txg_timeout}\n"
						if [[ -f "$temp_file" ]] && grep -q "zfs_compression" "$temp_file"; then
							config_preview+="zfs_compression=${current_compression}\n"
						fi

						dialog_msgbox "Saving ZFS Configuration" "$config_preview"

						# Build configuration file
						{
							echo "# ZFS Performance Tuning Configuration"
							echo "# Generated by Armbian config on $(date)"
							echo ""
							echo "# ARC Cache Settings"
							if [[ $arc_max_mb -gt 0 ]]; then
								echo "options zfs zfs_arc_min=$((arc_min_mb * 1024 * 1024))"
								echo "options zfs zfs_arc_max=$((arc_max_mb * 1024 * 1024))"
							else
								echo "# options zfs zfs_arc_min=$((arc_min_mb * 1024 * 1024))"
								echo "# options zfs zfs_arc_max=0  # 0 = use all RAM"
							fi
							echo ""
							echo "# Dirty Data Settings"
							echo "options zfs zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024))"
							echo ""
							echo "# Transaction Group Settings"
							echo "options zfs zfs_txg_timeout=${txg_timeout}"
							echo ""
							# Append compression if set
							if [[ -f "$temp_file" ]] && grep -q "zfs_compression" "$temp_file"; then
								cat "$temp_file"
							fi
						} > "$config_file"

						# Apply changes
						dialog_msgbox "Applying Changes" \
							"Configuration saved.\n\nTo apply changes, ZFS module must be reloaded.\n\nThis requires either:\n1. Reboot\n2. Manual: rmmod zfs && modprobe zfs\n\nWARNING: Unloading ZFS requires unmounting all ZFS filesystems first."

						if dialog_yesno "Reload ZFS Module" \
							"WARNING: All ZFS filesystems must be unmounted first!\n\nContinue?"; then
							if zfs list 2>/dev/null | grep -q "^"; then
								dialog_msgbox "Cannot Reload" \
									"ZFS filesystems are mounted.\n\nPlease unmount all ZFS filesystems first:\nzfs umount -a"
							else
								rmmod zfs 2>/dev/null && modprobe zfs
								if lsmod | grep -q "^zfs "; then
									dialog_msgbox "Success" \
										"ZFS module reloaded successfully.\n\nNew settings are now active."
								else
									dialog_msgbox "Failed" \
										"Failed to reload ZFS module.\n\nCheck 'dmesg' for errors."
								fi
							fi
						fi

						rm -f "$temp_file"
						break
						;;

					8)
						# Show current configuration
						local show_text="Current ZFS Configuration:\n\n"
						show_text+="ARC Min: ${arc_min_mb} MB ($((arc_min_mb * 1024 * 1024)) bytes)\n"
						show_text+="ARC Max: ${arc_max_mb} MB ($((arc_max_mb * 1024 * 1024)) bytes)\n"
						show_text+="Dirty Data Max: ${dirty_max_mb} MB ($((dirty_max_mb * 1024 * 1024)) bytes)\n"
						show_text+="TXG Timeout: ${txg_timeout} seconds\n"
						show_text+="Compression: ${current_compression}\n\n"
						show_text+="Configuration file: ${config_file}\n\n"
						if [[ -f "$config_file" ]]; then
							show_text+="Current file contents:\n\n"
							show_text+=$(cat "$config_file" 2>/dev/null || echo "Cannot read file")
						else
							show_text+="(No custom configuration file yet)"
						fi
						dialog_msgbox "Current ZFS Configuration" "$show_text"
						;;
				esac
			done

			rm -f "$temp_file"
			;;
		"${commands[4]}")
			echo "${ZFS_KERNEL_MAX:-<not set>}"
		;;
		"${commands[5]}")
			if [[ -n "${ZFS_DKMS_VERSION}" ]]; then
				echo "v${ZFS_DKMS_VERSION}"
			else
				echo "<version not available>"
			fi
		;;
		"${commands[6]}")
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null | head -1 | cut -d"-" -f2
			else
				echo "ZFS is not installed"
				return 1
			fi
		;;
		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_zfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zfs,example"]}"
			echo "Available commands:"
			echo -e "  install              - Install $title."
			echo -e "  remove               - Remove $title."
			echo -e "  status               - Installation status $title."
			echo -e "  tune                 - Fine-tune ZFS performance parameters (ARC, dirty data, TXG, etc.)"
			echo -e "  kernel_max           - Determine maximum version of kernel to support $title."
			echo -e "  zfs_version          - Gets $title version from DKMS."
			echo -e "  zfs_installed_version - Read $title module info."
			echo
		;;
		*)
			${module_options["module_zfs,feature"]} ${commands[7]}
		;;
	esac
}
