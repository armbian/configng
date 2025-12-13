module_options+=(
	["module_octoprint,author"]="@armbian"
	["module_octoprint,maintainer"]="@igorpecovnik"
	["module_octoprint,feature"]="module_octoprint"
	["module_octoprint,example"]="install remove purge status help"
	["module_octoprint,desc"]="Install octoprint container"
	["module_octoprint,status"]="Active"
	["module_octoprint,doc_link"]="https://transmissionbt.com/"
	["module_octoprint,group"]="Printing"
	["module_octoprint,port"]="7981"
	["module_octoprint,arch"]="x86-64 arm64"
)
#
# Module octoprint
#
function module_octoprint () {
	local title="octoprint"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/octoprint?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/octoprint?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_octoprint,example"]}"

	OCTOPRINT_BASE="${SOFTWARE_FOLDER}/octoprint"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$OCTOPRINT_BASE" ]] || mkdir -p "$OCTOPRINT_BASE" || { echo "Couldn't create storage directory: $OCTOPRINT_BASE"; exit 1; }
			docker volume create octoprint
			docker run -d \
			--name octoprint \
			-v "${OCTOPRINT_BASE}:/octoprint/octoprint" \
			--device /dev/video0:/dev/video0 \
			-e TZ="$(cat /etc/timezone)" \
			-e ENABLE_MJPG_STREAMER=true \
			-p 7981:80 \
			--restart unless-stopped \
			octoprint/octoprint
			#--device /dev/ttyACM0:/dev/ttyACM0 \
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' octoprint >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs octoprint\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_octoprint,feature"]} ${commands[1]}
			if [[ -n "${OCTOPRINT_BASE}" && "${OCTOPRINT_BASE}" != "/" ]]; then
				rm -rf "${OCTOPRINT_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_octoprint,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_octoprint,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_octoprint,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_sonarr,author"]="@armbian"
	["module_sonarr,maintainer"]="@igorpecovnik"
	["module_sonarr,feature"]="module_sonarr"
	["module_sonarr,example"]="install remove purge status help"
	["module_sonarr,desc"]="Install sonarr container"
	["module_sonarr,status"]="Active"
	["module_sonarr,doc_link"]="https://transmissionbt.com/"
	["module_sonarr,group"]="Downloaders"
	["module_sonarr,port"]="8989"
	["module_sonarr,arch"]="x86-64 arm64"
)
#
# Mmodule_sonarr
#
function module_sonarr () {
	local title="sonarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/sonarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/sonarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sonarr,example"]}"

	SONARR_BASE="${SOFTWARE_FOLDER}/sonarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$SONARR_BASE" ]] || mkdir -p "$SONARR_BASE" || { echo "Couldn't create storage directory: $SONARR_BASE"; exit 1; }
			docker run -d \
			--name=sonarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8989:8989 \
			-v "${SONARR_BASE}/config:/config" \
			-v "${SONARR_BASE}/tvseries:/tv" `#optional` \
			-v "${SONARR_BASE}/client:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/sonarr:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' sonarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs sonarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_sonarr,feature"]} ${commands[1]}
			[[ -n "${SONARR_BASE}" && "${SONARR_BASE}" != "/" ]] && rm -rf "${SONARR_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_sonarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_sonarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_sonarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_armbianrouter,author"]="@armbian"
	["module_armbianrouter,maintainer"]="@efectn"
	["module_armbianrouter,feature"]="module_armbianrouter"
	["module_armbianrouter,example"]="install remove purge status help"
	["module_armbianrouter,desc"]="Install armbian router container"
	["module_armbianrouter,status"]="Active"
	["module_armbianrouter,doc_link"]="https://github.com/armbian/armbian-router"
	["module_armbianrouter,group"]="Armbian"
	["module_armbianrouter,port"]="8080 8081 8082 8083 8084 8100"
	["module_armbianrouter,arch"]="x86-64 arm64"
)

function download_all_images() {
	wget -qO- https://github.armbian.com/all-images.json > "${1}/all-images.json"
}

#
# Module armbianrouter
#
function module_armbianrouter () {
	local title="armbianrouter"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a --format '{{.ID}} {{.Names}}' | mawk '$2 ~ /^armbianrouter/ {print $1}')
		local image=$(docker image ls -a | mawk '/armbian-router?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbianrouter,example"]}"

	ROUTER_BASE="${SOFTWARE_FOLDER}/armbian_router"

	declare -A routers
	routers["8080"]="dlrouter-debs"
	routers["8081"]="dlrouter-images"
	routers["8082"]="dlrouter-archive"
	routers["8083"]="dlrouter-debs-beta"
	routers["8084"]="dlrouter-cache"
	routers["8100"]="dlrouter-content"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$ROUTER_BASE" ]] || mkdir -p "$ROUTER_BASE" || { echo "Couldn't create storage directory: $ROUTER_BASE"; exit 1; }

			# Download all config yaml files
			for port in "${!routers[@]}"; do
				wget -qO- https://github.armbian.com/${routers[$port]}.yaml > "${ROUTER_BASE}/${routers[$port]}.yaml"
				sed -i "s|/scripts/redirect-config|/app|g" "${ROUTER_BASE}/${routers[$port]}.yaml"
			done

			# Download geoip database
			wget -qO- https://github.armbian.com/GeoLite2-ASN.mmdb > "${ROUTER_BASE}/GeoLite2-ASN.mmdb"
			wget -qO- https://github.armbian.com/GeoLite2-City.mmdb > "${ROUTER_BASE}/GeoLite2-City.mmdb"

			# Download all images json
			download_all_images "${ROUTER_BASE}"

			for port in "${!routers[@]}"; do
				docker run -d \
					--name=armbianrouter-${routers[$port]} \
					--net=lsio \
					-p $port:$port \
					-v "${ROUTER_BASE}:/app" \
					--restart unless-stopped \
					ghcr.io/armbian/armbian-router:latest /bin/dlrouter --config /app/${routers[$port]}.yaml
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' armbianrouter-${routers[$port]} >/dev/null 2>&1 ; then
						break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs armbianrouter-dlrouter-{debs,images,archive,debs-beta,cache}\`)"
						exit 1
					fi
				done
			done
		;;
		"${commands[1]}")
			for port in "${!routers[@]}"; do
				docker container rm -f armbianrouter-${routers[$port]} >/dev/null
			done

			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_armbianrouter,feature"]} ${commands[1]}
			if [[ -n "${ROUTER_BASE}" && "${ROUTER_BASE}" != "/" ]]; then
				rm -rf "${ROUTER_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_armbianrouter,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbianrouter,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_armbianrouter,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_navidrome,author"]="@armbian"
	["module_navidrome,maintainer"]="@igorpecovnik"
	["module_navidrome,feature"]="module_navidrome"
	["module_navidrome,example"]="install remove purge status help"
	["module_navidrome,desc"]="Install navidrome container"
	["module_navidrome,status"]="Active"
	["module_navidrome,doc_link"]="https://github.com/pynavidrome/navidrome/wiki"
	["module_navidrome,group"]="Downloaders"
	["module_navidrome,port"]="4533"
	["module_navidrome,arch"]="x86-64 arm64"
)
#
# Install Module navidrome
#
function module_navidrome () {
	local title="navidrome"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/navidrome?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/navidrome?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_navidrome,example"]}"

	NAVIDROME_BASE="${SOFTWARE_FOLDER}/navidrome"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NAVIDROME_BASE" ]] || mkdir -p "$NAVIDROME_BASE"/{music,data} || { echo "Couldn't create storage directory: $NAVIDROME_BASE"; exit 1; }
			sudo chown -R 1000:1000 "$NAVIDROME_BASE"/
			docker run -d \
			--name=navidrome \
			--net=lsio \
			--user 1000:1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 4533:4533 \
			-v "${NAVIDROME_BASE}/music:/music" \
			-v "${NAVIDROME_BASE}/data:/data" \
			--restart unless-stopped \
			deluan/navidrome:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' navidrome >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs navidrome\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then docker container rm -f "$container" >/dev/null; fi
			if [[ "${image}" ]]; then docker image rm "$image" >/dev/null; fi
		;;
		"${commands[2]}")
			${module_options["module_navidrome,feature"]} ${commands[1]}
			if [[ -n "${NAVIDROME_BASE}" && "${NAVIDROME_BASE}" != "/" ]]; then rm -rf "${NAVIDROME_BASE}"; fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_navidrome,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_navidrome,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_navidrome,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,maintainer"]="@schwar3kat"
	["module_portainer,feature"]="module_portainer"
	["module_portainer,example"]="install remove purge status help"
	["module_portainer,desc"]="Install/uninstall/check status of portainer container"
	["module_portainer,status"]="Active"
	["module_portainer,doc_link"]="https://docs.portainer.io/"
	["module_portainer,group"]="Containers"
	["module_portainer,port"]="9000 8000 9443"
	["module_portainer,arch"]="x86-64 arm64 armhf"
)
#
# Install Portainer
#
module_portainer() {
	local title="portainer"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_portainer,example"]}"

	PORTAINER_BASE="${SOFTWARE_FOLDER}/portainer"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PORTAINER_BASE" ]] || mkdir -p "$PORTAINER_BASE" || { echo "Couldn't create storage directory: $PORTAINER_BASE"; exit 1; }
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data
			docker run -d \
			--name=portainer \
			-p '9000:9000' \
			-p '8000:8000' \
			-p '9443:9443' \
			-v '/run/docker.sock:/var/run/docker.sock' \
			-v "${PORTAINER_BASE}/data:/data" \
			--restart=always \
			portainer/portainer-ce
			#-v '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro' \
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' portainer >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs portainer\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_portainer,feature"]} ${commands[1]}
			if [[ -n "${PORTAINER_BASE}" && "${PORTAINER_BASE}" != "/" ]]; then
				rm -rf "${PORTAINER_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_portainer,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_portainer,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_portainer,feature"]} ${commands[4]}
		;;
	esac
}

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
	["module_pi_hole,arch"]=""
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
			-e FTLCONF_dns_upstreams="${unbound_ip}" \
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
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


module_options+=(
	["module_owncloud,author"]="@armbian"
	["module_owncloud,maintainer"]="@igorpecovnik"
	["module_owncloud,feature"]="module_owncloud"
	["module_owncloud,example"]="install remove purge status help"
	["module_owncloud,desc"]="Install owncloud container"
	["module_owncloud,status"]="Active"
	["module_owncloud,doc_link"]="https://doc.owncloud.com/"
	["module_owncloud,group"]="Database"
	["module_owncloud,port"]="7787"
	["module_owncloud,arch"]="x86-64 arm64"
)
#
# Module owncloud
#
function module_owncloud () {
	local title="owncloud"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/owncloud?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/owncloud/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_owncloud,example"]}"

	OWNCLOUD_BASE="${SOFTWARE_FOLDER}/owncloud"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$OWNCLOUD_BASE" ]] || mkdir -p "$OWNCLOUD_BASE" || { echo "Couldn't create storage directory: $OWNCLOUD_BASE"; exit 1; }
			docker run -d \
			--name=owncloud \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e "OWNCLOUD_TRUSTED_DOMAINS=${LOCALIPADD}" \
			-p 7787:8080 \
			-v "${OWNCLOUD_BASE}/config:/config" \
			-v "${OWNCLOUD_BASE}/data:/mnt/data" \
			--restart unless-stopped \
			owncloud/server
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' owncloud >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs owncloud\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_owncloud,feature"]} ${commands[1]}
			if [[ -n "${OWNCLOUD_BASE}" && "${OWNCLOUD_BASE}" != "/" ]]; then
				rm -rf "${OWNCLOUD_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_owncloud,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_owncloud,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_owncloud,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_readarr,author"]="@armbian"
	["module_readarr,maintainer"]="@igorpecovnik"
	["module_readarr,feature"]="module_readarr"
	["module_readarr,example"]="install remove purge status help"
	["module_readarr,desc"]="Install readarr container"
	["module_readarr,status"]="Active"
	["module_readarr,doc_link"]="https://wiki.servarr.com/readarr"
	["module_readarr,group"]="Downloaders"
	["module_readarr,port"]="8787"
	["module_readarr,arch"]="x86-64 arm64"
)
#
# Module readarr
#
function module_readarr () {
	local title="readarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/readarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/readarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_readarr,example"]}"

	READARR_BASE="${SOFTWARE_FOLDER}/readarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$READARR_BASE" ]] || mkdir -p "$READARR_BASE" || { echo "Couldn't create storage directory: $READARR_BASE"; exit 1; }
			docker run -d \
			--name=readarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8787:8787 \
			-v "${READARR_BASE}/config:/config" \
			-v "${READARR_BASE}/books:/books" `#optional` \
			-v "${READARR_BASE}/client:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/readarr:develop
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' readarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs readarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_readarr,feature"]} ${commands[1]}
			[[ -n "${READARR_BASE}" && "${READARR_BASE}" != "/" ]] && rm -rf "${READARR_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_readarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_readarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_readarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_postgres,author"]=""
	["module_postgres,maintainer"]="@igorpecovnik"
	["module_postgres,feature"]="module_postgres"
	["module_postgres,example"]="install remove purge status help"
	["module_postgres,desc"]="Install PostgreSQL container (advanced relational database)"
	["module_postgres,status"]="Active"
	["module_postgres,doc_link"]="https://www.postgresql.org/docs/"
	["module_postgres,group"]="Database"
	["module_postgres,port"]="5432"
	["module_postgres,arch"]="x86-64 arm64"
)

