module_options+=(
	["module_sonarr,author"]="@armbian"
	["module_sonarr,maintainer"]="@igorpecovnik"
	["module_sonarr,feature"]="module_sonarr"
	["module_sonarr,example"]="install remove purge status help"
	["module_sonarr,desc"]="Install sonarr container"
	["module_sonarr,status"]="Active"
	["module_sonarr,doc_link"]="https://transmissionbt.com/"
	["module_sonarr,group"]="Downloaders"
	["module_sonarr,port"]="8989"
	["module_sonarr,arch"]="x86-64 arm64"
)
#
# Module sonarr
#
function module_sonarr () {
	local title="sonarr"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=sonarr" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'sonarr' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sonarr,example"]}"

	SONARR_BASE="${SOFTWARE_FOLDER}/sonarr"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$SONARR_BASE" ]] || mkdir -p "$SONARR_BASE" || { echo "Couldn't create storage directory: $SONARR_BASE"; exit 1; }
			docker run -d \
			--name=sonarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8989:8989 \
			-v "${SONARR_BASE}/config:/config" \
			-v "${SONARR_BASE}/tvseries:/tv" `#optional` \
			-v "${SONARR_BASE}/client:/downloads" `#optional` \
			--restart=always \
			lscr.io/linuxserver/sonarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' sonarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs sonarr\`)"
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
			${module_options["module_sonarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${SONARR_BASE}" && "${SONARR_BASE}" != "/" ]]; then
				rm -rf "${SONARR_BASE}"
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
			echo -e "\nUsage: ${module_options["module_sonarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_sonarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_sonarr,feature"]} ${commands[4]}
		;;
	esac
}
