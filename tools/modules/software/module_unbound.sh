module_options+=(
	["module_unbound,author"]="@igorpecovnik"
	["module_unbound,maintainer"]="@igorpecovnik"
	["module_unbound,feature"]="module_unbound"
	["module_unbound,example"]="install remove purge status help"
	["module_unbound,desc"]="Install unbound container"
	["module_unbound,status"]="Active"
	["module_unbound,doc_link"]="https://unbound.docs.nlnetlabs.nl/en/latest/"
	["module_unbound,group"]="DNS"
	["module_unbound,port"]="8053"
	["module_unbound,arch"]="x86-64"
)
#
# Module Unbound
#
function module_unbound () {
	local title="unbound"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/unbound?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/unbound?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_unbound,example"]}"

	UNBOUND_BASE="${SOFTWARE_FOLDER}/unbound"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$UNBOUND_BASE" ]] || mkdir -p "$UNBOUND_BASE" || { echo "Couldn't create storage directory: $UNBOUND_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-p ${module_options["module_unbound,port"]}:53/tcp \
			-p ${module_options["module_unbound,port"]}:53/udp \
			--name unbound \
			--restart=unless-stopped \
			mvance/unbound:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' unbound >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs unbound\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_unbound,feature"]} ${commands[1]}
			[[ -n "${UNBOUND_BASE}" && "${UNBOUND_BASE}" != "/" ]] && rm -rf "${UNBOUND_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_unbound,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_unbound,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_unbound,feature"]} ${commands[4]}
		;;
	esac
}
