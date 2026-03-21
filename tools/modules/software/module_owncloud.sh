module_options+=(
	["module_owncloud,author"]="@armbian"
	["module_owncloud,maintainer"]="@igorpecovnik"
	["module_owncloud,feature"]="module_owncloud"
	["module_owncloud,example"]="install remove purge status help"
	["module_owncloud,desc"]="Install owncloud container"
	["module_owncloud,status"]="Active"
	["module_owncloud,doc_link"]="https://doc.owncloud.com/"
	["module_owncloud,group"]="Database"
	["module_owncloud,port"]="7787"
	["module_owncloud,arch"]="x86-64 arm64"
	["module_owncloud,dockerimage"]="owncloud/server:latest"
	["module_owncloud,dockername"]="owncloud"
)
#
# Module owncloud
#
function module_owncloud () {
	local title="ownCloud"
	local dockerimage="${module_options["module_owncloud,dockerimage"]}"
	local dockername="${module_options["module_owncloud,dockername"]}"
	local port="${module_options["module_owncloud,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_owncloud,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/data"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e "OWNCLOUD_TRUSTED_DOMAINS=${LOCALIPADD}" \
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data:/mnt/data" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_owncloud,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_owncloud" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_owncloud,feature"]} ${commands[4]}
		;;
	esac
}
