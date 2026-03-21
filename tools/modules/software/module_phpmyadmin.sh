module_options+=(
	["module_phpmyadmin,author"]="@igorpecovnik"
	["module_phpmyadmin,maintainer"]="@igorpecovnik"
	["module_phpmyadmin,feature"]="module_phpmyadmin"
	["module_phpmyadmin,example"]="install remove purge status help"
	["module_phpmyadmin,desc"]="Install phpmyadmin container"
	["module_phpmyadmin,status"]="Active"
	["module_phpmyadmin,doc_link"]="https://www.phpmyadmin.net/docs/"
	["module_phpmyadmin,group"]="Database"
	["module_phpmyadmin,port"]="8071"
	["module_phpmyadmin,arch"]="x86-64 arm64"
	["module_phpmyadmin,dockerimage"]="lscr.io/linuxserver/phpmyadmin:latest"
	["module_phpmyadmin,dockername"]="phpmyadmin"
)
#
# Module phpmyadmin-PDF
#
function module_phpmyadmin () {
	local title="phpMyAdmin"
	local dockerimage="${module_options["module_phpmyadmin,dockerimage"]}"
	local dockername="${module_options["module_phpmyadmin,dockername"]}"
	local port="${module_options["module_phpmyadmin,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_phpmyadmin,example"]}"

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
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e PMA_ARBITRARY=1 \
				-p "${port}:80" \
				-v "${base_dir}/config:/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_phpmyadmin,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_phpmyadmin" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_phpmyadmin,feature"]} ${commands[4]}
		;;
	esac
}
