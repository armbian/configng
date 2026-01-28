module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="2080 2443 5007 9123"
	["module_openhab,arch"]="x86-64 arm64 armhf"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {

	local title="openhab"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=openhab" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'openhab' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	OPENHAB_BASE="${SOFTWARE_FOLDER}/openhab"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			docker run -d \
			--name openhab \
			--net=lsio \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $1}'):8080 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $2}'):8443 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $3}'):5007 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $4}'):9123 \
			-v /etc/localtime:/etc/localtime:ro \
			-v /etc/timezone:/etc/timezone:ro \
			-v ${OPENHAB_BASE}/conf:/openhab/conf \
			-v ${OPENHAB_BASE}/userdata:/openhab/userdata \
			-v ${OPENHAB_BASE}/addons:/openhab/addons \
			-e USER_ID=1000 \
			-e GROUP_ID=1000 \
			-e CRYPTO_POLICY=unlimited \
			--restart=always \
			openhab/openhab:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' openhab 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs openhab\`)"
					return 1
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
			${module_options["module_openhab,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_openhab,feature"]} ${commands[1]}
			if [[ -n "${OPENHAB_BASE}" && "${OPENHAB_BASE}" != "/" ]]; then
				rm -rf "${OPENHAB_BASE}"
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
			echo -e "\nUsage: ${module_options["module_openhab,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openhab,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_openhab,feature"]} ${commands[4]}
		;;
	esac
}
