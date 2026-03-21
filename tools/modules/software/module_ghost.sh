module_options+=(
	["module_ghost,author"]="@igorpecovnik"
	["module_ghost,maintainer"]="@igorpecovnik"
	["module_ghost,feature"]="module_ghost"
	["module_ghost,example"]="install remove purge status help"
	["module_ghost,desc"]="Install Ghost CMS container"
	["module_ghost,status"]="Active"
	["module_ghost,doc_link"]="https://ghost.org/docs/"
	["module_ghost,group"]="WebHosting"
	["module_ghost,port"]="9190"
	["module_ghost,arch"]="x86-64 arm64"
	["module_ghost,dockerimage"]="ghost:6"
	["module_ghost,dockername"]="ghost"
)

#
# Module ghost
#
function module_ghost () {
	local title="Ghost CMS"
	local dockerimage="${module_options["module_ghost,dockerimage"]}"
	local dockername="${module_options["module_ghost,dockername"]}"
	local port="${module_options["module_ghost,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_ghost,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Install mysql if not installed
			if ! module_mysql status; then
				module_mysql install
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Exit if ghost is already running
			if docker_is_installed "$dockername" "$dockerimage"; then
				echo "Ghost container is already installed and running."
				exit 0
			fi

			# User inputs for MySQL
			local mysql_user="${2:-armbian}"
			local mysql_password="${3:-armbian}"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net=lsio \
				--restart unless-stopped \
				-e database__client=mysql \
				-e database__connection__host="mysql" \
				-e database__connection__user="${mysql_user}" \
				-e database__connection__password="${mysql_password}" \
				-e database__connection__database="ghost" \
				-p "${port}:2368" \
				-e url="http://$LOCALIPADD:${port}" \
				-v "$base_dir:/var/lib/ghost/content" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_ghost,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_ghost" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nOptional arguments for install:\n  db_user db_pass"
		;;
		*)
			${module_options["module_ghost,feature"]} ${commands[4]}
		;;
	esac
}
