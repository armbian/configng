module_options+=(
	["module_prowlarr,author"]="@armbian"
	["module_prowlarr,feature"]="module_prowlarr"
	["module_prowlarr,desc"]="Install prowlarr container"
	["module_prowlarr,example"]="install remove status help"
	["module_prowlarr,port"]="9696"
	["module_prowlarr,status"]="Active"
	["module_prowlarr,arch"]="x86-64,arm64"
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
			pkg_installed docker-ce || install_docker
			[[ -d "$PROWLARR_BASE" ]] || mkdir -p "$PROWLARR_BASE" || { echo "Couldn't create storage directory: $PROWLARR_BASE"; exit 1; }
			docker run -d \
			--name=prowlarr \
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
			[[ -n "${PROWLARR_BASE}" && "${PROWLARR_BASE}" != "/" ]] && rm -rf "${PROWLARR_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_prowlarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_prowlarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_prowlarr,feature"]} ${commands[3]}
		;;
	esac
}
