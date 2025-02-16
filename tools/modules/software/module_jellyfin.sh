#
# Module jellyfin
#
function module_jellyfin () {
	local title="jellyfin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/jellyfin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/jellyfin?( |$)/{print $3}')
	fi

	# Hardware acceleration
	unset hwacc
	if [[ "${LINUXFAMILY}" == "rockchip64" && "${BOOT_SOC}" == "rk3588" ]]; then
		for dev in dri dma_heap mali0 rga mpp_service \
			iep mpp-service vpu_service vpu-service \
			hevc_service hevc-service rkvdec rkvenc vepu h265e ; do \
			[ -e "/dev/$dev" ] && hwacc+=" --device /dev/$dev"; \
		done
	elif [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		local hwacc="--device=/dev/video10:/dev/video10 --device=/dev/video11:/dev/video11 --device=/dev/video12:/dev/video12"
	elif [[ "${LINUXFAMILY}" == "x86" ]]; then
		local hwacc="--device=/dev/dri:/dev/dri"
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyfin,example"]}"

	JELLYFIN_BASE="${SOFTWARE_FOLDER}/jellyfin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$JELLYFIN_BASE" ]] || mkdir -p "$JELLYFIN_BASE" || { echo "Couldn't create storage directory: $JELLYFIN_BASE"; exit 1; }
			docker run -d \
			--name=jellyfin \
			--net=lsio "${hwacc}" \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 8096:8096 \
			-p 8920:8920 `#optional` \
			-p 7359:7359/udp `#optional` \
			-p 1900:1900/udp `#optional` \
			-v "${JELLYFIN_BASE}/config:/config" \
			-v "${JELLYFIN_BASE}/tvseries:/data/tvshows" \
			-v "${JELLYFIN_BASE}/movies:/data/movies" \
			--restart unless-stopped \
			lscr.io/linuxserver/jellyfin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' jellyfin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs jellyfin\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then docker container rm -f "$container" >/dev/null; fi
			if [[ "${image}" ]]; then docker image rm "$image" >/dev/null; fi
		;;
		"${commands[2]}")
			${module_options["module_jellyfin,feature"]} ${commands[1]}
			if [[ -n "${NAVIDROME_BASE}" && "${NAVIDROME_BASE}" != "/" ]]; then rm -rf "${NAVIDROME_BASE}"; fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_jellyfin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_jellyfin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_jellyfin,feature"]} ${commands[4]}
		;;
	esac
}