#
# Module postgres
#
function module_postgres () {
	local title="postgres"
	local condition=$(which "$title" 2>/dev/null)

	# Accept optional parameters
	local POSTGRES_USER="$2"
	local POSTGRES_PASSWORD="$3"
	local POSTGRES_DB="$4"
	local POSTGRES_IMAGE="$5"
	local POSTGRES_CONTAINER="$6"

	# Defaults if nothing is set
	POSTGRES_USER="${POSTGRES_USER:-armbian}"
	POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-armbian}"
	POSTGRES_DB="${POSTGRES_DB:-armbian}"
	POSTGRES_IMAGE="${POSTGRES_IMAGE:-tensorchord/pgvecto-rs:pg14-v0.2.0}"
	POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-postgres}"

	if pkg_installed docker-ce; then
		local container=$(docker ps -q -f "name=^${POSTGRES_CONTAINER}$")
		local image=$(docker images -q $POSTGRES_IMAGE)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	POSTGRES_BASE="${SOFTWARE_FOLDER}/${POSTGRES_CONTAINER}"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$POSTGRES_BASE" ]] || mkdir -p "$POSTGRES_BASE" || { echo "Couldn't create storage directory: $POSTGRES_BASE"; exit 1; }
			# Download or update image
			docker pull $POSTGRES_IMAGE
			docker run -d \
			--name=${POSTGRES_CONTAINER} \
			--net=lsio \
			-e POSTGRES_USER=${POSTGRES_USER} \
			-e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
			-e POSTGRES_DB=${POSTGRES_DB} \
			-e TZ="$(cat /etc/timezone)" \
			-v "${POSTGRES_BASE}/${POSTGRES_CONTAINER}/data:/var/lib/postgresql/data" \
			--restart unless-stopped \
			${POSTGRES_IMAGE}
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' ${POSTGRES_CONTAINER} >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs ${POSTGRES_CONTAINER}\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "${container}" >/dev/null
			fi
			if [[ -n "${image}" ]]; then
				docker image rm "${image}" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_postgres,feature"]} ${commands[1]} $POSTGRES_USER $POSTGRES_PASSWORD $POSTGRES_DB $POSTGRES_IMAGE $POSTGRES_CONTAINER
			if [[ -n "${POSTGRES_BASE}" && "${POSTGRES_BASE}" != "/" ]]; then
				rm -rf "${POSTGRES_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			# Help
			echo -e "\nUsage: ${module_options["module_postgres,feature"]} <command> [username] [password] [database]"
			echo "Commands: ${module_options["module_postgres,example"]}"
			echo -e "\tinstall [username] [password] [database] - Install ${title} (defaults: armbian/armbian/armbian)"
			echo -e "\tremove - Remove ${title}"
			echo -e "\tpurge  - Purge ${title} data"
			echo -e "\tstatus - Check ${title} installation status"
			echo
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_wireguard,author"]="@armbian"
	["module_wireguard,maintainer"]="@igorpecovnik"
	["module_wireguard,feature"]="module_wireguard"
	["module_wireguard,example"]="pull client server remove purge qrcode image container servermode help"
	["module_wireguard,desc"]="Install wireguard container"
	["module_wireguard,status"]="Active"
	["module_wireguard,doc_link"]="https://docs.linuxserver.io/images/docker-wireguard/#server-mode"
	["module_wireguard,group"]="Network"
	["module_wireguard,port"]="51820"
	["module_wireguard,arch"]="x86-64 arm64"
)
#
# Module wireguard
#
function module_wireguard () {
	local title="wireguard"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wireguard,example"]}"

	WIREGUARD_BASE="${SOFTWARE_FOLDER}/wireguard"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			pkg_installed docker-ce || module_docker install

			# Create the base and config directory if it doesn't exist
			[[ -d "$WIREGUARD_BASE" ]] || mkdir -p "$WIREGUARD_BASE" || { echo "Couldn't create storage directory: $WIREGUARD_BASE"; exit 1; }
			[[ -d "$WIREGUARD_BASE/config/wg_confs/" ]] || mkdir -p "$WIREGUARD_BASE/config/wg_confs/" || { echo "Couldn't create config directory: $WIREGUARD_BASE/config/wg_confs/"; exit 1; }

			# Check if the image is already pulled
			${module_options["module_wireguard,feature"]} ${commands[6]}
			if [[ $? -ne 0 ]]; then
				docker pull lscr.io/linuxserver/wireguard:latest || { echo "Couldn't pull image: lscr.io/linuxserver/wireguard:latest"; exit 1; }
			fi
		;;
		"${commands[1]}")

			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			# Create temp file
			TMP_FILE=$(mktemp)

			# Optional initial content
			if [[ -f "${WIREGUARD_BASE}/config/wg_confs/client.conf" ]]; then
				cp "${WIREGUARD_BASE}/config/wg_confs/client.conf" "$TMP_FILE"
			else
				echo "# WireGuard client configuration file" > "$TMP_FILE"
			fi

			# Ask user to edit content
			${EDITOR:-nano} "$TMP_FILE"

			# Use `install` to move the file with correct owner and permissions
			rm -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf"
			install -m 600 -o 1000 -g 1000 "$TMP_FILE" "${WIREGUARD_BASE}/config/wg_confs/client.conf"
			rm -f "$TMP_FILE"

			# Check if the container is running, if so, remove it
			${module_options["module_wireguard,feature"]} ${commands[7]}
			if [[ $? -eq 0 ]]; then
				docker rm -f wireguard >/dev/null 2>&1
			fi

			# Get local subnets from user input or use default
			if [[ -z $2 ]]; then
				LOCAL_SUBNETS=$($DIALOG --title "Enter comma delimited subnets for routing" --inputbox "\n* delete if this is not your local subnet \n" 9 70 "10.0.10.0/24" 3>&1 1>&2 2>&3)
			else
				LOCAL_SUBNETS="$2"
			fi

			docker run -d \
			--name=wireguard \
			--net=lsio \
			--cap-add=NET_ADMIN \
			--cap-add=SYS_MODULE \
			--privileged \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-v "${WIREGUARD_BASE}/config:/config" \
			--restart unless-stopped \
			--sysctl net.ipv4.ip_forward=1 \
			lscr.io/linuxserver/wireguard:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard >/dev/null 2>&1 && [[ -f "${WIREGUARD_BASE}/config/wg_confs/client.conf" ]]; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs wireguard\`)"
					exit 1
				fi
			done
			if [[ -n "${LOCAL_SUBNETS}" ]]; then
				# Create host-side route helper script for LAN routing via WireGuard container
				cat > "/usr/local/bin/add-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash

				docker exec wireguard iptables -t nat -A POSTROUTING -o client -j MASQUERADE

				# Get the IP address of the WireGuard container dynamically
				CONTAINER_IP=\$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' wireguard)

				if [[ -z "\$CONTAINER_IP" ]]; then
					echo "WireGuard container not found or not running"
					exit 1
				fi

				echo "Adding LAN routes via container IP: \$CONTAINER_IP"

				# Add route for specific LAN subnets (customize as needed)
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route add $subnet via \"\$CONTAINER_IP\"" >> /usr/local/bin/add-vpn-lan-routes.sh
				done

				cat > "/usr/local/bin/remove-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash
				docker exec wireguard iptables -t nat -C POSTROUTING -o client -j MASQUERADE 2>/dev/null && \
				docker exec wireguard iptables -t nat -D POSTROUTING -o client -j MASQUERADE || true
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route show \"$subnet\" | grep -q \"$subnet\" && ip route del \"$subnet\" || true" >> /usr/local/bin/remove-vpn-lan-routes.sh
				done

				chmod +x /usr/local/bin/add-vpn-lan-routes.sh
				chmod +x /usr/local/bin/remove-vpn-lan-routes.sh

				echo -e "\n✅ Created: /usr/local/bin/add-vpn-lan-routes.sh"
				echo -e "Run this script to restore LAN routes via the WireGuard container."

				echo -e "\n✅ Created: /usr/local/bin/remove-vpn-lan-routes.sh"
				echo -e "Run this script to remove LAN routes via the WireGuard container."

				cat > "/etc/systemd/system/add-vpn-lan-routes.service" <<- EOT
				[Unit]
				Description=Add routes for LAN via WireGuard Docker container
				After=network-online.target docker.service
				Wants=network-online.target

				[Service]
				Type=oneshot
				ExecStart=/usr/local/bin/add-vpn-lan-routes.sh
				RemainAfterExit=yes

				[Install]
				WantedBy=multi-user.target
				EOT

				# Remove routes just in case they were added before
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true

				systemctl daemon-reexec
				systemctl daemon-reload
				systemctl enable add-vpn-lan-routes.service
				systemctl restart add-vpn-lan-routes.service
			fi
		;;
		"${commands[2]}")

			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			if [[ -z $2 ]]; then
				NUMBER_OF_PEERS=$($DIALOG --title "Enter comma delimited peer keywords" --inputbox " \n" 7 50 "laptop" 3>&1 1>&2 2>&3)
			fi
			if [[ $? -eq 0 ]]; then
				${module_options["module_wireguard,feature"]} ${commands[7]}
				if [[ $? -eq 0 ]]; then
					docker rm -f wireguard >/dev/null 2>&1
				fi

				# Remove client config if any
				rm -f "${WIREGUARD_BASE}/config/wg_confs/client.conf"

				docker run -d \
				--name=wireguard \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE `#optional` \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e SERVERURL=auto \
				-e SERVERPORT=51820 \
				-e PEERS="${NUMBER_OF_PEERS}" \
				-e PEERDNS=auto \
				-e INTERNAL_SUBNET=10.13.13.0 \
				-e ALLOWEDIPS=0.0.0.0/0 \
				-e PERSISTENTKEEPALIVE_PEERS= \
				-e LOG_CONFS=true \
				-p 51820:51820/udp \
				-v "${WIREGUARD_BASE}/config:/config" \
				--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
				--restart unless-stopped \
				lscr.io/linuxserver/wireguard:latest
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard >/dev/null 2>&1 && [[ -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf" ]]; then
							break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs wireguard\`)"
						exit 1
					fi
				done
				${module_options["module_wireguard,feature"]} ${commands[5]}
			fi
		;;
		"${commands[3]}")
			if srv_active add-vpn-lan-routes; then
				srv_stop add-vpn-lan-routes.service
				srv_disable add-vpn-lan-routes.service
			fi
			# Run route removal script only if it exists, ignore errors
			if [[ -f "/usr/local/bin/remove-vpn-lan-routes.sh" ]]; then
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true
			fi
			# Remove files
			rm -f /usr/local/bin/add-vpn-lan-routes.sh
			rm -f /usr/local/bin/remove-vpn-lan-routes.sh
			rm -f /etc/systemd/system/add-vpn-lan-routes.service
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[4]}")
			${module_options["module_wireguard,feature"]} ${commands[3]}
			[[ -n "${WIREGUARD_BASE}" && "${WIREGUARD_BASE}" != "/" ]] && rm -rf "${WIREGUARD_BASE}"
		;;
		"${commands[5]}")
			if [[ -z $2 ]]; then
				LIST=($(ls -1 ${WIREGUARD_BASE}/config/ | grep peer | cut -d"_" -f2))
				LIST_LENGTH=$((${#LIST[@]} / 2))
				SELECTED_PEER=$(dialog --title "Select peer" --no-items --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			fi
			if [[ -n ${SELECTED_PEER} ]]; then
				clear
				docker exec -it wireguard /app/show-peer ${SELECTED_PEER}
				cat ${WIREGUARD_BASE}/config/peer_${SELECTED_PEER}/peer_${SELECTED_PEER}.conf
				read
			fi
		;;
		"${commands[6]}")
			if pkg_installed docker-ce; then
				local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
			fi
			if [[ "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[7]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
			fi
			if [[ "${container}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[8]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
				local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
			fi
			if [[ "${container}" && "${image}" && -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[9]}")
			echo -e "\nUsage: ${module_options["module_wireguard,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_wireguard,example"]}"
			echo "Available commands:"
			echo -e "\tpull\t\t- Pull $title image."
			echo -e "\tclient\t\t- Add client config $title."
			echo -e "\tserver\t\t- Add server config $title."
			echo -e "\tremove\t\t- Remove $title."
			echo -e "\tpurge\t\t- Purge $title with data."
			echo -e "\tqrcode\t\t- Show qrcodes for clients $title."
			echo -e "\timage\t\t- Image download status $title."
			echo -e "\tcontainer\t- Container run status $title."
			echo
		;;
		*)
			${module_options["module_wireguard,feature"]} ${commands[9]}
		;;
	esac
}

module_options+=(
	["module_omv,author"]="@igorpecovnik"
	["module_omv,maintainer"]="@igorpecovnik"
	["module_omv,feature"]="module_omv"
	["module_omv,example"]="install remove status help"
	["module_omv,desc"]="Install OpenMediaVault (OMV)"
	["module_omv,status"]="Active"
	["module_omv,doc_link"]="https://docs.openmediavault.org/en/stable/"
	["module_omv,group"]="NAS"
	["module_omv,port"]="80"
	["module_omv,arch"]="amd64 arm64 armhf"
	["module_omv,release"]="bookworm"
)

function module_omv() {
	local title="openmediavault"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_omv,example"]}"

	case "$1" in
		"${commands[0]}")
			echo "Adding GPG key for OpenMediaVault..."
			curl --max-time 60 -4 -fsSL "https://packages.openmediavault.org/public/archive.key" | \
			gpg --dearmor -o /usr/share/keyrings/openmediavault-archive-keyring.gpg

			echo "Adding OMV sources.list..."
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] \
			https://packages.openmediavault.org/public sandworm main" | \
			tee /etc/apt/sources.list.d/openmediavault.list

			pkg_update

			echo "Installing OpenMediaVault packages..."
			DEBIAN_FRONTEND=noninteractive pkg_install --yes --auto-remove --show-upgraded \
			--allow-downgrades --allow-change-held-packages \
			--no-install-recommends \
			--option DPkg::Options::="--force-confdef" \
			--option DPkg::Options::="--force-confold" \
			openmediavault

		;;
		"${commands[1]}")
			if pkg_installed openmediavault 2>/dev/null; then
				DEBIAN_FRONTEND=noninteractive pkg_remove openmediavault
			fi
		;;
		"${commands[2]}")
			if pkg_installed openmediavault 2>/dev/null; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_omv,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_omv,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_omv,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_duplicati,author"]=""
	["module_duplicati,maintainer"]="@igorpecovnik"
	["module_duplicati,feature"]="module_duplicati"
	["module_duplicati,example"]="install remove purge status help"
	["module_duplicati,desc"]="Install duplicati container"
	["module_duplicati,status"]="Active"
	["module_duplicati,doc_link"]="https://prev-docs.duplicati.com/en/latest/"
	["module_duplicati,group"]="Backup"
	["module_duplicati,port"]="8200"
	["module_duplicati,arch"]="x86-64 arm64"
)
#
# Module duplicati
#
function module_duplicati () {
	local title="duplicati"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/duplicati?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/duplicati?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_duplicati,example"]}"

	DUPLICATI_BASE="${SOFTWARE_FOLDER}/duplicati"

	case "$1" in
		"${commands[0]}")
			shift
			# Accept encryption key and WebUI password from parameters if provided
			local DUPLICATI_ENCRYPTION_KEY="$1"
			local DUPLICATI_WEBUI_PASSWORD="$2"

			pkg_installed docker-ce || module_docker install
			[[ -d "$DUPLICATI_BASE" ]] || mkdir -p "$DUPLICATI_BASE" || { echo "Couldn't create storage directory: $DUPLICATI_BASE"; exit 1; }

			# If no encryption key provided, prompt for it
			if [[ -z "${DUPLICATI_ENCRYPTION_KEY}" ]]; then
				DUPLICATI_ENCRYPTION_KEY=$($DIALOG --title "Duplicati Encryption Key" --inputbox "\nEnter an encryption key for Duplicati (at least 8 characters):" 9 60 "" 3>&1 1>&2 2>&3)
			fi

			# Check encryption key length
			if [[ -z "${DUPLICATI_ENCRYPTION_KEY}" || ${#DUPLICATI_ENCRYPTION_KEY} -lt 8 ]]; then
				echo -e "\nError: Encryption key must be at least 8 characters long!"
				exit 1
			fi

			# If no WebUI password provided, prompt for it
			if [[ -z "${DUPLICATI_WEBUI_PASSWORD}" ]]; then
				DUPLICATI_WEBUI_PASSWORD=$($DIALOG --title "Duplicati WebUI Password" --inputbox "\nEnter a password for Duplicati WebUI (at least 8 characters):" 9 60 "" 3>&1 1>&2 2>&3)
			fi

			# Check WebUI password length
			if [[ -z "${DUPLICATI_WEBUI_PASSWORD}" || ${#DUPLICATI_WEBUI_PASSWORD} -lt 8 ]]; then
				echo -e "\nError: WebUI password must be at least 8 characters long!"
				exit 1
			fi

			docker run -d \
			--name=duplicati \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e SETTINGS_ENCRYPTION_KEY="${DUPLICATI_ENCRYPTION_KEY}" \
			-e DUPLICATI__WEBSERVICE_PASSWORD="${DUPLICATI_WEBUI_PASSWORD}" \
			-p 8200:8200 \
			-v "${DUPLICATI_BASE}/config:/config" \
			-v "${DUPLICATI_BASE}/backups:/backups" \
			-v /:/source:ro \
			--restart unless-stopped \
			lscr.io/linuxserver/duplicati:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' duplicati >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs duplicati\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "${container}" >/dev/null
			fi

			if [[ -n "${image}" ]]; then
				docker image rm "${image}" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_duplicati,feature"]} ${commands[1]}
			if [[ -n "${DUPLICATI_BASE}" && "${DUPLICATI_BASE}" != "/" ]]; then
				rm -rf "${DUPLICATI_BASE}"
			fi

		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_duplicati,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_duplicati,example"]}"
			echo "Available commands:"
			echo -e "\tinstall [key] [password] - Install $title. (parameters optional)"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_duplicati,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_homepage,author"]="@armbian"
	["module_homepage,maintainer"]="@igorpecovnik"
	["module_homepage,feature"]="module_homepage"
	["module_homepage,example"]="install remove purge status help"
	["module_homepage,desc"]="Install homepage container"
	["module_homepage,status"]="Active"
	["module_homepage,doc_link"]="https://gethomepage.dev/configs/"
	["module_homepage,group"]="Management"
	["module_homepage,port"]="3021"
	["module_homepage,arch"]=""
)
#
# Module homepage
#
function module_homepage () {
	local title="homepage"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/homepage?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/homepage( |$ )/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_homepage,example"]}"

	HOMEPAGE_BASE="${SOFTWARE_FOLDER}/homepage"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || install_docker
			[[ -d "$HOMEPAGE_BASE" ]] || mkdir -p "$HOMEPAGE_BASE" || { echo "Couldn't create storage directory: $HOMEPAGE_BASE"; exit 1; }

			docker run -d \
			--net=lsio \
			--name homepage \
			-e PUID=1000 \
			-e PGID=1000 \
			-e HOMEPAGE_ALLOWED_HOSTS=${LOCALIPADD}:${module_options["module_homepage,port"]},homepage.local:${module_options["module_homepage,port"]},localhost:${module_options["module_homepage,port"]} \
			-p ${module_options["module_homepage,port"]}:3000 \
			-v "${HOMEPAGE_BASE}/config:/app/config" \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart unless-stopped \
			ghcr.io/gethomepage/homepage:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' homepage >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs homepage\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_homepage,feature"]} ${commands[1]}
			[[ -n "${HOMEPAGE_BASE}" && "${HOMEPAGE_BASE}" != "/" ]] && rm -rf "${HOMEPAGE_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_homepage,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_homepage,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove $title and delete its data."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_homepage,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_mariadb,author"]="@igorpecovnik"
	["module_mariadb,maintainer"]="@igorpecovnik"
	["module_mariadb,feature"]="module_mariadb"
	["module_mariadb,example"]="install remove purge status help"
	["module_mariadb,desc"]="Install mariadb container"
	["module_mariadb,status"]="Active"
	["module_mariadb,doc_link"]="https://mariadb.org/documentation/"
	["module_mariadb,group"]="Database"
	["module_mariadb,port"]="3307"
	["module_mariadb,arch"]="x86-64 arm64"
)
#
# Module mariadb-PDF
#
function module_mariadb () {
	local title="mariadb"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/mariadb?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/mariadb?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mariadb,example"]}"

	MARIADB_BASE="${SOFTWARE_FOLDER}/mariadb"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$MARIADB_BASE" ]] || mkdir -p "$MARIADB_BASE" || { echo "Couldn't create storage directory: $MARIADB_BASE"; exit 1; }

			# get parameters
			MYSQL_ROOT_PASSWORD=$($DIALOG --title "Enter root password for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_DATABASE=$($DIALOG --title "Enter database name for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_USER=$($DIALOG --title "Enter user name for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_PASSWORD=$($DIALOG --title "Enter new password for ${MYSQL_USER}" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			docker run -d \
			--name=mariadb \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" \
			-e "MYSQL_DATABASE=${MYSQL_DATABASE}" \
			-e "MYSQL_USER=${MYSQL_USER}" \
			-e "MYSQL_PASSWORD=${MYSQL_PASSWORD}" \
			-p ${module_options["module_mariadb,port"]}:3306 \
			-v "${MARIADB_BASE}/config:/config" \
			--restart unless-stopped \
			lscr.io/linuxserver/mariadb:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' mariadb >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs mariadb\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_mariadb,feature"]} ${commands[1]}
			if [[ -n "${MARIADB_BASE}" && "${MARIADB_BASE}" != "/" ]]; then
				rm -rf "${MARIADB_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_mariadb,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_mariadb,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_mariadb,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,maintainer"]="@igorpecovnik"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,example"]="install remove status help"
	["module_watchtower,desc"]="Install watchtower container"
	["module_watchtower,status"]="Active"
	["module_watchtower,doc_link"]="https://containrrr.dev/watchtower/"
	["module_watchtower,group"]="Updates"
	["module_watchtower,port"]=""
	["module_watchtower,arch"]="x86-64 arm64"
)
#
# Module watchtower
#
function module_watchtower () {
	local title="watchtower"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/watchtower?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/watchtower?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			docker run -d \
			--net=lsio \
			--name watchtower \
			-v /var/run/docker.sock:/var/run/docker.sock \
			containrrr/watchtower
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' watchtower >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs watchtower\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_watchtower,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_watchtower,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_watchtower,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_radarr,author"]="@armbian"
	["module_radarr,maintainer"]="@igorpecovnik"
	["module_radarr,feature"]="module_radarr"
	["module_radarr,example"]="install remove purge status help"
	["module_radarr,desc"]="Install radarr container"
	["module_radarr,status"]="Active"
	["module_radarr,doc_link"]="https://wiki.servarr.com/radarr"
	["module_radarr,group"]="Downloaders"
	["module_radarr,port"]="7878"
	["module_radarr,arch"]="x86-64 arm64"
)
#
# Module radarr
#
function module_radarr () {
	local title="radarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/radarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/radarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_radarr,example"]}"

	RADARR_BASE="${SOFTWARE_FOLDER}/radarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$RADARR_BASE" ]] || mkdir -p "$RADARR_BASE" || { echo "Couldn't create storage directory: $RADARR_BASE"; exit 1; }
			docker run -d \
			--name=radarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 7878:7878 \
			-v "${RADARR_BASE}/config:/config" \
			-v "${RADARR_BASE}/movies:/movies" `#optional` \
			-v "${RADARR_BASE}/client:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/radarr:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' radarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs radarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_radarr,feature"]} ${commands[1]}
			[[ -n "${RADARR_BASE}" && "${RADARR_BASE}" != "/" ]] && rm -rf "${RADARR_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_radarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_radarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_radarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_netdata,author"]="@armbian"
	["module_netdata,maintainer"]="@igorpecovnik"
	["module_netdata,feature"]="module_netdata"
	["module_netdata,example"]="install remove purge status help"
	["module_netdata,desc"]="Install netdata container"
	["module_netdata,status"]="Active"
	["module_netdata,doc_link"]="https://transmissionbt.com/"
	["module_netdata,group"]="Monitoring"
	["module_netdata,port"]="19999"
	["module_netdata,arch"]="x86-64 arm64"
)
#
# Module netdata
#
function module_netdata () {
	local title="netdata"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/netdata?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/netdata?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netdata,example"]}"

	NETDATA_BASE="${SOFTWARE_FOLDER}/netdata"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NETDATA_BASE" ]] || mkdir -p "$NETDATA_BASE" || { echo "Couldn't create storage directory: $NETDATA_BASE"; exit 1; }
			docker run -d \
			--name=netdata \
			--pid=host \
			--network=host \
			-v "${NETDATA_BASE}/netdataconfig:/etc/netdata" \
			-v "${NETDATA_BASE}/netdatalib:/var/lib/netdata" \
			-v "${NETDATA_BASE}/netdatacache:/var/cache/netdata" \
			-v /:/host/root:ro,rslave \
			-v /etc/passwd:/host/etc/passwd:ro \
			-v /etc/group:/host/etc/group:ro \
			-v /etc/localtime:/etc/localtime:ro \
			-v /proc:/host/proc:ro \
			-v /sys:/host/sys:ro \
			-v /etc/os-release:/host/etc/os-release:ro \
			-v /var/log:/host/var/log:ro \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart unless-stopped \
			--cap-add SYS_PTRACE \
			--cap-add SYS_ADMIN \
			--security-opt apparmor=unconfined \
			netdata/netdata
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' netdata >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs netdata\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_netdata,feature"]} ${commands[1]}
			if [[ -n "${NETDATA_BASE}" && "${NETDATA_BASE}" != "/" ]]; then
				rm -rf "${NETDATA_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_netdata,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netdata,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_netdata,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_stirling,author"]="@Frooodle"
	["module_stirling,maintainer"]="@igorpecovnik"
	["module_stirling,feature"]="module_stirling"
	["module_stirling,example"]="install remove purge status help"
	["module_stirling,desc"]="Install stirling container"
	["module_stirling,status"]="Active"
	["module_stirling,doc_link"]="https://docs.stirlingpdf.com"
	["module_stirling,group"]="Media"
	["module_stirling,port"]="8075"
	["module_stirling,arch"]="x86-64 arm64"
)
#
# Module stirling-PDF
#
function module_stirling () {
	local title="stirling"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/stirling-pdf?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/stirling-pdf?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_stirling,example"]}"

	STIRLING_BASE="${SOFTWARE_FOLDER}/stirling"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$STIRLING_BASE" ]] || mkdir -p "$STIRLING_BASE" || { echo "Couldn't create storage directory: $STIRLING_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-p ${module_options["module_stirling,port"]}:8080 \
			-v "${STIRLING_BASE}/trainingData:/usr/share/tessdata" \
			-v "${STIRLING_BASE}/extraConfigs:/configs" \
			-v "${STIRLING_BASE}/logs:/logs" \
			-v "${STIRLING_BASE}/customFiles:/customFiles" \
			-e DOCKER_ENABLE_SECURITY=false \
			-e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
			-e LANGS=en_GB \
			--name stirling-pdf \
			--restart unless-stopped \
			stirlingtools/stirling-pdf:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' stirling-pdf >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs stirling-pdf\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_stirling,feature"]} ${commands[1]}
			[[ -n "${STIRLING_BASE}" && "${STIRLING_BASE}" != "/" ]] && rm -rf "${STIRLING_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_stirling,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_stirling,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_stirling,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_zerotier,author"]="@jnovos"
	["module_zerotier,maintainer"]="@jnovos"
	["module_zerotier,feature"]="module_zerotier"
	["module_zerotier,ref_link"]="https://github.com/jnovos/configng/"
	["module_zerotier,desc"]="Install Zerotier"
	["module_zerotier,example"]="help install remove start stop enable disable status check"
	["module_zerotier,doc_link"]="https://docs.zerotier.com/wat"
	["module_zerotier,status"]="Active"
	["module_zerotier,group"]="VPN"
	["module_zerotier,arch"]="x86-64 arm64 armhf"
)

