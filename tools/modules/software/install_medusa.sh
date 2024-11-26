declare -A module_options
module_options+=(
	["module_medusa,author"]="@armbian"
	["module_medusa,feature"]="module_medusa"
	["module_medusa,desc"]="Install medusa container"
	["module_medusa,example"]="install remove status help"
	["module_medusa,port"]="8081"
	["module_medusa,status"]="Active"
	["module_medusa,arch"]="x86-64,arm64"
)
#
# Install Module medusa
#
function module_medusa () {
	local title="Medusa"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/medusa?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/medusa?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_medusa,example"]}"

	MEDUSA_BASE="${SOFTWARE_FOLDER}/medusa"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$MEDUSA_BASE" ]] || mkdir -p "$MEDUSA_BASE" || { echo "Couldn't create storage directory: $MEDUSA_BASE"; exit 1; }
			docker run -d \
			--name=medusa \
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${MEDUSA_BASE}" && "${MEDUSA_BASE}" != "/" ]] && rm -rf "${MEDUSA_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_medusa,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_medusa,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_medusa,feature"]} ${commands[3]}
		;;
	esac
}
