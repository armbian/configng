module_options+=(
	["module_lidarr,author"]="@armbian"
	["module_lidarr,maintainer"]="@igorpecovnik"
	["module_lidarr,feature"]="module_lidarr"
	["module_lidarr,example"]="install remove purge status help"
	["module_lidarr,desc"]="Install lidarr container"
	["module_lidarr,status"]="Active"
	["module_lidarr,doc_link"]="https://wiki.servarr.com/lidarr"
	["module_lidarr,group"]="Downloaders"
	["module_lidarr,port"]="8686"
	["module_lidarr,arch"]="x86-64 arm64"
)
#
# Module lidarr
#
function module_lidarr () {
	local title="lidarr"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=lidarr" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'lidarr' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_lidarr,example"]}"

	LIDARR_BASE="${SOFTWARE_FOLDER}/lidarr"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$LIDARR_BASE" ]] || mkdir -p "$LIDARR_BASE" || { echo "Couldn't create storage directory: $LIDARR_BASE"; exit 1; }
			docker run -d \
			--name=lidarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8686:8686 \
			-v "${LIDARR_BASE}/config:/config" \
			-v "${LIDARR_BASE}/music:/music" `#optional` \
			-v "${LIDARR_BASE}/downloads:/downloads" `#optional` \
			--restart=always \
			lscr.io/linuxserver/lidarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' lidarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs lidarr\`)"
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
			${module_options["module_lidarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_lidarr,feature"]} ${commands[1]}
			if [[ -n "${LIDARR_BASE}" && "${LIDARR_BASE}" != "/" ]]; then
				rm -rf "${LIDARR_BASE}"
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
			echo -e "\nUsage: ${module_options["module_lidarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_lidarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_lidarr,feature"]} ${commands[4]}
		;;
	esac
}
