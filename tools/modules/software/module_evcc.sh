module_options+=(
	["module_evcc,author"]="@naltatis"
	["module_evcc,maintainer"]="@igorpecovnik"
	["module_evcc,feature"]="module_evcc"
	["module_evcc,example"]="install remove purge status help"
	["module_evcc,desc"]="Install evcc container"
	["module_evcc,status"]="Active"
	["module_evcc,doc_link"]="https://docs.evcc.io/en"
	["module_evcc,group"]="HomeAutomation"
	["module_evcc,port"]="7070"
	["module_evcc,arch"]=""
	["module_evcc,dockerimage"]="evcc/evcc:latest"
	["module_evcc,dockername"]="evcc"
)
#
# Module evcc: Solar charging. Super simple
#
function module_evcc () {
	local title="evcc"
	local dockerimage="${module_options["module_evcc,dockerimage"]}"
	local dockername="${module_options["module_evcc,dockername"]}"
	local port="${module_options["module_evcc,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_evcc,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config file
			touch "${base_dir}/evcc.yaml"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-v "${base_dir}/evcc.yaml:/app/evcc.yaml" \
				-v "${base_dir}/.evcc:/root/.evcc" \
				-v /etc/machine-id:/etc/machine-id \
				-p "${port}:7070" \
				-p 8887:8887 \
				-p 9522:9522/udp \
				-p 4712:4712 \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_evcc,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_evcc" "$title" \
				"Docker Image: $dockerimage\nPorts: $port (main), 8887, 9522/udp, 4712"
		;;
		*)
			${module_options["module_evcc,feature"]} ${commands[4]}
		;;
	esac
}
