module_options+=(
	["module_mysql,author"]="@igorpecovnik"
	["module_mysql,maintainer"]="@igorpecovnik"
	["module_mysql,feature"]="module_mysql"
	["module_mysql,example"]="install remove purge status help"
	["module_mysql,desc"]="Install mysql container"
	["module_mysql,status"]="Active"
	["module_mysql,doc_link"]="https://hub.docker.com/_/mysql"
	["module_mysql,group"]="Database"
	["module_mysql,port"]="3306"
	["module_mysql,arch"]="x86-64 arm64"
	["module_mysql,dockerimage"]="mysql:lts"
	["module_mysql,dockername"]="mysql"
)
#
# Module MySQL
#
function module_mysql () {
	local title="MySQL"
	local dockerimage="${module_options["module_mysql,dockerimage"]}"
	local dockername="${module_options["module_mysql,dockername"]}"
	local port="${module_options["module_mysql,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mysql,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/mysql"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Exit if already installed (check is done by pull, but we need to handle params)
			if docker_is_installed "$dockername" "$dockerimage" 2>/dev/null; then
				echo "MySQL container is already installed."
				return 0
			fi

			# Get parameters or use defaults
			local mysql_root_password="${2:-armbian}"
			local mysql_database="${3:-armbian}"
			local mysql_user="${4:-armbian}"
			local mysql_password="${5:-armbian}"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e MYSQL_ROOT_PASSWORD="${mysql_root_password}" \
				-e MYSQL_DATABASE="${mysql_database}" \
				-e MYSQL_USER="${mysql_user}" \
				-e MYSQL_PASSWORD="${mysql_password}" \
				-v "${base_dir}:/var/lib/mysql" \
				-p "${port}:3306" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for MySQL to be ready
			until docker exec "$dockername" \
				env MYSQL_PWD="$mysql_root_password" \
				mysql -uroot -e "SELECT 1;" &>/dev/null; do
				echo "⏳ Waiting for MySQL to accept connections..."
				sleep 2
			done

			# Create additional databases
			local mysql_databases=("ghost")
			for db_name in "${mysql_databases[@]}"; do
				echo "⏳ Creating database: $db_name and granting privileges..."
				docker exec -i "$dockername" \
				env MYSQL_PWD="$mysql_root_password" \
				mysql -uroot <<-EOF
					CREATE DATABASE IF NOT EXISTS \`$db_name\`;
					GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '${mysql_user}'@'%';
					FLUSH PRIVILEGES;
				EOF
			done
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_mysql,feature"]} ${commands[1]}; then
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
			docker_show_module_help "module_mysql" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage\n\nOptionally accepts arguments:\n root_password database user user_password"
		;;
		*)
			${module_options["module_mysql,feature"]} ${commands[4]}
		;;
	esac
}
