module_options+=(
	["module_grafana,author"]="@armbian"
	["module_grafana,maintainer"]="@igorpecovnik"
	["module_grafana,feature"]="module_grafana"
	["module_grafana,example"]="install remove purge status help"
	["module_grafana,desc"]="Install grafana container"
	["module_grafana,status"]="Active"
	["module_grafana,doc_link"]="https://grafana.com/docs/"
	["module_grafana,group"]="Monitoring"
	["module_grafana,port"]="3022"
	["module_grafana,arch"]="x86-64 arm64"
)
#
# Module grafana
#
function module_grafana () {
	local title="grafana"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=grafana" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'grafana' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_grafana,example"]}"

	GRAFANA_BASE="${SOFTWARE_FOLDER}/grafana"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$GRAFANA_BASE" ]] || mkdir -p "$GRAFANA_BASE" || { echo "Couldn't create storage directory: $GRAFANA_BASE"; exit 1; }
			docker run -d \
			--name=grafana \
			--pid=host \
			--net=lsio \
			--user 0 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_grafana,port"]}:3000 \
			-v "${GRAFANA_BASE}:/var/lib/grafana" \
			--restart=always \
			grafana/grafana-enterprise
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' grafana 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs grafana\`)"
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
			${module_options["module_grafana,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_grafana,feature"]} ${commands[1]}
			if [[ -n "${GRAFANA_BASE}" && "${GRAFANA_BASE}" != "/" ]]; then
				rm -rf "${GRAFANA_BASE}"
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
			echo -e "\nUsage: ${module_options["module_grafana,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_grafana,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_grafana,feature"]} ${commands[4]}
		;;
	esac
}
