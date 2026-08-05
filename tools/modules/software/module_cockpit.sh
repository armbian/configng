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
			# qemu-kvm is a legacy meta that's only published for amd64
			# and arm64 (and Ubuntu carries it as a x86-leaning shim
			# pulling qemu-system-x86). It has no installation
			# candidate on riscv64, causing the cockpit install to
			# fail with "Package 'qemu-kvm' has no installation
			# candidate". qemu-system below is the modern arch-agnostic
			# meta - on each host it pulls qemu-system-<host-arch>,
			# which is what libvirt + cockpit-machines actually need.
			# UEFI guest firmware. The package is arch-specific: ovmf is
			# x86 only, while arm64/armhf guests can boot *only* via UEFI and
			# need the matching AAVMF build. riscv64 has no OVMF equivalent,
			# so it is simply left without one (same "no candidate" trap as
			# qemu-kvm above).
			local host_arch uefi_fw=""
			host_arch="$(dpkg --print-architecture)"
			case "${host_arch}" in
				amd64) uefi_fw="ovmf" ;;
				arm64) uefi_fw="qemu-efi-aarch64" ;;
				armhf) uefi_fw="qemu-efi-arm" ;;
			esac
			pkg_install cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-utils qemu-system ${uefi_fw}

			# On a desktop, also install the virt-manager GUI so VMs can be
			# managed locally, not just through Cockpit's web UI. Headless
			# servers skip it to avoid pulling in GTK and its dependencies.
			check_desktop
			if [[ -n "${DESKTOP_INSTALLED}" ]]; then
				pkg_install virt-manager
			fi

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

			# Default new VMs to UEFI. arm64/armhf guests are UEFI-only
			# already; x86 still defaults to SeaBIOS, so - gated to amd64 -
			# install a libvirt qemu hook that flips firmware-less x86 domains
			# to UEFI (firmware='efi') at prepare time. cockpit-machines and
			# virt-install create BIOS guests otherwise; domains that already
			# picked a firmware/loader (UEFI or an explicit BIOS choice) are
			# left untouched.
			if [[ "${host_arch}" == amd64 ]]; then
				mkdir -p /etc/libvirt/hooks
				cat > /etc/libvirt/hooks/qemu <<'HOOK'
#!/usr/bin/env python3
# Managed by Armbian config (module_cockpit) - changes may be overwritten.
# libvirt qemu hook: on the "prepare" phase, default firmware-less x86 guests
# to UEFI so newly created VMs boot UEFI (OVMF) instead of SeaBIOS.
import sys
import xml.etree.ElementTree as ET

op = sys.argv[2] if len(sys.argv) > 2 else ""
data = sys.stdin.read()
# Only the prepare phase transforms the XML libvirt then uses; every other
# phase must leave things alone (its stdout is ignored anyway).
if op != "prepare" or not data.strip():
    sys.exit(0)
try:
    dom = ET.fromstring(data)
except ET.ParseError:
    sys.stdout.write(data)
    sys.exit(0)
os_el = dom.find("os")
type_el = os_el.find("type") if os_el is not None else None
arch = type_el.get("arch", "") if type_el is not None else ""
# skip when the domain already commits to a firmware/loader, or isn't x86
already = (os_el is None or os_el.get("firmware")
           or os_el.find("loader") is not None
           or os_el.find("nvram") is not None)
if arch in ("x86_64", "i686") and not already:
    os_el.set("firmware", "efi")
    sys.stdout.write(ET.tostring(dom, encoding="unicode"))
else:
    sys.stdout.write(data)
HOOK
				chmod +x /etc/libvirt/hooks/qemu
				systemctl restart libvirtd 2>/dev/null || systemctl restart libvirt 2>/dev/null || true
			fi

			if dialog_yesno " Reboot required " "A reboot is required to start $title properly. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
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
			pkg_installed virt-manager && pkg_remove virt-manager
			rm -f /etc/libvirt/hooks/qemu
			for fw in ovmf qemu-efi-aarch64 qemu-efi-arm; do
				pkg_installed "$fw" && pkg_remove "$fw"
			done
			pkg_remove cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-utils qemu-system

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
