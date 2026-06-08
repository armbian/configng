module_options+=(
	["module_sonarr,author"]="@armbian"
	["module_sonarr,maintainer"]="@igorpecovnik"
	["module_sonarr,feature"]="module_sonarr"
	["module_sonarr,example"]="install remove purge status help"
	["module_sonarr,desc"]="Install sonarr container"
	["module_sonarr,status"]="Active"
	["module_sonarr,doc_link"]="https://wiki.servarr.com/sonarr"
	["module_sonarr,group"]="Downloaders"
	["module_sonarr,port"]="8989"
	["module_sonarr,arch"]="x86-64 arm64"
	["module_sonarr,dockerimage"]="linuxserver/sonarr:latest"
	["module_sonarr,dockername"]="sonarr"
)
#
# Module Sonarr
#
function module_sonarr () {
	local title="Sonarr"
	local dockerimage="${module_options["module_sonarr,dockerimage"]}"
	local dockername="${module_options["module_sonarr,dockername"]}"
	local port="${module_options["module_sonarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sonarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/sonarr"

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
				-p "${port}:8989" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/tvseries:/tv" \
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
			if ! ${module_options["module_sonarr,feature"]} ${commands[1]}; then
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
			show_module_help "module_sonarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_sonarr,feature"]} ${commands[4]}
		;;
	esac
}
