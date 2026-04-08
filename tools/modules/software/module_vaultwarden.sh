module_options+=(
	["module_vaultwarden,author"]="@armbian"
	["module_vaultwarden,maintainer"]="@armbian"
	["module_vaultwarden,feature"]="module_vaultwarden"
	["module_vaultwarden,example"]="install remove purge status help"
	["module_vaultwarden,desc"]="Install Vaultwarden container (unofficial Bitwarden password manager server)"
	["module_vaultwarden,status"]="Active"
	["module_vaultwarden,doc_link"]="https://github.com/dani-garcia/vaultwarden/wiki"
	["module_vaultwarden,group"]="Productivity"
	["module_vaultwarden,port"]="8080"
	["module_vaultwarden,arch"]="x86-64 arm64"
	["module_vaultwarden,dockerimage"]="vaultwarden/server:latest"
	["module_vaultwarden,dockername"]="vaultwarden"
)

#
# Module Vaultwarden
#
function module_vaultwarden () {
	local title="Vaultwarden"
	local dockerimage="${module_options["module_vaultwarden,dockerimage"]}"
	local dockername="${module_options["module_vaultwarden,dockername"]}"
	local port="${module_options["module_vaultwarden,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_vaultwarden,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				return 0
			fi

			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run Vaultwarden container
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-p "${port}:80" \
				-v "${base_dir}:/data" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for container to be ready
			wait_for_container_ready "$dockername" 30 3 "running"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_vaultwarden,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_vaultwarden" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nThis is an alternative Bitwarden server implementation written in Rust.\n\nData is stored in: $base_dir\n\nNote: Web Crypto API requires HTTPS for web vault access.\nConfigure reverse proxy with SSL for production use."
		;;
		*)
			${module_options["module_vaultwarden,feature"]} ${commands[4]}
		;;
	esac
}
