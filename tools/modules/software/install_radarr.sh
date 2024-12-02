module_options+=(
	["module_radarr,author"]="@armbian"
	["module_radarr,feature"]="module_radarr"
	["module_radarr,desc"]="Install radarr container"
	["module_radarr,example"]="install remove status help"
	["module_radarr,port"]="7878"
	["module_radarr,status"]="Active"
	["module_radarr,arch"]="x86-64,arm64"
)
#
# Module radarr
#
function module_radarr () {
	local title="radarr"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/radarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/radarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_radarr,example"]}"

	RADARR_BASE="${SOFTWARE_FOLDER}/radarr"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$RADARR_BASE" ]] || mkdir -p "$RADARR_BASE" || { echo "Couldn't create storage directory: $RADARR_BASE"; exit 1; }
			docker run -d \
			--name=radarr \
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
			[[ -n "${RADARR_BASE}" && "${RADARR_BASE}" != "/" ]] && rm -rf "${RADARR_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_radarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_radarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_radarr,feature"]} ${commands[3]}
		;;
	esac
}
