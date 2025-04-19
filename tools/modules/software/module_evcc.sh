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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/evcc?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/evcc?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_evcc,example"]}"

	EVCC_BASE="${SOFTWARE_FOLDER}/evcc"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$EVCC_BASE" ]] || mkdir -p "$EVCC_BASE" || { echo "Couldn't create storage directory: $EVCC_BASE"; exit 1; }
			touch "${EVCC_BASE}/evcc.yaml"
			docker run -d \
			--net=lsio \
			--name evcc \
			-v "${EVCC_BASE}/evcc.yaml:/app/evcc.yaml" \
			-v "${EVCC_BASE}/.evcc:/root/.evcc" \
			-v /etc/machine-id:/etc/machine-id \
			-p 7070:7070 \
			-p 8887:8887 \
			-p 9522:9522/udp \
			-p 4712:4712 \
			evcc/evcc:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' evcc >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs evcc\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
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
