module_options+=(
	["module_wallos,author"]="@igorpecovnik"
	["module_wallos,maintainer"]="@igorpecovnik"
	["module_wallos,feature"]="module_wallos"
	["module_wallos,example"]="install remove purge status help"
	["module_wallos,desc"]="Install Wallos finance tracker container"
	["module_wallos,status"]="Active"
	["module_wallos,doc_link"]="https://github.com/Wallos-app/Wallos"
	["module_wallos,group"]="Finance"
	["module_wallos,port"]="8282"
	["module_wallos,arch"]="x86-64 arm64"
	["module_wallos,dockerimage"]="bellamy/wallos:latest"
	["module_wallos,dockername"]="wallos"
)
#
# Module Wallos
#
# Wallos is a self-hosted finance tracker application that helps you track
# subscriptions and recurring expenses. This module manages the Docker
# container deployment with persistent storage for database and logos.
#
function module_wallos () {
	local title="Wallos"
	local dockerimage="${module_options["module_wallos,dockerimage"]}"
	local dockername="${module_options["module_wallos,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wallos,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local config_dir="${base_dir}/config"
	local db_dir="${config_dir}/db"
	local logos_dir="${config_dir}/logos"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config directories
			mkdir -p "$db_dir" "$logos_dir" || {
				dialog_msgbox "Directory Creation Failed" \
					"Failed to create required directories.\n\nCheck permissions and try again." 8 50
				return 1
			}

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-v "${db_dir}:/var/www/html/db" \
				-v "${logos_dir}:/var/www/html/images/uploads/logos" \
				-e TZ="${TZ:-Europe/Berlin}" \
				-p 8282:80 \
				--restart=unless-stopped \
				"$dockerimage"

			dialog_msgbox "Wallos Installed" \
				"Wallos finance tracker has been installed!\n\nAccess it at: http://localhost:8282\n\nConfiguration directory:\n${config_dir}" 10 70
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_wallos,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_wallos" "$title" \
				"Docker Image: $dockerimage\nPort: 8282\nData directories:\n  Database: ${db_dir}\n  Logos: ${logos_dir}"
		;;
		*)
			${module_options["module_wallos,feature"]} ${commands[4]}
		;;
	esac
}
