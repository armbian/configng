
module_options+=(
	["pi_hole,author"]="@armbian"
	["pi_hole,ref_link"]=""
	["pi_hole,feature"]="pi_hole"
	["pi_hole,desc"]="Install/uninstall/check status of pi-hole container"
	["pi_hole,example"]="help install uninstall status password"
	["pi_hole,status"]="Active"
)
#
# Install Pi-Hole DNS blocking
#
function pi_hole () {

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/pihole?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/pihole?( |$)/{print $3}')
	fi
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["pi_hole,example"]}"

	PIHOLE_BASE=/opt/pihole-storage
	PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
	[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["pi_hole,feature"]} <command>"
			echo -e "Commands: ${module_options["pi_hole,example"]}"
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

			check_if_installed docker-ce || install_docker

			# disable dns within systemd-resolved
			if systemctl is-active --quiet systemd-resolved.service && ! grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf; then
				sed -i "s/^#\?DNSStubListener=.*/DNSStubListener=no/" /etc/systemd/resolved.conf
				systemctl restart systemd-resolved.service
				sleep 3
			fi
			# disable dns within Network manager
			if systemctl is-active --quiet NetworkManager && grep -q "dns=true" /etc/NetworkManager/NetworkManager.conf; then
				sed -i "s/dns=.*/dns=false/g" /etc/NetworkManager/NetworkManager.conf
				systemctl restart NetworkManager
				sleep 3
			fi

			docker run -d \
			--name pihole \
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
				if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)"
					exit 1
				fi
			done
		;;

		uninstall)
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		password)
			SELECTED_PASSWORD=$($DIALOG --title "Enter new password for Pi-hole admin" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
			if [[ -n $SELECTED_PASSWORD ]]; then
				docker exec -it "${container}" sh -c "sudo pihole -a -p ${SELECTED_PASSWORD}" >/dev/null
			fi
		;;
		status)
			[[ "${container}" ]] || [[ "${image}" ]] && return 0
		;;
	esac
}

#pi_hole help
