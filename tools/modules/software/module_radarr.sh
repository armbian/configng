module_options+=(
	["module_radarr,author"]="@armbian"
	["module_radarr,maintainer"]="@igorpecovnik"
	["module_radarr,feature"]="module_radarr"
	["module_radarr,example"]="install remove purge status help"
	["module_radarr,desc"]="Install radarr container"
	["module_radarr,status"]="Active"
	["module_radarr,doc_link"]="https://wiki.servarr.com/radarr"
	["module_radarr,group"]="Downloaders"
	["module_radarr,port"]="7878"
	["module_radarr,arch"]="x86-64 arm64"
	["module_radarr,dockerimage"]="linuxserver/radarr:latest"
	["module_radarr,dockername"]="radarr"
)
#
# Module Radarr
#
function module_radarr () {
	local title="Radarr"
	local dockerimage="${module_options["module_radarr,dockerimage"]}"
	local dockername="${module_options["module_radarr,dockername"]}"
	local port="${module_options["module_radarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_radarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/radarr"

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
				-p "${port}:7878" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/movies:/movies" \
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
			if ! ${module_options["module_radarr,feature"]} ${commands[1]}; then
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
			show_module_help "module_radarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_radarr,feature"]} ${commands[4]}
		;;
	esac
}
