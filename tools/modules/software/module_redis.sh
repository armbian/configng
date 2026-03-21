module_options+=(
	["module_redis,author"]="@armbian"
	["module_redis,maintainer"]="@igorpecovnik"
	["module_redis,feature"]="module_redis"
	["module_redis,example"]="install remove purge status help"
	["module_redis,desc"]="Install Redis in a container (In-Memory Data Store)"
	["module_redis,status"]="Active"
	["module_redis,doc_link"]="https://redis.io/docs/"
	["module_redis,group"]="Database"
	["module_redis,port"]="6379"
	["module_redis,arch"]="x86-64 arm64"
	["module_redis,dockerimage"]="redis:alpine"
	["module_redis,dockername"]="redis"
)
#
# Module Redis
#
function module_redis () {
	local title="Redis"
	local dockerimage="${module_options["module_redis,dockerimage"]}"
	local dockername="${module_options["module_redis,dockername"]}"
	local port="${module_options["module_redis,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/redis"

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
				--restart=always \
				-p "${port}:6379" \
				-v "${base_dir}/data:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_redis,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_redis" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_redis,feature"]} ${commands[4]}
		;;
	esac
}
