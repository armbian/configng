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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/domoticz?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/domoticz?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_domoticz,example"]}"

	DOMOTICZ_BASE="${SOFTWARE_FOLDER}/domoticz"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$DOMOTICZ_BASE" ]] || mkdir -p "$DOMOTICZ_BASE" || { echo "Couldn't create storage directory: $DOMOTICZ_BASE"; exit 1; }
			docker run -d \
			--name=domoticz \
			--pid=host \
			--net=lsio \
			--device /dev/ttyUSB0:/dev/ttyUSB0 \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_domoticz,port"]}:8080 \
			-p 8443:443 \
			-v "${DOMOTICZ_BASE}:/opt/domoticz/userdata" \
			--restart unless-stopped \
			domoticz/domoticz:stable
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' domoticz >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs domoticz\`)"
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
