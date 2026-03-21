module_options+=(
	["module_bazarr,author"]="@igorpecovnik"
	["module_bazarr,maintainer"]="@igorpecovnik"
	["module_bazarr,feature"]="module_bazarr"
	["module_bazarr,example"]="install remove purge status help"
	["module_bazarr,desc"]="Install bazarr container"
	["module_bazarr,status"]="Active"
	["module_bazarr,doc_link"]="https://wiki.bazarr.media/"
	["module_bazarr,group"]="Downloaders"
	["module_bazarr,port"]="6767"
	["module_bazarr,arch"]="x86-64 arm64"
	["module_bazarr,dockerimage"]="lscr.io/linuxserver/bazarr:latest"
	["module_bazarr,dockername"]="bazarr"
)
#
# Module Bazarr
#
function module_bazarr () {
	local title="Bazarr"
	local dockerimage="${module_options["module_bazarr,dockerimage"]}"
	local dockername="${module_options["module_bazarr,dockername"]}"
	local port="${module_options["module_bazarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_bazarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/bazarr"

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
				-p "${port}:6767" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/movies:/movies" \
				-v "${base_dir}/tv:/tv" \
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
			if ! ${module_options["module_bazarr,feature"]} ${commands[1]}; then
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
			docker_show_module_help "module_bazarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_bazarr,feature"]} ${commands[4]}
		;;
	esac
}
