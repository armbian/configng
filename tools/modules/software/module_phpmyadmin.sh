module_options+=(
	["module_phpmyadmin,author"]="@igorpecovnik"
	["module_phpmyadmin,maintainer"]="@igorpecovnik"
	["module_phpmyadmin,feature"]="module_phpmyadmin"
	["module_phpmyadmin,example"]="install remove purge status help"
	["module_phpmyadmin,desc"]="Install phpmyadmin container"
	["module_phpmyadmin,status"]="Active"
	["module_phpmyadmin,doc_link"]="https://www.phpmyadmin.net/docs/"
	["module_phpmyadmin,group"]="Database"
	["module_phpmyadmin,port"]="8071"
	["module_phpmyadmin,arch"]="x86-64 arm64"
)
#
# Module phpmyadmin-PDF
#
function module_phpmyadmin () {
	local title="phpmyadmin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/phpmyadmin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/phpmyadmin?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_phpmyadmin,example"]}"

	PHPMYADMIN_BASE="${SOFTWARE_FOLDER}/phpmyadmin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PHPMYADMIN_BASE" ]] || mkdir -p "$PHPMYADMIN_BASE" || { echo "Couldn't create storage directory: $PHPMYADMIN_BASE"; exit 1; }
			docker run -d \
			--name=phpmyadmin \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e PMA_ARBITRARY=1 \
			-p 8071:80 \
			-v "${PHPMYADMIN_BASE}/config:/config" \
			--restart unless-stopped \
			lscr.io/linuxserver/phpmyadmin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' phpmyadmin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs phpmyadmin\`)"
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
			${module_options["module_phpmyadmin,feature"]} ${commands[1]}
			if [[ -n "${PHPMYADMIN_BASE}" && "${PHPMYADMIN_BASE}" != "/" ]]; then
				rm -rf "${PHPMYADMIN_BASE}"
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
			echo -e "\nUsage: ${module_options["module_phpmyadmin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_phpmyadmin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_phpmyadmin,feature"]} ${commands[4]}
		;;
	esac
}
