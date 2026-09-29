module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,maintainer"]="@igorpecovnik"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,example"]="remove purge status help"
	["module_watchtower,desc"]="Remove watchtower container (install no longer offered)"
	["module_watchtower,status"]="Active"
	["module_watchtower,doc_link"]="https://containrrr.dev/watchtower/"
	["module_watchtower,group"]="Updates"
	["module_watchtower,port"]=""
	["module_watchtower,arch"]="x86-64 arm64"
	["module_watchtower,dockerimage"]="containrrr/watchtower:latest"
	["module_watchtower,dockername"]="watchtower"
)
#
# Module watchtower
#
function module_watchtower () {
	local title="Watchtower"
	local dockerimage="${module_options["module_watchtower,dockerimage"]}"
	local dockername="${module_options["module_watchtower,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[1]}") # purge
			# Remove container and image first
			if ! ${module_options["module_watchtower,feature"]} ${commands[0]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[2]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[3]}") # help
			show_module_help "module_watchtower" "$title" \
				"Docker Image: $dockerimage\nPorts: None\n\nNote: upstream is archived; install is no longer offered"
		;;
		*)
			${module_options["module_watchtower,feature"]} ${commands[3]}
		;;
	esac
}
