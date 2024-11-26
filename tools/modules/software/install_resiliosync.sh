module_options+=(
	["module_resiliosync,author"]="@igorpecovnik"
	["module_resiliosync,feature"]="module_resiliosync"
	["module_resiliosync,desc"]="Install resiliosync container"
	["module_resiliosync,example"]="install remove status help"
	["module_resiliosync,port"]="8888"
	["module_resiliosync,status"]="Active"
	["module_resiliosync,arch"]="x86-64,arm64"
)
#
# Module resiliosync
#
function module_resiliosync () {
	local title="resiliosync"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a --format "{{.Names}},{{.ID}}" | grep resiliosync | cut -d"," -f2)
		local image=$(docker image ls -a | mawk '/resilio-sync?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_resiliosync,example"]}"
SOFTWARE_FOLDER="/armbian"
	RESILIOSYNC_BASE="${SOFTWARE_FOLDER}/resiliosync"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$RESILIOSYNC_BASE" ]] || mkdir -p "$RESILIOSYNC_BASE" || { echo "Couldn't create storage directory: $RESILIOSYNC_BASE"; exit 1; }
			docker run -d \
			--name=resiliosync \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8443:443 \
			-p 8888:80 \
			-v "${RESILIOSYNC_BASE}/config:/config" \
			-v "${RESILIOSYNC_BASE}/downloads:/downloads" \
			-v "${RESILIOSYNC_BASE}/sync:/sync" \
			--restart unless-stopped \
			lscr.io/linuxserver/resilio-sync:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' resiliosync >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs resiliosync\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${RESILIOSYNC_BASE}" && "${RESILIOSYNC_BASE}" != "/" ]] && rm -rf "${RESILIOSYNC_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_resiliosync,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_resiliosync,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_resiliosync,feature"]} ${commands[3]}
		;;
	esac
}
