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
