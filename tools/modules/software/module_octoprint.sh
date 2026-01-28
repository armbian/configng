module_options+=(
	["module_octoprint,author"]="@armbian"
	["module_octoprint,maintainer"]="@igorpecovnik"
	["module_octoprint,feature"]="module_octoprint"
	["module_octoprint,example"]="install remove purge status help"
	["module_octoprint,desc"]="Install octoprint container"
	["module_octoprint,status"]="Active"
	["module_octoprint,doc_link"]="https://transmissionbt.com/"
	["module_octoprint,group"]="Printing"
	["module_octoprint,port"]="7981"
	["module_octoprint,arch"]="x86-64 arm64"
)
#
# Module octoprint
#
function module_octoprint () {
	local title="octoprint"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=octoprint" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'octoprint' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_octoprint,example"]}"

	OCTOPRINT_BASE="${SOFTWARE_FOLDER}/octoprint"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$OCTOPRINT_BASE" ]] || mkdir -p "$OCTOPRINT_BASE" || { echo "Couldn't create storage directory: $OCTOPRINT_BASE"; exit 1; }
			docker volume create octoprint

			# Check if camera device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/video0 ]]; then
				device_params="--device /dev/video0:/dev/video0"
			else
				echo "Warning: /dev/video0 not found. Camera support will not be available."
			fi

			docker run -d \
			--name=octoprint \
			-v "${OCTOPRINT_BASE}:/octoprint/octoprint" \
			$device_params \
			-e TZ="$(cat /etc/timezone)" \
			-e ENABLE_MJPG_STREAMER=true \
			-p 7981:80 \
			--restart=always \
			octoprint/octoprint
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' octoprint 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs octoprint\`)"
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
			${module_options["module_octoprint,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_octoprint,feature"]} ${commands[1]}
			if [[ -n "${OCTOPRINT_BASE}" && "${OCTOPRINT_BASE}" != "/" ]]; then
				rm -rf "${OCTOPRINT_BASE}"
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
			echo -e "\nUsage: ${module_options["module_octoprint,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_octoprint,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_octoprint,feature"]} ${commands[4]}
		;;
	esac
}
