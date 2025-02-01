module_options+=(
	["module_armbian_kvmtest,author"]="@igorpecovnik"
	["module_armbian_kvmtest,feature"]="module_armbian_kvmtest"
	["module_armbian_kvmtest,desc"]="Deploy Armbian KVM instances"
	["module_armbian_kvmtest,example"]="install remove save restore list help"
	["module_armbian_kvmtest,port"]=""
	["module_armbian_kvmtest,status"]="Active"
	["module_armbian_kvmtest,arch"]="x86-64"
)
#
# Module deploy Armbian QEMU KVM instances
#
function module_armbian_kvmtest () {

	local title="kvmtest"
	local condition=$(which "$title" 2>/dev/null)

	# read additional parameters from command line
	local parameter
	IFS=' ' read -r -a parameter <<< "${1}"
	for feature in instances provisioning firstconfig startingip gateway keyword arch kvmprefix network bridge memory vcpus; do
	for selected in ${parameter[@]}; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
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
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local memory="${memory:-3072}"
	local vcpus="${vcpus:-2}"
	local startingip="${startingip:-10.0.60.60}"
	local gateway="${gateway:-10.0.60.1}"
	local keyword=$(echo $keyword | sed "s/_/|/g") # convert

	qcowimages=(
		"https://dl.armbian.com/nightly/uefi-${arch}/Bullseye_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Bookworm_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Trixie_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Focal_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Jammy_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Noble_current_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Plucky_current_minimal-qcow2"
	)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "${parameter[0]}" in

		"${commands[0]}")

			# Install portainer with KVM support and / KVM support only
			# TBD - need to be added to armbian-config
			pkg_install virtinst libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils dnsmasq

			# start network
			virsh net-start default 2>/dev/null
			virsh net-autostart default

			if ! pkg_installed xz-utils; then
				pkg_install xz-utils
			fi

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				curl --progress-bar -L $qcowimage | xz -d > ${tempfolder}/$(basename $qcowimage | sed "s/-qcow2/.qcow2/g")
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
					qemu-img resize ${destination}/${image} +10G # expand
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
				# create snapshot
				virsh snapshot-create-as --domain ${j} --name "initial-state"
			done
		;;
		"${commands[3]}")
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
		"${commands[4]}")
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				echo $qcowimage
			done
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_armbian_kvmtest,feature"]} <command> [switches]"
			echo -e "Commands:  ${module_options["module_armbian_kvmtest,example"]}"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove all virtual machines $title."
			echo -e "\tsave\t- Save state of all VM $title."
			echo -e "\trestore\t- Restore all saved state of VM $title."
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
			${module_options["module_armbian_kvmtest,feature"]} ${commands[5]}
		;;
	esac
}

