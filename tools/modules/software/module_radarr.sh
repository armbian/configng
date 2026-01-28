module_options+=(
	["module_radarr,author"]="@armbian"
	["module_radarr,maintainer"]="@igorpecovnik"
	["module_radarr,feature"]="module_radarr"
	["module_radarr,example"]="install remove purge status help"
	["module_radarr,desc"]="Install radarr container"
	["module_radarr,status"]="Active"
	["module_radarr,doc_link"]="https://wiki.servarr.com/radarr"
	["module_radarr,group"]="Downloaders"
	["module_radarr,port"]="7878"
	["module_radarr,arch"]="x86-64 arm64"
)
#
# Module radarr
#
function module_radarr () {
	local title="radarr"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi
	local container=$(docker container ls -a --filter "name=radarr" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'radarr' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_radarr,example"]}"

	RADARR_BASE="${SOFTWARE_FOLDER}/radarr"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$RADARR_BASE" ]] || mkdir -p "$RADARR_BASE" || { echo "Couldn't create storage directory: $RADARR_BASE"; exit 1; }
			docker run -d \
			--name=radarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 7878:7878 \
			-v "${RADARR_BASE}/config:/config" \
			-v "${RADARR_BASE}/movies:/movies" `#optional` \
			-v "${RADARR_BASE}/client:/downloads" `#optional` \
			--restart=always \
			lscr.io/linuxserver/radarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' radarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs radarr\`)"
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
			${module_options["module_radarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${RADARR_BASE}" && "${RADARR_BASE}" != "/" ]]; then
				rm -rf "${RADARR_BASE}"
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
			echo -e "\nUsage: ${module_options["module_radarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_radarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_radarr,feature"]} ${commands[4]}
		;;
	esac
}
