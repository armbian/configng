module_options+=(
	["module_armbian_kvmtest,author"]="@igorpecovnik"
	["module_armbian_kvmtest,feature"]="module_armbian_kvmtest"
	["module_armbian_kvmtest,desc"]="Deploy Armbian KVM instances"
	["module_armbian_kvmtest,example"]="install remove save drop restore list help"
	["module_armbian_kvmtest,port"]=""
	["module_armbian_kvmtest,status"]="Active"
	["module_armbian_kvmtest,arch"]="x86-64"
)
#
# Module deploy Armbian QEMU KVM instances
# module_armbian_kvmtest - Manage the lifecycle of Armbian KVM virtual machines.
#
# This function deploys, configures, and manages Armbian-based KVM instances. It supports a suite of
# commands (install, remove, save, drop, restore, list, help) to handle the entire virtual machine lifecycle.
# Depending on the command, the function performs operations such as downloading cloud-based Armbian images,
# resizing and mounting VM disk images, customizing network settings, and executing provisioning scripts.
#
# Globals:
#   module_options - An associative array with module metadata (author, features, command examples, etc.).
#
# Arguments:
#   The first argument specifies the command to execute (e.g., install, remove, save, drop, restore, list, help).
#   Additional arguments should be provided as key=value pairs to customize the operation. Supported keys include:
#     instances     - Number of VM instances to deploy (default: "01").
#     provisioning  - Path to a provisioning script to be run on the first boot of each VM.
#     firstconfig   - File with initial configuration commands for the VMs.
#     startingip    - Starting IP address (with underscores replacing dots, e.g., 192_168_1_100).
#     gateway       - Gateway IP address (with underscores replacing dots, e.g., 192_168_1_1).
#     keyword       - Image filter keyword; supports comma-separated values (converted internally to a regex).
#     arch          - Architecture of the VM image (default: "x86").
#     kvmprefix     - Prefix used for naming VMs (default: "kvmtest").
#     network       - Network configuration (default: "default", or set to "bridge=[bridge]" if a bridge is specified).
#     bridge        - Overrides the default network by specifying a network bridge.
#     memory        - Memory allocation for each VM, in MB (default: "3072").
#     vcpus         - Number of virtual CPUs allocated per VM (default: "2").
#     size          - Additional disk space in GB to allocate to each VM (default: "10").
#
# Outputs:
#   The function prints deployment progress, image URLs (when listing), and usage instructions to STDOUT.
#
# Returns:
#   This function does not return a value; it executes commands with side effects.
#
# Example:
#   To deploy three VMs using a custom provisioning script, increased memory, and specific IP settings:
#     module_armbian_kvmtest install instances=03 memory=4096 vcpus=4 startingip=192_168_1_100 gateway=192_168_1_1 provisioning=/path/to/script keyword=Focal
#
#   To remove all deployed VMs:
#     module_armbian_kvmtest remove
function module_armbian_kvmtest () {

	local title="kvmtest"
	local condition=$(which "$title" 2>/dev/null)

	# read additional parameters from command line
	local parameter
	declare -A params
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for selected in ${parameter[@]}; do
			IFS='=' read -r -a split <<< "${selected}"
			# Only accept known parameters for security
			case "${split[0]}" in
				instances|provisioning|firstconfig|startingip|gateway|keyword|arch|kvmprefix|network|bridge|memory|vcpus|size|destination|channel)
					params["${split[0]}"]="${split[1]}"
					;;
			esac
		done
	done

	# Extract parameters from array
	instances="${params[instances]:-}"
	provisioning="${params[provisioning]:-}"
	firstconfig="${params[firstconfig]:-}"
	startingip="${params[startingip]:-}"
	gateway="${params[gateway]:-}"
	keyword="${params[keyword]:-}"
	arch="${params[arch]:-}"
	kvmprefix="${params[kvmprefix]:-}"
	network="${params[network]:-}"
	bridge="${params[bridge]:-}"
	memory="${params[memory]:-}"
	vcpus="${params[vcpus]:-}"
	size="${params[size]:-}"
	destination="${params[destination]:-}"
	channel="${params[channel]:-nightly}"

	# if we provide startingip and gateway, set network
	if [[ -n "${startingip}" && -n "${gateway}" ]]; then
		PRESET_NET_CHANGE_DEFAULTS="1"
	fi

	local startingip=$(echo "${startingip:-}" | sed "s/_/./g")
	local gateway=$(echo "${gateway:-}" | sed "s/_/./g")

	local arch="${arch:-x86}" # VM architecture
	local network="${network:-default}"
	if [[ -n "${bridge}" ]]; then network="bridge=${bridge}"; fi
	local instances="${instances:-01}" # number of instances
	local size="${size:-10}" # additional disk space in GB
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local memory="${memory:-3072}"
	local vcpus="${vcpus:-2}"
	local startingip="${startingip:-10.0.60.60}"
	local gateway="${gateway:-10.0.60.1}"
	local keyword=$(echo "${keyword:-}" | sed "s/,/|/g") # convert

	# Define image arrays for different channels
	local qcowimages_nightly=(
		"https://dl.armbian.com/nightly/uefi-${arch}/Forky_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Plucky_cloud_minimal-qcow2"
	)

	local qcowimages_stable=(
		"https://dl.armbian.com/uefi-${arch}/Noble_cloud_minimal-qcow2"
		"https://dl.armbian.com/uefi-${arch}/Jammy_cloud_minimal-qcow2"
		"https://dl.armbian.com/uefi-${arch}/Bookworm_cloud_minimal-qcow2"
		"https://dl.armbian.com/uefi-${arch}/Bullseye_cloud_minimal-qcow2"
	)

	# Select image array based on channel parameter
	case "${channel}" in
		stable)
			qcowimages=("${qcowimages_stable[@]}")
			;;
		nightly|*)
			qcowimages=("${qcowimages_nightly[@]}")
			;;
	esac

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "$1" in

		"${commands[0]}")

			pkg_install virtinst libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils dnsmasq

			# start network
			virsh net-start default 2>/dev/null
			virsh net-autostart default 2>/dev/null

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ -n "${keyword}" && ! $qcowimage =~ ${keyword} ]] && continue # skip not needed ones
				local filename=$(basename "$qcowimage" | sed "s/-qcow2/.qcow2/g")
				local output_file="${tempfolder}/${filename}"

				# Download with real progress based on file size
				(
					# Get expected file size
					expected_size=$(curl -sI "$qcowimage" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
					[[ -z "$expected_size" || "$expected_size" -eq 0 ]] && expected_size=100000000

					# Start download in background
					curl -sL "$qcowimage" -o "$output_file" &
					curl_pid=$!

					# Monitor file size and report progress
					while kill -0 $curl_pid 2>/dev/null; do
						if [[ -f "$output_file" ]]; then
							current_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
							percent=$((current_size * 100 / expected_size))
							[[ $percent -gt 95 ]] && percent=95
							echo $percent
						fi
						sleep 0.5
					done
					echo 100
					wait $curl_pid
				) | dialog_gauge "Download" "Downloading $filename" 8 70
			done

			# we will mount qcow image
			modprobe nbd max_part=8

			mounttempfolder=$(mktemp -d)
			trap '{ umount "$mounttempfolder" 2>/dev/null; rm -rf -- "$tempfolder"; }' EXIT

			# Deploy several instances
			local j=0  # Initialize IP address counter
			for i in $(seq -w 01 $instances); do
				for qcowimage in ${qcowimages[@]}; do
					[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
					local filename=$(basename $qcowimage | sed "s/-qcow2/.qcow2/g") # identify filename
					local domain=$i-${kvmprefix}-$(basename $qcowimage | sed "s/-qcow2//g") # without qcow2
					local image="$i"-"${kvmprefix}"-"${filename}" # get image name
					cp ${tempfolder}/${filename} ${destination}/${image} # make a copy under different number
					sync
					qemu-img resize ${destination}/${image} +"${size}G" 2>/dev/null # expand
					qemu-nbd --connect=/dev/nbd0 ${destination}/${image} 2>/dev/null # connect to qemu image
					printf "fix\n" | sudo parted ---pretend-input-tty /dev/nbd0 print >/dev/null # fix resize
					mount /dev/nbd0p3 ${mounttempfolder} # 3rd partition on uefi images is rootfs
					# Check if it reads and display OS info
					local os_name=$(cat ${mounttempfolder}/etc/os-release | grep ARMBIAN_PRETTY_NAME | cut -d"=" -f2 | sed 's/"//g')
					dialog_infobox "" "$os_name" 6 60
					# commands for changing follows here
					j=$(( j + 1 ))
					local ip_address=$(awk -F\. '{ print $1"."$2"."$3"."$4+'$j' }' <<< $startingip )

					# script that is executed at firstrun
					if [[ -f ${provisioning} ]]; then
						echo "INSTANCE=$i" > ${mounttempfolder}/root/provisioning.sh
						cat "${provisioning}" >> ${mounttempfolder}/root/provisioning.sh
						chmod +x ${mounttempfolder}/root/provisioning.sh
					fi

					# first config
					if [[ ${firstconfig} ]]; then
						if [[ -f ${firstconfig} ]]; then
							cat "${firstconfig}" >> ${mounttempfolder}/root/.not_logged_in_yet
						fi
					else
					dialog_infobox "" "Applying first config to $domain" 6 60
					cat <<- EOF >> ${mounttempfolder}/root/.not_logged_in_yet
					PRESET_NET_CHANGE_DEFAULTS="${PRESET_NET_CHANGE_DEFAULTS}"
					PRESET_NET_ETHERNET_ENABLED="1"
					PRESET_NET_USE_STATIC="1"
					PRESET_NET_STATIC_IP="${ip_address}"
					PRESET_NET_STATIC_MASK="255.255.255.0"
					PRESET_NET_STATIC_GATEWAY="${gateway}"
					PRESET_NET_STATIC_DNS="9.9.9.9 8.8.4.4"
					SET_LANG_BASED_ON_LOCATION="y"
					PRESET_LOCALE="$(locale | cut -d'.' -f1)$(locale | cut -d'.' -f2)"
					PRESET_TIMEZONE="$(timedatectl | grep "Time zone" | awk '{print $3}')"
					PRESET_ROOT_PASSWORD="armbian"
					PRESET_USER_NAME="armbian"
					PRESET_USER_PASSWORD="armbian"
					PRESET_USER_KEY=""
					PRESET_DEFAULT_REALNAME="Armbian user"
					PRESET_USER_SHELL="bash"
					EOF
					fi

					umount /dev/nbd0p3 # unmount
					qemu-nbd --disconnect /dev/nbd0 >/dev/null # disconnect from qemu image
					# install and start VM
					sleep 3
					virt-install \
					--name ${domain} \
					--memory ${memory} \
					--vcpus ${vcpus} \
					--autostart \
					--disk ${destination}/${image},bus=sata \
					--import \
					--os-variant ubuntu24.04 \
					--network ${network} \
					--noautoconsole
				done
			done

		;;
		"${commands[1]}")
			dialog_infobox "Info" "Removing VMs..." 6 60
			local shutdown_success=false
			for i in {1..10}; do
				for j in $(virsh list --all --name | grep ${kvmprefix}); do
					dialog_infobox "Shutting Down" "Stopping VM: $(virsh shutdown $j)" 6 60

					snapshots=($(virsh snapshot-list $j | tail -n +3 | head -n -1 | cut -d' ' -f2))
					if [[ ${#snapshots[@]} -gt 0 ]]; then
						local count=0
						local total=${#snapshots[@]}
						for snapshot in "${snapshots[@]}"; do
							count=$((count + 1))
							percent=$((count * 100 / total))
							echo $percent
							virsh snapshot-delete $j $snapshot
						done | dialog_gauge "Removing Snapshots" "Deleting snapshots from $j" 8 70
					fi
				done
				sleep 2
				if [[ -z "$(virsh list --name | grep ${kvmprefix})" ]]; then
					shutdown_success=true
					break
				fi
			done
			if $shutdown_success; then
				vms=($(virsh list --all --name | grep ${kvmprefix}))
				if [[ ${#vms[@]} -gt 0 ]]; then
					local count=0
					local total=${#vms[@]}
					for j in "${vms[@]}"; do
						count=$((count + 1))
						percent=$((count * 100 / total))
						echo $percent
						virsh undefine $j --remove-all-storage
					done | dialog_gauge "Removing VMs" "Undefining and removing VM storage" 8 70
				fi
			fi
		;;
		"${commands[2]}")
			dialog_infobox "" "Saving VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# create snapshots
				virsh snapshot-create-as --domain ${j} --name "initial-state"
			done
		;;
		"${commands[3]}")
			dialog_infobox "" "Dropping VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# drop snapshots
				virsh snapshot-delete "${j}" "initial-state"
			done
		;;
		"${commands[4]}")
			dialog_infobox "" "Restoring VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				virsh shutdown $j 2>/dev/null
				virsh snapshot-revert --domain $j --snapshotname "initial-state" --running
				virsh shutdown $j 2>/dev/null
				for i in {1..20}; do
					sleep 2
					if [[ "$(virsh domstate $j | grep "shut off")" == "shut off" ]]; then break; fi
				done
				virsh start $j 2>/dev/null
			done
		;;
		"${commands[5]}")
			for qcowimage in ${qcowimages[@]}; do
				[[ -n "${keyword}" && ! $qcowimage =~ ${keyword} ]] && continue # skip not needed ones
				echo $qcowimage
			done
		;;
		"${commands[6]}")
			local help_text="Usage: ${module_options["module_armbian_kvmtest,feature"]} <command> [switches]\n\n"
			help_text+="Commands:  ${module_options["module_armbian_kvmtest,example"]}\n\n"
			help_text+="Available commands:\n\n"
			help_text+="  install  - Install $title\n"
			help_text+="  remove   - Remove all virtual machines $title\n"
			help_text+="  save     - Save state of all VM $title\n"
			help_text+="  restore  - Restore all saved state of VM $title\n"
			help_text+="  drop     - Drop all saved states of VM $title\n"
			help_text+="  list     - Show available VM machines $title\n"
			help_text+="\nAvailable switches:\n\n"
			help_text+="  kvmprefix     - Name prefix (default = kvmtest)\n"
			help_text+="  memory        - KVM memory (default = 3072)\n"
			help_text+="  vcpus         - Virtual CPUs (default = 2)\n"
			help_text+="  bridge        - Use network bridge br0,br1,... instead of default interface\n"
			help_text+="  instances     - Number of instances (default = 01)\n"
			help_text+="  provisioning  - File of command that is executed at first run\n"
			help_text+="  firstconfig   - Armbian first config\n"
			help_text+="  keyword       - Select only certain image, example: Focal_Jammy VM image\n"
			help_text+="  arch          - Architecture of VM image (default = x86)\n"
			help_text+="  size          - Additional disk space in GB (default = 10)\n"
			help_text+="  startingip    - Starting IP address (default = 10.0.60.60)\n"
			help_text+="  gateway       - Gateway IP address (default = 10.0.60.1)\n"
			help_text+="  channel       - Image channel: stable or nightly (default = nightly)\n"

			if [[ "$DIALOG" == "read" ]]; then
				echo -e "$help_text"
			else
				dialog_msgbox "Armbian KVM Test Help" "$help_text" 25 80
			fi
		;;
		*)
			${module_options["module_armbian_kvmtest,feature"]} ${commands[6]}
		;;
	esac
}

