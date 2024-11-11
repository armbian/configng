
module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,ref_link"]=""
	["module_portainer,feature"]="module_portainer"
	["module_portainer,desc"]="Manage: Portainer container"
	["module_portainer,example"]="help install uninstall start stop reset status"
	["module_portainer,status"]="reviewe"
)
#
# Install portainer container
#
module_portainer() {
	local title="Portainer"
	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $3}')
	fi
	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_portainer,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_portainer"]} <command>"
			echo -e "Commands: ${module_options["module_portainer,example"]}"
			echo "Available commands:"
			if [[ "${container}" ]] || [[ "${image}" ]]; then
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."
				echo -e "\tstart\t- Start the $title container."
				echo -e "\tstop\t- Stop the $title container."
				echo -e "\treset\t- Reset the default state: $title container."
			else
				echo -e "  install\t- Install $title."
			fi
			echo
		;;
		install)
			check_if_installed docker-ce || install_docker
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data
			docker run -d -p '9000:9000' -p '8000:8000' --name=portainer --restart=always \
			-v '/run/docker.sock:/var/run/docker.sock' \
			-v '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro' \
			-v 'portainer_data:/data' 'portainer/portainer-ce'
		;;
		uninstall)
			[[ "${container}" ]] && docker container rm -f "$container"
			[[ "${image}" ]] && docker image rm "$image"
		;;
		start)
			[[ "${container}" ]] && docker container start "$container"
		;;
		stop)
			[[ "${container}" ]] && docker container stop "$container"
		;;
		reset)
			if [[ "${container}" ]]; then
				docker container stop "$container"
				docker container rm -f "$container"
				docker volume rm portainer_data
				docker run -d -p '9000:9000' -p '8000:8000' --name=portainer --restart=always \
				-v '/run/docker.sock:/var/run/docker.sock' \
				-v '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro' \
				-v 'portainer_data:/data' 'portainer/portainer-ce'
			else
				echo "No container found to stop."
			fi
		;;
		status)
			[[ "${container}" ]] || [[ "${image}" ]] && return 0
		;;
	esac
}

#module_portainer help
