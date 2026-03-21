module_options+=(
	["module_grafana,author"]="@armbian"
	["module_grafana,maintainer"]="@igorpecovnik"
	["module_grafana,feature"]="module_grafana"
	["module_grafana,example"]="install remove purge status help"
	["module_grafana,desc"]="Install grafana container"
	["module_grafana,status"]="Active"
	["module_grafana,doc_link"]="https://grafana.com/docs/"
	["module_grafana,group"]="Monitoring"
	["module_grafana,port"]="3022"
	["module_grafana,arch"]="x86-64 arm64"
	["module_grafana,dockerimage"]="grafana/grafana-enterprise:latest"
	["module_grafana,dockername"]="grafana"
)
#
# Module Grafana
#
function module_grafana () {
	local title="Grafana"
	local dockerimage="${module_options["module_grafana,dockerimage"]}"
	local dockername="${module_options["module_grafana,dockername"]}"
	local port="${module_options["module_grafana,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_grafana,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/grafana"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--pid=host \
				--net=lsio \
				--user 0 \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:3000" \
				-v "${base_dir}:/var/lib/grafana" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_grafana,feature"]} ${commands[1]}; then
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
			docker_show_module_help "module_grafana" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_grafana,feature"]} ${commands[4]}
		;;
	esac
}