function module_zerotier() {
	local title="zerotier-one"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zerotier,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_zerotier,feature"]} <command>"
			echo -e "Commands: ${module_options["module_zerotier,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else
				if srv_active zerotier-one; then
					echo -e "\tstop\t- Stop the $title service."
					echo -e "\tdisable\t- Disable $title from starting on boot."
				else
					echo -e "\tenable\t- Enable $title to start on boot."
					echo -e "\tstart\t- Start the $title service."
				fi
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."
			fi
			echo
		;;
		"${commands[1]}")
			## install zerotier-one
			pkg_update
			curl -fsSL http://download.zerotier.com/contact%40zerotier.com.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/zerotier.gpg > /dev/null
			echo "deb http://download.zerotier.com/debian/$DISTROID $DISTROID main" | sudo tee /etc/apt/sources.list.d/zerotier.list
			pkg_update
			pkg_install zerotier-one
			echo "Zerotier installed successfully."
		;;
		"${commands[2]}")
			## remove zerotier-one
			srv_disable zerotier-one
			pkg_remove zerotier-one
			rm -R /var/lib/zerotier-one
			rm /etc/apt/trusted.gpg.d/zerotier.gpg
			rm /etc/apt/sources.list.d/zerotier.list
			pkg_update
			echo "Zerotier removed successfully."
		;;

		"${commands[3]}")
			srv_start zerotier-one
			echo "Zerotier service started."
		;;

		"${commands[4]}")
			srv_stop zerotier-one
			echo "Zerotier service stopped."
		;;

		"${commands[5]}")
			srv_enable zerotier-one
			echo "Zerotier service enabled."
		;;

		"${commands[6]}")
			srv_disable zerotier-one
			echo "Zerotier service disabled."
		;;

		"${commands[7]}")
			if srv_active zerotier-one ; then
				echo -e "\033[0;32m****** Active *****\033[0m"
			else
				echo -e "\033[0;31m****** Inactive *****\033[0m"
			fi
		;;

		"${commands[8]}")
			## check zerotier-one status
			if srv_active zerotier-one; then
				echo "Zerotier service is active."
				return 0
			elif ! srv_enabled zerotier-one ]]; then
				echo "Zerotier service is disabled."
				return 1
			else
				echo "Zerotier service is in an unknown state."
				return 1
			fi
		;;
		*)
			echo "Invalid command.try: '${module_options["module_zerotier,example"]}'"
		;;
	esac
}

