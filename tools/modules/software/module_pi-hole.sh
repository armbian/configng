module_options+=(
	["module_pi_hole,author"]="@armbian"
	["module_pi_hole,maintainer"]="@igorpecovnik"
	["module_pi_hole,feature"]="module_pi_hole"
	["module_pi_hole,example"]="install remove purge password status help"
	["module_pi_hole,desc"]="Install Pi-hole container"
	["module_pi_hole,status"]="Active"
	["module_pi_hole,doc_link"]="https://docs.pi-hole.net/"
	["module_pi_hole,group"]="DNS"
	["module_pi_hole,port"]="80 53"
	["module_pi_hole,arch"]="x86-64 arm64"
)
#
# Module Pi-Hole
#
function module_pi_hole () {
	local title="pihole"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/pihole?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/pihole?( |$)/{print $3}')
	fi
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_pi_hole,example"]}"

	PIHOLE_BASE="${SOFTWARE_FOLDER}/pihole"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }
			# disable dns within systemd-resolved
			if systemctl is-active --quiet systemd-resolved.service; then
				# Debian doesn't enable this file by default
				[[ ! -f /etc/systemd/resolved.conf ]] && ln -s /etc/systemd/resolved.conf.real /etc/systemd/resolved.conf
				if ! grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf 2> /dev/null; then
					sed -i "s/^#\?DNSStubListener=.*/DNSStubListener=no/" /etc/systemd/resolved.conf
					systemctl restart systemd-resolved.service
					sleep 3
				fi
			fi
			# disable dns within Network manager
			if systemctl is-active --quiet NetworkManager && [[ -f /etc/NetworkManager/NetworkManager.conf ]]; then
				if grep -q "dns=true" /etc/NetworkManager/NetworkManager.conf; then
					sed -i "s/dns=.*/dns=false/g" /etc/NetworkManager/NetworkManager.conf
					systemctl restart NetworkManager
					sleep 3
				fi
			fi
			docker run -d \
			--name pihole \
			--net=lsio \
			-p 53:53/tcp -p 53:53/udp \
			-p 80:80 \
			-e TZ="$(cat /etc/timezone)" \
			-v "${PIHOLE_BASE}/etc-pihole:/etc/pihole" \
			-v "${PIHOLE_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d" \
			--dns=9.9.9.9 \
			--restart=unless-stopped \
			--hostname pi.hole \
			-e VIRTUAL_HOST="pi.hole" \
			-e PROXY_LOCATION="pi.hole" \
			-e FTLCONF_LOCAL_IPV4="${LOCALIPADD}" \
			pihole/pihole:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' pihole >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs pihole\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_pi_hole,feature"]} ${commands[1]}
			[[ -n "${PIHOLE_BASE}" && "${PIHOLE_BASE}" != "/" ]] && rm -rf "${PIHOLE_BASE}"
		;;
		"${commands[3]}")
			SELECTED_PASSWORD=$($DIALOG --title "Enter new password for Pi-hole admin" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
			if [[ -n $SELECTED_PASSWORD ]]; then
				docker exec -it "${container}" sh -c "sudo pihole -a -p ${SELECTED_PASSWORD}" >/dev/null
			fi
		;;
		"${commands[4]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_pi_hole,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_pi_hole,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tpassword\t- Set webadmin password $title."
			echo
		;;
		*)
			${module_options["module_pi_hole,feature"]} ${commands[5]}
		;;
	esac
}

