module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,desc"]="Install uptimekuma container"
	["module_uptimekuma,example"]="install remove status help"
	["module_uptimekuma,port"]="3001"
	["module_uptimekuma,status"]="Active"
	["module_uptimekuma,arch"]="x86-64,arm64"
)
#
# Module uptimekuma
#
function module_uptimekuma () {
	local title="uptimekuma"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/uptime-kuma?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/uptime-kuma?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_uptimekuma,example"]}"

	UPTIMEKUMA_BASE="${SOFTWARE_FOLDER}/uptimekuma"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			[[ -d "$UPTIMEKUMA_BASE" ]] || mkdir -p "$UPTIMEKUMA_BASE" || { echo "Couldn't create storage directory: $UPTIMEKUMA_BASE"; exit 1; }
			docker run -d --name uptime-kuma \
			--restart=always \
			-p 3001:3001 \
			-v uptime-kuma:/app/data \
			louislam/uptime-kuma:1
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' uptime-kuma >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs uptimekuma\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${UPTIMEKUMA_BASE}" && "${UPTIMEKUMA_BASE}" != "/" ]] && rm -rf "${uptimekuma_BASE}"
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_uptimekuma,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_uptimekuma,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_uptimekuma,feature"]} ${commands[3]}
		;;
	esac
}
