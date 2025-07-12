module_options+=(
	["module_embyserver,author"]="@schwar3kat"
	["module_embyserver,maintainer"]="@schwar3kat"
	["module_embyserver,feature"]="module_embyserver"
	["module_embyserver,example"]="install remove purge status help"
	["module_embyserver,desc"]="Install embyserver container"
	["module_embyserver,status"]="Active"
	["module_embyserver,doc_link"]="https://emby.media"
	["module_embyserver,group"]="Media"
	["module_embyserver,port"]="8091"
	["module_embyserver,arch"]="x86-64 arm64"
)
#
# Module Emby server
#
function module_embyserver () {
	local title="emby"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/emby?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/emby?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_embyserver,example"]}"

	EMBY_BASE="${SOFTWARE_FOLDER}/emby"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$EMBY_BASE" ]] || mkdir -p "$EMBY_BASE" || { echo "Couldn't create storage directory: $EMBY_BASE"; exit 1; }
			docker run -d \
			--name=emby \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_embyserver,port"]}:8096 \
			-v "${EMBY_BASE}/emby/library:/config" \
			-v "${EMBY_BASE}/movies:/movies" \
			-v "${EMBY_BASE}/tvshows:/tvshows" \
			--restart unless-stopped \
			lscr.io/linuxserver/emby:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' emby >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs emby\`)"
					exit 1
				fi
			done
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
			${module_options["module_embyserver,feature"]} ${commands[1]}
			if [[ -n "${EMBY_BASE}" && "${EMBY_BASE}" != "/" ]]; then
				rm -rf "${EMBY_BASE}"
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
			echo -e "\nUsage: ${module_options["module_embyserver,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_embyserver,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_embyserver,feature"]} ${commands[4]}
		;;
	esac
}
