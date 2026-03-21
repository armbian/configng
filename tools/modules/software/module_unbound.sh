module_options+=(
	["module_unbound,author"]="@igorpecovnik"
	["module_unbound,maintainer"]="@igorpecovnik"
	["module_unbound,feature"]="module_unbound"
	["module_unbound,example"]="install remove purge status help"
	["module_unbound,desc"]="Install unbound container"
	["module_unbound,status"]="Active"
	["module_unbound,doc_link"]="https://unbound.docs.nlnetlabs.nl/en/latest/"
	["module_unbound,group"]="DNS"
	["module_unbound,port"]="5335"
	["module_unbound,arch"]="x86-64"
	["module_unbound,dockerimage"]="alpinelinux/unbound"
	["module_unbound,dockername"]="unbound"
)
#
# Module Unbound
#
function module_unbound () {
	local title="Unbound"
	local dockerimage="${module_options["module_unbound,dockerimage"]}"
	local dockername="${module_options["module_unbound,dockername"]}"
	local port="${module_options["module_unbound,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_unbound,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create unbound.conf with port from module_options
			cat > "${base_dir}/unbound.conf" <<-EOT
			server:
				interface: 0.0.0.0
				port: $port
				access-control: 0.0.0.0/0 allow
				do-ip4: yes
				do-udp: yes
				do-tcp: yes
				do-ip6: no
				verbosity: 1
			EOT
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-p "${port}:${port}/tcp" \
				-p "${port}:${port}/udp" \
				-v "${base_dir}/unbound.conf:/etc/unbound/unbound.conf:ro" \
				--name "$dockername" \
				--restart=unless-stopped \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_unbound,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_unbound" "$title" \
				"Docker Image: $dockerimage\nPort: $port (TCP/UDP)"
		;;
		*)
			${module_options["module_unbound,feature"]} ${commands[4]}
		;;
	esac
}
