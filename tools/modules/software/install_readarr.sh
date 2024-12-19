module_options+=(
	["module_readarr,author"]="@armbian"
	["module_readarr,feature"]="module_readarr"
	["module_readarr,desc"]="Install readarr container"
	["module_readarr,example"]="install remove status help"
	["module_readarr,port"]="8787"
	["module_readarr,status"]="Active"
	["module_readarr,arch"]="x86-64,arm64"
)
#
# Module readarr
#
function module_readarr () {
	local title="readarr"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/readarr?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/readarr?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_readarr,example"]}"

	READARR_BASE="${SOFTWARE_FOLDER}/readarr"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || install_docker
			[[ -d "$READARR_BASE" ]] || mkdir -p "$READARR_BASE" || { echo "Couldn't create storage directory: $READARR_BASE"; exit 1; }
			docker run -d \
			--name=readarr \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ=Etc/UTC \
			-p 8787:8787 \
			-v "${READARR_BASE}/config:/config" \
			-v "${READARR_BASE}/books:/books" `#optional` \
			-v "${READARR_BASE}/client:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/readarr:develop
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' readarr >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs readarr\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${READARR_BASE}" && "${READARR_BASE}" != "/" ]] && rm -rf "${READARR_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_readarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_readarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_readarr,feature"]} ${commands[3]}
		;;
	esac
}
