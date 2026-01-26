module_options+=(
	["module_prowlarr,author"]="@Prowlarr"
	["module_prowlarr,maintainer"]="@armbian"
	["module_prowlarr,feature"]="module_prowlarr"
	["module_prowlarr,example"]="install remove purge status help"
	["module_prowlarr,desc"]="Install prowlarr container"
	["module_prowlarr,status"]="Active"
	["module_prowlarr,doc_link"]="https://prowlarr.com/"
	["module_prowlarr,group"]="Database"
	["module_prowlarr,port"]="9696"
	["module_prowlarr,arch"]="x86-64 arm64"
)
#
# Module prowlarr
#
function module_prowlarr () {
	local title="prowlarr"
	local condition=$(which "$title" 2>/dev/null)

	pkg_installed docker.io || module_docker install
	local container=$(docker container ls -a --filter "name=prowlarr" --format '{{.ID}}')
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' | grep 'prowlarr' | awk '{print $2}')

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prowlarr,example"]}"

	PROWLARR_BASE="${SOFTWARE_FOLDER}/prowlarr"

	case "$1" in
		"${commands[0]}")
			[[ -d "$PROWLARR_BASE" ]] || mkdir -p "$PROWLARR_BASE" || { echo "Couldn't create storage directory: $PROWLARR_BASE"; exit 1; }
			docker run -d \
			--name=prowlarr \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 9696:9696 \
			-v "${PROWLARR_BASE}/config:/config" \
			--restart=always \
			lscr.io/linuxserver/prowlarr:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' prowlarr 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs prowlarr\`)"
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
			${module_options["module_prowlarr,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
			${module_options["module_prowlarr,feature"]} ${commands[1]}
			if [[ -n "${PROWLARR_BASE}" && "${PROWLARR_BASE}" != "/" ]]; then
				rm -rf "${PROWLARR_BASE}"
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
			echo -e "\nUsage: ${module_options["module_prowlarr,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_prowlarr,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_prowlarr,feature"]} ${commands[4]}
		;;
	esac
}
