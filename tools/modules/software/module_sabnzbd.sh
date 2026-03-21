module_options+=(
	["module_sabnzbd,author"]="@armbian"
	["module_sabnzbd,maintainer"]="@igorpecovnik"
	["module_sabnzbd,feature"]="module_sabnzbd"
	["module_sabnzbd,example"]="install remove purge status help"
	["module_sabnzbd,desc"]="Install sabnzbd container"
	["module_sabnzbd,status"]="Active"
	["module_sabnzbd,doc_link"]="https://sabnzbd.org/wiki/faq"
	["module_sabnzbd,group"]="Downloaders"
	["module_sabnzbd,port"]="8380"
	["module_sabnzbd,arch"]="x86-64 arm64"
	["module_sabnzbd,dockerimage"]="lscr.io/linuxserver/sabnzbd:latest"
	["module_sabnzbd,dockername"]="sabnzbd"
)
#
# Module SABnzbd
#
function module_sabnzbd () {
	local title="SABnzbd"
	local dockerimage="${module_options["module_sabnzbd,dockerimage"]}"
	local dockername="${module_options["module_sabnzbd,dockername"]}"
	local port="${module_options["module_sabnzbd,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sabnzbd,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/sabnzbd"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/incomplete:/incomplete-downloads" \
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
			if ! ${module_options["module_sabnzbd,feature"]} ${commands[1]}; then
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
			docker_show_module_help "module_sabnzbd" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_sabnzbd,feature"]} ${commands[4]}
		;;
	esac
}
