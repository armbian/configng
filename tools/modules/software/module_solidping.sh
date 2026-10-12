module_options+=(
	["module_solidping,author"]="@fclairamb"
	["module_solidping,maintainer"]="@fclairamb"
	["module_solidping,feature"]="module_solidping"
	["module_solidping,example"]="install remove purge status help"
	["module_solidping,desc"]="Install SolidPing container"
	["module_solidping,status"]="Active"
	["module_solidping,doc_link"]="https://docs.solidping.io"
	["module_solidping,group"]="Monitoring"
	["module_solidping,port"]="4000"
	["module_solidping,arch"]="x86-64 arm64"
	["module_solidping,dockerimage"]="ghcr.io/fclairamb/solidping:latest"
	["module_solidping,dockername"]="solidping"
)
#
# Module SolidPing
#
function module_solidping () {
	local title="SolidPing"
	local dockerimage="${module_options["module_solidping,dockerimage"]}"
	local dockername="${module_options["module_solidping,dockername"]}"
	local port="${module_options["module_solidping,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_solidping,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/solidping"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			# The worker name is derived from the hostname, so it must be set.
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--hostname "$dockername" \
				--restart=always \
				--user "${DOCKER_USERUID}:${DOCKER_GROUPUID}" \
				-p "${port}:4000" \
				-v "${base_dir}:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername" || return 1
			docker_operation_progress rmi "$dockerimage" || return 1
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_solidping,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_solidping" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_solidping,feature"]} ${commands[4]}
		;;
	esac
}
