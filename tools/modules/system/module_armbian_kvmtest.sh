#declare -A module_options
module_options+=(
	["module_armbian_kvmtest,author"]="@igorpecovnik"
	["module_armbian_kvmtest,feature"]="module_armbian_kvmtest"
	["module_armbian_kvmtest,desc"]="Deploy Armbian KVM instances"
	["module_armbian_kvmtest,example"]="install remove restore list help"
	["module_armbian_kvmtest,port"]=""
	["module_armbian_kvmtest,status"]="Active"
	["module_armbian_kvmtest,arch"]=""
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
	for feature in instances provisioning firstconfig keyword arch distro bridge; do
	for selected in ${parameter[@]}; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
		done
	done

	local arch="${arch:-x86}" # VM architecture
	local bridge="${bridge:-br0}" # Bridge number
	local distro="${distro:-stable}" # Stable or rolling images
	local instances="${instances:-01}" # number of instances
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local startingip="${startingip:-10.0.40.60}"
	local keyword=$(echo $keyword | sed "s/_/|/g") # convert

	if [[ ${distro} == stable ]]; then
		# use point releases
		qcowimages=(
			https://imola.armbian.com/dl/uefi-${arch}/archive/Armbian_24.11.1_Uefi-${arch}_noble_current_6.6.60_minimal.img.qcow2.xz
			https://imola.armbian.com/dl/uefi-${arch}/archive/Armbian_24.11.1_Uefi-${arch}_bookworm_current_6.6.60_minimal.img.qcow2.xz
		)
	else
		# those targets we are updating every day
		qcowimages=(
			"https://dl.armbian.com/nightly/uefi-${arch}/Bullseye_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Bookworm_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Trixie_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Focal_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Jammy_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Noble_current_minimal-qcow2"
			"https://dl.armbian.com/nightly/uefi-${arch}/Oracular_current_minimal-qcow2"
		)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "${parameter[0]}" in

		"${commands[0]}")
			# Install portainer with KVM support
			# TBD - need to be added to armbian-config

			if ! pkg_installed xz-utils; then
				pkg_install xz-utils
			fi

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				curl --progress-bar -L $qcowimage | xz -d > ${tempfolder}/$(basename $qcowimage | sed "s/.xz//g")
			done

			# we will mount qcow image
			modprobe nbd max_part=8

			mounttempfolder=$(mktemp -d)
			trap '{ umount "$mounttempfolder" 2>/dev/null; rm -rf -- "$tempfolder"; }' EXIT
			# Deploy several instances
			for i in $(seq -w 01 $instances); do
				for qcowimage in ${qcowimages[@]}; do
					[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
					local image=$i-$(basename $qcowimage | sed "s/.xz//g" | cut -d"_" -f4,5) # get image name
					cp ${tempfolder}/$(basename $qcowimage | sed "s/.xz//g") ${destination}/$i-$(basename $qcowimage | sed "s/.xz//g") # make a copy
					qemu-img resize ${destination}/$i-$(basename $qcowimage | sed "s/.xz//g") +10G # expand
					qemu-nbd --connect=/dev/nbd0 ${destination}/$i-$(basename $qcowimage | sed "s/.xz//g") # connect to qemu image
					printf "fix\n" | sudo parted ---pretend-input-tty /dev/nbd0 print >/dev/null # fix resize
					mount /dev/nbd0p3 ${mounttempfolder} # 3rd partition on uefi images is rootfs
					cat ${mounttempfolder}/etc/os-release | grep ARMBIAN_PRETTY_NAME | cut -d"=" -f2 | sed 's/"//g'
					# Move this to main system
					#mkdir -p ${mounttempfolder}/etc/shadow-maint/useradd-post.d/
					#echo "#!/bin/sh" > ${mounttempfolder}/etc/shadow-maint/useradd-post.d/01groups
					#echo "usermod -a -G docker \"\$SUBJECT\"" >> ${mounttempfolder}/etc/shadow-maint/useradd-post.d/01groups
					#chmod a+x ${mounttempfolder}/etc/shadow-maint/useradd-post.d/01groups
					# commands for changing follows here
					local ip_address=$(awk -F\. '{ print $1"."$2"."$3"."$4+'$i' }' <<< $startingip )
					# this part needs be changed in build framework
					cp ${mounttempfolder}/etc/rc.local ${mounttempfolder}/etc/rc.local.bak
					if [[ -f ${provisioning} ]]; then 
					echo "Provision"
						echo "#!/bin/bash" > ${mounttempfolder}/etc/rc.local
						echo "for i in {1..10}; do ping -q -c 5 -i 1 9.9.9.9; [[ \$? -eq 0 ]] && break; sleep 1; done" >> ${mounttempfolder}/etc/rc.local
						cat "${provisioning}" >> ${mounttempfolder}/etc/rc.local
						echo "mv /etc/rc.local.bak /etc/rc.local" >> ${mounttempfolder}/etc/rc.local
						echo "exit 0" >> ${mounttempfolder}/etc/rc.local
						chmod +x ${mounttempfolder}/etc/rc.local
					fi

					# copy first config
					if [[ -f ${firstconfig} ]]; then
						cat "${firstconfig}" >> ${mounttempfolder}/root/.not_logged_in_yet
					fi
					umount /dev/nbd0p3 # unmount
					qemu-nbd --disconnect /dev/nbd0 >/dev/null # disconnect from qemu image
					# install and start VM
					virt-install \
					--name ${kvmprefix}-$image \
					--memory 3072 \
					--vcpus 4 \
					--autostart \
					--disk ${destination}/$i-$(basename $qcowimage | sed "s/.xz//g"),bus=sata \
					--import \
					--os-variant ubuntu24.04 \
					--network bridge=${bridge} \
					--noautoconsole
					# create snapshot of initial state
					virsh snapshot-create-as --domain ${kvmprefix}-$image --name "initial-state"
				done
			done
			rm -rf ${tempfolder} ${mounttempfolder}
		;;
		"${commands[1]}")
			for i in {1..10}; do
				for j in $(virsh list --all --name | grep ${kvmprefix}); do 
					virsh shutdown $j 2>/dev/null
					for snapshot in $(virsh snapshot-list $j | tail -n +3 | head -n -1 | cut -d' ' -f2); do virsh snapshot-delete $j $snapshot; done
				done				
				sleep 2
				if [[ -z "$(virsh list --name | grep ${kvmprefix})" ]]; then break; fi
			done
			if [[ $i -lt 10 ]]; then
				for j in $(virsh list --all --name | grep ${kvmprefix}); do virsh undefine $j; done
			fi
		;;
		"${commands[2]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				virsh shutdown $j 2>/dev/null
				virsh snapshot-revert --domain $j --snapshotname "initial-state" --running
			done
		;;
		"${commands[3]}")
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
			echo -e "\trestore\t- Restore intial state of VM $title."
			echo -e "\tlist\t- Show available VM machines $title."
			echo -e "\tkeyword\t- Use only certain. keyword=Jammy_Noble for example"
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tbridge\t- Network bridge br0,br1,...\n"
			echo -e "\tinstances\t- Repetitions if more then 1"
			echo -e "\tprovisioning\t- File of command that is executed at first run."
			echo -e "\tfirstconfig\t- Armbian first config."
			echo -e "\tkeyword\t\t- Select only certain image, example: Focal_Jammy VM image."
			echo -e "\tarch\t\t- architecture of VM image."
			echo -e "\tdistro\t\t- stable or rolling."
			echo
		;;
		*)
			${module_options["module_armbian_kvmtest,feature"]} ${commands[6]}
		;;
	esac
}
#module_armbian_kvmtest $1 $2 "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$10"