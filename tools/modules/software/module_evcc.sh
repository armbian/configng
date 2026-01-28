module_options+=(
	["module_evcc,author"]="@naltatis"
	["module_evcc,maintainer"]="@igorpecovnik"
	["module_evcc,feature"]="module_evcc"
	["module_evcc,example"]="install remove purge status help"
	["module_evcc,desc"]="Install evcc container"
	["module_evcc,status"]="Active"
	["module_evcc,doc_link"]="https://docs.evcc.io/en"
	["module_evcc,group"]="HomeAutomation"
	["module_evcc,port"]="7070"
	["module_evcc,arch"]=""
)
#
# Module evcc: Solar charging. Super simple
#
function module_evcc () {
	local title="evcc"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=evcc" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'evcc' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_evcc,example"]}"

	EVCC_BASE="${SOFTWARE_FOLDER}/evcc"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$EVCC_BASE" ]] || mkdir -p "$EVCC_BASE" || { echo "Couldn't create storage directory: $EVCC_BASE"; exit 1; }
			touch "${EVCC_BASE}/evcc.yaml"
			docker run -d \
			--net=lsio \
			--name=evcc \
			-v "${EVCC_BASE}/evcc.yaml:/app/evcc.yaml" \
			-v "${EVCC_BASE}/.evcc:/root/.evcc" \
			-v /etc/machine-id:/etc/machine-id \
			-p 7070:7070 \
			-p 8887:8887 \
			-p 9522:9522/udp \
			-p 4712:4712 \
			--restart=always \
			evcc/evcc:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' evcc 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs evcc\`)"
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
			${module_options["module_evcc,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_evcc,feature"]} ${commands[1]}
			if [[ -n "${EVCC_BASE}" && "${EVCC_BASE}" != "/" ]]; then
				rm -rf "${EVCC_BASE}"
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
			echo -e "\nUsage: ${module_options["module_evcc,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_evcc,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_evcc,feature"]} ${commands[4]}
		;;
	esac
}
