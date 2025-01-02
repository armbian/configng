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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/octoprint?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/octoprint?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_octoprint,example"]}"

	OCTOPRINT_BASE="${SOFTWARE_FOLDER}/octoprint"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$OCTOPRINT_BASE" ]] || mkdir -p "$OCTOPRINT_BASE" || { echo "Couldn't create storage directory: $OCTOPRINT_BASE"; exit 1; }
			docker volume create octoprint
			docker run -d \
			--name octoprint \
			-v "${OCTOPRINT_BASE}:/octoprint/octoprint" \
			--device /dev/video0:/dev/video0 \
			-e TZ="$(cat /etc/timezone)" \
			-e ENABLE_MJPG_STREAMER=true \
			-p 7981:80 \
			--restart unless-stopped \
			octoprint/octoprint
			#--device /dev/ttyACM0:/dev/ttyACM0 \
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' octoprint >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs octoprint\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_octoprint,feature"]} ${commands[1]}
			[[ -n "${OCTOPRINT_BASE}" && "${OCTOPRINT_BASE}" != "/" ]] && rm -rf "${OCTOPRINT_BASE}"
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
			echo
		;;
		*)
			${module_options["module_octoprint,feature"]} ${commands[4]}
		;;
	esac
}
