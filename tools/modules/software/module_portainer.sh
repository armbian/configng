module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,maintainer"]="@schwar3kat"
	["module_portainer,feature"]="module_portainer"
	["module_portainer,example"]="install remove purge status help"
	["module_portainer,desc"]="Install/uninstall/check status of portainer container"
	["module_portainer,status"]="Active"
	["module_portainer,doc_link"]="https://docs.portainer.io/"
	["module_portainer,group"]="Containers"
	["module_portainer,port"]="9000 8000 9443"
	["module_portainer,arch"]="x86-64 arm64 armhf"
)
#
# Install Portainer
#
module_portainer() {
	local title="portainer"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_portainer,example"]}"

	PORTAINER_BASE="${SOFTWARE_FOLDER}/portainer"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PORTAINER_BASE" ]] || mkdir -p "$PORTAINER_BASE" || { echo "Couldn't create storage directory: $PORTAINER_BASE"; exit 1; }
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data
			docker run -d \
			--name=portainer \
			-p '9000:9000' \
			-p '8000:8000' \
			-p '9443:9443' \
			-v '/run/docker.sock:/var/run/docker.sock' \
			-v "${PORTAINER_BASE}/data:/data" \
			--restart=always \
			portainer/portainer-ce
			#-v '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro' \
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' portainer >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs portainer\`)"
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
			${module_options["module_portainer,feature"]} ${commands[1]}
			if [[ -n "${PORTAINER_BASE}" && "${PORTAINER_BASE}" != "/" ]]; then
				rm -rf "${PORTAINER_BASE}"
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
			echo -e "\nUsage: ${module_options["module_portainer,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_portainer,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_portainer,feature"]} ${commands[4]}
		;;
	esac
}
