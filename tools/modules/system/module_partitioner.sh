declare -A module_options
module_options+=(
	["module_partitioner,author"]="@igorpecovnik"
	["module_partitioner,maintainer"]="@igorpecovnik"
	["module_partitioner,feature"]="module_partitioner"
	["module_partitioner,example"]="new run create delete show getroot autoinstall help"
	["module_partitioner,desc"]="Partitioner manager TUI"
	["module_partitioner,status"]="review"
	["module_partitioner,doc_link"]="https://docs.armbian.com"
	["module_partitioner,group"]="System"
	["module_partitioner,port"]=""
	["module_partitioner,arch"]=""
)

function module_partitioner() {
	local title="Partitioner"
	local condition=$(which "$title" 2>/dev/null)

	# Read boot loader functions
	[[ -f /usr/lib/u-boot/platform_install.sh ]] && source /usr/lib/u-boot/platform_install.sh

	# Start mtdcheck with probable MTD block device partitions:
	mtdcheck=$(grep 'mtdblock' /proc/partitions | awk '{print $NF}' | xargs)
	# Append mtdcheck with probable MTD char devices filtered for partition name(s)
	# containing "spl" or "boot" case insensitive,
	# since we are currently interested in MTD partitions for boot flashing only.
	# Note: The following statement will add matching MTD char device names
	#       combined with partition name (separated from devicename by a :colon:):
	#       mtd0:partition0_name mtd1:partition1_name ... mtdN:partitionN_name
	[[ -f /proc/mtd ]] && mtdcheck="$mtdcheck${mtdcheck:+ }$(grep -i -E '^mtd[0-9]+:.*(spl|boot).*' /proc/mtd | awk '{print $1$NF}' | sed 's/\"//g' | xargs)"

	apt -y install ntfs-3g bc

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_partitioner,example"]}"

	case "$1" in
		"${commands[0]}")
			echo "Install to partition $2"
			exit
		;;
		"${commands[1]}")

			while true; do

				# get all available targets
				${module_options["module_partitioner,feature"]} ${commands[4]}

				list=()
				periodic=1
				while IFS== read key value; do
					case "$key" in
						"name") name="$value" ;;
						"size") size=$(printf "%14s" "$value") ;;
						"type") type=$(printf "%4s" "$value") ;;
						"fsused") fsused="$value" ;;
						"fstype") fstype="$value" ;;
						"mountpoint") mountpoint="$value" ;;
					esac
					if [ "$(($periodic % 6))" -eq 0 ]; then
						if [[ "$type" == "disk" ]]; then
							# recognize devices features
							driveinfo=$(udevadm info --query=all --name=$name | grep 'ID_MODEL=' | cut -d"=" -f2 | sed "s/_/ /g")
							drivebus=$(udevadm info --query=all --name=$name | grep 'ID_BUS=' | cut -d"=" -f2 | sed "s/_/ /g")
							[[ $name == *mtdb* ]] && driveinfo="SPI flash"
							[[ $name == *nvme* ]] && driveinfo="M2 NVME solid state drive $driveinfo"
							# if smartmontools are installed, lets query more info
							if [[ $name == *nvme* ]] && command -v smartctl >/dev/null; then
								mapfile -t array < <(smartctl -ija $name | jq -r '
								.model_name,
								.nvme_smart_health_information_log.data_units_written,
								.temperature.current'
								)
								tbw=$(echo ${array[1]} | awk '{ printf "%.0f\n", $1*500/1024/1024/1024; }')""
								temperature=$(echo ${array[2]})"℃"
								driveinfo="${array[0]} | TBW: ${tbw} | Temperature: ${temperature}"
							fi
							[[ $name == *mmc* ]] && driveinfo="eMMC or SD card"
							[[ $name == *sd* && $drivebus == usb ]] && driveinfo="USB storage $driveinfo"
							list+=("${name}" "$(printf "%-30s%12s" $name $size)" "$driveinfo")
						fi # type is disk
					fi
					periodic=$(($periodic + 1))
				done <<< "$devices"

				list_length=$((${#list[@]} / 3))
				selected_disk=$(dialog \
				--notags \
				--cancel-label "Cancel" \
				--ok-label "Install" \
				--extra-button \
				--extra-label "Advanced" \
				--erase-on-exit \
				--item-help \
				--title "Select destination drive" \
				--menu "\n Storage device                        Size" \
				$((${list_length} + 8)) 48 $((${list_length} + 1)) \
				"${list[@]}" 3>&1 1>&2 2>&3)
				exitstatus=$?

				case "$exitstatus" in
					0) ${module_options["module_partitioner,feature"]} ${commands[5]} # auto install
						;;
					1) break
						;;
					3)
						# drive partitioning
						devices=$(
							lsblk -Alnp -io NAME,SIZE,FSUSED,TYPE,FSTYPE,MOUNTPOINT -e 252 --json \
							| jq --arg selected_disk "$selected_disk" '.blockdevices[]?
							| select((.name | test ($selected_disk))
							and (.name | test ("mtdblock0|nvme|mmcblk|sd"))
							and (.name | test ("boot") | not ))' \
							| jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]'
						)
						list=()
						periodic=1
						while IFS== read key value; do
								case "$key" in
									"name") name="$value" ;;
									"size") size=$(printf "%14s" "$value") ;;
									"type") type=$(printf "%4s" "$value") ;;
									"fsused") fsused="$value" ;;
									"fstype") fstype="$value" ;;
									"mountpoint") mountpoint="$value" ;;
								esac
								if [ "$(($periodic % 6))" -eq 0 ]; then
									if [[ "$type" == "part" ]]; then
										#echo "$periodic $name $size $type $fsused $fstype $mountpoint"
										driveinfo=$(udevadm info --query=all --name=$name | grep 'ID_MODEL=' | cut -d"=" -f2 | sed "s/_/ /g")
										drivebus=$(udevadm info --query=all --name=$name | grep 'ID_BUS=' | cut -d"=" -f2 | sed "s/_/ /g")
										[[ $fstype == null ]] && fstype=""
										[[ $fsused == null ]] && fsused=""
										[[ $name == *mtdb* ]] && driveinfo="SPI flash"
										[[ $name == *nvme* ]] && driveinfo="M2 NVME solid state drive $driveinfo"
										[[ $name == *mmc* ]] && driveinfo="eMMC or SD card"
										[[ $name == *sd* && $drivebus == usb ]] && driveinfo="USB storage $driveinfo"
										list+=("${name}" "$(printf "%-10s%14s%9s%9s" ${name} ${fstype} ${size} ${fsused})" "$driveinfo")
									fi
								fi
								periodic=$(($periodic + 1))
						done <<< "$devices"
						;;
					esac
				list_length=$((${#list[@]} / 3))
				partitioner=$(dialog \
				--notags \
				--cancel-label "Cancel" \
				--ok-label "Install" \
				--erase-on-exit \
				--extra-button \
				--item-help \
				--extra-label "Manage" \
				--title "Select or manage partitions" \
				--menu "\n Partition        FS type     Size     Used" \
				$((${list_length} + 8)) 48 $((${list_length} + 1)) \
				"${list[@]}" 3>&1 1>&2 2>&3)
				exitstatus=$?
				case "$exitstatus" in
					*) ${module_options["module_partitioner,feature"]} ${commands[${exitstatus}]} $partitioner ;;
					1) break ;;
				esac
			done
		;;
		"${commands[2]}")
			echo "Select $3"
			exit
		;;
		"${commands[3]}")
			# get additional info from partition
			local size=$(lsblk -Alnbp -io SIZE $2 | xargs -I {} echo "scale=0;{}/1024/1024/1024" | bc -l)
			local fstype=$(lsblk -Alnbp -io FSTYPE $2)
			local minimal=$(ntfsresize --info $2 -m | tail -1 | grep -Eo '[0-9]{1,10}' | xargs -I {} echo "scale=0;{}/1024" | bc -l)
			while true; do
				shrinkedsize=$(dialog --title "Shrinking $fstype partition $2" \
				--inputbox "\nValid size between ${minimal}-${size} GB" 9 50 "$(( minimal + size / 2 ))" 3>&1 1>&2 2>&3)
				exitstatus=$?
				if [[ $shrinkedsize -ge $minimal ]]; then
					break
				fi
			done
			ntfsresize --no-action --size "${shrinkedsize}G" $2 >/dev/null
			if [[ $exitstatus -ne 1 && $? -eq 0 ]]; then
				ntfsresize -f --size "${shrinkedsize}G" $2
			fi
			read
			# Removal logic here
		;;
		"${commands[4]}")
			#recognize_root
			root_uuid=$(sed -e 's/^.*root=//' -e 's/ .*$//' < /proc/cmdline)
			root_partition=$(blkid | tr -d '":' | grep "${root_uuid}" | awk '{print $1}')
			root_partition_name=$(echo $root_partition | sed 's/\/dev\///g')
			root_partition_device_name=$(lsblk -ndo pkname $root_partition)
			root_partition_device=/dev/$root_partition_device_name
			# list all devices except rootfs
			devices=$(
				lsblk -Alnp -io NAME,SIZE,FSUSED,TYPE,FSTYPE,MOUNTPOINT -e 252 --json \
				| jq --arg root_partition_device "$root_partition_device" '.blockdevices[]?
				| select((.name | test ($root_partition_device) | not)
				and (.name | test ("mtdblock0|nvme|mmcblk|sd"))
				and (.name | test ("boot|mtdb") | not ))' \
				| jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]'
			)
		;;
		"${commands[6]}")

				if [[ $(type -t write_uboot_platform_mtd) == function ]]; then
					dialog --title "$title" --backtitle "$backtitle" --yesno \
						"Do you want to write the bootloader to MTD Flash?\n\nIt is required if you have not done it before or if you have some non-Armbian bootloader in this flash." 8 60

					if [[ $? -eq 0 ]]; then
						write_uboot_to_mtd_flash "$DIR" "$mtdcheck"
					fi
				fi

			echo "Delete $2"
			read
			# Removal logic here
		;;
		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_partitioner,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_partitioner,example"]}"
			echo "Available commands:"
			echo -e "\trun\t- Run $title."
			echo
		;;
		*)
			${module_options["module_partitioner,feature"]} ${commands[7]}
		;;
	esac
	}

# uncomment to test the module
module_partitioner "$1"




