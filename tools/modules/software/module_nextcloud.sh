module_options+=(
	["module_nextcloud,author"]="@igorpecovnik"
	["module_nextcloud,maintainer"]="@igorpecovnik"
	["module_nextcloud,feature"]="module_nextcloud"
	["module_nextcloud,example"]="install remove purge status help"
	["module_nextcloud,desc"]="Install nextcloud container"
	["module_nextcloud,status"]="Active"
	["module_nextcloud,doc_link"]="https://nextcloud.com/support/"
	["module_nextcloud,group"]="Downloaders"
	["module_nextcloud,port"]="1443"
	["module_nextcloud,arch"]="x86-64 arm64"
	["module_nextcloud,dockerimage"]="lscr.io/linuxserver/nextcloud:latest"
	["module_nextcloud,dockername"]="nextcloud"
)
#
# Module nextcloud
#
function module_nextcloud () {
	local title="Nextcloud"
	local dockerimage="${module_options["module_nextcloud,dockerimage"]}"
	local dockername="${module_options["module_nextcloud,dockername"]}"
	local port="${module_options["module_nextcloud,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nextcloud,example"]}"

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
				-p "${port}:443" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data:/data" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_nextcloud,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_nextcloud" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_nextcloud,feature"]} ${commands[4]}
		;;
	esac
}
