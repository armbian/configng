module_options+=(
	["module_wireguard,author"]="@armbian"
	["module_wireguard,maintainer"]="@igorpecovnik"
	["module_wireguard,feature"]="module_wireguard"
	["module_wireguard,example"]="install remove purge qrcode status help"
	["module_wireguard,desc"]="Install wireguard container"
	["module_wireguard,status"]="Active"
	["module_wireguard,doc_link"]="https://docs.linuxserver.io/images/docker-wireguard/#server-mode"
	["module_wireguard,group"]="Network"
	["module_wireguard,port"]="51820"
	["module_wireguard,arch"]="x86-64 arm64"
)
#
# Module wireguard
#
function module_wireguard () {
	local title="wireguard"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wireguard,example"]}"

	WIREGUARD_BASE="${SOFTWARE_FOLDER}/wireguard"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$WIREGUARD_BASE" ]] || mkdir -p "$WIREGUARD_BASE" || { echo "Couldn't create storage directory: $WIREGUARD_BASE"; exit 1; }
			if [[ -z $2 ]]; then
				NUMBER_OF_PEERS=$($DIALOG --title "Enter comma delimited peer keywords" --inputbox " \n" 7 50 "pc,laptop,phone" 3>&1 1>&2 2>&3)
			fi
			docker run -d \
			--name=wireguard \
			--net=lsio \
			--cap-add=NET_ADMIN \
			--cap-add=SYS_MODULE `#optional` \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e SERVERURL=auto \
			-e SERVERPORT=51820 \
			-e PEERS="${NUMBER_OF_PEERS}" \
			-e PEERDNS=auto \
			-e INTERNAL_SUBNET=10.13.13.0 \
			-e ALLOWEDIPS=0.0.0.0/0 \
			-e PERSISTENTKEEPALIVE_PEERS= \
			-e LOG_CONFS=true \
			-p 51820:51820/udp \
			-v "${WIREGUARD_BASE}/config:/config" \
			--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
			--restart unless-stopped \
			lscr.io/linuxserver/wireguard:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs wireguard\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_wireguard,feature"]} ${commands[1]}
			[[ -n "${WIREGUARD_BASE}" && "${WIREGUARD_BASE}" != "/" ]] && rm -rf "${WIREGUARD_BASE}"
		;;
		"${commands[3]}")
			if [[ -z $2 ]]; then
				LIST=($(ls -1 ${WIREGUARD_BASE}/config/ | grep peer | cut -d"_" -f2))
				LIST_LENGTH=$((${#LIST[@]} / 2))
				SELECTED_PEER=$(dialog --title "Select peer" --no-items --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			fi
			if [[ -n ${SELECTED_PEER} ]]; then
				clear
				docker exec -it wireguard /app/show-peer ${SELECTED_PEER}
				cat ${WIREGUARD_BASE}/config/peer_${SELECTED_PEER}/peer_${SELECTED_PEER}.conf
				read
			fi
		;;
		"${commands[4]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_wireguard,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_wireguard,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_wireguard,feature"]} ${commands[5]}
		;;
	esac
}
