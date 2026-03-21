module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,maintainer"]="@igorpecovnik"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,example"]="install remove purge status help"
	["module_watchtower,desc"]="Install watchtower container"
	["module_watchtower,status"]="Active"
	["module_watchtower,doc_link"]="https://containrrr.dev/watchtower/"
	["module_watchtower,group"]="Updates"
	["module_watchtower,port"]=""
	["module_watchtower,arch"]="x86-64 arm64"
	["module_watchtower,dockerimage"]="containrrr/watchtower:latest"
	["module_watchtower,dockername"]="watchtower"
)
#
# Module watchtower
#
function module_watchtower () {
	local title="Watchtower"
	local dockerimage="${module_options["module_watchtower,dockerimage"]}"
	local dockername="${module_options["module_watchtower,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container with docker socket mount
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v "${base_dir}:/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_watchtower,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_watchtower" "$title" \
				"Docker Image: $dockerimage\nPorts: None\n\nNote: Mounts Docker socket for container updates"
		;;
		*)
			${module_options["module_watchtower,feature"]} ${commands[4]}
		;;
	esac
}
