module_options+=(
	["module_cockpit,author"]="@tearran"
	["module_cockpit,maintainer"]="@igorpecovnik"
	["module_cockpit,feature"]="module_cockpit"
	["module_cockpit,example"]="install remove purge status help"
	["module_cockpit,desc"]="Cockpit setup and service setting."
	["module_cockpit,status"]="Stable"
	["module_cockpit,doc_link"]="https://cockpit-project.org/guide/latest/"
	["module_cockpit,group"]="Management"
	["module_cockpit,port"]="9890"
	["module_cockpit,arch"]="x86-64 arm64 armhf"
)

function module_cockpit() {
	local title="cockpit"
	local condition=$(dpkg -s "cockpit" 2>/dev/null | sed -n "s/Status: //p")

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_cockpit,example"]}"

	case "$1" in

		"${commands[0]}")

			sudo mkdir -p /etc/systemd/system/cockpit.socket.d
			cat <<- EOF > /etc/systemd/system/cockpit.socket.d/override.conf
			[Socket]
			ListenStream=
			ListenStream=${module_options["module_cockpit,port"]}
			EOF

			## install cockpit
			pkg_update
			pkg_install cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-kvm qemu-utils qemu-system

			usermod -a -G libvirt libvirtdbus
			usermod -a -G libvirt libvirt-qemu

			# add bridged networking if bridges exists on the system
			for f in /sys/class/net/*; do
				intf=$(basename $f)
				if [[ $intf =~ ^br[0-9] ]]; then
					cat <<- EOF > /etc/libvirt/kvm-hostbridge-${intf}.xml
					<network>
					<name>hostbridge-${intf}</name>
					<forward mode="bridge"/>
					<bridge name="${intf}"/>
					</network>
					EOF
					virsh net-define /etc/libvirt/kvm-hostbridge-${intf}.xml
					virsh net-start hostbridge-${intf}
					virsh net-autostart hostbridge-${intf}
				fi
			done
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
				"A reboot is required to start $title properly. Shall we reboot now?" 7 34; then
				reboot
			fi

		;;
		"${commands[1]}")
			## remove cockpit
			systemctl stop cockpit.socket 2>/dev/null
			systemctl stop cockpit 2>/dev/null
			systemctl disable cockpit 2>/dev/null
			for bridge in $(grep hostbridge /etc/libvirt/kvm-hostbridge-br*.xml 2>/dev/null | grep -o -P '(?<=name>).*(?=\</name)' 2>/dev/null); do
				virsh net-destroy ${bridge}
				virsh net-undefine ${bridge}
			done
			pkg_remove cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-kvm qemu-utils qemu-system

		;;
		"${commands[2]}")
			for vm in $(virsh list --all --name); do virsh destroy "$vm" 2>/dev/null; virsh undefine "$vm" --remove-all-storage; done
			for net in $(virsh net-list --all --name); do
				virsh net-destroy "$net" 2>/dev/null
				virsh net-undefine "$net"
			done
			ip link show virbr0 &>/dev/null && ip link delete virbr0
			${module_options["module_cockpit,feature"]} ${commands[1]}
			rm -rf /var/lib/libvirt
		;;
		"${commands[3]}")
			if pkg_installed cockpit; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_cockpit,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_cockpit,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;
		*)
			${module_options["module_cockpit,feature"]} ${commands[4]}
		;;
	esac
}
