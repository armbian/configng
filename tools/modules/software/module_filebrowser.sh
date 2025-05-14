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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/filebrowser?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/filebrowser?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_filebrowser,example"]}"

	FILEBROWSER_BASE="${SOFTWARE_FOLDER}/filebrowser"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
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
			--restart unless-stopped \
			filebrowser/filebrowser \
			--database /database/filebrowser.db

			sleep 3
			if docker inspect -f '{{ .State.Running }}' filebrowser 2>/dev/null | grep true; then
				echo "Filebrowser installed and running."
			else
				echo "Filebrowser failed to start. Check logs with: docker logs filebrowser"
				exit 1
			fi
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
