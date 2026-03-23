module_options+=(
	["module_filebrowser,author"]="@armbian"
	["module_filebrowser,maintainer"]="@igorpecovnik"
	["module_filebrowser,feature"]="module_filebrowser"
	["module_filebrowser,example"]="install remove purge status help"
	["module_filebrowser,desc"]="Install Filebrowser container"
	["module_filebrowser,status"]="Active"
	["module_filebrowser,doc_link"]="https://filebrowser.org/"
	["module_filebrowser,group"]="Utilities"
	["module_filebrowser,port"]="8095"
	["module_filebrowser,arch"]="x86-64 arm64 armhf"
	["module_filebrowser,dockerimage"]="filebrowser/filebrowser:latest"
	["module_filebrowser,dockername"]="filebrowser"
)

#
# Module File Browser
#
function module_filebrowser () {
	local title="File Browser"
	local dockerimage="${module_options["module_filebrowser,dockerimage"]}"
	local dockername="${module_options["module_filebrowser,dockername"]}"
	local port="${module_options["module_filebrowser,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_filebrowser,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/filebrowser"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create database directory with proper ownership
			mkdir -p "${base_dir}/database"
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "${base_dir}/database"

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-v "${base_dir}/srv:/srv" \
				-v "${base_dir}/database:/database" \
				-v "${base_dir}/branding:/branding" \
				-v "${base_dir}/.filebrowser.json:/.filebrowser.json" \
				-e TZ="$(cat /etc/timezone)" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-p "${port}:80" \
				--restart=always \
				"$dockerimage" \
				--database /database/filebrowser.db

			# Wait for container to initialize and extract password from logs
			sleep 3
			local admin_password
			admin_password=$(docker logs "$dockername" 2>&1 | grep "initialized with randomly generated password" | awk -F': ' '{print $NF}')

			# Display credentials with 10-second countdown
			local countdown=10
			while [[ $countdown -gt 0 ]]; do
				dialog_infobox "${title} installed" \
					"Web Interface: http://${LOCALIPADD}:${port}\n\nUsername: admin\nPassword: ${admin_password}\n\nClosing in ${countdown} seconds..." 11 70
				sleep 1
				((countdown--))
			done
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_filebrowser,feature"]} ${commands[1]}; then
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
			show_module_help "module_filebrowser" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_filebrowser,feature"]} ${commands[4]}
		;;
	esac
}
