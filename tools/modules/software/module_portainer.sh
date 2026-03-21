module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,maintainer"]="@schwar3kat"
	["module_portainer,feature"]="module_portainer"
	["module_portainer,example"]="install remove purge status help"
	["module_portainer,desc"]="Install/uninstall/check status of portainer container"
	["module_portainer,status"]="Active"
	["module_portainer,doc_link"]="https://docs.portainer.io/"
	["module_portainer,group"]="Containers"
	["module_portainer,port"]="9000"
	["module_portainer,arch"]="x86-64 arm64 armhf"
	["module_portainer,dockerimage"]="portainer/portainer-ce"
	["module_portainer,dockername"]="portainer"
)
#
# Module Portainer
#
function module_portainer () {
	local title="Portainer"
	local dockerimage="${module_options["module_portainer,dockerimage"]}"
	local dockername="${module_options["module_portainer,dockername"]}"
	local port="${module_options["module_portainer,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_portainer,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/portainer"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create Docker volume if it doesn't exist
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--restart=always \
				-p 9000:9000 \
				-p 8000:8000 \
				-p 9443:9443 \
				-v /run/docker.sock:/var/run/docker.sock \
				-v "${base_dir}/data:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_portainer,feature"]} ${commands[1]}
			# Remove Docker volume
			docker volume rm portainer_data 2>/dev/null || true
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_portainer" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_portainer,feature"]} ${commands[4]}
		;;
	esac
}
