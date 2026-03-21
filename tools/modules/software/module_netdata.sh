module_options+=(
	["module_netdata,author"]="@armbian"
	["module_netdata,maintainer"]="@igorpecovnik"
	["module_netdata,feature"]="module_netdata"
	["module_netdata,example"]="install remove purge status help"
	["module_netdata,desc"]="Install netdata container"
	["module_netdata,status"]="Active"
	["module_netdata,doc_link"]="https://learn.netdata.cloud/"
	["module_netdata,group"]="Monitoring"
	["module_netdata,port"]="19999"
	["module_netdata,arch"]="x86-64 arm64"
	["module_netdata,dockerimage"]="netdata/netdata"
	["module_netdata,dockername"]="netdata"
)
#
# Module Netdata
#
function module_netdata () {
	local title="Netdata"
	local dockerimage="${module_options["module_netdata,dockerimage"]}"
	local dockername="${module_options["module_netdata,dockername"]}"
	local port="${module_options["module_netdata,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netdata,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/netdata"

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
				--network=host \
				-v "${base_dir}/netdataconfig:/etc/netdata" \
				-v "${base_dir}/netdatalib:/var/lib/netdata" \
				-v "${base_dir}/netdatacache:/var/cache/netdata" \
				-v /:/host/root:ro,rslave \
				-v /etc/passwd:/host/etc/passwd:ro \
				-v /etc/group:/host/etc/group:ro \
				-v /etc/localtime:/etc/localtime:ro \
				-v /proc:/host/proc:ro \
				-v /sys:/host/sys:ro \
				-v /etc/os-release:/host/etc/os-release:ro \
				-v /var/log:/host/var/log:ro \
				-v /var/run/docker.sock:/var/run/docker.sock:ro \
				--restart=always \
				--cap-add SYS_PTRACE \
				--cap-add SYS_ADMIN \
				--security-opt apparmor=unconfined \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_netdata,feature"]} ${commands[1]}; then
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
			docker_show_module_help "module_netdata" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage\n\nUses host networking for system monitoring"
		;;
		*)
			${module_options["module_netdata,feature"]} ${commands[4]}
		;;
	esac
}
