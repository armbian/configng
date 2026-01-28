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
	local title="qbittorrent"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi
	local container=$(docker container ls -a --filter "name=qbittorrent" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'qbittorrent' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_qbittorrent,example"]}"

	QBITTORRENT_BASE="${SOFTWARE_FOLDER}/qbittorrent"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
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
			--restart=always \
			lscr.io/linuxserver/qbittorrent:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' qbittorrent 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs qbittorrent\`)"
					exit 1
				fi
			done
			sleep 3
			TEMP_PASSWORD=$(docker logs qbittorrent 2>&1 | grep password | grep session | cut -d":" -f2 | xargs)
			if [[ -t 1 ]]; then
				# We have a terminal, use dialog
				$DIALOG --title "qBittorrent installed" --msgbox "qBittorrent is listening at http://$LOCALIPADD:${module_options["module_qbittorrent,port"]% *}\n\nLogin as: admin\n\nTemporary password: ${TEMP_PASSWORD} " 10 70
			else
				# No terminal, just print
				echo -e "\nqBittorrent is listening at http://$LOCALIPADD:${module_options["module_qbittorrent,port"]% *}\nLogin as: admin\nTemporary password: ${TEMP_PASSWORD}\n"
			fi
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
		;;
		"${commands[2]}")
			${module_options["module_qbittorrent,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${QBITTORRENT_BASE}" && "${QBITTORRENT_BASE}" != "/" ]]; then
				rm -rf "${QBITTORRENT_BASE}"
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
			echo -e "\nUsage: ${module_options["module_qbittorrent,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_qbittorrent,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_qbittorrent,feature"]} ${commands[4]}
		;;
	esac
}
