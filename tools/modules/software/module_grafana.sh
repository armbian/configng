module_options+=(
	["module_grafana,author"]="@armbian"
	["module_grafana,maintainer"]="@igorpecovnik"
	["module_grafana,feature"]="module_grafana"
	["module_grafana,example"]="install remove purge status help"
	["module_grafana,desc"]="Install grafana container"
	["module_grafana,status"]="Active"
	["module_grafana,doc_link"]="https://grafana.com/docs/"
	["module_grafana,group"]="Monitoring"
	["module_grafana,port"]="3000"
	["module_grafana,arch"]="x86-64 arm64"
)
#
# Module grafana
#
function module_grafana () {
	local title="grafana"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/grafana-enterprise?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/grafana-enterprise?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_grafana,example"]}"

	GRAFANA_BASE="${SOFTWARE_FOLDER}/grafana"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$GRAFANA_BASE" ]] || mkdir -p "$GRAFANA_BASE" || { echo "Couldn't create storage directory: $GRAFANA_BASE"; exit 1; }
			docker run -d \
			--name=grafana \
			--pid=host \
			--net=lsio \
			--user 0 \
			-e TZ="$(cat /etc/timezone)" \
			-p 3000:3000 \
			-v "${GRAFANA_BASE}:/var/lib/grafana" \
			--restart unless-stopped \
			grafana/grafana-enterprise
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' grafana >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs grafana\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_grafana,feature"]} ${commands[1]}
			[[ -n "${GRAFANA_BASE}" && "${GRAFANA_BASE}" != "/" ]] && rm -rf "${GRAFANA_BASE}"
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
			echo
		;;
		*)
			${module_options["module_grafana,feature"]} ${commands[4]}
		;;
	esac
}
