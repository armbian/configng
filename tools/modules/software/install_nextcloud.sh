module_options+=(
	["module_nextcloud,author"]="@igorpecovnik"
	["module_nextcloud,feature"]="module_nextcloud"
	["module_nextcloud,desc"]="Install nextcloud container"
	["module_nextcloud,example"]="install remove status help"
	["module_nextcloud,port"]="8007"
	["module_nextcloud,status"]="Active"
	["module_nextcloud,arch"]="x86-64,arm64"
)
#
# Module nextcloud
#
function module_nextcloud () {
	local title="nextcloud"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/nextcloud?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/nextcloud?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nextcloud,example"]}"
SOFTWARE_FOLDER="/armbian"
	NEXTCLOUD_BASE="${SOFTWARE_FOLDER}/nextcloud"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$NEXTCLOUD_BASE" ]] || mkdir -p "$NEXTCLOUD_BASE" || { echo "Couldn't create storage directory: $NEXTCLOUD_BASE"; exit 1; }
			docker run -d \
			--name=nextcloud \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ=Etc/UTC \
			-p 8444:443 \
			-p 8007:80 \
			-v "${NEXTCLOUD_BASE}/config:/config" \
			-v "${NEXTCLOUD_BASE}/data:/data" \
			--restart unless-stopped \
			lscr.io/linuxserver/nextcloud:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' nextcloud >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs nextcloud\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${NEXTCLOUD_BASE}" && "${NEXTCLOUD_BASE}" != "/" ]] && rm -rf "${NEXTCLOUD_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_nextcloud,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nextcloud,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_nextcloud,feature"]} ${commands[3]}
		;;
	esac
}
