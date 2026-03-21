module_options+=(
	["module_postgres,author"]="@armbian"
	["module_postgres,maintainer"]="@igorpecovnik"
	["module_postgres,feature"]="module_postgres"
	["module_postgres,example"]="install remove purge status help"
	["module_postgres,desc"]="Install PostgreSQL container (advanced relational database)"
	["module_postgres,status"]="Active"
	["module_postgres,doc_link"]="https://www.postgresql.org/docs/"
	["module_postgres,group"]="Database"
	["module_postgres,port"]="5432"
	["module_postgres,arch"]="x86-64 arm64"
	["module_postgres,dockerimage"]="tensorchord/pgvecto-rs:pg14-v0.2.0"
	["module_postgres,dockername"]="postgres"
)

#
# Module PostgreSQL
#
function module_postgres () {
	local title="PostgreSQL"
	local port="${module_options["module_postgres,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	# Accept optional parameters
	local postgres_user="${2:-armbian}"
	local postgres_password="${3:-armbian}"
	local postgres_db="${4:-armbian}"
	local postgres_image="${5:-tensorchord/pgvecto-rs}"
	local postgres_tag="${6:-pg14-v0.2.0}"
	local postgres_container="${7:-postgres}"

	local dockerimage="${postgres_image}:${postgres_tag}"
	local dockername="$postgres_container"
	local base_dir="${SOFTWARE_FOLDER}/${postgres_container}"

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
				-e POSTGRES_USER="${postgres_user}" \
				-e POSTGRES_PASSWORD="${postgres_password}" \
				-e POSTGRES_DB="${postgres_db}" \
				-e TZ="$(cat /etc/timezone)" \
				-v "${base_dir}/${postgres_container}/data:/var/lib/postgresql/data" \
				-p "${port}:5432" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_postgres,feature"]} ${commands[1]}; then
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
			if [[ -t 1 ]]; then
				dialog_msgbox "$title Help" \
					"Usage: ${module_options["module_postgres,feature"]} <command> [username] [password] [database]\n\nCommands: ${module_options["module_postgres,example"]}\n\ninstall [username] [password] [database] - Install $title (defaults: armbian/armbian/armbian)\nremove - Remove $title\npurge  - Purge $title data\nstatus - Check $title installation status" 15 70
			else
				echo -e "\nUsage: ${module_options["module_postgres,feature"]} <command> [username] [password] [database]"
				echo "Commands: ${module_options["module_postgres,example"]}"
				echo -e "\tinstall [username] [password] [database] - Install ${title} (defaults: armbian/armbian/armbian)"
				echo -e "\tremove - Remove ${title}"
				echo -e "\tpurge  - Purge ${title} data"
				echo -e "\tstatus - Check ${title} installation status"
				echo
			fi
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}
