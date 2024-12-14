declare -A module_options
module_options+=(
	["module_haos,author"]="@igorpecovnik"
	["module_haos,feature"]="module_haos"
	["module_haos,example"]="help install uninstall"
	["module_haos,desc"]="Hos container install and configure"
	["module_haos,port"]="8123"
	["module_haos,status"]="review"
)
#
# Install haos container
#
module_haos() {



	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/home-assistant/{print $1}')
		local image=$(docker image ls -a | mawk '/home-assistant/{print $3}')
	fi

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_haos,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_haos,feature"]} <command>"
			echo -e "Commands: ${module_options["module_haos,example"]}"
			echo "Available commands:"
			if [[ "${container}" ]] || [[ "${image}" ]]; then
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."
			else
				echo -e "  install\t- Install $title."
			fi
			echo
		;;
		install)
			pkg_installed docker-ce || install_docker

			# this hack will allow running it on minimal image, but this has to be done properly in the network section, to allow easy switching
			systemctl disable systemd-networkd

			# hack to force install
			sed -i 's/^PRETTY_NAME=".*/PRETTY_NAME="Debian GNU\/Linux 12 (bookworm)"/g' "${SDCARD}/etc/os-release"

			# we host packages at our repository and version for both is determined:
			# https://github.com/armbian/os/blob/main/external/haos-agent.conf
			# https://github.com/armbian/os/blob/main/external/haos-supervised-installer.conf

			apt_install_wrapper apt-get -y install --download-only homeassistant-supervised os-agent

			# determine machine type
			case "${ARCH}" in
				armhf) MACHINE="tinker";;
				amd64) MACHINE="generic-x86-64";;
				arm64) MACHINE="odroid-n2";;
				*) exit 1;;
			esac

			# this we can't put behind wrapper
			MACHINE="${MACHINE}" apt-get -y install homeassistant-supervised os-agent

			# workarounding supervisor loosing healthy state https://github.com/home-assistant/supervisor/issues/4381
			cat <<- SUPERVISOR_FIX > "/usr/local/bin/supervisor_fix.sh"
			#!/bin/bash
			while true; do
			if ha supervisor info 2>&1 | grep -q "healthy: false"; then
				echo "Unhealthy detected, restarting" | systemd-cat -t $(basename "$0") -p debug
				systemctl restart hassio-supervisor.service
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

			if [[ -f /boot/armbianEnv.txt ]]; then
				echo "extraargs=systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor" >> "/boot/armbianEnv.txt"
			fi
			sleep 5
			for s in {1..10};do
				for i in {0..100..10}; do
					j=$i
					echo "$i"
					sleep 1
				done
				if [[ -n "$(docker container ls -a | mawk '/hassio-cli/{print $1}')" ]]; then
					ha supervisor info --raw-json >/dev/null
					if [[ $status -ne 0 ]]; then break; fi
				fi
			done | $DIALOG --gauge "Preparing Home Assistant Supervised\n\nPlease wait! " 10 50 0

			# enable service
			systemctl enable supervisor-fix >/dev/null 2>&1
			systemctl start supervisor-fix >/dev/null 2>&1

			# restore os-release
			sed -i "s/^PRETTY_NAME=\".*/PRETTY_NAME=\"${VENDOR} ${REVISION} ($VERSION_CODENAME)\"/g" "/etc/os-release"

			# show that its done
			$DIALOG --msgbox "Home assistant is available at\n\nhttps://${LOCALIPADD}:8123 " 10 38
		;;
		uninstall)
			# disable service
			systemctl disable supervisor-fix >/dev/null 2>&1
			systemctl stop supervisor-fix >/dev/null 2>&1
			apt_install_wrapper apt-get -y purge homeassistant-supervised os-agent
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
			systemctl daemon-reload >/dev/null 2>&1
			# restore os-release
			sed -i "s/^PRETTY_NAME=\".*/PRETTY_NAME=\"${VENDOR} ${REVISION} ($VERSION_CODENAME)\"/g" "/etc/os-release"
		;;
		status)
			[[ "${container}" ]] || [[ "${image}" ]] && return 0
		;;
	esac
}

module_haos "$1"
