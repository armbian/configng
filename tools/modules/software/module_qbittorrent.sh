module_options+=(
	["module_qbittorrent,author"]="@qbittorrent"
	["module_qbittorrent,maintainer"]="@igorpecovnik"
	["module_qbittorrent,feature"]="module_qbittorrent"
	["module_qbittorrent,example"]="install remove purge status help"
	["module_qbittorrent,desc"]="Install qbittorrent container"
	["module_qbittorrent,status"]="Active"
	["module_qbittorrent,doc_link"]="https://github.com/qbittorrent/qBittorrent/wiki/"
	["module_qbittorrent,group"]="Downloaders"
	["module_qbittorrent,port"]="8090 6881"
	["module_qbittorrent,arch"]="x86-64 arm64"
)
#
# Module qbittorrent
#
function module_qbittorrent () {

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/qbittorrent?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/qbittorrent?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_qbittorrent,example"]}"

	QBITTORRENT_BASE="${SOFTWARE_FOLDER}/qbittorrent"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || install_docker
			[[ -d "$QBITTORRENT_BASE" ]] || mkdir -p "$QBITTORRENT_BASE" || { echo "Couldn't create storage directory: $QBITTORRENT_BASE"; exit 1; }
			docker run -d \
			--name=qbittorrent \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e WEBUI_PORT=8090 \
			-e TORRENTING_PORT=6881 \
			-p 8090:8090 \
			-p 6881:6881 \
			-p 6881:6881/udp \
			-v "${QBITTORRENT_BASE}/config:/config" \
			-v "${QBITTORRENT_BASE}/downloads:/downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/qbittorrent:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' qbittorrent >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs qbittorrent\`)"
					exit 1
				fi
			done
			sleep 3
			TEMP_PASSWORD=$(docker logs qbittorrent 2>&1 | grep password | grep session | cut -d":" -f2 | xargs)
			dialog --msgbox "Qbittorrent is listening at http://$LOCALIPADD:${module_options["module_qbittorrent,port"]}\n\nLogin as: admin\n\nTemporally password: ${TEMP_PASSWORD} " 9 70
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_qbittorrent,feature"]} ${commands[1]}
			[[ -n "${QBITTORRENT_BASE}" && "${QBITTORRENT_BASE}" != "/" ]] && rm -rf "${QBITTORRENT_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_qbittorrent,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_qbittorrent,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_qbittorrent,feature"]} ${commands[4]}
		;;
	esac
}
