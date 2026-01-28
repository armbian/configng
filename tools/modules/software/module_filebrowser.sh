module_options+=(
	["module_filebrowser,author"]="@armbian"
	["module_filebrowser,maintainer"]="@igorpecovnik"
	["module_filebrowser,feature"]="module_filebrowser"
	["module_filebrowser,example"]="install remove purge status help"
	["module_filebrowser,desc"]="Install Filebrowser container"
	["module_filebrowser,status"]="Active"
	["module_filebrowser,doc_link"]="https://filebrowser.org/"
	["module_filebrowser,group"]="Utilities"
	["module_filebrowser,port"]="8095"
	["module_filebrowser,arch"]="x86-64 arm64"
)

function module_filebrowser () {
	local title="filebrowser"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=filebrowser" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'filebrowser' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_filebrowser,example"]}"

	FILEBROWSER_BASE="${SOFTWARE_FOLDER}/filebrowser"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$FILEBROWSER_BASE" ]] || mkdir -p "$FILEBROWSER_BASE" || { echo "Couldn't create storage directory: $FILEBROWSER_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name=filebrowser \
			-v "${FILEBROWSER_BASE}/srv:/srv" \
			-v "${FILEBROWSER_BASE}/database:/database" \
			-v "${FILEBROWSER_BASE}/branding:/branding" \
			-v "${FILEBROWSER_BASE}/.filebrowser.json:/.filebrowser.json" \
			-e TZ="$(cat /etc/timezone)" \
			-e PUID=1000 \
			-e PGID=1000 \
			-p ${module_options["module_filebrowser,port"]}:80 \
			--restart=always \
			filebrowser/filebrowser \
			--database /database/filebrowser.db
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' filebrowser 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs filebrowser\`)"
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
			${module_options["module_filebrowser,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_filebrowser,feature"]} ${commands[1]}
			if [[ -n "${FILEBROWSER_BASE}" && "${FILEBROWSER_BASE}" != "/" ]]; then
				rm -rf "${FILEBROWSER_BASE}"
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
			echo -e "\nUsage: ${module_options["module_filebrowser,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_filebrowser,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove and clean up $title data."
			echo -e "\tstatus\t- Check if $title is installed."
			echo
		;;
		*)
			${module_options["module_filebrowser,feature"]} ${commands[4]}
		;;
	esac
}
