module_options+=(
	["module_dozzle,author"]="@armbian"
	["module_dozzle,maintainer"]="@armbian"
	["module_dozzle,feature"]="module_dozzle"
	["module_dozzle,example"]="install remove purge status help"
	["module_dozzle,desc"]="Install Dozzle container (real-time Docker log viewer)"
	["module_dozzle,status"]="Active"
	["module_dozzle,doc_link"]="https://dozzle.dev/"
	["module_dozzle,group"]="Productivity"
	["module_dozzle,port"]="8888"
	["module_dozzle,arch"]="x86-64 arm64"
	["module_dozzle,dockerimage"]="amir20/dozzle:latest"
	["module_dozzle,dockername"]="dozzle"
)

#
# Module Dozzle
#
function module_dozzle () {
	local title="Dozzle"
	local dockerimage="${module_options["module_dozzle,dockerimage"]}"
	local dockername="${module_options["module_dozzle,dockername"]}"
	local port="${module_options["module_dozzle,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_dozzle,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				return 0
			fi

			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Run Dozzle container with Docker socket mount
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net lsio \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-p "${port}:8080" \
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
			if ! ${module_options["module_dozzle,feature"]} ${commands[1]}; then
				return 1
			fi
			# No data directory to clean up for Dozzle
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_dozzle" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nDozzle is a lightweight, real-time Docker log viewer.\n\nFeatures:\n- View logs from all containers in real-time\n- Search and filter logs\n- Color-coded log levels\n- No authentication required (secure with reverse proxy)\n\nAccess at: http://<your-ip>:$port\n\nNote: Docker socket is mounted for log access.\nConsider securing with reverse proxy for production use."
		;;
		*)
			${module_options["module_dozzle,feature"]} ${commands[4]}
		;;
	esac
}
