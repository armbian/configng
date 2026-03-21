module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,maintainer"]="@igorpecovnik"
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,example"]="install remove purge status help"
	["module_uptimekuma,desc"]="Install uptimekuma container"
	["module_uptimekuma,status"]="Active"
	["module_uptimekuma,doc_link"]="https://github.com/louislam/uptime-kuma/wiki"
	["module_uptimekuma,group"]="Downloaders"
	["module_uptimekuma,port"]="3001"
	["module_uptimekuma,arch"]="x86-64 arm64"
	["module_uptimekuma,dockerimage"]="louislam/uptime-kuma:2"
	["module_uptimekuma,dockername"]="uptime-kuma"
)
#
# Module uptimekuma
#
function module_uptimekuma () {
	local title="Uptime Kuma"
	local dockerimage="${module_options["module_uptimekuma,dockerimage"]}"
	local dockername="${module_options["module_uptimekuma,dockername"]}"
	local port="${module_options["module_uptimekuma,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_uptimekuma,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/uptimekuma"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				-p "${port}:3001" \
				-v "${base_dir}:/app/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_uptimekuma,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_uptimekuma" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_uptimekuma,feature"]} ${commands[4]}
		;;
	esac
}
