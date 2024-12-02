module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,desc"]="Install watchtower container"
	["module_watchtower,example"]="install remove status help"
	["module_watchtower,port"]=""
	["module_watchtower,status"]="Active"
	["module_watchtower,arch"]=""
)
#
# Module watchtower
#
function module_watchtower () {
	local title="watchtower"
	local condition=$(which "$title" 2>/dev/null)

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/watchtower?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/watchtower?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	case "$1" in
		"${commands[0]}")
			check_if_installed docker-ce || install_docker
			docker run -d \
			--name watchtower \
			-v /var/run/docker.sock:/var/run/docker.sock \
			containrrr/watchtower
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' watchtower >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs watchtower\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_watchtower,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_watchtower,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_watchtower,feature"]} ${commands[3]}
		;;
	esac
}