module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,maintainer"]="@igorpecovnik"
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,example"]="install remove purge status help"
	["module_uptimekuma,desc"]="Install uptimekuma container"
	["module_uptimekuma,status"]="Active"
	["module_uptimekuma,doc_link"]="https://github.com/louislam/uptime-kuma/wiki"
	["module_uptimekuma,group"]="Downloaders"
	["module_uptimekuma,port"]="3001"
	["module_uptimekuma,arch"]="x86-64 arm64"
)
#
# Module uptimekuma
#
function module_uptimekuma () {
	local title="uptimekuma"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/uptime-kuma?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/uptime-kuma?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_uptimekuma,example"]}"

	UPTIMEKUMA_BASE="${SOFTWARE_FOLDER}/uptimekuma"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$UPTIMEKUMA_BASE" ]] || mkdir -p "$UPTIMEKUMA_BASE" || { echo "Couldn't create storage directory: $UPTIMEKUMA_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name uptime-kuma \
			--restart=always \
			-p 3001:3001 \
			-v "${UPTIMEKUMA_BASE}:/app/data" \
			louislam/uptime-kuma:1
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' uptime-kuma >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs uptimekuma\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_uptimekuma,feature"]} ${commands[1]}
			if [[ -n "${UPTIMEKUMA_BASE}" && "${UPTIMEKUMA_BASE}" != "/" ]]; then
				rm -rf "${UPTIMEKUMA_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_uptimekuma,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_uptimekuma,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_uptimekuma,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_evcc,author"]="@naltatis"
	["module_evcc,maintainer"]="@igorpecovnik"
	["module_evcc,feature"]="module_evcc"
	["module_evcc,example"]="install remove purge status help"
	["module_evcc,desc"]="Install evcc container"
	["module_evcc,status"]="Active"
	["module_evcc,doc_link"]="https://docs.evcc.io/en"
	["module_evcc,group"]="HomeAutomation"
	["module_evcc,port"]="7070"
	["module_evcc,arch"]=""
)
#
# Module evcc: Solar charging. Super simple
#
function module_evcc () {
	local title="evcc"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/evcc?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/evcc?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_evcc,example"]}"

	EVCC_BASE="${SOFTWARE_FOLDER}/evcc"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$EVCC_BASE" ]] || mkdir -p "$EVCC_BASE" || { echo "Couldn't create storage directory: $EVCC_BASE"; exit 1; }
			touch "${EVCC_BASE}/evcc.yaml"
			docker run -d \
			--net=lsio \
			--name evcc \
			-v "${EVCC_BASE}/evcc.yaml:/app/evcc.yaml" \
			-v "${EVCC_BASE}/.evcc:/root/.evcc" \
			-v /etc/machine-id:/etc/machine-id \
			-p 7070:7070 \
			-p 8887:8887 \
			-p 9522:9522/udp \
			-p 4712:4712 \
			evcc/evcc:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' evcc >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs evcc\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_evcc,feature"]} ${commands[1]}
			if [[ -n "${EVCC_BASE}" && "${EVCC_BASE}" != "/" ]]; then
				rm -rf "${EVCC_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_evcc,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_evcc,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_evcc,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_qbittorrent,author"]="@qbittorrent"
	["module_qbittorrent,maintainer"]="@igorpecovnik"
	["module_qbittorrent,feature"]="module_qbittorrent"
	["module_qbittorrent,example"]="install remove purge status help"
	["module_qbittorrent,desc"]="Install qbittorrent container"
	["module_qbittorrent,status"]="Active"
	["module_qbittorrent,doc_link"]="https://github.com/qbittorrent/qBittorrent/wiki/"
	["module_qbittorrent,group"]="Downloaders"
	["module_qbittorrent,port"]="8090 6881"
	["module_qbittorrent,arch"]="x86-64 arm64"
)
#
# Module qbittorrent
#
function module_qbittorrent () {

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/qbittorrent?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/qbittorrent?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_qbittorrent,example"]}"

	QBITTORRENT_BASE="${SOFTWARE_FOLDER}/qbittorrent"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$QBITTORRENT_BASE" ]] || mkdir -p "$QBITTORRENT_BASE" || { echo "Couldn't create storage directory: $QBITTORRENT_BASE"; exit 1; }
			docker run -d \
			--name=qbittorrent \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e WEBUI_PORT=8090 \
			-e TORRENTING_PORT=6881 \
			-p 8090:8090 \
			-p 6881:6881 \
			-p 6881:6881/udp \
			-v "${QBITTORRENT_BASE}/config:/config" \
			-v "${QBITTORRENT_BASE}/downloads:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/qbittorrent:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' qbittorrent >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs qbittorrent\`)"
					exit 1
				fi
			done
			sleep 3
			TEMP_PASSWORD=$(docker logs qbittorrent 2>&1 | grep password | grep session | cut -d":" -f2 | xargs)
			dialog --msgbox "Qbittorrent is listening at http://$LOCALIPADD:${module_options["module_qbittorrent,port"]% *}\n\nLogin as: admin\n\nTemporally password: ${TEMP_PASSWORD} " 9 70
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_qbittorrent,feature"]} ${commands[1]}
			[[ -n "${QBITTORRENT_BASE}" && "${QBITTORRENT_BASE}" != "/" ]] && rm -rf "${QBITTORRENT_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_qbittorrent,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_qbittorrent,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_qbittorrent,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_unbound,author"]="@igorpecovnik"
	["module_unbound,maintainer"]="@igorpecovnik"
	["module_unbound,feature"]="module_unbound"
	["module_unbound,example"]="install remove purge status help"
	["module_unbound,desc"]="Install unbound container"
	["module_unbound,status"]="Active"
	["module_unbound,doc_link"]="https://unbound.docs.nlnetlabs.nl/en/latest/"
	["module_unbound,group"]="DNS"
	["module_unbound,port"]="8053"
	["module_unbound,arch"]="x86-64"
)
#
# Module Unbound
#
function module_unbound () {
	local title="unbound"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/unbound?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/unbound?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_unbound,example"]}"

	UNBOUND_BASE="${SOFTWARE_FOLDER}/unbound"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$UNBOUND_BASE" ]] || mkdir -p "$UNBOUND_BASE" || { echo "Couldn't create storage directory: $UNBOUND_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-p ${module_options["module_unbound,port"]}:53/tcp \
			-p ${module_options["module_unbound,port"]}:53/udp \
			--name unbound \
			--restart=unless-stopped \
			mvance/unbound:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' unbound >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs unbound\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_unbound,feature"]} ${commands[1]}
			[[ -n "${UNBOUND_BASE}" && "${UNBOUND_BASE}" != "/" ]] && rm -rf "${UNBOUND_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_unbound,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_unbound,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_unbound,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_medusa,author"]="@armbian"
	["module_medusa,maintainer"]="@igorpecovnik"
	["module_medusa,feature"]="module_medusa"
	["module_medusa,example"]="install remove purge status help"
	["module_medusa,desc"]="Install medusa container"
	["module_medusa,status"]="Active"
	["module_medusa,doc_link"]="https://github.com/pymedusa/Medusa/wiki"
	["module_medusa,group"]="Downloaders"
	["module_medusa,port"]="8081"
	["module_medusa,arch"]="x86-64 arm64"
)
#
# Install Module medusa
#
function module_medusa () {
	local title="Medusa"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/medusa?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/medusa?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_medusa,example"]}"

	MEDUSA_BASE="${SOFTWARE_FOLDER}/medusa"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$MEDUSA_BASE" ]] || mkdir -p "$MEDUSA_BASE" || { echo "Couldn't create storage directory: $MEDUSA_BASE"; exit 1; }
			docker run -d \
			--name=medusa \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8081:8081 \
			-v "${MEDUSA_BASE}/config:/config" \
			-v "${MEDUSA_BASE}/downloads:/downloads" \
			-v "${MEDUSA_BASE}/downloads/tv:/tv" \
			--restart unless-stopped \
			lscr.io/linuxserver/medusa:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' medusa >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs medusa\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_medusa,feature"]} ${commands[1]}
			if [[ -n "${MEDUSA_BASE}" && "${MEDUSA_BASE}" != "/" ]]; then
				rm -rf "${MEDUSA_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_medusa,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_medusa,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_medusa,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_domoticz,author"]="@armbian"
	["module_domoticz,maintainer"]="@igorpecovnik"
	["module_domoticz,feature"]="module_domoticz"
	["module_domoticz,example"]="install remove purge status help"
	["module_domoticz,desc"]="Install domoticz container"
	["module_domoticz,status"]="Active"
	["module_domoticz,doc_link"]="https://wiki.domoticz.com"
	["module_domoticz,group"]="Monitoring"
	["module_domoticz,port"]="8780"
	["module_domoticz,arch"]=""
)
#
# Module domoticz
#
function module_domoticz () {
	local title="domoticz"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/domoticz?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/domoticz?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_domoticz,example"]}"

	DOMOTICZ_BASE="${SOFTWARE_FOLDER}/domoticz"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$DOMOTICZ_BASE" ]] || mkdir -p "$DOMOTICZ_BASE" || { echo "Couldn't create storage directory: $DOMOTICZ_BASE"; exit 1; }
			docker run -d \
			--name=domoticz \
			--pid=host \
			--net=lsio \
			--device /dev/ttyUSB0:/dev/ttyUSB0 \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_domoticz,port"]}:8080 \
			-p 8443:443 \
			-v "${DOMOTICZ_BASE}:/opt/domoticz/userdata" \
			--restart unless-stopped \
			domoticz/domoticz:stable
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' domoticz >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs domoticz\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_domoticz,feature"]} ${commands[1]}
			if [[ -n "${DOMOTICZ_BASE}" && "${DOMOTICZ_BASE}" != "/" ]]; then
				rm -rf "${DOMOTICZ_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_domoticz,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_domoticz,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_domoticz,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_adguardhome,author"]="@igorpecovnik"
	["module_adguardhome,maintainer"]="@igorpecovnik"
	["module_adguardhome,feature"]="module_adguardhome"
	["module_adguardhome,example"]="install remove purge status help"
	["module_adguardhome,desc"]="Install adguardhome container"
	["module_adguardhome,status"]="Active"
	["module_adguardhome,doc_link"]="https://github.com/AdguardTeam/AdGuardHome/wiki"
	["module_adguardhome,group"]="DNS"
	["module_adguardhome,port"]="3000"
	["module_adguardhome,arch"]=""
)
#
# Module adguardhome
#
function module_adguardhome () {
	local title="adguardhome"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/adguardhome?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/adguardhome?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_adguardhome,example"]}"

	ADGUARDHOME_BASE="${SOFTWARE_FOLDER}/adguardhome"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$ADGUARDHOME_BASE" ]] || mkdir -p "$ADGUARDHOME_BASE" || { echo "Couldn't create storage directory: $ADGUARDHOME_BASE"; exit 1; }
			if [[ ! -f "/etc/systemd/resolved.conf.d/armbian-defaults.conf" ]]; then
				${module_options["module_adguardhome,feature"]} ${commands[1]}
			fi
			docker run -d \
			--net=host \
			-p 53:53/tcp -p 53:53/udp \
			-p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp \
			-p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
			-v "${ADGUARDHOME_BASE}/workdir:/opt/adguardhome/work" \
			-v "${ADGUARDHOME_BASE}/confdir:/opt/adguardhome/conf" \
			--name adguardhome \
			--restart=unless-stopped \
			adguard/adguardhome
			#-p 67:67/udp -p 68:68/udp \ # add if you intend to use AdGuard Home as a DHCP server.
			#-p 853:853/tcp \ # if you are going to run AdGuard Home as a DNS-over-TLS⁠ server.
			#-p 5443:5443/tcp -p 5443:5443/udp \ add if you are going to run AdGuard Home as a DNSCrypt⁠ server.
			# More info: https://hub.docker.com/r/adguard/adguardhome
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' adguardhome >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs adguardhome\`)"
					exit 1
				fi
			done
			local container_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' adguardhome)
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
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
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
			${module_options["module_adguardhome,feature"]} ${commands[1]}
			if [[ -n "${ADGUARDHOME_BASE}" && "${ADGUARDHOME_BASE}" != "/" ]]; then
				rm -rf "${ADGUARDHOME_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_adguardhome,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_adguardhome,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_adguardhome,feature"]} ${commands[4]}
		;;
	esac
}

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

module_options+=(
	["module_samba,author"]="@Tearran"
	["module_samba,maintainer"]="@Tearran"
	["module_samba,feature"]="module_samba"
	["module_samba,example"]="help install remove start stop enable disable configure default status"
	["module_samba,desc"]="Samba setup and service setting."
	["module_samba,status"]="Active"
	["module_samba,doc_link"]="https://www.samba.org/samba/docs/"
	["module_samba,group"]="Networking"
	["module_samba,port"]="445"
	["module_samba,arch"]="x86-64 arm64 armhf"
)

function module_samba() {
	local title="samba"
	local condition
	condition=$(command -v smbd)

	# Set the interface for dialog tools
	set_interface

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_samba,example"]}"

	case "$1" in
		"${commands[0]}"|"")
		## help/menu options for the module
		echo -e "\nUsage: ${module_options["module_samba,feature"]} <command>"
		# Full list of commands to referance is printed
		echo -e "Commands: ${module_options["module_samba,example"]}"
		echo "Available commands:"
		# Unlike the for mentioned `echo -e "Commands: ${module_options["module_samba,example"]}"``
		# comprehenive referance the Avalible commands are commands considered useable in UI/UX
		# intened use below.
		if [[ -z "$condition" ]]; then
			echo -e "\t${commands[1]}\t- ${commands[1]} $title."
		else
			if srv_active smbd; then
			echo -e "\t${commands[2]}\t- ${commands[2]} $title service."
			echo -e "\t${commands[3]}\t- ${commands[3]} $title from starting on boot."
			else
			echo -e "\t${commands[4]}\t- ${commands[4]} $title to start on boot."
			echo -e "\t${commands[5]}\t- ${commands[5]} $title. service."
			fi
			echo -e "\t${commands[6]}\t- ${commands[6]} $title. $title."
			# Note: Comment to hide advanced option from menu
			# while remaining avalible for advance options --api flag
			echo -e "\t${commands[8]}\t- $title ${commands[8]} conf"
			echo -e "\t${commands[9]}\t- $title ${commands[9]}."
		fi
		echo
		;;
		"${commands[1]}")
		# install samba
		pkg_install samba
		# Check if /etc/samba/smb.conf exists
		if [[ ! -f "/etc/samba/smb.conf" ]]; then
			if [[ -f "/usr/share/samba/smb.conf" ]]; then
				cp "/usr/share/samba/smb.conf" "/etc/samba/smb.conf"
			else
				echo "Warning: Missing configuration file. Use the <configure> option."
			fi
		fi

		echo "Samba installed successfully."
		;;
		"${commands[2]}")
		## added subshell to prevent srv_disable exiting befor removing is complete.
		srv_disable smbd
		pkg_remove samba
		echo "$title remove complete."
		;;
		"${commands[3]}")
		srv_start smbd
		echo "Samba service started."
		;;
		"${commands[4]}")
		srv_stop smbd
		echo "Samba service stopped."
		;;
		"${commands[5]}")
		srv_enable smbd
		echo "Samba service enabled."
		;;
		"${commands[6]}")
		srv_disable smbd
		echo "Samba service disabled."
		;;
		"${commands[7]}"|"${commands[8]}")
		echo "Using package default configuration..."

		# Check if the default Samba configuration file and directory exist
		if [[ -f "/usr/share/samba/smb.conf" && -d "/etc/samba" ]]; then
			echo "Found default configuration and target directory."
			cp /usr/share/samba/smb.conf /etc/samba/smb.conf
			echo "Default configuration copied to /etc/samba/smb.conf."
		else
			# Provide more specific error messages
			if [[ ! -f "/usr/share/samba/smb.conf" ]]; then
			echo "Error: Default configuration file /usr/share/samba/smb.conf not found."
			fi
			if [[ ! -d "/etc/samba" ]]; then
			echo "Error: Target directory /etc/samba does not exist."
			fi
			return 1
		fi
		;;
		"${commands[9]}")
		## check samba status
		if srv_active smbd; then
			echo "active."
			return 0
		elif ! srv_enabled smbd; then
			echo "inactive"
			return 1
		else
			echo "Samba service is in an unknown state."
			return 1
		fi
		;;
		*)
		# Full list of commands to referance is printed
		echo "Invalid command. Try: '${module_options["module_samba,example"]}'"
		;;
	esac
}

