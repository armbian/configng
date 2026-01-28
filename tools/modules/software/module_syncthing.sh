module_options+=(
	["module_syncthing,author"]="@igorpecovnik"
	["module_syncthing,maintainer"]="@igorpecovnik"
	["module_syncthing,feature"]="module_syncthing"
	["module_syncthing,example"]="install remove purge status help"
	["module_syncthing,desc"]="Install syncthing container"
	["module_syncthing,status"]="Active"
	["module_syncthing,doc_link"]="https://docs.syncthing.net/"
	["module_syncthing,group"]="Media"
	["module_syncthing,port"]="8884 22000 21027"
	["module_syncthing,arch"]="x86-64 arm64"
)
#
# Module syncthing
#
function module_syncthing () {
	local title="syncthing"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=syncthing" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'syncthing' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_syncthing,example"]}"

	SYNCTHING_BASE="${SOFTWARE_FOLDER}/syncthing"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$SYNCTHING_BASE" ]] || mkdir -p "$SYNCTHING_BASE" || { echo "Couldn't create storage directory: $SYNCTHING_BASE"; exit 1; }
			docker run -d \
			--name=syncthing \
			--hostname=syncthing `#optional` \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8884:8384 \
			-p 22000:22000/tcp \
			-p 22000:22000/udp \
			-p 21027:21027/udp \
			-v "${SYNCTHING_BASE}/config:/config" \
			-v "${SYNCTHING_BASE}/data1:/data1" \
			-v "${SYNCTHING_BASE}/data2:/data2" \
			--restart=always \
			lscr.io/linuxserver/syncthing:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' syncthing 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs syncthing\`)"
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
			${module_options["module_syncthing,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_syncthing,feature"]} ${commands[1]}
			if [[ -n "${SYNCTHING_BASE}" && "${SYNCTHING_BASE}" != "/" ]]; then
				rm -rf "${SYNCTHING_BASE}"
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
			echo -e "\nUsage: ${module_options["module_syncthing,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_syncthing,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_syncthing,feature"]} ${commands[4]}
		;;
	esac
}
