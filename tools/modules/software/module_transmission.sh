module_options+=(
	["module_transmission,author"]="@armbian"
	["module_transmission,maintainer"]="@igorpecovnik"
	["module_transmission,feature"]="module_transmission"
	["module_transmission,example"]="install remove purge status help"
	["module_transmission,desc"]="Install transmission container"
	["module_transmission,status"]="Active"
	["module_transmission,doc_link"]="https://transmissionbt.com/"
	["module_transmission,group"]="Downloaders"
	["module_transmission,port"]="9091"
	["module_transmission,arch"]="x86-64 arm64"
	["module_transmission,dockerimage"]="linuxserver/transmission:latest"
	["module_transmission,dockername"]="transmission"
	["module_transmission,servicename"]="transmission"
)
#
# Module Transmission
#
function module_transmission () {
	local title="Transmission"
	local dockerimage="${module_options["module_transmission,dockerimage"]}"
	local dockername="${module_options["module_transmission,dockername"]}"
	local port="${module_options["module_transmission,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_transmission,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/transmission"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Get username and password
			local transmission_user
			local transmission_pass
			transmission_user=$(dialog_inputbox "Enter username for Transmission" "\nHit enter for default" "armbian" 9 50)
			transmission_pass=$(dialog_inputbox "Enter password for Transmission" "\nHit enter for default" "armbian" 9 50)

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e USER="${transmission_user}" \
				-e PASS="${transmission_pass}" \
				-e WHITELIST="${TRANSMISSION_WHITELIST}" \
				-p 9091:9091 \
				-p 51413:51413 \
				-p 51413:51413/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/watch:/watch" \
				--restart=always \
				"$dockerimage"
		# Auto-configure SWAG reverse proxy if available
		docker_configure_swag_proxy "transmission"
			;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_transmission,feature"]} ${commands[1]}; then
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
			show_module_help "module_transmission" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_transmission,feature"]} ${commands[4]}
		;;
	esac
}
