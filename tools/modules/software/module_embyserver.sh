module_options+=(
	["module_embyserver,author"]="@schwar3kat"
	["module_embyserver,maintainer"]="@schwar3kat"
	["module_embyserver,feature"]="module_embyserver"
	["module_embyserver,example"]="install remove purge status help"
	["module_embyserver,desc"]="Install embyserver container"
	["module_embyserver,status"]="Active"
	["module_embyserver,doc_link"]="https://emby.media"
	["module_embyserver,group"]="Media"
	["module_embyserver,port"]="8091"
	["module_embyserver,arch"]="x86-64 arm64"
	["module_embyserver,dockerimage"]="lscr.io/linuxserver/emby:latest"
	["module_embyserver,dockername"]="emby"
)
#
# Module Emby server
#
function module_embyserver () {
	local title="Emby"
	local dockerimage="${module_options["module_embyserver,dockerimage"]}"
	local dockername="${module_options["module_embyserver,dockername"]}"
	local port="${module_options["module_embyserver,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_embyserver,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/emby/library" "${base_dir}/movies" "${base_dir}/tvshows"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8096" \
				-v "${base_dir}/emby/library:/config" \
				-v "${base_dir}/movies:/movies" \
				-v "${base_dir}/tvshows:/tvshows" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_embyserver,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_embyserver" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_embyserver,feature"]} ${commands[4]}
		;;
	esac
}
