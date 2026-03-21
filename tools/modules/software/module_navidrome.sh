module_options+=(
	["module_navidrome,author"]="@armbian"
	["module_navidrome,maintainer"]="@igorpecovnik"
	["module_navidrome,feature"]="module_navidrome"
	["module_navidrome,example"]="install remove purge status help"
	["module_navidrome,desc"]="Install navidrome container"
	["module_navidrome,status"]="Active"
	["module_navidrome,doc_link"]="https://github.com/pynavidrome/navidrome/wiki"
	["module_navidrome,group"]="Downloaders"
	["module_navidrome,port"]="4533"
	["module_navidrome,arch"]="x86-64 arm64"
	["module_navidrome,dockerimage"]="deluan/navidrome:latest"
	["module_navidrome,dockername"]="navidrome"
)
#
# Install Module navidrome
#
function module_navidrome () {
	local title="Navidrome"
	local dockerimage="${module_options["module_navidrome,dockerimage"]}"
	local dockername="${module_options["module_navidrome,dockername"]}"
	local port="${module_options["module_navidrome,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_navidrome,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory and subdirectories
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/music" "${base_dir}/data"

			# Set ownership (navidrome requires specific UID)
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir/"

			# Run container with explicit user
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				--user "${DOCKER_USERUID}:${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:4533" \
				-v "${base_dir}/music:/music" \
				-v "${base_dir}/data:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_navidrome,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_navidrome" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_navidrome,feature"]} ${commands[4]}
		;;
	esac
}
