module_options+=(
	["module_jellyseerr,author"]="@armbian"
	["module_jellyseerr,maintainer"]="@igorpecovnik"
	["module_jellyseerr,feature"]="module_jellyseerr"
	["module_jellyseerr,example"]="install remove purge status help"
	["module_jellyseerr,desc"]="Install jellyseerr container"
	["module_jellyseerr,status"]="Active"
	["module_jellyseerr,doc_link"]="https://docs.jellyseerr.dev/"
	["module_jellyseerr,group"]="Downloaders"
	["module_jellyseerr,port"]="5055"
	["module_jellyseerr,arch"]="x86-64 arm64"
	["module_jellyseerr,dockerimage"]="fallenbagel/jellyseerr:latest"
	["module_jellyseerr,dockername"]="jellyseerr"
)
#
# Module jellyseerr
#
function module_jellyseerr () {
	local title="Jellyseerr"
	local dockerimage="${module_options["module_jellyseerr,dockerimage"]}"
	local dockername="${module_options["module_jellyseerr,dockername"]}"
	local port="${module_options["module_jellyseerr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyseerr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e LOG_LEVEL=debug \
				-e TZ="$(cat /etc/timezone)" \
				-e PORT=5055 \
				-p "${port}:5055" \
				-v "${base_dir}/config:/app/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_jellyseerr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_jellyseerr" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_jellyseerr,feature"]} ${commands[4]}
		;;
	esac
}
