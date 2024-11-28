module_options+=(
	["module_lidarr,author"]="@armbian"
	["module_lidarr,feature"]="module_lidarr"
	["module_lidarr,desc"]="Install lidarr container"
	["module_lidarr,example"]="install remove status help"
	["module_lidarr,port"]="8686"
	["module_lidarr,status"]="Active"
	["module_lidarr,arch"]="x86-64,arm64"
)
#
# Module lidarr
#
function module_lidarr () {
	local title="lidarr"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/lidarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/lidarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_lidarr,example"]}"

	LIDARR_BASE="${SOFTWARE_FOLDER}/lidarr"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$LIDARR_BASE" ]] || mkdir -p "$LIDARR_BASE" || { echo "Couldn't create storage directory: $LIDARR_BASE"; exit 1; }
			docker run -d \
			--name=lidarr \
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${LIDARR_BASE}" && "${LIDARR_BASE}" != "/" ]] && rm -rf "${LIDARR_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_lidarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_lidarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_lidarr,feature"]} ${commands[3]}
		;;
	esac
}
