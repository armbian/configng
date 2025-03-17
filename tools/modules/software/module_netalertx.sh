module_options+=(
	["module_netalertx,author"]="@jokob-sk"
	["module_netalertx,maintainer"]="@igorpecovnik"
	["module_netalertx,feature"]="module_netalertx"
	["module_netalertx,example"]="install remove purge status help"
	["module_netalertx,desc"]="Install netalertx container"
	["module_netalertx,status"]="Preview"
	["module_netalertx,doc_link"]="https://netalertx.com"
	["module_netalertx,group"]="Monitoring"
	["module_netalertx,port"]="20211"
	["module_netalertx,arch"]="x86-64 arm64 armhf"
)
#
# Module netalertx
#
function module_netalertx () {
	local title="netalertx"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/netalertx?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/netalertx?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netalertx,example"]}"

	NETALERTX_BASE="${SOFTWARE_FOLDER}/netalertx"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NETALERTX_BASE" ]] || mkdir -p "$NETALERTX_BASE" || { echo "Couldn't create storage directory: $NETALERTX_BASE"; exit 1; }
			docker run -d --rm --network=host \
			--name=netalertx \
			-e PUID=200 \
			-e PGID=300 \
			-e TZ="$(cat /etc/timezone)" \
			-e PORT=20211 \
			-v "${NETALERTX_BASE}/config:/app/config" \
			-v "${NETALERTX_BASE}/db:/app/db" \
			--mount type=tmpfs,target=/app/api \
			ghcr.io/jokob-sk/netalertx:latest

			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' netalertx >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs netalertx\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then docker container rm -f "$container" >/dev/null; fi
			if [[ "${image}" ]]; then docker image rm "$image" >/dev/null; fi
		;;
		"${commands[2]}")
			${module_options["module_netalertx,feature"]} ${commands[1]}
			if [[ -n "${NETALERTX_BASE}" && "${NETALERTX_BASE}" != "/" ]]; then rm -rf "${NETALERTX_BASE}"; fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_netalertx,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netalertx,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_netalertx,feature"]} ${commands[4]}
		;;
	esac
}
