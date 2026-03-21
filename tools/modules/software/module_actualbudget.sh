module_options+=(
	["module_actualbudget,author"]="@armbian"
	["module_actualbudget,maintainer"]="@igorpecovnik"
	["module_actualbudget,feature"]="module_actualbudget"
	["module_actualbudget,example"]="install remove purge status help"
	["module_actualbudget,desc"]="Install actualbudget container"
	["module_actualbudget,status"]="Active"
	["module_actualbudget,doc_link"]="https://actualbudget.org/docs"
	["module_actualbudget,group"]="Finances"
	["module_actualbudget,port"]="5443"
	["module_actualbudget,arch"]="x86-64 arm64"
	["module_actualbudget,dockerimage"]="actualbudget/actual-server:latest"
	["module_actualbudget,dockername"]="my_actual_budget"
)
#
# Module ActualBudget
#
function module_actualbudget () {
	local title="ActualBudget"
	local dockerimage="${module_options["module_actualbudget,dockerimage"]}"
	local dockername="${module_options["module_actualbudget,dockername"]}"
	local port="${module_options["module_actualbudget,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_actualbudget,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/actualbudget"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				--name "$dockername" \
				-v "${base_dir}/data:/data" \
				-p 5006:5006 \
				-p "${port}:443" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_actualbudget,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_actualbudget" "$title" \
				"Web Interface: http://localhost:${port}\nData Port: 5006\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_actualbudget,feature"]} ${commands[4]}
		;;
	esac
}