module_options+=(
	["module_phpmyadmin,author"]="@igorpecovnik"
	["module_phpmyadmin,maintainer"]="@igorpecovnik"
	["module_phpmyadmin,feature"]="module_phpmyadmin"
	["module_phpmyadmin,example"]="install remove purge status help"
	["module_phpmyadmin,desc"]="Install phpmyadmin container"
	["module_phpmyadmin,status"]="Active"
	["module_phpmyadmin,doc_link"]="https://www.phpmyadmin.net/docs/"
	["module_phpmyadmin,group"]="Database"
	["module_phpmyadmin,port"]="8071"
	["module_phpmyadmin,arch"]="x86-64 arm64"
)
#
# Module phpmyadmin-PDF
#
function module_phpmyadmin () {
	local title="phpmyadmin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/phpmyadmin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/phpmyadmin?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_phpmyadmin,example"]}"

	PHPMYADMIN_BASE="${SOFTWARE_FOLDER}/phpmyadmin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PHPMYADMIN_BASE" ]] || mkdir -p "$PHPMYADMIN_BASE" || { echo "Couldn't create storage directory: $PHPMYADMIN_BASE"; exit 1; }
			docker run -d \
			--name=phpmyadmin \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e PMA_ARBITRARY=1 \
			-p 8071:80 \
			-v "${PHPMYADMIN_BASE}/config:/config" \
			--restart unless-stopped \
			lscr.io/linuxserver/phpmyadmin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' phpmyadmin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs phpmyadmin\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_phpmyadmin,feature"]} ${commands[1]}
			if [[ -n "${PHPMYADMIN_BASE}" && "${PHPMYADMIN_BASE}" != "/" ]]; then
				rm -rf "${PHPMYADMIN_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_phpmyadmin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_phpmyadmin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_phpmyadmin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_grafana,author"]="@armbian"
	["module_grafana,maintainer"]="@igorpecovnik"
	["module_grafana,feature"]="module_grafana"
	["module_grafana,example"]="install remove purge status help"
	["module_grafana,desc"]="Install grafana container"
	["module_grafana,status"]="Active"
	["module_grafana,doc_link"]="https://grafana.com/docs/"
	["module_grafana,group"]="Monitoring"
	["module_grafana,port"]="3022"
	["module_grafana,arch"]="x86-64 arm64"
)
#
# Module grafana
#
function module_grafana () {
	local title="grafana"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/grafana-enterprise?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/grafana-enterprise?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_grafana,example"]}"

	GRAFANA_BASE="${SOFTWARE_FOLDER}/grafana"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$GRAFANA_BASE" ]] || mkdir -p "$GRAFANA_BASE" || { echo "Couldn't create storage directory: $GRAFANA_BASE"; exit 1; }
			docker run -d \
			--name=grafana \
			--pid=host \
			--net=lsio \
			--user 0 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_grafana,port"]}:3000 \
			-v "${GRAFANA_BASE}:/var/lib/grafana" \
			--restart unless-stopped \
			grafana/grafana-enterprise
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' grafana >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs grafana\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_grafana,feature"]} ${commands[1]}
			if [[ -n "${GRAFANA_BASE}" && "${GRAFANA_BASE}" != "/" ]]; then
				rm -rf "${GRAFANA_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_grafana,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_grafana,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_grafana,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_bazarr,author"]="@igorpecovnik"
	["module_bazarr,maintainer"]="@igorpecovnik"
	["module_bazarr,feature"]="module_bazarr"
	["module_bazarr,example"]="install remove purge status help"
	["module_bazarr,desc"]="Install bazarr container"
	["module_bazarr,status"]="Active"
	["module_bazarr,doc_link"]="https://wiki.bazarr.media/"
	["module_bazarr,group"]="Downloaders"
	["module_bazarr,port"]="6767"
	["module_bazarr,arch"]="x86-64 arm64"
)
#
# Module Bazarr
#
function module_bazarr () {
	local title="bazarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/bazarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/bazarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_bazarr,example"]}"

	BAZARR_BASE="${SOFTWARE_FOLDER}/bazarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$BAZARR_BASE" ]] || mkdir -p "$BAZARR_BASE" || { echo "Couldn't create storage directory: $BAZARR_BASE"; exit 1; }
			docker run -d \
			--name=bazarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 6767:6767 \
			-v "${BAZARR_BASE}/config:/config" \
			-v "${BAZARR_BASE}/movies:/movies" `#optional` \
			-v "${BAZARR_BASE}/tv:/tv" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/bazarr:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' bazarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs bazarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_bazarr,feature"]} ${commands[1]}
			if [[ -n "${BAZARR_BASE}" && "${BAZARR_BASE}" != "/" ]]; then
				rm -rf "${BAZARR_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_bazarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_bazarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_bazarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_lidarr,author"]="@armbian"
	["module_lidarr,maintainer"]="@igorpecovnik"
	["module_lidarr,feature"]="module_lidarr"
	["module_lidarr,example"]="install remove purge status help"
	["module_lidarr,desc"]="Install lidarr container"
	["module_lidarr,status"]="Active"
	["module_lidarr,doc_link"]="https://wiki.servarr.com/lidarr"
	["module_lidarr,group"]="Downloaders"
	["module_lidarr,port"]="8686"
	["module_lidarr,arch"]="x86-64 arm64"
)
#
# Module lidarr
#
function module_lidarr () {
	local title="lidarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/lidarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/lidarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_lidarr,example"]}"

	LIDARR_BASE="${SOFTWARE_FOLDER}/lidarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$LIDARR_BASE" ]] || mkdir -p "$LIDARR_BASE" || { echo "Couldn't create storage directory: $LIDARR_BASE"; exit 1; }
			docker run -d \
			--name=lidarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8686:8686 \
			-v "${LIDARR_BASE}/config:/config" \
			-v "${LIDARR_BASE}/music:/music" `#optional` \
			-v "${LIDARR_BASE}/downloads:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/lidarr:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' lidarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs lidarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_lidarr,feature"]} ${commands[1]}
			if [[ -n "${LIDARR_BASE}" && "${LIDARR_BASE}" != "/" ]]; then
				rm -rf "${LIDARR_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_lidarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_lidarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_lidarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_ghost,author"]="@igorpecovnik"
	["module_ghost,maintainer"]="@igorpecovnik"
	["module_ghost,feature"]="module_ghost"
	["module_ghost,example"]="install remove purge status help"
	["module_ghost,desc"]="Install Ghost CMS container"
	["module_ghost,status"]="Active"
	["module_ghost,doc_link"]="https://ghost.org/docs/"
	["module_ghost,group"]="WebHosting"
	["module_ghost,port"]="9190"
	["module_ghost,arch"]="x86-64 arm64"
)

#
# Module ghost
#
function module_ghost () {
	local title="ghost"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
		local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
	fi

	GHOST_BASE="${SOFTWARE_FOLDER}/ghost"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_ghost,example"]}"

	case $1 in
	"${commands[0]}")

		# instatall mysql if not installed
		if ! module_mysql status; then
			module_mysql install
		fi

		# exit if ghost is already running
		if module_ghost status; then
			exit 0
		fi

		MYSQL_USER="${2:-armbian}"
		MYSQL_PASSWORD="${3:-armbian}"

		[[ -d "$GHOST_BASE" ]] || mkdir -p "$GHOST_BASE" || { echo "Couldn't create storage directory: $GHOST_BASE"; exit 1; }
		docker pull ghost:5-alpine
		docker run -d \
			--name ghost \
			--net=lsio \
			--restart unless-stopped \
			-e database__client=mysql \
			-e database__connection__host="mysql" \
			-e database__connection__user="${MYSQL_USER}" \
			-e database__connection__password="${MYSQL_PASSWORD}" \
			-e database__connection__database="ghost" \
			-p ${module_options["module_ghost,port"]}:2368 \
			-e url=http://$LOCALIPADD:${module_options["module_ghost,port"]} \
			-v "$GHOST_BASE:/var/lib/ghost/content" \
			ghost:6
		;;
	"${commands[1]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
				local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
			fi
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
	"${commands[2]}")
			${module_options["module_ghost,feature"]} ${commands[1]}
			if [[ -n "${GHOST_BASE}" && "${GHOST_BASE}" != "/" ]]; then
				rm -rf "${GHOST_BASE}"
			fi
		;;
	"${commands[3]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
				local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
			fi
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
	"${commands[4]}")
		echo -e "\nUsage: ${module_options["module_ghost,feature"]} <command>"
		echo -e "Commands:  ${module_options["module_ghost,example"]}"
		echo "Available commands:"
		echo -e "\tinstall\t- Install $title."
		echo -e "\t         Optionally accepts arguments:"
		echo -e "\t         db_host db_user db_pass db_name url"
		echo -e "\tremove\t- Remove $title."
		echo -e "\tpurge\t- Purge $title image and data."
		echo -e "\tstatus\t- Show container status."
		echo
		;;
	*)
			module_ghost "${commands[4]}"
		;;
	esac
}

module_options+=(
	["module_immich,author"]=""
	["module_immich,maintainer"]="@igorpecovnik"
	["module_immich,feature"]="module_immich"
	["module_immich,example"]="install remove purge status help"
	["module_immich,desc"]="Install Immich (photo and video backup solution)"
	["module_immich,status"]="Active"
	["module_immich,doc_link"]="https://immich.app/docs"
	["module_immich,group"]="Media"
	["module_immich,port"]="8077"
	["module_immich,arch"]="x86-64 arm64"
)
#
# Module immich
#
function module_immich () {
	local title="immich"
	local condition=$(which "$title" 2>/dev/null)

	# Database
	local DATABASE_USER="immich"
	local DATABASE_PASSWORD="immich"
	local DATABASE_NAME="immich"
	local DATABASE_HOST="postgres-immich"
	local DATABASE_IMAGE="tensorchord/pgvecto-rs:pg14-v0.2.0"
	local DATABASE_PORT="5432"

	if pkg_installed docker-ce; then
		local container=$(docker ps -q -f "name=^immich$")
		local image=$(docker images -q ghcr.io/imagegenius/immich)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_immich,example"]}"

	IMMICH_BASE="${SOFTWARE_FOLDER}/immich"

	case "$1" in
		"${commands[0]}")
			shift


			if ! pkg_installed docker-ce; then
				module_docker install
			fi

			# workaround if we re-install
			mkdir -p \
			"$IMMICH_BASE"/photos/{backups,encoded-video,library,profile,thumbs,upload} \
			"$IMMICH_BASE"/config \
			"$IMMICH_BASE"/libraries
			touch "$IMMICH_BASE"/photos/{backups,thumbs,profile,upload,library,encoded-video}/.immich
			sudo chown -R 1000:1000 "$IMMICH_BASE"/

			# Install armbian-config dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then module_redis install; fi
			if ! docker container ls -a --format '{{.Names}}' | grep "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			fi

			until docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; do
				echo "⏳ Waiting for PostgreSQL to be ready..."
				sleep 2
			done
			echo "✅ PostgreSQL is ready. Creating Immich DB..."

			if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" | grep -q 1; then
				echo "✅ Database '$DATABASE_NAME' exists."
			else
				docker exec -i $DATABASE_HOST psql -U $DATABASE_USER <<-EOT
				CREATE DATABASE $DATABASE_NAME;
				GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
				EOT
			fi

			# Download or update image
			docker pull ghcr.io/imagegenius/immich:latest

			# Run Immich container
			if ! docker run -d \
				--name=immich \
				--net=lsio \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e DB_HOSTNAME=$DATABASE_HOST \
				-e DB_USERNAME=$DATABASE_USER \
				-e DB_PASSWORD=$DATABASE_PASSWORD \
				-e DB_DATABASE_NAME=$DATABASE_NAME \
				-e REDIS_HOSTNAME=redis \
				-e DB_PORT=$DATABASE_PORT \
				-e REDIS_PORT=6379 \
				-e REDIS_PASSWORD= \
				-e SERVER_HOST=0.0.0.0 \
				-e SERVER_PORT=8080 \
				-p ${module_options["module_immich,port"]}:8080 \
				-v "${IMMICH_BASE}/config:/config" \
				-v "${IMMICH_BASE}/photos:/photos" \
				-v "${IMMICH_BASE}/libraries:/libraries" \
				--restart unless-stopped \
				ghcr.io/imagegenius/immich:latest; then
					echo "❌ Failed to start Immich container"
					exit 1
			fi

			sleep 5

			if [ -t 1 ]; then
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Starting Immich\n\nPlease wait..." 10 50 0
			else
				echo "Waiting for Immich to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						echo "✅ Immich is responding."
						break
					fi
				done
			fi
		;;
		"${commands[1]}")
			if [ -n "$container" ]; then
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}")
			module_immich "${commands[1]}"
			if [ -n "$image" ]; then
				docker image rm -f "$image"
			fi
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			if [ -n "$IMMICH_BASE" ] && [ "$IMMICH_BASE" != "/" ]; then
				rm -rf "$IMMICH_BASE"
			fi
		;;
		"${commands[3]}")
			if [ -n "$container" ] && [ -n "$image" ]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_immich,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_immich,example"]}"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			module_immich "${commands[4]}"
		;;
	esac
}

module_options+=(
	["module_nextcloud,author"]="@igorpecovnik"
	["module_nextcloud,maintainer"]="@igorpecovnik"
	["module_nextcloud,feature"]="module_nextcloud"
	["module_nextcloud,example"]="install remove purge status help"
	["module_nextcloud,desc"]="Install nextcloud container"
	["module_nextcloud,status"]="Active"
	["module_nextcloud,doc_link"]="https://nextcloud.com/support/"
	["module_nextcloud,group"]="Downloaders"
	["module_nextcloud,port"]="1443"
	["module_nextcloud,arch"]="x86-64 arm64"
)
#
# Module nextcloud
#
function module_nextcloud () {
	local title="nextcloud"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/nextcloud?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/nextcloud?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nextcloud,example"]}"

	NEXTCLOUD_BASE="${SOFTWARE_FOLDER}/nextcloud"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NEXTCLOUD_BASE" ]] || mkdir -p "$NEXTCLOUD_BASE" || { echo "Couldn't create storage directory: $NEXTCLOUD_BASE"; exit 1; }
			docker run -d \
			--name=nextcloud \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_nextcloud,port"]}:443 \
			-v "${NEXTCLOUD_BASE}/config:/config" \
			-v "${NEXTCLOUD_BASE}/data:/data" \
			--restart unless-stopped \
			lscr.io/linuxserver/nextcloud:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' nextcloud >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs nextcloud\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_nextcloud,feature"]} ${commands[1]}
			if [[ -n "${NEXTCLOUD_BASE}" && "${NEXTCLOUD_BASE}" != "/" ]]; then
				rm -rf "${NEXTCLOUD_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_nextcloud,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nextcloud,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_nextcloud,feature"]} ${commands[4]}
		;;
	esac
}

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

			# we host packages at our repository and version for both is determined:
			# https://github.com/armbian/os/blob/main/external/haos-agent.conf
			# https://github.com/armbian/os/blob/main/external/haos-supervised-installer.conf

			pkg_install --download-only homeassistant-supervised os-agent

			# determine machine type
			case "${ARCH}" in
				armhf) MACHINE="tinker";;
				x86_64) MACHINE="generic-x86-64";;
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
				systemctl restart hassio-supervisor
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
				sed -i '/./ s/$/ apparmor=1 security=apparmor/' /boot/firmware/cmdline.txt
			elif [[ -f /boot/armbianEnv.txt ]]; then
				echo "extraargs=apparmor=1 security=apparmor" >> "/boot/armbianEnv.txt"
			fi
			sleep 5

			if [[ -t 1 ]]; then
				# We have a terminal, use dialog
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_haos,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Preparing Home Assistant Supervised\n\nPlease wait! (can take a few minutes) " 10 50 0
			else
				# No terminal, fallback to echoing progress
				echo "Waiting for Home Assistant Supervised to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_haos,port"]}/ > /dev/null; then
						echo "✅ Home Assistant Supervised is responding."
						break
					fi
				done
			fi

			# enable service
			srv_enable supervisor-fix
			srv_start supervisor-fix

			# reboot related to apparmor install
			if [[ -t 1 ]]; then
				if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
					"A reboot is required to enable AppArmor. Shall we reboot now?" 7 68; then
					reboot
				fi
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
			sed -i "s/ apparmor=1 security=apparmor//" /boot/armbianEnv.txt
			# Raspberry Pi
			sed -i "s/ apparmor=1 security=apparmor//" /boot/firmware/cmdline.txt
			srv_daemon_reload
		;;
		"${commands[2]}")
			${module_options["module_haos,feature"]} ${commands[1]}
			if [[ -n "${HAOS_BASE}" && "${HAOS_BASE}" != "/" ]]; then
				rm -rf "${HAOS_BASE}"
			fi
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

