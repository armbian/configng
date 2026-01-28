module_options+=(
	["module_nextcloud,author"]="@igorpecovnik"
	["module_nextcloud,maintainer"]="@igorpecovnik"
	["module_nextcloud,feature"]="module_nextcloud"
	["module_nextcloud,example"]="install remove purge status help"
	["module_nextcloud,desc"]="Install nextcloud container"
	["module_nextcloud,status"]="Active"
	["module_nextcloud,doc_link"]="https://nextcloud.com/support/"
	["module_nextcloud,group"]="Downloaders"
	["module_nextcloud,port"]="1443"
	["module_nextcloud,arch"]="x86-64 arm64"
)
#
# Module nextcloud
#
function module_nextcloud () {
	local title="nextcloud"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=nextcloud" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'nextcloud' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nextcloud,example"]}"

	NEXTCLOUD_BASE="${SOFTWARE_FOLDER}/nextcloud"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$NEXTCLOUD_BASE" ]] || mkdir -p "$NEXTCLOUD_BASE" || { echo "Couldn't create storage directory: $NEXTCLOUD_BASE"; exit 1; }
			docker run -d \
			--name=nextcloud \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_nextcloud,port"]}:443 \
			-v "${NEXTCLOUD_BASE}/config:/config" \
			-v "${NEXTCLOUD_BASE}/data:/data" \
			--restart=always \
			lscr.io/linuxserver/nextcloud:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' nextcloud 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs nextcloud\`)"
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
			${module_options["module_nextcloud,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_nextcloud,feature"]} ${commands[1]}
			if [[ -n "${NEXTCLOUD_BASE}" && "${NEXTCLOUD_BASE}" != "/" ]]; then
				rm -rf "${NEXTCLOUD_BASE}"
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
			echo -e "\nUsage: ${module_options["module_nextcloud,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nextcloud,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_nextcloud,feature"]} ${commands[4]}
		;;
	esac
}
