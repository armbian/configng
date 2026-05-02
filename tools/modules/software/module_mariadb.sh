module_options+=(
	["module_mariadb,author"]="@igorpecovnik"
	["module_mariadb,maintainer"]="@igorpecovnik"
	["module_mariadb,feature"]="module_mariadb"
	["module_mariadb,example"]="install remove purge status help"
	["module_mariadb,desc"]="Install mariadb container"
	["module_mariadb,status"]="Active"
	["module_mariadb,doc_link"]="https://mariadb.org/documentation/"
	["module_mariadb,group"]="Database"
	["module_mariadb,port"]="3307"
	["module_mariadb,arch"]="x86-64 arm64"
	["module_mariadb,dockerimage"]="linuxserver/mariadb:latest"
	["module_mariadb,dockername"]="mariadb"
)
#
# Module MariaDB
#
function module_mariadb () {
	local title="MariaDB"
	local dockerimage="${module_options["module_mariadb,dockerimage"]}"
	local dockername="${module_options["module_mariadb,dockername"]}"
	local port="${module_options["module_mariadb,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mariadb,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/mariadb"

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
				-p "${port}:3306" \
				-v "${base_dir}:/config" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e MYSQL_ROOT_PASSWORD=armbian \
				-e MYSQL_DATABASE=armbian \
				-e MYSQL_USER=armbian \
				-e MYSQL_PASSWORD=armbian \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_mariadb,feature"]} ${commands[1]}; then
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
			show_module_help "module_mariadb" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_mariadb,feature"]} ${commands[4]}
		;;
	esac
}
