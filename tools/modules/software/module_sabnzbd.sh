module_options+=(
	["module_sabnzbd,author"]="@armbian"
	["module_sabnzbd,maintainer"]="@igorpecovnik"
	["module_sabnzbd,feature"]="module_sabnzbd"
	["module_sabnzbd,example"]="install remove purge status help"
	["module_sabnzbd,desc"]="Install sabnzbd container"
	["module_sabnzbd,status"]="Active"
	["module_sabnzbd,doc_link"]="https://sabnzbd.org/wiki/faq"
	["module_sabnzbd,group"]="Downloaders"
	["module_sabnzbd,port"]="8380"
	["module_sabnzbd,arch"]="x86-64 arm64"
)
#
# Module Sabnzbd
#
function module_sabnzbd () {
	local title="sabnzbd"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/sabnzbd?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/sabnzbd?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sabnzbd,example"]}"

	SABNZBD_BASE="${SOFTWARE_FOLDER}/sabnzbd"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$SABNZBD_BASE" ]] || mkdir -p "$SABNZBD_BASE" || { echo "Couldn't create storage directory: $SABNZBD_BASE"; exit 1; }
			docker run -d \
			--name=sabnzbd \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_sabnzbd,port"]}:8080 \
			-v "${SABNZBD_BASE}/config:/config" \
			-v "${SABNZBD_BASE}/downloads:/downloads" `#optional` \
			-v "${SABNZBD_BASE}/incomplete:/incomplete-downloads" `#optional` \
			--restart unless-stopped \
			lscr.io/linuxserver/sabnzbd:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' sabnzbd >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs sabnzbd\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_sabnzbd,feature"]} ${commands[1]}
			[[ -n "${SABNZBD_BASE}" && "${SABNZBD_BASE}" != "/" ]] && rm -rf "${SABNZBD_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_sabnzbd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_sabnzbd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_sabnzbd,feature"]} ${commands[4]}
		;;
	esac
}
