module_options+=(
	["module_readarr,author"]="@armbian"
	["module_readarr,maintainer"]="@igorpecovnik"
	["module_readarr,feature"]="module_readarr"
	["module_readarr,example"]="install remove purge status help"
	["module_readarr,desc"]="Install readarr container"
	["module_readarr,status"]="Active"
	["module_readarr,doc_link"]="https://wiki.servarr.com/readarr"
	["module_readarr,group"]="Downloaders"
	["module_readarr,port"]="8787"
	["module_readarr,arch"]="x86-64 arm64"
)
#
# Module readarr
#
function module_readarr () {
	local title="readarr"
	local condition=$(which "$title" 2>/dev/null)

	pkg_installed docker.io || module_docker install
	local container=$(docker container ls -a --filter "name=readarr" --format '{{.ID}}')
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' | grep 'readarr' | awk '{print $2}')

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_readarr,example"]}"

	READARR_BASE="${SOFTWARE_FOLDER}/readarr"

	case "$1" in
		"${commands[0]}")
			[[ -d "$READARR_BASE" ]] || mkdir -p "$READARR_BASE" || { echo "Couldn't create storage directory: $READARR_BASE"; exit 1; }
			docker run -d \
			--name=readarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8787:8787 \
			-v "${READARR_BASE}/config:/config" \
			-v "${READARR_BASE}/books:/books" `#optional` \
			-v "${READARR_BASE}/client:/downloads" `#optional` \
			--restart=always \
			lscr.io/linuxserver/readarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' readarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs readarr\`)"
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
			${module_options["module_readarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
			${module_options["module_readarr,feature"]} ${commands[1]}
			if [[ -n "${READARR_BASE}" && "${READARR_BASE}" != "/" ]]; then
				rm -rf "${READARR_BASE}"
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
			echo -e "\nUsage: ${module_options["module_readarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_readarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_readarr,feature"]} ${commands[4]}
		;;
	esac
}