module_options+=(
	["module_sabnzbd,author"]="@armbian"
	["module_sabnzbd,maintainer"]="@igorpecovnik"
	["module_sabnzbd,feature"]="module_sabnzbd"
	["module_sabnzbd,example"]="install remove purge status help"
	["module_sabnzbd,desc"]="Install sabnzbd container"
	["module_sabnzbd,status"]="Active"
	["module_sabnzbd,doc_link"]="https://sabnzbd.org/wiki/faq"
	["module_sabnzbd,group"]="Downloaders"
	["module_sabnzbd,port"]="8380"
	["module_sabnzbd,arch"]="x86-64 arm64"
)
#
# Module Sabnzbd
#
function module_sabnzbd () {
	local title="sabnzbd"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/sabnzbd?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/sabnzbd?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sabnzbd,example"]}"

	SABNZBD_BASE="${SOFTWARE_FOLDER}/sabnzbd"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$SABNZBD_BASE" ]] || mkdir -p "$SABNZBD_BASE" || { echo "Couldn't create storage directory: $SABNZBD_BASE"; exit 1; }
			docker run -d \
			--name=sabnzbd \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_sabnzbd,port"]}:8080 \
			-v "${SABNZBD_BASE}/config:/config" \
			-v "${SABNZBD_BASE}/downloads:/downloads" `#optional` \
			-v "${SABNZBD_BASE}/incomplete:/incomplete-downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/sabnzbd:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' sabnzbd >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs sabnzbd\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_sabnzbd,feature"]} ${commands[1]}
			[[ -n "${SABNZBD_BASE}" && "${SABNZBD_BASE}" != "/" ]] && rm -rf "${SABNZBD_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_sabnzbd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_sabnzbd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_sabnzbd,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_netalertx,author"]="@jokob-sk"
	["module_netalertx,maintainer"]="@igorpecovnik"
	["module_netalertx,feature"]="module_netalertx"
	["module_netalertx,example"]="install remove purge status help"
	["module_netalertx,desc"]="Install netalertx container"
	["module_netalertx,status"]="Preview"
	["module_netalertx,doc_link"]="https://netalertx.com"
	["module_netalertx,group"]="Monitoring"
	["module_netalertx,port"]="20211"
	["module_netalertx,arch"]="x86-64 arm64 armhf"
)
#
# Module netalertx
#
# module_netalertx - Manage the lifecycle of the 'netalertx' Docker container.
#
# This function processes a command argument to perform one of several operations on
# the netalertx container, including installation, removal, purging, status checking,
# and help display. It verifies that Docker is installed (and installs it if necessary),
# prepares the storage environment, and handles container startup with a timeout mechanism.
#
# Globals:
#   module_options  - Associative array containing module metadata and example command strings.
#   SOFTWARE_FOLDER - Base directory path for software installations.
#   NETALERTX_BASE  - Set to the storage directory for netalertx configuration and database.
#
# Arguments:
#   $1  The command to execute. Recognized commands (as defined in module_options) include:
#         install  - Installs and starts the netalertx container.
#         remove   - Stops and removes the netalertx container and its image.
#         purge    - Removes the container and image, then deletes the storage directory.
#         status   - Checks if both the container and image exist; returns success (0) if true, failure (1) otherwise.
#         help     - Displays usage instructions and available commands.
#
# Outputs:
#   Prints messages to STDOUT/STDERR regarding operation progress, usage instructions, or error notifications.
#
# Returns:
#   Exits with status 0 on success (e.g., container running, valid status check)
#   or with status 1 on errors (e.g., failure to create the storage directory or container startup timeout).
#
# Example:
#   module_netalertx install   # Installs and runs the netalertx container.
#   module_netalertx status    # Checks the installation status of netalertx.
#
function module_netalertx () {
	local title="netalertx"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/netalertx( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/netalertx( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netalertx,example"]}"

	NETALERTX_BASE="${SOFTWARE_FOLDER}/netalertx"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NETALERTX_BASE" ]] || mkdir -p "$NETALERTX_BASE" || { echo "Couldn't create storage directory: $NETALERTX_BASE"; exit 1; }
			docker run -d --rm --network=host \
			--name=netalertx \
			-e PUID=200 \
			-e PGID=300 \
			-e TZ="$(cat /etc/timezone)" \
			-e PORT=20211 \
			-v "${NETALERTX_BASE}/config:/app/config" \
			-v "${NETALERTX_BASE}/db:/app/db" \
			--mount type=tmpfs,target=/app/api \
			ghcr.io/jokob-sk/netalertx:latest

			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' netalertx >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs netalertx\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then docker container rm -f "$container" >/dev/null; fi
			if [[ "${image}" ]]; then docker image rm "$image" >/dev/null; fi
		;;
		"${commands[2]}")
			${module_options["module_netalertx,feature"]} ${commands[1]}
			if [[ -n "${NETALERTX_BASE}" && "${NETALERTX_BASE}" != "/" ]]; then rm -rf "${NETALERTX_BASE}"; fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_netalertx,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netalertx,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_netalertx,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_hastebin,author"]="@armbian"
	["module_hastebin,maintainer"]="@efectn"
	["module_hastebin,feature"]="module_hastebin"
	["module_hastebin,example"]="install remove purge status help"
	["module_hastebin,desc"]="Install hastebin container"
	["module_hastebin,status"]="Active"
	["module_hastebin,doc_link"]="https://github.com/rpardini/ansi-hastebin"
	["module_hastebin,group"]="Media"
	["module_hastebin,port"]="7777"
	["module_hastebin,arch"]="x86-64 arm64"
)
#
# Module hastebin
#
function module_hastebin () {
	local title="hastebin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/hastebin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/ansi-hastebin?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hastebin,example"]}"

	HASTEBIN_BASE="${SOFTWARE_FOLDER}/hastebin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$HASTEBIN_BASE" ]] || mkdir -p "$HASTEBIN_BASE" || { echo "Couldn't create storage directory: $HASTEBIN_BASE"; exit 1; }
			mkdir -p "$HASTEBIN_BASE/pastes"

			wget -qO- https://raw.githubusercontent.com/armbian/hastebin-ansi/refs/heads/main/about.md > "$HASTEBIN_BASE/about.md"

			docker run -d \
			--name=hastebin \
			--net=lsio \
			-e STORAGE_TYPE=file \
			-e STORAGE_FILE_PATH="/app/pastes" \
			-e RATE_LIMITING_ENABLE=true \
			-e RATE_LIMITING_LIMIT=100 \
			-e RATE_LIMITING_WINDOW=300 \
			-p 7777:7777 \
			-v "${HASTEBIN_BASE}:/app:rw" \
			--restart unless-stopped \
			ghcr.io/armbian/ansi-hastebin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' hastebin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs hastebin\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_hastebin,feature"]} ${commands[1]}
			if [[ -n "${HASTEBIN_BASE}" && "${HASTEBIN_BASE}" != "/" ]]; then
				rm -rf "${HASTEBIN_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_hastebin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_hastebin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_hastebin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_syncthing,author"]="@igorpecovnik"
	["module_syncthing,maintainer"]="@igorpecovnik"
	["module_syncthing,feature"]="module_syncthing"
	["module_syncthing,example"]="install remove purge status help"
	["module_syncthing,desc"]="Install syncthing container"
	["module_syncthing,status"]="Active"
	["module_syncthing,doc_link"]="https://docs.syncthing.net/"
	["module_syncthing,group"]="Media"
	["module_syncthing,port"]="8884 22000 21027"
	["module_syncthing,arch"]="x86-64 arm64"
)
#
# Module syncthing
#
function module_syncthing () {
	local title="syncthing"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/syncthing?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/syncthing?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_syncthing,example"]}"

	SYNCTHING_BASE="${SOFTWARE_FOLDER}/syncthing"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$SYNCTHING_BASE" ]] || mkdir -p "$SYNCTHING_BASE" || { echo "Couldn't create storage directory: $SYNCTHING_BASE"; exit 1; }
			docker run -d \
			--name=syncthing \
			--hostname=syncthing `#optional` \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8884:8384 \
			-p 22000:22000/tcp \
			-p 22000:22000/udp \
			-p 21027:21027/udp \
			-v "${SYNCTHING_BASE}/config:/config" \
			-v "${SYNCTHING_BASE}/data1:/data1" \
			-v "${SYNCTHING_BASE}/data2:/data2" \
			--restart unless-stopped \
			lscr.io/linuxserver/syncthing:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' syncthing >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs syncthing\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_syncthing,feature"]} ${commands[1]}
			[[ -n "${SYNCTHING_BASE}" && "${SYNCTHING_BASE}" != "/" ]] && rm -rf "${SYNCTHING_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_syncthing,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_syncthing,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_syncthing,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_docker,author"]="@schwar3kat"
	["module_docker,maintainer"]="@igorpecovnik"
	["module_docker,feature"]="module_docker"
	["module_docker,example"]="install remove purge status help"
	["module_docker,desc"]="Install docker from a repo using apt"
	["module_docker,status"]="Active"
	["module_docker,doc_link"]="https://docs.docker.com"
	["module_docker,group"]="Containers"
	["module_docker,port"]=""
	["module_docker,arch"]="x86-64 arm64 armhf"
)
#
# Install Docker from repo using apt
#
function module_docker() {

	local title="docker"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_docker,example"]}"

	case "$1" in
		"${commands[0]}")
			# Check if repo for distribution exists.
			URL="https://download.docker.com/linux/${DISTRO,,}/dists/$DISTROID"
			if wget --spider "${URL}" 2> /dev/null; then
				# Add Docker's official GPG key:
				wget -qO - https://download.docker.com/linux/${DISTRO,,}/gpg \
				| gpg --dearmor | sudo tee /usr/share/keyrings/docker.gpg > /dev/null
				if [[ $? -eq 0 ]]; then
					# Add the repository to Apt sources:
					cat <<- EOF > "/etc/apt/sources.list.d/docker.list"
					deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
					https://download.docker.com/linux/${DISTRO,,} $DISTROID stable
					EOF
					pkg_update
					# Install docker
					if [ "$2" = "engine" ]; then
						pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
					else
						pkg_install docker-ce docker-ce-cli containerd.io
					fi

					groupadd docker 2>/dev/null || true
					if [[ -n "${SUDO_USER}" ]]; then
						usermod -aG docker "${SUDO_USER}"
					fi
					srv_enable docker containerd
					srv_start docker
					docker network create lsio 2> /dev/null
				fi
			else
				$DIALOG --msgbox "ERROR ! ${DISTRO} $DISTROID distribution not found in repository!" 7 70
			fi
		;;
		"${commands[1]}")
			pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
		;;
		"${commands[2]}")
			rm -rf /var/lib/docker
			rm -rf /var/lib/containerd
		;;
		"${commands[3]}")
			if [ "$2" = "docker-ce" ]; then
				if pkg_installed docker-ce; then
					return 0
				else
					return 1
				fi
			fi
			if [ "$2" = "docker-compose-plugin" ]; then
				if pkg_installed docker-compose-plugin; then
					return 0
				else
					return 1
				fi
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_docker,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_docker,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
		${module_options["module_docker,feature"]} ${commands[4]}
		;;
	esac
}


module_options+=(
	["module_prowlarr,author"]="@Prowlarr"
	["module_prowlarr,maintainer"]="@armbian"
	["module_prowlarr,feature"]="module_prowlarr"
	["module_prowlarr,example"]="install remove purge status help"
	["module_prowlarr,desc"]="Install prowlarr container"
	["module_prowlarr,status"]="Active"
	["module_prowlarr,doc_link"]="https://prowlarr.com/"
	["module_prowlarr,group"]="Database"
	["module_prowlarr,port"]="9696"
	["module_prowlarr,arch"]="x86-64 arm64"
)
#
# Module prowlarr
#
function module_prowlarr () {
	local title="prowlarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/prowlarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/prowlarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prowlarr,example"]}"

	PROWLARR_BASE="${SOFTWARE_FOLDER}/prowlarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PROWLARR_BASE" ]] || mkdir -p "$PROWLARR_BASE" || { echo "Couldn't create storage directory: $PROWLARR_BASE"; exit 1; }
			docker run -d \
			--name=prowlarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 9696:9696 \
			-v "${PROWLARR_BASE}/config:/config" \
			--restart unless-stopped \
			lscr.io/linuxserver/prowlarr:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' prowlarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs prowlarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_prowlarr,feature"]} ${commands[1]}
			[[ -n "${PROWLARR_BASE}" && "${PROWLARR_BASE}" != "/" ]] && rm -rf "${PROWLARR_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_prowlarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_prowlarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_prowlarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_mysql,author"]="@igorpecovnik"
	["module_mysql,maintainer"]="@igorpecovnik"
	["module_mysql,feature"]="module_mysql"
	["module_mysql,example"]="install remove purge status help"
	["module_mysql,desc"]="Install mysql container"
	["module_mysql,status"]="Active"
	["module_mysql,doc_link"]="https://hub.docker.com/_/mysql"
	["module_mysql,group"]="Database"
	["module_mysql,port"]="3306"
	["module_mysql,arch"]="x86-64 arm64"
)
#
# Module mysql
#
function module_mysql () {
	local title="mysql"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/mysql?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/mysql?( |$)/{print $1":"$2}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mysql,example"]}"

	MYSQL_BASE="${SOFTWARE_FOLDER}/mysql"

	case $1 in
		"${commands[0]}")

			if module_mysql status; then
			echo "deb"
			exit 0
			fi

			pkg_installed docker-ce || module_docker install
			# get parameters or fallback to dialog
			MYSQL_ROOT_PASSWORD="${2:-armbian}"
			MYSQL_DATABASE="${3:-armbian}"
			MYSQL_USER="${4:-armbian}"
			MYSQL_PASSWORD="${5:-armbian}"

			[[ -d "$MYSQL_BASE" ]] || mkdir -p "$MYSQL_BASE" || { echo "Couldn't create storage directory: $MYSQL_BASE"; exit 1; }

			docker pull mysql:lts
			docker run -d \
				--name mysql \
				--net=lsio \
				-e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-armbian}" \
				-e MYSQL_DATABASE="${MYSQL_DATABASE:-armbian}" \
				-e MYSQL_USER="${MYSQL_USER:-armbian}" \
				-e MYSQL_PASSWORD="${MYSQL_PASSWORD:-armbian}" \
				-v "${MYSQL_BASE}:/var/lib/mysql" \
				-p 3306:3306 \
				--restart unless-stopped \
				mysql:lts

			until docker exec mysql \
				env MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
				mysql -uroot -e "SELECT 1;" &>/dev/null; do
				echo "⏳ Waiting for MySQL to accept connections..."
				sleep 2
			done

			MYSQL_DATABASES=("ghost") # Add any additional databases you want to create here
			for MYSQL_DATABASE in "${MYSQL_DATABASES[@]}"; do
				echo "⏳ Creating database: $MYSQL_DATABASE and granting privileges..."

				docker exec -i mysql \
				env MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
				mysql -uroot <<-EOF
					CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
					GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
					FLUSH PRIVILEGES;
				EOF
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_mysql,feature"]} ${commands[1]}
			if [[ -n "${MYSQL_BASE}" && "${MYSQL_BASE}" != "/" ]]; then
				rm -rf "${MYSQL_BASE}"
			fi
		;;
		"${commands[3]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/mysql?( |$)/{print $1}')
				local image=$(docker image ls -a | mawk '/mysql?( |$)/{print $1":"$2}')
			fi
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_mysql,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_mysql,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\t          Optionally accepts arguments:"
			echo -e "\t          root_password database user user_password"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_mysql,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_netbox,author"]=""
	["module_netbox,maintainer"]="@igorpecovnik"
	["module_netbox,feature"]="module_netbox"
	["module_netbox,example"]="install remove purge status help"
	["module_netbox,desc"]="Install NetBox container (IPAM/DCIM tool)"
	["module_netbox,status"]="Active"
	["module_netbox,doc_link"]="https://netbox.readthedocs.io/en/stable/"
	["module_netbox,group"]="Management"
	["module_netbox,port"]="8222"
	["module_netbox,arch"]="x86-64 arm64"
)

