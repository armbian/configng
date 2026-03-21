module_options+=(
	["module_qbittorrent,author"]="@qbittorrent"
	["module_qbittorrent,maintainer"]="@igorpecovnik"
	["module_qbittorrent,feature"]="module_qbittorrent"
	["module_qbittorrent,example"]="install remove purge status help"
	["module_qbittorrent,desc"]="Install qbittorrent container"
	["module_qbittorrent,status"]="Active"
	["module_qbittorrent,doc_link"]="https://github.com/qbittorrent/qBittorrent/wiki/"
	["module_qbittorrent,group"]="Downloaders"
	["module_qbittorrent,port"]="8090"
	["module_qbittorrent,arch"]="x86-64 arm64"
	["module_qbittorrent,dockerimage"]="lscr.io/linuxserver/qbittorrent:latest"
	["module_qbittorrent,dockername"]="qbittorrent"
)
#
# Module qBittorrent
#
function module_qbittorrent () {
	local title="qBittorrent"
	local dockerimage="${module_options["module_qbittorrent,dockerimage"]}"
	local dockername="${module_options["module_qbittorrent,dockername"]}"
	local port="${module_options["module_qbittorrent,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_qbittorrent,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/qbittorrent"

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
				-e WEBUI_PORT=8090 \
				-e TORRENTING_PORT=6881 \
				-p 8090:8090 \
				-p 6881:6881 \
				-p 6881:6881/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"

			# Get temporary password from logs
			local temp_password
			temp_password=$(docker logs "$dockername" 2>&1 | grep password | grep session | cut -d":" -f2 | xargs)

			if [[ -t 1 ]]; then
				dialog_msgbox "qBittorrent installed" \
					"qBittorrent is listening at http://$LOCALIPADD:${port}\n\nLogin as: admin\n\nTemporary password: ${temp_password}" 10 70
			else
				echo -e "\nqBittorrent is listening at http://$LOCALIPADD:${port}\nLogin as: admin\nTemporary password: ${temp_password}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_qbittorrent,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_qbittorrent" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_qbittorrent,feature"]} ${commands[4]}
		;;
	esac
}
