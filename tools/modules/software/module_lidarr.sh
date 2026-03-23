module_options+=(
	["module_lidarr,author"]="@armbian"
	["module_lidarr,maintainer"]="@igorpecovnik"
	["module_lidarr,feature"]="module_lidarr"
	["module_lidarr,example"]="install remove purge status help"
	["module_lidarr,desc"]="Install lidarr container"
	["module_lidarr,status"]="Active"
	["module_lidarr,doc_link"]="https://wiki.servarr.com/lidarr"
	["module_lidarr,group"]="Downloaders"
	["module_lidarr,port"]="8686"
	["module_lidarr,arch"]="x86-64 arm64"
	["module_lidarr,dockerimage"]="lscr.io/linuxserver/lidarr:latest"
	["module_lidarr,dockername"]="lidarr"
)
#
# Module Lidarr
#
function module_lidarr () {
	local title="Lidarr"
	local dockerimage="${module_options["module_lidarr,dockerimage"]}"
	local dockername="${module_options["module_lidarr,dockername"]}"
	local port="${module_options["module_lidarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_lidarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/lidarr"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8686" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/music:/music" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_lidarr,feature"]} ${commands[1]}; then
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
			show_module_help "module_lidarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_lidarr,feature"]} ${commands[4]}
		;;
	esac
}
