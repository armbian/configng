module_options+=(
	["module_deluge,author"]="@igorpecovnik"
	["module_deluge,maintainer"]="@igorpecovnik"
	["module_deluge,feature"]="module_deluge"
	["module_deluge,example"]="install remove purge status help"
	["module_deluge,desc"]="Install deluge container"
	["module_deluge,status"]="Active"
	["module_deluge,doc_link"]="https://deluge-torrent.org/userguide/"
	["module_deluge,group"]="Downloaders"
	["module_deluge,port"]="8112 6181 58846"
	["module_deluge,arch"]="x86-64 arm64"
)
#
# Module deluge
#
function module_deluge () {
	local title="deluge"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=deluge" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'deluge' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_deluge,example"]}"

	DELUGE_BASE="${SOFTWARE_FOLDER}/deluge"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$DELUGE_BASE" ]] || mkdir -p "$DELUGE_BASE" || { echo "Couldn't create storage directory: $DELUGE_BASE"; exit 1; }
			docker run -d \
			--name=deluge \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e DELUGE_LOGLEVEL=error `#optional` \
			-p 8112:8112 \
			-p 6181:6881 \
			-p 6181:6881/udp \
			-p 58846:58846 `#optional` \
			-v "${DELUGE_BASE}/config:/config" \
			-v "${DELUGE_BASE}/downloads:/downloads" \
			--restart=always \
			lscr.io/linuxserver/deluge:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' deluge 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs deluge\`)"
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
			${module_options["module_deluge,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${DELUGE_BASE}" && "${DELUGE_BASE}" != "/" ]]; then
				rm -rf "${DELUGE_BASE}"
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
			echo -e "\nUsage: ${module_options["module_deluge,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_deluge,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_deluge,feature"]} ${commands[4]}
		;;
	esac
}
