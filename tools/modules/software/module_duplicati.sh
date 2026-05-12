module_options+=(
	["module_duplicati,author"]="@armbian"
	["module_duplicati,maintainer"]="@igorpecovnik"
	["module_duplicati,feature"]="module_duplicati"
	["module_duplicati,example"]="install remove purge status help"
	["module_duplicati,desc"]="Install duplicati container"
	["module_duplicati,status"]="Active"
	["module_duplicati,doc_link"]="https://prev-docs.duplicati.com/en/latest/"
	["module_duplicati,group"]="Backup"
	["module_duplicati,port"]="8200"
	["module_duplicati,arch"]="x86-64 arm64"
	["module_duplicati,dockerimage"]="linuxserver/duplicati:latest"
	["module_duplicati,dockername"]="duplicati"
)
#
# Module duplicati
#
function module_duplicati () {
	local title="Duplicati"
	local dockerimage="${module_options["module_duplicati,dockerimage"]}"
	local dockername="${module_options["module_duplicati,dockername"]}"
	local port="${module_options["module_duplicati,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_duplicati,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			shift
			# Accept encryption key and WebUI password from parameters if provided
			local encryption_key="$1"
			local webui_password="$2"

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/config" "${base_dir}/backups"

			# If no encryption key provided, prompt for it
			if [[ -z "${encryption_key}" ]]; then
				encryption_key=$(dialog_inputbox "Duplicati Encryption Key" "\nEnter an encryption key for Duplicati (at least 8 characters):" "" 9 60)
			fi

			# Check encryption key length
			if [[ -z "${encryption_key}" || ${#encryption_key} -lt 8 ]]; then
				echo -e "\nError: Encryption key must be at least 8 characters long!"
				exit 1
			fi

			# If no WebUI password provided, prompt for it
			if [[ -z "${webui_password}" ]]; then
				webui_password=$(dialog_inputbox "Duplicati WebUI Password" "\nEnter a password for Duplicati WebUI (at least 8 characters):" "" 9 60)
			fi

			# Check WebUI password length
			if [[ -z "${webui_password}" || ${#webui_password} -lt 8 ]]; then
				echo -e "\nError: WebUI password must be at least 8 characters long!"
				exit 1
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e SETTINGS_ENCRYPTION_KEY="${encryption_key}" \
				-e DUPLICATI__WEBSERVICE_PASSWORD="${webui_password}" \
				-p "${port}:8200" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/backups:/backups" \
				-v /:/source:ro \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_duplicati,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_duplicati" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nOptional arguments for install:\n  encryption_key webui_password"
		;;
		*)
			${module_options["module_duplicati,feature"]} ${commands[4]}
		;;
	esac
}
