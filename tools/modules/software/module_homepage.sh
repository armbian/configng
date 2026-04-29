module_options+=(
	["module_homepage,author"]="@armbian"
	["module_homepage,maintainer"]="@igorpecovnik"
	["module_homepage,feature"]="module_homepage"
	["module_homepage,example"]="install remove purge status help"
	["module_homepage,desc"]="Install homepage container"
	["module_homepage,status"]="Active"
	["module_homepage,doc_link"]="https://gethomepage.dev/configs/"
	["module_homepage,group"]="Management"
	["module_homepage,port"]="3021"
	["module_homepage,arch"]=""
	["module_homepage,dockerimage"]="ghcr.io/gethomepage/homepage:latest"
	["module_homepage,dockername"]="homepage"
	["module_homepage,servicename"]="homepage"
)
#
# Module Homepage
#
function module_homepage () {
	local title="Homepage"
	local dockerimage="${module_options["module_homepage,dockerimage"]}"
	local dockername="${module_options["module_homepage,dockername"]}"
	local port="${module_options["module_homepage,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_homepage,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/homepage"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e HOMEPAGE_ALLOWED_HOSTS="${LOCALIPADD}:${port},homepage.local:${port},localhost:${port}" \
				-p "${port}:3000" \
				-v "${base_dir}/config:/app/config" \
				-v /var/run/docker.sock:/var/run/docker.sock:ro \
				--restart=always \
				"$dockerimage"
			# Auto-configure SWAG reverse proxy if available
			docker_configure_swag_proxy "homepage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_homepage,feature"]} ${commands[1]}; then
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
			show_module_help "module_homepage" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_homepage,feature"]} ${commands[4]}
		;;
	esac
}
