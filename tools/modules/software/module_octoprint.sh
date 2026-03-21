module_options+=(
	["module_octoprint,author"]="@armbian"
	["module_octoprint,maintainer"]="@igorpecovnik"
	["module_octoprint,feature"]="module_octoprint"
	["module_octoprint,example"]="install remove purge status help"
	["module_octoprint,desc"]="Install octoprint container"
	["module_octoprint,status"]="Active"
	["module_octoprint,doc_link"]="https://transmissionbt.com/"
	["module_octoprint,group"]="Printing"
	["module_octoprint,port"]="7981"
	["module_octoprint,arch"]="x86-64 arm64"
	["module_octoprint,dockerimage"]="octoprint/octoprint:latest"
	["module_octoprint,dockername"]="octoprint"
)
#
# Module octoprint
#
function module_octoprint () {
	local title="OctoPrint"
	local dockerimage="${module_options["module_octoprint,dockerimage"]}"
	local dockername="${module_options["module_octoprint,dockername"]}"
	local port="${module_options["module_octoprint,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_octoprint,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Check if camera device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/video0 ]]; then
				device_params="--device /dev/video0:/dev/video0"
			else
				echo "Warning: /dev/video0 not found. Camera support will not be available."
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-v "${base_dir}:/octoprint/octoprint" \
				$device_params \
				-e TZ="$(cat /etc/timezone)" \
				-e ENABLE_MJPG_STREAMER=true \
				-p "${port}:80" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_octoprint,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_octoprint" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nNote: Camera support requires /dev/video0 device."
		;;
		*)
			${module_options["module_octoprint,feature"]} ${commands[4]}
		;;
	esac
}
