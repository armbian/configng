module_options+=(
	["module_pi_hole,author"]="@armbian"
	["module_pi_hole,maintainer"]="@igorpecovnik"
	["module_pi_hole,feature"]="module_pi_hole"
	["module_pi_hole,example"]="install remove purge password status help"
	["module_pi_hole,desc"]="Install Pi-hole container"
	["module_pi_hole,status"]="Active"
	["module_pi_hole,doc_link"]="https://docs.pi-hole.net/"
	["module_pi_hole,group"]="DNS"
	["module_pi_hole,port"]="8811"
	["module_pi_hole,arch"]="x86-64 arm64"
)
#
# Module Pi-Hole
#
function module_pi_hole () {
	local title="pihole"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter 'name=^/pihole$' --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --filter 'reference=pihole/pihole:*' --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_pi_hole,example"]}"

	PIHOLE_BASE="${SOFTWARE_FOLDER}/pihole"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			# Check if the module is already installed
			if [[ "${container}" && "${image}" ]]; then
				echo "Pi-hole container is already installed."
				exit 0
			fi

			if ! docker container ls -a --format '{{.Names}}' | grep -q '^unbound$'; then module_unbound install; fi
			local unbound_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' unbound)
			[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }
			[[ ! -f "/etc/systemd/resolved.conf.d/armbian-defaults.conf" ]] && ${module_options["module_pi_hole,feature"]} ${commands[1]}
			docker run -d \
			--name pihole \
			--net=lsio \
			-p 53:53/tcp \
			-p 53:53/udp \
			-p ${module_options["module_pi_hole,port"]}:80 \
			-e TZ="$(cat /etc/timezone)" \
			-e PIHOLE_UID=1000 \
			-e PIHOLE_GID=1000 \
			-v "${PIHOLE_BASE}/etc-pihole:/etc/pihole" \
			-v "${PIHOLE_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d" \
			--dns=9.9.9.9 \
			--restart=unless-stopped \
			--hostname pi.hole \
			-e VIRTUAL_HOST="pi.hole" \
			-e PROXY_LOCATION="pi.hole" \
			-e FTLCONF_LOCAL_IPV4="${LOCALIPADD}" \
			-e FTLCONF_dns_upstreams="unbound#5335" \
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
			local container_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' pihole)
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1 ${container_ip}
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
			${module_options["module_pi_hole,feature"]} ${commands[3]}
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
			# restore DNS settings
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}")
			${module_options["module_pi_hole,feature"]} ${commands[1]}
			[[ -n "${PIHOLE_BASE}" && "${PIHOLE_BASE}" != "/" ]] && rm -rf "${PIHOLE_BASE}"
		;;
		"${commands[3]}")
			SELECTED_PASSWORD=$($DIALOG --title "Enter new password for Pi-hole admin" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
			if [[ -n $SELECTED_PASSWORD ]]; then
				docker exec -it "${container}" sh -c "pihole setpassword ${SELECTED_PASSWORD}"
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

