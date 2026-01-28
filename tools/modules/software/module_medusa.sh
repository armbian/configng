module_options+=(
	["module_medusa,author"]="@armbian"
	["module_medusa,maintainer"]="@igorpecovnik"
	["module_medusa,feature"]="module_medusa"
	["module_medusa,example"]="install remove purge status help"
	["module_medusa,desc"]="Install medusa container"
	["module_medusa,status"]="Active"
	["module_medusa,doc_link"]="https://github.com/pymedusa/Medusa/wiki"
	["module_medusa,group"]="Downloaders"
	["module_medusa,port"]="8081"
	["module_medusa,arch"]="x86-64 arm64"
)
#
# Install Module medusa
#
function module_medusa () {
	local title="medusa"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=medusa" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'medusa' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_medusa,example"]}"

	MEDUSA_BASE="${SOFTWARE_FOLDER}/medusa"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$MEDUSA_BASE" ]] || mkdir -p "$MEDUSA_BASE" || { echo "Couldn't create storage directory: $MEDUSA_BASE"; exit 1; }
			docker run -d \
			--name=medusa \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8081:8081 \
			-v "${MEDUSA_BASE}/config:/config" \
			-v "${MEDUSA_BASE}/downloads:/downloads" \
			-v "${MEDUSA_BASE}/downloads/tv:/tv" \
			--restart=always \
			lscr.io/linuxserver/medusa:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' medusa 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs medusa\`)"
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
			${module_options["module_medusa,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_medusa,feature"]} ${commands[1]}
			if [[ -n "${MEDUSA_BASE}" && "${MEDUSA_BASE}" != "/" ]]; then
				rm -rf "${MEDUSA_BASE}"
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
			echo -e "\nUsage: ${module_options["module_medusa,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_medusa,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_medusa,feature"]} ${commands[4]}
		;;
	esac
}
