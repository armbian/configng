module_options+=(
	["module_syncthing,author"]="@igorpecovnik"
	["module_syncthing,maintainer"]="@igorpecovnik"
	["module_syncthing,feature"]="module_syncthing"
	["module_syncthing,example"]="install remove purge status help"
	["module_syncthing,desc"]="Install syncthing container"
	["module_syncthing,status"]="Active"
	["module_syncthing,doc_link"]="https://docs.syncthing.net/"
	["module_syncthing,group"]="Media"
	["module_syncthing,port"]="8884 22000 21027"
	["module_syncthing,arch"]="x86-64 arm64"
	["module_syncthing,dockerimage"]="lscr.io/linuxserver/syncthing:latest"
	["module_syncthing,dockername"]="syncthing"
)
#
# Module syncthing
#
function module_syncthing () {
	local title="Syncthing"
	local dockerimage="${module_options["module_syncthing,dockerimage"]}"
	local dockername="${module_options["module_syncthing,dockername"]}"
	local port="${module_options["module_syncthing,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_syncthing,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories for data
			mkdir -p "${base_dir}/config" "${base_dir}/data1" "${base_dir}/data2"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--hostname="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p 8884:8384 \
				-p 22000:22000/tcp \
				-p 22000:22000/udp \
				-p 21027:21027/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data1:/data1" \
				-v "${base_dir}/data2:/data2" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_syncthing,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_syncthing" "$title" \
				"Docker Image: $dockerimage\nPorts: 8884 (Web UI), 22000 (TCP/UDP), 21027 (UDP)"
		;;
		*)
			${module_options["module_syncthing,feature"]} ${commands[4]}
		;;
	esac
}
