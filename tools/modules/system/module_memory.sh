module_options+=(
	["module_memory,author"]="@igorpecovnik"
	["module_memory,maintainer"]="@igorpecovnik"
	["module_memory,feature"]="module_memory"
	["module_memory,desc"]="Memory management and tuning interface"
	["module_memory,example"]="install remove status tune help"
	["module_memory,port"]=""
	["module_memory,status"]="Active"
	["module_memory,arch"]="x86-64 arm64"
	["module_memory,doc_link"]="https://docs.armbian.com/User-Guide_Fine-Tuning/"
	["module_memory,group"]="System"
	["module_memory,config_file"]="/etc/default/armbian-zram-config"
	# Custom command help descriptions
	["module_memory,help_tune"]="Fine-tune ZRAM compression and system memory parameters"
)
#
# Module Memory Management
#
function module_memory () {
	local title="Memory Management"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_memory,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already enabled
			if module_memory status >/dev/null 2>&1; then
				echo "Memory management is already enabled."
				return 0
			fi

			# Check if zram-config package is installed
			if ! pkg_installed zram-config; then
				echo "Installing zram-config package..."
				pkg_install zram-config || {
					echo "Failed to install zram-config package."
					return 1
				}
			fi

			# Enable and start the service
			echo "Enabling ZRAM memory compression..."
			srv_enable armbian-zram-config
			srv_start armbian-zram-config

			# Set recommended swappiness for ZRAM
			if [[ ! -f /etc/sysctl.d/99-armbian-memory.conf ]]; then
				echo "vm.swappiness=100" > /etc/sysctl.d/99-armbian-memory.conf
				sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1
			fi

			echo "Memory management enabled successfully."
			echo "Use 'armbian-config' → 'System' → 'Storage' → 'Tune Memory' to configure settings."
		;;

		"${commands[1]}") # remove
			if ! module_memory status >/dev/null 2>&1; then
				echo "Memory management is not enabled."
				return 0
			fi

			# Stop and disable the service
			echo "Disabling ZRAM memory compression..."
			srv_stop armbian-zram-config
			srv_disable armbian-zram-config

			# Remove swappiness override created during install
			if [[ -f /etc/sysctl.d/99-armbian-memory.conf ]]; then
				rm -f /etc/sysctl.d/99-armbian-memory.conf
				sysctl --system >/dev/null 2>&1
			fi

			echo "Memory management disabled successfully."
		;;

		"${commands[2]}") # status
			if srv_active armbian-zram-config; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # tune
			# Check if memory management is enabled
			if ! module_memory status >/dev/null 2>&1; then
				dialog_msgbox "Memory Management Not Enabled" \
					"Memory management is not enabled.\n\nPlease enable it first:\nSystem → Storage → Memory" 11 70
				return 1
			fi

			local config_file="/etc/default/armbian-zram-config"
			local backup_file="${config_file}.bak"

			# Get current system memory in MB
			local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
			local total_mem_mb=$((total_mem_kb / 1024))
			local total_mem_gb=$((total_mem_mb / 1024))
			local cpu_cores=$(nproc 2>/dev/null || echo "4")
			local recommended_devices=$(( cpu_cores > 8 ? 8 : cpu_cores ))

			# Calculate recommended values based on system memory
			local recommended_zram_percentage=50
			local recommended_mem_limit=50
			local recommended_swappiness=100

			if [[ $total_mem_gb -ge 4 ]]; then
				recommended_zram_percentage=25
				recommended_mem_limit=25
				recommended_swappiness=80
			fi

			# Read current configuration
			local zram_enabled=$(grep "^ENABLED=" "$config_file" 2>/dev/null | cut -d= -f2)
			local zram_swap_enabled=$(grep "^SWAP=" "$config_file" 2>/dev/null | cut -d= -f2)
			local zram_percentage=$(grep "^ZRAM_PERCENTAGE=" "$config_file" 2>/dev/null | cut -d= -f2)
			local mem_limit_percentage=$(grep "^MEM_LIMIT_PERCENTAGE=" "$config_file" 2>/dev/null | cut -d= -f2)
			local max_devices=$(grep "^ZRAM_MAX_DEVICES=" "$config_file" 2>/dev/null | cut -d= -f2)
			local swap_algorithm=$(grep "^SWAP_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local ramlog_algorithm=$(grep "^RAMLOG_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local tmp_algorithm=$(grep "^TMP_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local tmp_size=$(grep "^TMP_SIZE=" "$config_file" 2>/dev/null | cut -d= -f2)

			# Set defaults if not found
			zram_enabled=${zram_enabled:-true}
			zram_swap_enabled=${zram_swap_enabled:-true}
			zram_percentage=${zram_percentage:-50}
			mem_limit_percentage=${mem_limit_percentage:-50}
			max_devices=${max_devices:-4}
			swap_algorithm=${swap_algorithm:-lzo}
			ramlog_algorithm=${ramlog_algorithm:-zstd}
			tmp_algorithm=${tmp_algorithm:-zstd}
			tmp_size=${tmp_size:-500M}

			# Get current swappiness
			local swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "100")

			# Main tuning menu
			while true; do
				# Build status string
				local status_string="Disabled"
				[[ "$zram_enabled" = "true" ]] && status_string="Enabled"

				# Build menu text
				local menu_text="System Memory: ${total_mem_mb} MB (${total_mem_gb} GB)\nCPU Cores: ${cpu_cores}\n\n"
				menu_text+="Current ZRAM Settings:\n"
				menu_text+="Status: ${status_string}\n"
				menu_text+="Swap Size: ${zram_percentage}% of RAM (= $((total_mem_mb * zram_percentage / 100)) MB)\n"
				menu_text+="Memory Limit: ${mem_limit_percentage}% of RAM\n"
				menu_text+="Max Devices: ${max_devices}\n"
				menu_text+="Compression Algorithm: ${swap_algorithm}\n\n"
				menu_text+="System Parameters:\n"
				menu_text+="Swappiness: ${swappiness}\n\n"
				menu_text+="Select a parameter to tune:"

				local choice=$(dialog_menu "Memory Management Tuning" "$menu_text" 22 80 6 \
					"1" "ZRAM Settings - Configure ZRAM compression parameters" \
					"2" "System Parameters - Configure swappiness" \
					"3" "Reset to Defaults - Restore recommended settings" \
					"4" "Show Current Configuration - Display current config file" \
					"5" "Save & Apply Configuration - Save changes and restart ZRAM service")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # ZRAM Settings submenu
						while true; do
							# Build status string for menu
							local zram_status="Disabled"
							[[ "$zram_enabled" = "true" ]] && zram_status="Enabled"

							local zram_choice=$(dialog_menu "ZRAM Settings" \
								"Configure ZRAM compression parameters\n\nSystem: ${total_mem_mb} MB RAM, ${cpu_cores} cores" 18 80 7 \
								"1" "Enable/Disable ZRAM - Current: ${zram_status}" \
								"2" "ZRAM Size Percentage - Current: ${zram_percentage}% of RAM (recommended: ${recommended_zram_percentage}%)" \
								"3" "Memory Limit Percentage - Current: ${mem_limit_percentage}% (recommended: ${recommended_mem_limit}%)" \
								"4" "Max Devices - Current: ${max_devices} (recommended: ${recommended_devices})" \
								"5" "Swap Compression Algorithm - Current: ${swap_algorithm}" \
								"6" "RAM & Temp Compression - RAMLOG: ${ramlog_algorithm}, /tmp: ${tmp_algorithm}, Size: ${tmp_size}" \
								"7" "Back to Main Menu - Return to main menu")

							[[ -z "$zram_choice" ]] && break

							case $zram_choice in
								1) # Toggle ZRAM enable/disable
									if [[ "$zram_enabled" = "true" ]]; then
										if dialog_yesno "Disable ZRAM" \
											"Disable ZRAM compression?\n\nThis will reduce available memory."; then
											zram_enabled=false
											zram_swap_enabled=false
										fi
									else
										if dialog_yesno "Enable ZRAM" \
											"Enable ZRAM compression?\n\nThis will improve performance on memory-constrained systems."; then
											zram_enabled=true
											zram_swap_enabled=true
										fi
									fi
									;;
								2) # ZRAM percentage
									local new_percentage=$(dialog_inputbox "ZRAM Size Percentage" \
										"Enter ZRAM size as percentage of RAM:\n\nRecommended: ${recommended_zram_percentage}%\nCurrent: ${zram_percentage}%\n\nRange: 10-300%\nHigher values = more swap space (compressed)" \
										"$zram_percentage" 14 70)

									if [[ -n "$new_percentage" ]]; then
										if [[ "$new_percentage" =~ ^[0-9]+$ ]] && [[ $new_percentage -ge 10 ]] && [[ $new_percentage -le 300 ]]; then
											zram_percentage=$new_percentage
										else
											dialog_msgbox "Invalid Value" \
												"ZRAM percentage must be between 10 and 300." 8 50
										fi
									fi
									;;
								3) # Memory limit percentage
									local new_limit=$(dialog_inputbox "Memory Limit Percentage" \
										"Enter memory limit as percentage of RAM:\n\nRecommended: ${recommended_mem_limit}%\nCurrent: ${mem_limit_percentage}%\n\nRange: 10-100%\nThis limits actual memory usage by ZRAM" \
										"$mem_limit_percentage" 14 70)

									if [[ -n "$new_limit" ]]; then
										if [[ "$new_limit" =~ ^[0-9]+$ ]] && [[ $new_limit -ge 10 ]] && [[ $new_limit -le 100 ]]; then
											mem_limit_percentage=$new_limit
										else
											dialog_msgbox "Invalid Value" \
												"Memory limit must be between 10 and 100." 8 50
										fi
									fi
									;;
								4) # Max devices
									local new_devices=$(dialog_inputbox "Max ZRAM Devices" \
										"Enter maximum number of ZRAM devices:\n\nRecommended: ${recommended_devices}\nCurrent: ${max_devices}\n\nRange: 1-8\nUsually set to number of CPU cores" \
										"$max_devices" 13 70)

									if [[ -n "$new_devices" ]]; then
										if [[ "$new_devices" =~ ^[0-9]+$ ]] && [[ $new_devices -ge 1 ]] && [[ $new_devices -le 8 ]]; then
											max_devices=$new_devices
										else
											dialog_msgbox "Invalid Value" \
												"Max devices must be between 1 and 8." 8 50
										fi
									fi
									;;
								5) # Swap compression algorithm
									# Set default selection
									local lzo_selected="off"
									local lzo_rle_selected="off"
									local lz4_selected="off"
									local zstd_selected="off"

									case "$swap_algorithm" in
										lzo) lzo_selected="on" ;;
										lzo-rle) lzo_rle_selected="on" ;;
										lz4) lz4_selected="on" ;;
										zstd) zstd_selected="on" ;;
										*) lzo_selected="on" ;;
									esac

									local new_algorithm=$(dialog_radiolist "Swap Compression Algorithm" \
										"Choose compression algorithm for ZRAM swap:\n\nlzo: Best for ARM (recommended)\nlz4: Faster, less compression\nzstd: Best compression, slower" 15 80 4 \
										"lzo" "LZO - Best for ARM (recommended)" "$lzo_selected" \
										"lz4" "LZ4 - Faster compression" "$lz4_selected" \
										"zstd" "ZSTD - Best compression ratio" "$zstd_selected")

									if [[ -n "$new_algorithm" ]]; then
										swap_algorithm=$new_algorithm
									fi
									;;
								6) # RAM & Temp compression
									local ramtmp_choice=$(dialog_menu "RAM & Temp Compression" \
										"Configure compression for RAM log and /tmp partitions" 14 70 3 \
										"1" "RAMLOG Algorithm - Current: ${ramlog_algorithm}" \
										"2" "/tmp Algorithm - Current: ${tmp_algorithm}" \
										"3" "/tmp Size - Current: ${tmp_size}")

									case $ramtmp_choice in
										1) # RAMLOG algorithm
											# Pre-calculate radiolist selection states
											local lzo_selected="off"
											local lz4_ram_selected="off"
											local zstd_ram_selected="off"

											case "$ramlog_algorithm" in
												lzo) lzo_selected="on" ;;
												lz4) lz4_ram_selected="on" ;;
												zstd) zstd_ram_selected="on" ;;
											esac

											local new_ramlog=$(dialog_radiolist "RAMLOG Compression" \
												"Choose compression algorithm for /var/log:" 13 70 3 \
												"lzo" "LZO - Fast compression" "$lzo_selected" \
												"lz4" "LZ4 - Faster compression" "$lz4_ram_selected" \
												"zstd" "ZSTD - Best compression" "$zstd_ram_selected")

											if [[ -n "$new_ramlog" ]]; then
												ramlog_algorithm=$new_ramlog
											fi
											;;
										2) # /tmp algorithm
											# Pre-calculate radiolist selection states
											local lzo_tmp_selected="off"
											local lz4_tmp_selected="off"
											local zstd_tmp_selected="off"

											case "$tmp_algorithm" in
												lzo) lzo_tmp_selected="on" ;;
												lz4) lz4_tmp_selected="on" ;;
												zstd) zstd_tmp_selected="on" ;;
											esac

											local tmp_choice_alg=$(dialog_radiolist "/tmp Compression" \
												"Choose compression algorithm for /tmp:" 13 70 3 \
												"lzo" "LZO - Fast compression" "$lzo_tmp_selected" \
												"lz4" "LZ4 - Faster compression" "$lz4_tmp_selected" \
												"zstd" "ZSTD - Best compression" "$zstd_tmp_selected")

											if [[ -n "$tmp_choice_alg" ]]; then
												tmp_algorithm=$tmp_choice_alg
											fi
											;;
										3) # /tmp size
											local new_tmp_size=$(dialog_inputbox "/tmp Size" \
												"Enter size for ZRAM-based /tmp partition:\n\nCurrent: ${tmp_size}\n\nExamples: 500M, 1G, 2G\nDefault: Half of RAM if not specified" \
												"$tmp_size" 13 70)

											if [[ -n "$new_tmp_size" ]]; then
												tmp_size=$new_tmp_size
											fi
											;;
									esac
									;;
							esac
						done
						;;

					2) # System parameters
						local recommendation=""
						if [[ $swappiness -lt 80 ]]; then
							recommendation="\n\nNote: For ZRAM systems, values 80-100 are recommended\nto ensure aggressive swapping to compressed RAM."
						fi

						local new_swappiness=$(dialog_inputbox "Swappiness" \
							"Enter vm.swappiness (1-100):\n\nCurrent: ${swappiness}${recommendation}\n\nLower = swap less (1)\nHigher = swap more to ZRAM (100)" \
							"$swappiness" 15 70)

						if [[ -n "$new_swappiness" ]]; then
							if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [[ $new_swappiness -ge 1 ]] && [[ $new_swappiness -le 100 ]]; then
								# Apply immediately
								echo "vm.swappiness=$new_swappiness" > /etc/sysctl.d/99-armbian-memory.conf
								sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1
								swappiness=$new_swappiness
								dialog_msgbox "Swappiness Updated" \
									"Swappiness set to ${swappiness}\n\nSetting saved to /etc/sysctl.d/99-armbian-memory.conf" 10 60
							else
								dialog_msgbox "Invalid Value" \
									"Swappiness must be between 1 and 100." 8 50
							fi
						fi
						;;

					3) # Reset to defaults
						if dialog_yesno "Reset to Defaults" \
							"Reset all parameters to Armbian recommended defaults?\n\nThis will restore optimal settings for your system."; then
							# Reset to recommended values
							zram_enabled=true
							zram_swap_enabled=true
							zram_percentage=$recommended_zram_percentage
							mem_limit_percentage=$recommended_mem_limit
							max_devices=$recommended_devices
							swap_algorithm="lzo"
							ramlog_algorithm="zstd"
							tmp_algorithm="zstd"
							tmp_size="500M"
							swappiness=$recommended_swappiness

							dialog_msgbox "Reset Complete" \
								"Parameters reset to recommended defaults.\n\nApply changes to take effect." 11 70
						fi
						;;

					4) # Show current configuration
						local show_text="Current ZRAM Configuration:\n\n"
						show_text+="ENABLED=${zram_enabled}\n"
						show_text+="SWAP=${zram_swap_enabled}\n"
						show_text+="ZRAM_PERCENTAGE=${zram_percentage}\n"
						show_text+="MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}\n"
						show_text+="ZRAM_MAX_DEVICES=${max_devices}\n"
						show_text+="SWAP_ALGORITHM=${swap_algorithm}\n"
						show_text+="RAMLOG_ALGORITHM=${ramlog_algorithm}\n"
						show_text+="TMP_ALGORITHM=${tmp_algorithm}\n"
						show_text+="TMP_SIZE=${tmp_size}\n\n"
						show_text+="System Parameters:\n"
						show_text+="vm.swappiness=${swappiness}\n\n"
						show_text+="Configuration file: ${config_file}\n\n"
						show_text+="Active swap devices:\n"

						# Get active swap info
						local swap_info=$(swapon --show 2>/dev/null)
						if [[ -n "$swap_info" ]]; then
							show_text+="$swap_info"
						else
							show_text+="(No swap devices active)"
						fi

						dialog_msgbox "Current Configuration" "$show_text" 20 75
						;;

					5) # Save & Apply
						local config_preview="The following settings will be saved to:\n${config_file}\n\n"
						config_preview+="ENABLED=${zram_enabled}\n"
						config_preview+="SWAP=${zram_swap_enabled}\n"
						config_preview+="ZRAM_PERCENTAGE=${zram_percentage}%\n"
						config_preview+="MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}%\n"
						config_preview+="ZRAM_MAX_DEVICES=${max_devices}\n"
						config_preview+="SWAP_ALGORITHM=${swap_algorithm}\n"
						config_preview+="RAMLOG_ALGORITHM=${ramlog_algorithm}\n"
						config_preview+="TMP_ALGORITHM=${tmp_algorithm}\n"
						config_preview+="TMP_SIZE=${tmp_size}\n\n"
						config_preview+="vm.swappiness=${swappiness}\n\n"
						config_preview+="Save and apply these settings?"

						if dialog_yesno "Save Configuration" "$config_preview"; then
							# Backup existing config
							if [[ -f "$config_file" ]]; then
								cp "$config_file" "$backup_file" || {
									dialog_msgbox "Backup Failed" "Failed to backup existing configuration.\n\nContinuing without backup."
								}
							fi

							# Write new configuration, preserving unknown keys
							local tmp_config
							tmp_config=$(mktemp)

							# Collect keys we manage
							declare -A managed_keys=(
								[ENABLED]="${zram_enabled}"
								[SWAP]="${zram_swap_enabled}"
								[ZRAM_PERCENTAGE]="${zram_percentage}"
								[MEM_LIMIT_PERCENTAGE]="${mem_limit_percentage}"
								[ZRAM_MAX_DEVICES]="${max_devices}"
								[SWAP_ALGORITHM]="${swap_algorithm}"
								[RAMLOG_ALGORITHM]="${ramlog_algorithm}"
								[TMP_ALGORITHM]="${tmp_algorithm}"
								[TMP_SIZE]="${tmp_size}"
							)

							# If existing config, update known keys and preserve the rest
							if [[ -f "$config_file" ]]; then
								while IFS= read -r line; do
									local key="${line%%=*}"
									if [[ -n "${managed_keys[$key]+x}" ]]; then
										echo "${key}=${managed_keys[$key]}"
										unset "managed_keys[$key]"
									else
										echo "$line"
									fi
								done < "$config_file" > "$tmp_config"
								# Append any managed keys not already in file
								for key in "${!managed_keys[@]}"; do
									echo "${key}=${managed_keys[$key]}" >> "$tmp_config"
								done
							else
								{
									echo "# ZRAM Configuration - Generated by Armbian config"
									echo "# Generated on $(date)"
									echo ""
									echo "ENABLED=${zram_enabled}"
									echo "SWAP=${zram_swap_enabled}"
									echo "ZRAM_PERCENTAGE=${zram_percentage}"
									echo "MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}"
									echo "ZRAM_MAX_DEVICES=${max_devices}"
									echo "SWAP_ALGORITHM=${swap_algorithm}"
									echo "RAMLOG_ALGORITHM=${ramlog_algorithm}"
									echo "TMP_ALGORITHM=${tmp_algorithm}"
									echo "TMP_SIZE=${tmp_size}"
								} > "$tmp_config"
							fi

							mv "$tmp_config" "$config_file"

							# Persist swappiness
							echo "vm.swappiness=${swappiness}" > /etc/sysctl.d/99-armbian-memory.conf
							sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1

							# Notify about backup
							if [[ -f "$backup_file" ]]; then
								dialog_msgbox "Configuration Saved" \
									"Configuration saved successfully.\n\nPrevious configuration backed up to:\n${backup_file}\n\nYou can restore it manually if needed." 12 70
							fi

							# Restart service to apply changes
							if dialog_yesno "Apply Changes" \
								"Configuration saved.\n\nRestart ZRAM service to apply changes?\n\nThis will briefly stop swap operations."; then
								systemctl restart armbian-zram-config

								if systemctl is-active --quiet armbian-zram-config; then
									dialog_msgbox "Success" \
										"ZRAM service restarted successfully.\n\nNew settings are now active." 11 70
								else
									dialog_msgbox "Warning" \
										"ZRAM service may not have restarted properly.\n\nCheck 'systemctl status armbian-zram-config'" 11 70
								fi
							fi

							break
						fi
						;;
				esac
			done
		;;

		"${commands[4]}") # help
			show_module_help
		;;

		*)
			show_module_help
		;;
	esac
}
