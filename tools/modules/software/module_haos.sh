module_options+=(
	["module_haos,author"]="@igorpecovnik"
	["module_haos,maintainer"]="@igorpecovnik"
	["module_haos,feature"]="module_haos"
	["module_haos,example"]="install remove purge status help"
	["module_haos,desc"]="Install HA supervised container"
	["module_haos,status"]="Active"
	["module_haos,doc_link"]="https://github.com/home-assistant/supervised-installer"
	["module_haos,group"]="HomeAutomation"
	["module_haos,port"]="8123"
	["module_haos,arch"]="x86-64 arm64 armhf"
)
#
# Install haos supervised
#
function module_haos() {

	local title="haos"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/home-assistant/{print $1}')
		local image=$(docker image ls -a | mawk '/home-assistant/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_haos,example"]}"

	HAOS_BASE="${SOFTWARE_FOLDER}/haos"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$HAOS_BASE" ]] || mkdir -p "$HAOS_BASE" || { echo "Couldn't create storage directory: $HAOS_BASE"; exit 1; }

			# this hack will allow running it on minimal image, but this has to be done properly in the network section, to allow easy switching
			srv_disable systemd-networkd

			# hack to force install
			sed -i 's/^PRETTY_NAME=".*/PRETTY_NAME="Debian GNU\/Linux 12 (bookworm)"/g' "${SDCARD}/etc/os-release"

			# we host packages at our repository and version for both is determined:
			# https://github.com/armbian/os/blob/main/external/haos-agent.conf
			# https://github.com/armbian/os/blob/main/external/haos-supervised-installer.conf

			pkg_install --download-only homeassistant-supervised os-agent

			# determine machine type
			case "${ARCH}" in
				armhf) MACHINE="tinker";;
				amd64) MACHINE="generic-x86-64";;
				arm64) MACHINE="odroid-n2";;
				*) exit 1;;
			esac

			# this we can't put behind wrapper
			DATA_SHARE="$HAOS_BASE" MACHINE="${MACHINE}" pkg_install homeassistant-supervised os-agent

			# workarounding supervisor loosing healthy state https://github.com/home-assistant/supervisor/issues/4381
			cat <<- SUPERVISOR_FIX > "/usr/local/bin/supervisor_fix.sh"
			#!/bin/bash
			while true; do
			if ha supervisor info 2>&1 | grep -q "healthy: false"; then
				echo "Unhealthy detected, restarting" | systemd-cat -t $(basename "$0") -p debug
				srv_restart hassio-supervisor
				sleep 600
			else
				sleep 5
			fi
			done
			SUPERVISOR_FIX

			# add executable bit
			chmod +x "/usr/local/bin/supervisor_fix.sh"

			# generate service file to run this script
			cat <<- SUPERVISOR_FIX_SERVICE > "/etc/systemd/system/supervisor-fix.service"
			[Unit]
			Description=Supervisor Unhealthy Fix

			[Service]
			StandardOutput=null
			StandardError=null
			ExecStart=/usr/local/bin/supervisor_fix.sh

			[Install]
			WantedBy=multi-user.target
			SUPERVISOR_FIX_SERVICE

			if [[ -f /boot/firmware/cmdline.txt ]]; then
				# Raspberry Pi
				sed -i '/./ s/$/ systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor/' /boot/firmware/cmdline.txt
			elif [[ -f /boot/armbianEnv.txt ]]; then
				echo "extraargs=systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor" >> "/boot/armbianEnv.txt"
			fi
			sleep 5
			for s in {1..50};do
				for i in {0..100..10}; do
					j=$i
					echo "$i"
					sleep 2
				done
				if [[ -n "$(ss | grep ${module_options["module_haos,port"]})" ]]; then
						break;
				fi
			done | $DIALOG --gauge "Preparing Home Assistant Supervised\n\nPlease wait! (can take 15 minutes) " 10 50 0

			# enable service
			srv_enable supervisor-fix
			srv_start supervisor-fix

			# restore os-release
			sed -i "s/^PRETTY_NAME=\".*/PRETTY_NAME=\"${VENDOR} ${REVISION} ($VERSION_CODENAME)\"/g" "/etc/os-release"

			# reboot is mandatory
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to enable AppArmor. Shall we reboot now?" 7 68; then
			reboot
			fi

		;;
		"${commands[1]}")
			# disable service
			srv_disable supervisor-fix
			srv_stop supervisor-fix
			pkg_remove homeassistant-supervised os-agent
			echo -e "Removing Home Assistant containers.\n\nPlease wait few minutes! "
			if [[ "${container}" ]]; then
				echo "${container}" | xargs docker stop >/dev/null 2>&1
				echo "${container}" | xargs docker rm >/dev/null 2>&1
			fi
			if [[ "${image}" ]]; then
				echo "${image}" | xargs docker image rm >/dev/null 2>&1
			fi
			rm -f /usr/local/bin/supervisor_fix.sh
			rm -f /etc/systemd/system/supervisor-fix.service
			sed -i "s/ systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor//" /boot/armbianEnv.txt
			# Raspberry Pi
			sed -i "s/ systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor//" /boot/firmware/cmdline.txt
			srv_daemon_reload
			# restore os-release
			sed -i "s/^PRETTY_NAME=\".*/PRETTY_NAME=\"${VENDOR} ${REVISION} ($VERSION_CODENAME)\"/g" "/etc/os-release"
		;;
		"${commands[2]}")
			${module_options["module_haos,feature"]} ${commands[1]}
			[[ -n "${HAOS_BASE}" && "${HAOS_BASE}" != "/" ]] && rm -rf "${HAOS_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_haos,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_haos,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
		${module_options["module_haos,feature"]} ${commands[4]}
		;;
	esac
}
