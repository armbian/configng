module_options+=(
	["module_deluge,author"]="@armbian"
	["module_deluge,feature"]="module_deluge"
	["module_deluge,desc"]="Install deluge container"
	["module_deluge,example"]="install remove status help"
	["module_deluge,port"]="8112 6181 58846"
	["module_deluge,status"]="Active"
	["module_deluge,arch"]="x86-64,arm64"
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
			pkg_installed docker-ce || install_docker
			[[ -d "$DELUGE_BASE" ]] || mkdir -p "$DELUGE_BASE" || { echo "Couldn't create storage directory: $DELUGE_BASE"; exit 1; }
			docker run -d \
			--name=deluge \
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${DELUGE_BASE}" && "${DELUGE_BASE}" != "/" ]] && rm -rf "${DELUGE_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_deluge,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_deluge,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_deluge,feature"]} ${commands[3]}
		;;
	esac
}
