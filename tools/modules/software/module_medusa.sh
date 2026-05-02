module_options+=(
	["module_medusa,author"]="@armbian"
	["module_medusa,maintainer"]="@igorpecovnik"
	["module_medusa,feature"]="module_medusa"
	["module_medusa,example"]="install remove purge status help"
	["module_medusa,desc"]="Install medusa container"
	["module_medusa,status"]="Active"
	["module_medusa,doc_link"]="https://github.com/pymedusa/Medusa/wiki"
	["module_medusa,group"]="Downloaders"
	["module_medusa,port"]="8081"
	["module_medusa,arch"]="x86-64 arm64"
	["module_medusa,dockerimage"]="linuxserver/medusa:latest"
	["module_medusa,dockername"]="medusa"
)
#
# Install Module medusa
#
function module_medusa () {
	local title="Medusa"
	local dockerimage="${module_options["module_medusa,dockerimage"]}"
	local dockername="${module_options["module_medusa,dockername"]}"
	local port="${module_options["module_medusa,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_medusa,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/downloads" "${base_dir}/downloads/tv"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8081" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/downloads/tv:/tv" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_medusa,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_medusa" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_medusa,feature"]} ${commands[4]}
		;;
	esac
}
