module_options+=(
	["module_deluge,author"]="@igorpecovnik"
	["module_deluge,maintainer"]="@igorpecovnik"
	["module_deluge,feature"]="module_deluge"
	["module_deluge,example"]="install remove purge status help"
	["module_deluge,desc"]="Install deluge container"
	["module_deluge,status"]="Active"
	["module_deluge,doc_link"]="https://deluge-torrent.org/userguide/"
	["module_deluge,group"]="Downloaders"
	["module_deluge,port"]="8112"
	["module_deluge,arch"]="x86-64 arm64"
	["module_deluge,dockerimage"]="linuxserver/deluge:latest"
	["module_deluge,dockername"]="deluge"
)
#
# Module Deluge
#
function module_deluge () {
	local title="Deluge"
	local dockerimage="${module_options["module_deluge,dockerimage"]}"
	local dockername="${module_options["module_deluge,dockername"]}"
	local port="${module_options["module_deluge,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_deluge,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/deluge"

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
				-e DELUGE_LOGLEVEL=error \
				-p 8112:8112 \
				-p 6181:6881 \
				-p 6181:6881/udp \
				-p 58846:58846 \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
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
			if ! ${module_options["module_deluge,feature"]} ${commands[1]}; then
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
			show_module_help "module_deluge" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_deluge,feature"]} ${commands[4]}
		;;
	esac
}
