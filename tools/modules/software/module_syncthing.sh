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
