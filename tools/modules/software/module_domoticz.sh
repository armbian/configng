module_options+=(
	["module_domoticz,author"]="@armbian"
	["module_domoticz,maintainer"]="@igorpecovnik"
	["module_domoticz,feature"]="module_domoticz"
	["module_domoticz,example"]="install remove purge status help"
	["module_domoticz,desc"]="Install domoticz container"
	["module_domoticz,status"]="Active"
	["module_domoticz,doc_link"]="https://wiki.domoticz.com"
	["module_domoticz,group"]="Monitoring"
	["module_domoticz,port"]="8780"
	["module_domoticz,arch"]=""
)
#
# Module domoticz
#
function module_domoticz () {
	local title="domoticz"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=domoticz" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'domoticz' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_domoticz,example"]}"

	DOMOTICZ_BASE="${SOFTWARE_FOLDER}/domoticz"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$DOMOTICZ_BASE" ]] || mkdir -p "$DOMOTICZ_BASE" || { echo "Couldn't create storage directory: $DOMOTICZ_BASE"; exit 1; }

			# Check if USB serial device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/ttyUSB0 ]]; then
				device_params="--device /dev/ttyUSB0:/dev/ttyUSB0"
			else
				echo "Warning: /dev/ttyUSB0 not found. USB serial device support will not be available."
			fi

			docker run -d \
			--name=domoticz \
			--pid=host \
			--net=lsio \
			$device_params \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_domoticz,port"]}:8080 \
			-p 8443:443 \
			-v "${DOMOTICZ_BASE}:/opt/domoticz/userdata" \
			--restart=always \
			domoticz/domoticz:stable
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' domoticz 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs domoticz\`)"
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
			${module_options["module_domoticz,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_domoticz,feature"]} ${commands[1]}
			if [[ -n "${DOMOTICZ_BASE}" && "${DOMOTICZ_BASE}" != "/" ]]; then
				rm -rf "${DOMOTICZ_BASE}"
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
			echo -e "\nUsage: ${module_options["module_domoticz,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_domoticz,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_domoticz,feature"]} ${commands[4]}
		;;
	esac
}
