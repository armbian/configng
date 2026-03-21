module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="2080 2443 5007 9123"
	["module_openhab,arch"]="x86-64 arm64 armhf"
	["module_openhab,dockerimage"]="openhab/openhab:latest"
	["module_openhab,dockername"]="openhab"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {
	local title="openHAB"
	local dockerimage="${module_options["module_openhab,dockerimage"]}"
	local dockername="${module_options["module_openhab,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	# Parse ports
	local ports_array=(${module_options[module_openhab,port]})
	local port_http="${ports_array[0]}"
	local port_https="${ports_array[1]}"
	local port_l="${ports_array[2]}"
	local port_rest="${ports_array[3]}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/conf" "${base_dir}/userdata" "${base_dir}/addons"

			# Run container with multiple ports
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port_http}:8080" \
				-p "${port_https}:8443" \
				-p "${port_l}:5007" \
				-p "${port_rest}:9123" \
				-v /etc/localtime:/etc/localtime:ro \
				-v /etc/timezone:/etc/timezone:ro \
				-v "${base_dir}/conf:/openhab/conf" \
				-v "${base_dir}/userdata:/openhab/userdata" \
				-v "${base_dir}/addons:/openhab/addons" \
				-e USER_ID="${DOCKER_USERUID}" \
				-e GROUP_ID="${DOCKER_GROUPUID}" \
				-e CRYPTO_POLICY=unlimited \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_openhab,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_openhab" "$title" \
				"Docker Image: $dockerimage\nPorts: $port_http (HTTP), $port_https (HTTPS), $port_l, $port_rest"
		;;
		*)
			${module_options["module_openhab,feature"]} ${commands[4]}
		;;
	esac
}