#
# Module netbox
#
function module_netbox () {
	local title="netbox"
	local condition=$(which "$title" 2>/dev/null)

	# Accept optional parameters
	local SUPERUSER_EMAIL="$2"
	local SUPERUSER_PASSWORD="$3"

	# Database
	local DATABASE_USER="netbox"
	local DATABASE_PASSWORD="netbox"
	local DATABASE_NAME="netbox"
	local DATABASE_HOST="postgres-netbox"
	local DATABASE_IMAGE="postgres:17-alpine"
	local DATABASE_PORT="5432"

	if pkg_installed docker-ce; then
		local container=$(docker ps -q -f "name=^netbox$")
		local image=$(docker images -q netboxcommunity/netbox)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netbox,example"]}"

	NETBOX_BASE="${SOFTWARE_FOLDER}/netbox"

	case "$1" in
		"${commands[0]}")
			# Prompt for email and password using dialog
			[[ -z "$SUPERUSER_EMAIL" ]] && \
			SUPERUSER_EMAIL=$($DIALOG --title "Enter NetBox superuser email" --inputbox "" 8 50 3>&1 1>&2 2>&3)
			[[ -z "$SUPERUSER_EMAIL" ]] && SUPERUSER_EMAIL="info@armbian.com"
			[[ -z "$SUPERUSER_PASSWORD" ]] && \
			SUPERUSER_PASSWORD=$($DIALOG --title "Enter NetBox admin password" --passwordbox "" 8 50 3>&1 1>&2 2>&3)
			[[ -z "$SUPERUSER_PASSWORD" ]] && SUPERUSER_PASSWORD="armbian"

			clear  # Clean up dialog artifacts

			pkg_installed docker-ce || module_docker install
			[[ -d "$NETBOX_BASE" ]] || mkdir -p "$NETBOX_BASE" || { echo "Couldn't create storage directory: $NETBOX_BASE"; exit 1; }

			# Install armbian-config dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then module_redis install; fi
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			fi

			# Generate a random secret key (50+ chars)
			NETBOX_SECRET_KEY=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' </dev/urandom | head -c 64)

			# Generate starting configuration
			[[ -d "$NETBOX_BASE/config" ]] || mkdir -p "$NETBOX_BASE/config"

			if [[ ! -f "$NETBOX_BASE/config/configuration.py" ]]; then
				cat > "$NETBOX_BASE/config/configuration.py" <<- EOT
				ALLOWED_HOSTS = ['*']
				DATABASE = {
					'NAME': '$DATABASE_NAME',
					'USER': '$DATABASE_USER',
					'PASSWORD': '$DATABASE_PASSWORD',
					'HOST': '$DATABASE_HOST',
					'PORT': '$DATABASE_PORT',
				}

				REDIS = {
					'tasks': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 0,
						'SSL': False,
					},
					'caching': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 1,
						'SSL': False,
					}
				}
				SECRET_KEY = '${NETBOX_SECRET_KEY}'
			EOT
			fi

			# Download or update image
			docker pull netboxcommunity/netbox:latest

			if ! docker run -d \
			--name=netbox \
			--net=lsio \
			-e TZ="$(cat /etc/timezone)" \
			-e SUPERUSER_EMAIL="${SUPERUSER_EMAIL}" \
			-e SUPERUSER_PASSWORD="${SUPERUSER_PASSWORD}" \
			-e DB_NAME=netbox \
			-p ${module_options["module_netbox,port"]}:8080 \
			-v "${NETBOX_BASE}/config:/etc/netbox/config" \
			-v "${NETBOX_BASE}/reports:/etc/netbox/reports" \
			-v "${NETBOX_BASE}/scripts:/etc/netbox/scripts" \
			--restart unless-stopped \
			netboxcommunity/netbox:latest ; then
				echo "❌ Failed to start NetBox container"; exit 1
			fi

			# waiting for web
			sleep 5

			if [[ -t 1 ]]; then
				# We have a terminal, use dialog
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_netbox,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Preparing NetBox\n\nPlease wait! (can take a few minutes) " 10 50 0
			else
				# No terminal, fallback to echoing progress
				echo "Waiting for NetBox to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_netbox,port"]}/ > /dev/null; then
						echo "✅ NetBox is responding."
						break
					fi
				done
			fi

			# Delete default API Token
			docker exec -i netbox /opt/netbox/netbox/manage.py shell -c "from users.models import Token;Token.objects.filter(key='0123456789abcdef0123456789abcdef01234567').delete();"

		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_netbox,feature"]} ${commands[1]}
			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			if [[ -n "${NETBOX_BASE}" && "${NETBOX_BASE}" != "/" ]]; then
				rm -rf "${NETBOX_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_netbox,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netbox,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_netbox,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_prometheus,author"]="@armbian"
	["module_prometheus,maintainer"]="@efectn"
	["module_prometheus,feature"]="module_prometheus"
	["module_prometheus,example"]="install remove purge status help"
	["module_prometheus,desc"]="Install prometheus container"
	["module_prometheus,status"]="Active"
	["module_prometheus,doc_link"]="https://prometheus.io/docs/"
	["module_prometheus,group"]="Monitoring"
	["module_prometheus,port"]="9191"
	["module_prometheus,arch"]="x86-64 arm64"
)
#
# Module prometheus
#
function module_prometheus () {
	local title="prometheus"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/prometheus?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/prometheus?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prometheus,example"]}"

	PROMETHEUS_BASE="${SOFTWARE_FOLDER}/prometheus"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PROMETHEUS_BASE" ]] || mkdir -p "$PROMETHEUS_BASE" || { echo "Couldn't create storage directory: $PROMETHEUS_BASE"; exit 1; }

			# Create dummy prometheus config file if it is not exist
			if [ ! -f "$PROMETHEUS_BASE/prometheus.yml" ]; then
				# // editorconfig-checker-disable
  				cat <<- EOF > "$PROMETHEUS_BASE/prometheus.yml"
				global:
				  scrape_interval: 15s
				  evaluation_interval: 15s

				scrape_configs:
				  - job_name: 'prometheus'
				    static_configs:
				      - targets: ['localhost:9090']
				EOF
				# // editorconfig-checker-enable
			fi

			docker run -d \
			--name=prometheus \
			--net=lsio \
			-p ${module_options["module_prometheus,port"]}:9090 \
			-v "${PROMETHEUS_BASE}:/etc/prometheus" \
			--restart unless-stopped \
			prom/prometheus
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' prometheus >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs prometheus\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_prometheus,feature"]} ${commands[1]}
			[[ -n "${PROMETHEUS_BASE}" && "${PROMETHEUS_BASE}" != "/" ]] && rm -rf "${PROMETHEUS_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_prometheus,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_prometheus,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_prometheus,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_embyserver,author"]="@schwar3kat"
	["module_embyserver,maintainer"]="@schwar3kat"
	["module_embyserver,feature"]="module_embyserver"
	["module_embyserver,example"]="install remove purge status help"
	["module_embyserver,desc"]="Install embyserver container"
	["module_embyserver,status"]="Active"
	["module_embyserver,doc_link"]="https://emby.media"
	["module_embyserver,group"]="Media"
	["module_embyserver,port"]="8091"
	["module_embyserver,arch"]="x86-64 arm64"
)
#
# Module Emby server
#
function module_embyserver () {
	local title="emby"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/emby?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/emby?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_embyserver,example"]}"

	EMBY_BASE="${SOFTWARE_FOLDER}/emby"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$EMBY_BASE" ]] || mkdir -p "$EMBY_BASE" || { echo "Couldn't create storage directory: $EMBY_BASE"; exit 1; }
			docker run -d \
			--name=emby \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_embyserver,port"]}:8096 \
			-v "${EMBY_BASE}/emby/library:/config" \
			-v "${EMBY_BASE}/movies:/movies" \
			-v "${EMBY_BASE}/tvshows:/tvshows" \
			--restart unless-stopped \
			lscr.io/linuxserver/emby:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' emby >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs emby\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_embyserver,feature"]} ${commands[1]}
			if [[ -n "${EMBY_BASE}" && "${EMBY_BASE}" != "/" ]]; then
				rm -rf "${EMBY_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_embyserver,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_embyserver,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_embyserver,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="2080 2443 5007 9123"
	["module_openhab,arch"]="x86-64 arm64 armhf"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {

	local title="openhab"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/openhab?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/openhab?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	OPENHAB_BASE="${SOFTWARE_FOLDER}/openhab"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			docker run -d \
			--name openhab \
			--net=lsio \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $1}'):8080 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $2}'):8443 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $3}'):5007 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $4}'):9123 \
			-v /etc/localtime:/etc/localtime:ro \
			-v /etc/timezone:/etc/timezone:ro \
			-v ${OPENHAB_BASE}/conf:/openhab/conf \
			-v ${OPENHAB_BASE}/userdata:/openhab/userdata \
			-v ${OPENHAB_BASE}/addons:/openhab/addons \
			-e USER_ID=1000 \
			-e GROUP_ID=1000 \
			-e CRYPTO_POLICY=unlimited \
			--restart=unless-stopped \
			openhab/openhab:latest
			;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
			;;
		"${commands[2]}")
			${module_options["module_openhab,feature"]} ${commands[1]}
			if [[ -n "${OPENHAB_BASE}" && "${OPENHAB_BASE}" != "/" ]]; then
				rm -rf "${OPENHAB_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_openhab,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openhab,example"]}"
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

module_options+=(
	["module_jellyfin,author"]="@armbian"
	["module_jellyfin,maintainer"]="@igorpecovnik"
	["module_jellyfin,feature"]="module_jellyfin"
	["module_jellyfin,example"]="install remove purge status help"
	["module_jellyfin,desc"]="Install jellyfin container"
	["module_jellyfin,status"]="Preview"
	["module_jellyfin,doc_link"]="https://jellyfin.org/docs/general/quick-start/"
	["module_jellyfin,group"]="Media"
	["module_jellyfin,port"]="8096"
	["module_jellyfin,arch"]="x86-64 arm64"
)
#
# Module jellyfin
#
function module_jellyfin () {
	local title="jellyfin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/jellyfin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/jellyfin?( |$)/{print $3}')
	fi

	# Hardware acceleration
	unset hwacc
	if [[ "${LINUXFAMILY}" == "rk35xx" && "${BOOT_SOC}" == "rk3588" ]]; then
		# Add udev rules according to Jellyfin's recommendations for RKMPP
		cat > "/etc/udev/rules.d/50-rk3588-mpp.rules" <<- EOT
		KERNEL=="mpp_service", MODE="0660", GROUP="video"
		KERNEL=="rga", MODE="0660", GROUP="video"
		KERNEL=="system", MODE="0666", GROUP="video"
		KERNEL=="system-dma32", MODE="0666", GROUP="video"
		KERNEL=="system-uncached", MODE="0666", GROUP="video"
		KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video" RUN+="/usr/bin/chmod a+rw /dev/dma_heap"
		EOT
		udevadm control --reload-rules && udevadm trigger

		# Pack `hwacc` to expose MPP/VPU hardware to the container
		for dev in dri dma_heap mali0 rga mpp_service \
			iep mpp-service vpu_service vpu-service \
			hevc_service hevc-service rkvdec rkvenc vepu h265e ; do \
			[ -e "/dev/$dev" ] && hwacc+=" --device /dev/$dev"; \
		done
	elif [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		local hwacc="--device=/dev/video10:/dev/video10 --device=/dev/video11:/dev/video11 --device=/dev/video12:/dev/video12"
	elif [[ "${LINUXFAMILY}" == "x86" ]]; then
		local hwacc="--device=/dev/dri:/dev/dri"
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyfin,example"]}"

	JELLYFIN_BASE="${SOFTWARE_FOLDER}/jellyfin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$JELLYFIN_BASE" ]] || mkdir -p "$JELLYFIN_BASE" || { echo "Couldn't create storage directory: $JELLYFIN_BASE"; exit 1; }
			docker run -d \
			--name=jellyfin \
			--net=lsio \
			${hwacc} \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8096:8096 \
			-p 8920:8920 `#optional` \
			-p 7359:7359/udp `#optional` \
			-p 1900:1900/udp `#optional` \
			-v "${JELLYFIN_BASE}/config:/config" \
			-v "${JELLYFIN_BASE}/tvseries:/data/tvshows" \
			-v "${JELLYFIN_BASE}/movies:/data/movies" \
			--restart unless-stopped \
			lscr.io/linuxserver/jellyfin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' jellyfin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs jellyfin\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then docker container rm -f "$container" >/dev/null; fi
			if [[ "${image}" ]]; then docker image rm "$image" >/dev/null; fi
			# Drop udev rules upon app removal
			rm -f "/etc/udev/rules.d/50-rk3588-mpp.rules"
			udevadm control --reload-rules && udevadm trigger
		;;
		"${commands[2]}")
			${module_options["module_jellyfin,feature"]} ${commands[1]}
			if [[ -n "${JELLYFIN_BASE}" && "${JELLYFIN_BASE}" != "/" ]]; then rm -rf "${JELLYFIN_BASE}/config"; fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_jellyfin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_jellyfin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_jellyfin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_webmin,author"]="@Tearran"
	["module_webmin,maintainer"]="@Tearran"
	["module_webmin,feature"]="module_webmin"
	["module_webmin,example"]="help install remove start stop enable disable status check"
	["module_webmin,desc"]="Webmin setup and service setting."
	["module_webmin,status"]="Active"
	["module_webmin,doc_link"]="https://webmin.com/docs/"
	["module_webmin,group"]="Management"
	["module_webmin,port"]="10000"
	["module_webmin,arch"]="x86-64 arm64 armhf"
)

function module_webmin() {
	local title="webmin"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_webmin,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_webmin,feature"]} <command>"
			echo -e "Commands: ${module_options["module_webmin,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else

			if srv_active webmin; then
				echo -e "\tstop\t- Stop the $title service."
				echo -e "\tdisable\t- Disable $title from starting on boot."
			else
				echo -e "\tenable\t- Enable $title to start on boot."
				echo -e "\tstart\t- Start the $title service."
			fi
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."

			fi
			echo
		;;
		"${commands[1]}")
			## install webmin
			pkg_update
			pkg_install wget apt-transport-https
			echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list
			wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor | tee /usr/share/keyrings/webmin-archive-keyring.gpg > /dev/null
			pkg_update
			pkg_install webmin
			echo "Webmin installed successfully."
		;;
		"${commands[2]}")
			## remove webmin
			srv_disable webmin
			pkg_remove webmin
			rm /etc/apt/sources.list.d/webmin.list
			rm /usr/share/keyrings/webmin-archive-keyring.gpg
			pkg_update
			echo "Webmin removed successfully."
		;;

		"${commands[3]}")
			srv_start webmin
			echo "Webmin service started."
			;;

		"${commands[4]}")
			srv_stop webmin
			echo "Webmin service stopped."
			;;

		"${commands[5]}")
			srv_enable webmin
			echo "Webmin service enabled."
			;;

		"${commands[6]}")
			srv_disable webmin
			echo "Webmin service disabled."
			;;

		"${commands[7]}")
			srv_status webmin
			;;

		"${commands[8]}")
			## check webmin status
			if srv_active webmin; then
				echo "Webmin service is active."
				return 0
			elif ! srv_enabled webmin ]]; then
				echo "Webmin service is disabled."
				return 1
			else
				echo "Webmin service is in an unknown state."
				return 1
			fi
			;;
		*)
		echo "Invalid command.try: '${module_options["module_webmin,example"]}'"

		;;
	esac
}

