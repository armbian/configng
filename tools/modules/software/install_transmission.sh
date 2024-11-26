module_options+=(
	["module_transmission,author"]="@armbian"
	["module_transmission,feature"]="module_transmission"
	["module_transmission,desc"]="Install transmission container"
	["module_transmission,example"]="install remove status help"
	["module_transmission,port"]="9091"
	["module_transmission,status"]="Active"
	["module_transmission,arch"]="x86-64,arm64"
)
#
# Module transmission
#
function module_transmission () {
	local title="transmission"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/transmission?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/transmission?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_transmission,example"]}"

	TRANSMISSION_BASE="${SOFTWARE_FOLDER}/transmission"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$TRANSMISSION_BASE" ]] || mkdir -p "$TRANSMISSION_BASE" || { echo "Couldn't create storage directory: $TRANSMISSION_BASE"; exit 1; }
			docker run -d \
			--name=transmission \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e TRANSMISSION_WEB_HOME= `#optional` \
			-e USER= `#optional` \
			-e PASS= `#optional` \
			-e WHITELIST= `#optional` \
			-e PEERPORT= `#optional` \
			-e HOST_WHITELIST= `#optional` \
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${TRANSMISSION_BASE}" && "${TRANSMISSION_BASE}" != "/" ]] && rm -rf "${TRANSMISSION_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_transmission,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_transmission,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_transmission,feature"]} ${commands[3]}
		;;
	esac
}
