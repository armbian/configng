module_options+=(
	["module_domoticz,author"]="@armbian"
	["module_domoticz,maintainer"]="@igorpecovnik"
	["module_domoticz,feature"]="module_domoticz"
	["module_domoticz,example"]="install remove purge status help"
	["module_domoticz,desc"]="Install domoticz container"
	["module_domoticz,status"]="Active"
	["module_domoticz,doc_link"]="https://wiki.domoticz.com"
	["module_domoticz,group"]="Monitoring"
	["module_domoticz,port"]="8780"
	["module_domoticz,arch"]=""
	["module_domoticz,dockerimage"]="domoticz/domoticz:stable"
	["module_domoticz,dockername"]="domoticz"
)
#
# Module domoticz
#
function module_domoticz () {
	local title="Domoticz"
	local dockerimage="${module_options["module_domoticz,dockerimage"]}"
	local dockername="${module_options["module_domoticz,dockername"]}"
	local port="${module_options["module_domoticz,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_domoticz,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Check if USB serial device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/ttyUSB0 ]]; then
				device_params="--device /dev/ttyUSB0:/dev/ttyUSB0"
			else
				echo "Warning: /dev/ttyUSB0 not found. USB serial device support will not be available."
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--pid=host \
				--net=lsio \
				$device_params \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8080" \
				-p 8443:443 \
				-v "${base_dir}:/opt/domoticz/userdata" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_domoticz,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_domoticz" "$title" \
				"Docker Image: $dockerimage\nPorts: $port (HTTP), 8443 (HTTPS)\n\nNote: USB serial support requires /dev/ttyUSB0 device."
		;;
		*)
			${module_options["module_domoticz,feature"]} ${commands[4]}
		;;
	esac
}