module_options+=(
	["module_plexmediaserver,author"]="@schwar3kat"
	["module_plexmediaserver,maintainer"]="@igorpecovnik"
	["module_plexmediaserver,feature"]="Install plexmediaserver"
	["module_plexmediaserver,example"]="install remove status"
	["module_plexmediaserver,desc"]="Install plexmediaserver from repo using apt"
	["module_plexmediaserver,status"]="Active"
	["module_plexmediaserver,doc_link"]="https://www.plex.tv/"
	["module_plexmediaserver,group"]="Media"
	["module_plexmediaserver,port"]="32400"
	["module_plexmediaserver,arch"]="x86-64 arm64"

)
#
# Install plexmediaserver using apt
#
module_plexmediaserver() {
	local title="plexmediaserver"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_plexmediaserver,example"]}"

	case "$1" in
		"${commands[0]}")
			if [ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]; then
				echo "deb [arch=$(dpkg --print-architecture) \
				signed-by=/usr/share/keyrings/plexmediaserver.gpg] https://downloads.plex.tv/repo/deb public main" \
				| sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			else
				sed -i "/downloads.plex.tv/s/^#//g" /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			fi
			# Note: for compatibility with existing source file in some builds format must be gpg not asc
			# and location must be /usr/share/keyrings
			wget -qO- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor \
			| sudo tee /usr/share/keyrings/plexmediaserver.gpg > /dev/null 2>&1
			pkg_update
			pkg_install plexmediaserver
		;;
		"${commands[1]}")
			sed -i '/plexmediaserver.gpg/s/^/#/g' /etc/apt/sources.list.d/plexmediaserver.list
			pkg_remove plexmediaserver
		;;
		"${commands[2]}")
			if pkg_installed plexmediaserver; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_portainer,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_portainer,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_plexmediaserver,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_deluge,author"]="@igorpecovnik"
	["module_deluge,maintainer"]="@igorpecovnik"
	["module_deluge,feature"]="module_deluge"
	["module_deluge,example"]="install remove purge status help"
	["module_deluge,desc"]="Install deluge container"
	["module_deluge,status"]="Active"
	["module_deluge,doc_link"]="https://deluge-torrent.org/userguide/"
	["module_deluge,group"]="Downloaders"
	["module_deluge,port"]="8112 6181 58846"
	["module_deluge,arch"]="x86-64 arm64"
)
#
# Module deluge
#
function module_deluge () {
	local title="deluge"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/deluge?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/deluge?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_deluge,example"]}"

	DELUGE_BASE="${SOFTWARE_FOLDER}/deluge"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$DELUGE_BASE" ]] || mkdir -p "$DELUGE_BASE" || { echo "Couldn't create storage directory: $DELUGE_BASE"; exit 1; }
			docker run -d \
			--name=deluge \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e DELUGE_LOGLEVEL=error `#optional` \
			-p 8112:8112 \
			-p 6181:6881 \
			-p 6181:6881/udp \
			-p 58846:58846 `#optional` \
			-v "${DELUGE_BASE}/config:/config" \
			-v "${DELUGE_BASE}/downloads:/downloads" \
			--restart unless-stopped \
			lscr.io/linuxserver/deluge:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' deluge >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs deluge\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_deluge,feature"]} ${commands[1]}
			if [[ -n "${DELUGE_BASE}" && "${DELUGE_BASE}" != "/" ]]; then
				rm -rf "${DELUGE_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_deluge,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_deluge,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_deluge,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_swag,author"]="@igorpecovnik"
	["module_swag,maintainer"]="@igorpecovnik"
	["module_swag,feature"]="module_swag"
	["module_swag,example"]="install remove purge status password help"
	["module_swag,desc"]="Secure Web Application Gateway "
	["module_swag,status"]="Active"
	["module_swag,doc_link"]="https://github.com/linuxserver/docker-swag"
	["module_swag,group"]="WebHosting"
	["module_swag,port"]="443"
	["module_swag,arch"]="x86-64 arm64"
)

function module_swag() {
	local title="swag"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/swag?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/swag?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_swag,example"]}"

	SWAG_BASE="${SOFTWARE_FOLDER}/swag"

	case "$1" in
		"${commands[0]}")
			SWAG_URL=$(dialog --title \
			"Secure Web Application Gateway URL?" \
			--inputbox "\nExamples: myhome.domain.org (port 80 and 443 must be exposed to internet)" \
			8 80 "" 3>&1 1>&2 2>&3);

			if [[ ${SWAG_URL} && $? -eq 0 ]]; then

				# adjust hostname
				hostnamectl set-hostname $(echo ${SWAG_URL} | sed -E 's/^\s*.*:\/\///g')
				# install docker
				pkg_installed docker-ce || module_docker install

				[[ -d "$SWAG_BASE" ]] || mkdir -p "$SWAG_BASE" || { echo "Couldn't create storage directory: $SWAG_BASE"; exit 1; }

				docker run -d \
				--name=swag \
				--cap-add=NET_ADMIN \
				--net=lsio \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e URL="${SWAG_URL}" \
				-e VALIDATION=http \
				-p 443:443 \
				-p 80:80 \
				-v "${SWAG_BASE}/config:/config" \
				--restart unless-stopped \
				lscr.io/linuxserver/swag
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' swag >/dev/null 2>&1 ; then
						break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs swag\`)"
						exit 1
					fi
				done
				# set password
				${module_options["module_swag,feature"]} ${commands[4]}
			else
				show_message <<< "Entering fully qualified domain name is required!"
			fi
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			[[ -n "${SWAG_BASE}" && "${SWAG_BASE}" != "/" ]] && rm -rf "${SWAG_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			SWAG_USER=$($DIALOG --title "Secure webserver with .htaccess username and password" \
			--inputbox "\nHit enter for USERNAME defaults" 9 70 "armbian" 3>&1 1>&2 2>&3)
			SWAG_PASSWORD=$($DIALOG --title "Enter new password for ${SWAG_USER}" \
			--inputbox "\nHit enter for auto generated password" 9 70 "$(tr -dc 'A-Za-z0-9=' < /dev/urandom | head -c 10)" 3>&1 1>&2 2>&3)
			if [[ "${SWAG_USER}" && "${SWAG_PASSWORD}" ]]; then
				docker exec -it swag htpasswd -b -c /config/nginx/.htpasswd ${SWAG_USER} ${SWAG_PASSWORD} >/dev/null 2>&1
				docker restart ${container} >/dev/null
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_swag,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_swag,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tpassword\t- Set .htaccess password for $title."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_swag,feature"]} ${commands[5]}
		;;
	esac
}

module_options+=(
	["module_jellyseerr,author"]="@armbian"
	["module_jellyseerr,maintainer"]="@igorpecovnik"
	["module_jellyseerr,feature"]="module_jellyseerr"
	["module_jellyseerr,example"]="install remove purge status help"
	["module_jellyseerr,desc"]="Install jellyseerr container"
	["module_jellyseerr,status"]="Active"
	["module_jellyseerr,doc_link"]="https://docs.jellyseerr.dev/"
	["module_jellyseerr,group"]="Downloaders"
	["module_jellyseerr,port"]="5055"
	["module_jellyseerr,arch"]="x86-64 arm64"
)
#
# Module jellyseerr
#
function module_jellyseerr () {
	local title="jellyseerr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/jellyseerr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/jellyseerr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyseerr,example"]}"

	JELLYSEERR_BASE="${SOFTWARE_FOLDER}/jellyseerr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$JELLYSEERR_BASE" ]] || mkdir -p "$JELLYSEERR_BASE" || { echo "Couldn't create storage directory: $JELLYSEERR_BASE"; exit 1; }
			docker run -d \
			--name jellyseerr \
			--net=lsio \
			-e LOG_LEVEL=debug \
			-e TZ="$(cat /etc/timezone)" \
			-e PORT=5055 `#optional` \
			-p 5055:5055 \
			-v "${JELLYSEERR_BASE}/config:/app/config" \
			--restart unless-stopped \
			fallenbagel/jellyseerr
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' jellyseerr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs jellyseerr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_jellyseerr,feature"]} ${commands[1]}
			if [[ -n "${JELLYSEERR_BASE}" && "${JELLYSEERR_BASE}" != "/" ]]; then
				rm -rf "${JELLYSEERR_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_jellyseerr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_jellyseerr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_jellyseerr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_transmission,author"]="@armbian"
	["module_transmission,maintainer"]="@igorpecovnik"
	["module_transmission,feature"]="module_transmission"
	["module_transmission,example"]="install remove purge status help"
	["module_transmission,desc"]="Install transmission container"
	["module_transmission,status"]="Active"
	["module_transmission,doc_link"]="https://transmissionbt.com/"
	["module_transmission,group"]="Downloaders"
	["module_transmission,port"]="9091 51413"
	["module_transmission,arch"]="x86-64 arm64"
)
#
# Module transmission
#
function module_transmission () {
	local title="transmission"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/transmission?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/transmission?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_transmission,example"]}"

	TRANSMISSION_BASE="${SOFTWARE_FOLDER}/transmission"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$TRANSMISSION_BASE" ]] || mkdir -p "$TRANSMISSION_BASE" || { echo "Couldn't create storage directory: $TRANSMISSION_BASE"; exit 1; }
			TRANSMISSION_USER=$($DIALOG --title "Enter username for Transmission client" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			TRANSMISSION_PASS=$($DIALOG --title "Enter password for Transmission client" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			docker run -d \
			--name=transmission \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e USER="${TRANSMISSION_USER}" \
			-e PASS="${TRANSMISSION_PASS}" \
			-e WHITELIST="${TRANSMISSION_WHITELIST}" \
			-p 9091:9091 \
			-p 51413:51413 \
			-p 51413:51413/udp \
			-v "${TRANSMISSION_BASE}/config:/config" \
			-v "${TRANSMISSION_BASE}/downloads:/downloads" \
			-v "${TRANSMISSION_BASE}/watch:/watch" \
			--restart unless-stopped \
			lscr.io/linuxserver/transmission:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' transmission >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs transmission\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi

			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_transmission,feature"]} ${commands[1]}
			if [[ -n "${TRANSMISSION_BASE}" && "${TRANSMISSION_BASE}" != "/" ]]; then
				rm -rf "${TRANSMISSION_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_transmission,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_transmission,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_transmission,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_filebrowser,author"]="@armbian"
	["module_filebrowser,maintainer"]="@igorpecovnik"
	["module_filebrowser,feature"]="module_filebrowser"
	["module_filebrowser,example"]="install remove purge status help"
	["module_filebrowser,desc"]="Install Filebrowser container"
	["module_filebrowser,status"]="Active"
	["module_filebrowser,doc_link"]="https://filebrowser.org/"
	["module_filebrowser,group"]="Utilities"
	["module_filebrowser,port"]="8095"
	["module_filebrowser,arch"]="x86-64 arm64"
)

function module_filebrowser () {
	local title="filebrowser"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/filebrowser?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/filebrowser?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_filebrowser,example"]}"

	FILEBROWSER_BASE="${SOFTWARE_FOLDER}/filebrowser"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$FILEBROWSER_BASE" ]] || mkdir -p "$FILEBROWSER_BASE" || { echo "Couldn't create storage directory: $FILEBROWSER_BASE"; exit 1; }

			docker run -d \
			--net=lsio \
			--name=filebrowser \
			-v "${FILEBROWSER_BASE}/srv:/srv" \
			-v "${FILEBROWSER_BASE}/database:/database" \
			-v "${FILEBROWSER_BASE}/branding:/branding" \
			-v "${FILEBROWSER_BASE}/.filebrowser.json:/.filebrowser.json" \
			-e TZ="$(cat /etc/timezone)" \
			-e PUID=1000 \
			-e PGID=1000 \
			-p ${module_options["module_filebrowser,port"]}:80 \
			--restart unless-stopped \
			filebrowser/filebrowser \
			--database /database/filebrowser.db

			sleep 3
			if docker inspect -f '{{ .State.Running }}' filebrowser 2>/dev/null | grep true; then
				echo "Filebrowser installed and running."
			else
				echo "Filebrowser failed to start. Check logs with: docker logs filebrowser"
				exit 1
			fi
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi

			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_filebrowser,feature"]} ${commands[1]}
			if [[ -n "${FILEBROWSER_BASE}" && "${FILEBROWSER_BASE}" != "/" ]]; then
				rm -rf "${FILEBROWSER_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_filebrowser,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_filebrowser,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove and clean up $title data."
			echo -e "\tstatus\t- Check if $title is installed."
			echo
		;;
		*)
			${module_options["module_filebrowser,feature"]} ${commands[4]}
		;;
	esac
}


module_options+=(
	["see_monitoring,author"]="@Tearran"
	["see_monitoring,ref_link"]=""
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]="see_monitoring"
	["see_monitoring,status"]="review"
	["see_monitoring,doc_link"]=""
)
#
# @decrition generate a menu for armbianmonitor
#
function see_monitoring() {
	if [ -f /usr/bin/htop ]; then
		choice=$(armbianmonitor -h | grep -Ev '^\s*-c\s|^\s*-M\s' | show_menu)

		armbianmonitor -$choice

	else
		echo "htop is not installed"
	fi
}

module_options+=(
	["module_redis,author"]=""
	["module_redis,maintainer"]="@igorpecovnik"
	["module_redis,feature"]="module_redis"
	["module_redis,example"]="install remove purge status help"
	["module_redis,desc"]="Install Redis in a container (In-Memory Data Store)"
	["module_redis,status"]="Active"
	["module_redis,doc_link"]="https://redis.io/docs/"
	["module_redis,group"]="Database"
	["module_redis,port"]="6379"
	["module_redis,arch"]="x86-64 arm64"
)
#
# Module redis
#
function module_redis () {
	local title="redis"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/redis?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/redis?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	REDIS_BASE="${SOFTWARE_FOLDER}/redis"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$REDIS_BASE" ]] || mkdir -p "$REDIS_BASE" || { echo "Couldn't create storage directory: $REDIS_BASE"; exit 1; }
			docker run -d \
			--name=redis \
			--net=lsio \
			-p 6379:6379 \
			-v "${REDIS_BASE}/data:/data" \
			--restart unless-stopped \
			redis:alpine
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' redis >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs redis\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi

			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_redis,feature"]} ${commands[1]}
			if [[ -n "${REDIS_BASE}" && "${REDIS_BASE}" != "/" ]]; then
				rm -rf "${REDIS_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_redis,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_redis,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_redis,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_actualbudget,author"]=""
	["module_actualbudget,maintainer"]="@igorpecovnik"
	["module_actualbudget,feature"]="module_actualbudget"
	["module_actualbudget,example"]="install remove purge status help"
	["module_actualbudget,desc"]="Install actualbudget container"
	["module_actualbudget,status"]="Active"
	["module_actualbudget,doc_link"]="https://actualbudget.org/docs"
	["module_actualbudget,group"]="Finances"
	["module_actualbudget,port"]="5006"
	["module_actualbudget,arch"]=""
)
#
# Manages the lifecycle of the ActualBudget Docker container module.
#
# Supports installing, removing, purging, checking status, and displaying help for the ActualBudget containerized application.
#
function module_actualbudget () {
	local title="actualbudget"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/my_actual_budget?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/actual-server?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_actualbudget,example"]}"

	ACTUALBUDGET_BASE="${SOFTWARE_FOLDER}/actualbudget"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$ACTUALBUDGET_BASE" ]] || mkdir -p "$ACTUALBUDGET_BASE" || { echo "Couldn't create storage directory: $ACTUALBUDGET_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			--name my_actual_budget \
			--restart=unless-stopped \
			-v "${ACTUALBUDGET_BASE}/data:/data" \
			-p 5006:5006 \
			-p 443:443 \
			--restart unless-stopped \
			actualbudget/actual-server:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' my_actual_budget >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs actualbudget\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_actualbudget,feature"]} ${commands[1]}
			[[ -n "${ACTUALBUDGET_BASE}" && "${ACTUALBUDGET_BASE}" != "/" ]] && rm -rf "${ACTUALBUDGET_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_actualbudget,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_actualbudget,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_actualbudget,feature"]} ${commands[4]}
		;;
	esac
}

