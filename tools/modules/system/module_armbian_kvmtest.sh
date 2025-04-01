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
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for feature in instances provisioning firstconfig startingip gateway keyword arch kvmprefix network bridge memory vcpus size; do
			for selected in ${parameter[@]}; do
				IFS='=' read -r -a split <<< "${selected}"
				[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
			done
		done
	done

	# if we provide startingip and gateway, set network
	if [[ -n "${startingip}" && -n "${gateway}" ]]; then
		PRESET_NET_CHANGE_DEFAULTS="1"
	fi

	local startingip=$(echo $startingip | sed "s/_/./g")
	local gateway=$(echo $gateway | sed "s/_/./g")

	local arch="${arch:-x86}" # VM architecture
	local network="${network:-default}"
	if [[ -n "${bridge}" ]]; then network="bridge=${bridge}"; fi
	local instances="${instances:-01}" # number of instances
	local size="${size:-10}" # number of instances
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local memory="${memory:-3072}"
	local vcpus="${vcpus:-2}"
	local startingip="${startingip:-10.0.60.60}"
	local gateway="${gateway:-10.0.60.1}"
	local keyword=$(echo $keyword | sed "s/,/|/g") # convert

	qcowimages=(
		"https://dl.armbian.com/nightly/uefi-${arch}/Bullseye_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Bookworm_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Trixie_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Focal_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Jammy_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Noble_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Plucky_cloud_minimal-qcow2"
	)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "$1" in

		"${commands[0]}")

			# Install portainer with KVM support and / KVM support only
			# TBD - need to be added to armbian-config
			pkg_install virtinst libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils dnsmasq

			# start network
			virsh net-start default 2>/dev/null
			virsh net-autostart default

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				curl --progress-bar -L "$qcowimage" > "${tempfolder}/$(basename "$qcowimage" | sed "s/-qcow2/.qcow2/g")"
			done

			# we will mount qcow image
			modprobe nbd max_part=8

			mounttempfolder=$(mktemp -d)
			trap '{ umount "$mounttempfolder" 2>/dev/null; rm -rf -- "$tempfolder"; }' EXIT
			# Deploy several instances
			for i in $(seq -w 01 $instances); do
				for qcowimage in ${qcowimages[@]}; do
					[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
					local filename=$(basename $qcowimage | sed "s/-qcow2/.qcow2/g") # identify filename
					local domain=$i-${kvmprefix}-$(basename $qcowimage | sed "s/-qcow2//g") # without qcow2
					local image="$i"-"${kvmprefix}"-"${filename}" # get image name
					cp ${tempfolder}/${filename} ${destination}/${image} # make a copy under different number
					sync
					qemu-img resize ${destination}/${image} +"${size}G" # expand
					qemu-nbd --connect=/dev/nbd0 ${destination}/${image} # connect to qemu image
					printf "fix\n" | sudo parted ---pretend-input-tty /dev/nbd0 print >/dev/null # fix resize
					mount /dev/nbd0p3 ${mounttempfolder} # 3rd partition on uefi images is rootfs
					# Check if it reads
					cat ${mounttempfolder}/etc/os-release | grep ARMBIAN_PRETTY_NAME | cut -d"=" -f2 | sed 's/"//g'
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
					echo "first config"
					cat <<- EOF >> ${mounttempfolder}/root/.not_logged_in_yet
					PRESET_NET_CHANGE_DEFAULTS="${PRESET_NET_CHANGE_DEFAULTS}"
					PRESET_NET_ETHERNET_ENABLED="1"
					PRESET_NET_USE_STATIC="1"
					PRESET_NET_STATIC_IP="${ip_address}"
					PRESET_NET_STATIC_MASK="255.255.255.0"
					PRESET_NET_STATIC_GATEWAY="${gateway}"
					PRESET_NET_STATIC_DNS="9.9.9.9 8.8.4.4"
					SET_LANG_BASED_ON_LOCATION="y"
					PRESET_LOCALE="sl_SI.UTF-8"
					PRESET_TIMEZONE="Europe/Ljubljana"
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
			for i in {1..10}; do
				for j in $(virsh list --all --name | grep ${kvmprefix}); do
					virsh shutdown $j 2>/dev/null
					for snapshot in $(virsh snapshot-list $j \
					| tail -n +3 | head -n -1 | cut -d' ' -f2); do virsh snapshot-delete $j $snapshot; done
				done
				sleep 2
				if [[ -z "$(virsh list --name | grep ${kvmprefix})" ]]; then break; fi
			done
			if [[ $i -lt 10 ]]; then
				for j in $(virsh list --all --name | grep ${kvmprefix}); do virsh undefine $j --remove-all-storage; done
			fi
		;;
		"${commands[2]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# create snapshots
				virsh snapshot-create-as --domain ${j} --name "initial-state"
			done
		;;
		"${commands[3]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# drop snapshots
				virsh snapshot-delete "${j}" "initial-state"
			done
		;;
		"${commands[4]}")
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
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				echo $qcowimage
			done
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_kvmtest,feature"]} <command> [switches]"
			echo -e "Commands:  ${module_options["module_armbian_kvmtest,example"]}"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove all virtual machines $title."
			echo -e "\tsave\t- Save state of all VM $title."
			echo -e "\trestore\t- Restore all saved state of VM $title."
			echo -e "\tdrop\t- Drop all saved states of VM $title."
			echo -e "\tlist\t- Show available VM machines $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tkvmprefix\t- Name prefix (default = kvmtest)"
			echo -e "\tmemory\t\t- KVM memory (default = 2048)"
			echo -e "\tvcpus\t\t- Virtual CPUs (default = 2)"
			echo -e "\tbridge\t\t- Use network bridge br0,br1,... instead of default inteface"
			echo -e "\tinstances\t- Repetitions if more then 1"
			echo -e "\tprovisioning\t- File of command that is executed at first run."
			echo -e "\tfirstconfig\t- Armbian first config."
			echo -e "\tkeyword\t\t- Select only certain image, example: Focal_Jammy VM image."
			echo -e "\tarch\t\t- architecture of VM image."
			echo
		;;
		*)
			${module_options["module_armbian_kvmtest,feature"]} ${commands[6]}
		;;
	esac
}

