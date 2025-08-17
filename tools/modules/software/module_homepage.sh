module_options+=(
	["module_homepage,author"]="@armbian"
	["module_homepage,maintainer"]="@igorpecovnik"
	["module_homepage,feature"]="module_homepage"
	["module_homepage,example"]="install remove purge status help"
	["module_homepage,desc"]="Install homepage container"
	["module_homepage,status"]="Active"
	["module_homepage,doc_link"]="https://gethomepage.dev/configs/"
	["module_homepage,group"]="Management"
	["module_homepage,port"]="3021"
	["module_homepage,arch"]=""
)
#
# Module homepage
#
function module_homepage () {
	local title="homepage"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/homepage?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/homepage( |$ )/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_homepage,example"]}"

	HOMEPAGE_BASE="${SOFTWARE_FOLDER}/homepage"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || install_docker
			[[ -d "$HOMEPAGE_BASE" ]] || mkdir -p "$HOMEPAGE_BASE" || { echo "Couldn't create storage directory: $HOMEPAGE_BASE"; exit 1; }

			docker run -d \
			--net=lsio \
			--name homepage \
			-e PUID=1000 \
			-e PGID=1000 \
			-e HOMEPAGE_ALLOWED_HOSTS=${LOCALIPADD}:${module_options["module_homepage,port"]},homepage.local:${module_options["module_homepage,port"]},localhost:${module_options["module_homepage,port"]} \
			-p ${module_options["module_homepage,port"]}:3000 \
			-v "${HOMEPAGE_BASE}/config:/app/config" \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart unless-stopped \
			ghcr.io/gethomepage/homepage:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' homepage >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs homepage\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_homepage,feature"]} ${commands[1]}
			[[ -n "${HOMEPAGE_BASE}" && "${HOMEPAGE_BASE}" != "/" ]] && rm -rf "${HOMEPAGE_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_homepage,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_homepage,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove $title and delete its data."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_homepage,feature"]} ${commands[4]}
		;;
	esac
}
