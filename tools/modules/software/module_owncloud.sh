module_options+=(
	["module_owncloud,author"]="@armbian"
	["module_owncloud,maintainer"]="@igorpecovnik"
	["module_owncloud,feature"]="module_owncloud"
	["module_owncloud,example"]="install remove purge status help"
	["module_owncloud,desc"]="Install owncloud container"
	["module_owncloud,status"]="Active"
	["module_owncloud,doc_link"]="https://doc.owncloud.com/"
	["module_owncloud,group"]="Database"
	["module_owncloud,port"]="7787"
	["module_owncloud,arch"]="x86-64 arm64"
)
#
# Module owncloud
#
function module_owncloud () {
	local title="owncloud"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=owncloud" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'owncloud' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_owncloud,example"]}"

	OWNCLOUD_BASE="${SOFTWARE_FOLDER}/owncloud"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$OWNCLOUD_BASE" ]] || mkdir -p "$OWNCLOUD_BASE" || { echo "Couldn't create storage directory: $OWNCLOUD_BASE"; exit 1; }
			docker run -d \
			--name=owncloud \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e "OWNCLOUD_TRUSTED_DOMAINS=${LOCALIPADD}" \
			-p 7787:8080 \
			-v "${OWNCLOUD_BASE}/config:/config" \
			-v "${OWNCLOUD_BASE}/data:/mnt/data" \
			--restart=always \
			owncloud/server
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' owncloud 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs owncloud\`)"
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
			${module_options["module_owncloud,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${OWNCLOUD_BASE}" && "${OWNCLOUD_BASE}" != "/" ]]; then
				rm -rf "${OWNCLOUD_BASE}"
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
			echo -e "\nUsage: ${module_options["module_owncloud,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_owncloud,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_owncloud,feature"]} ${commands[4]}
		;;
	esac
}
