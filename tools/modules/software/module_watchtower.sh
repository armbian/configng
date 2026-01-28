module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,maintainer"]="@igorpecovnik"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,example"]="install remove purge status help"
	["module_watchtower,desc"]="Install watchtower container"
	["module_watchtower,status"]="Active"
	["module_watchtower,doc_link"]="https://containrrr.dev/watchtower/"
	["module_watchtower,group"]="Updates"
	["module_watchtower,port"]=""
	["module_watchtower,arch"]="x86-64 arm64"
)
#
# Module watchtower
#
function module_watchtower () {
	local title="watchtower"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=watchtower" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'watchtower' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	WATCHTOWER_BASE="${SOFTWARE_FOLDER}/watchtower"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$WATCHTOWER_BASE" ]] || mkdir -p "$WATCHTOWER_BASE" || { echo "Couldn't create storage directory: $WATCHTOWER_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name=watchtower \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v "${WATCHTOWER_BASE}:/config" \
			--restart=always \
			containrrr/watchtower
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' watchtower 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs watchtower\`)"
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
			${module_options["module_watchtower,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_watchtower,feature"]} ${commands[1]}
			if [[ -n "${WATCHTOWER_BASE}" && "${WATCHTOWER_BASE}" != "/" ]]; then
				rm -rf "${WATCHTOWER_BASE}"
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
			echo -e "\nUsage: ${module_options["module_watchtower,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_watchtower,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_watchtower,feature"]} ${commands[4]}
		;;
	esac
}
