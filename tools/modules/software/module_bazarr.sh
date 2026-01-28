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

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=bazarr" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'bazarr' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_bazarr,example"]}"

	BAZARR_BASE="${SOFTWARE_FOLDER}/bazarr"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
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
			--restart=always \
			lscr.io/linuxserver/bazarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' bazarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs bazarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
		;;
		"${commands[2]}")
			${module_options["module_bazarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
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
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_bazarr,feature"]} ${commands[4]}
		;;
	esac
}
