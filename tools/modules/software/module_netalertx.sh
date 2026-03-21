module_options+=(
	["module_netalertx,author"]="@jokob-sk"
	["module_netalertx,maintainer"]="@igorpecovnik"
	["module_netalertx,feature"]="module_netalertx"
	["module_netalertx,example"]="install remove purge status help"
	["module_netalertx,desc"]="Install netalertx container"
	["module_netalertx,status"]="Preview"
	["module_netalertx,doc_link"]="https://netalertx.com"
	["module_netalertx,group"]="Monitoring"
	["module_netalertx,port"]="20211"
	["module_netalertx,arch"]="x86-64 arm64 armhf"
	["module_netalertx,dockerimage"]="ghcr.io/jokob-sk/netalertx:latest"
	["module_netalertx,dockername"]="netalertx"
)
#
# Module netalertx
#
function module_netalertx () {
	local title="NetAlertX"
	local dockerimage="${module_options["module_netalertx,dockerimage"]}"
	local dockername="${module_options["module_netalertx,dockername"]}"
	local port="${module_options["module_netalertx,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netalertx,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	NETALERTX_NO_TMPFS=1

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/db"

			# Check if we should use tmpfs for /app/api (requires sufficient RAM)
			local mount_params=""
			if [[ "${NETALERTX_NO_TMPFS}" != "1" ]]; then
				# Get available memory in MB
				local available_mem=$(free -m | awk '/^Mem:/{print $7}')
				# Only use tmpfs if we have at least 512MB available RAM
				if [[ $available_mem -ge 512 ]]; then
					mount_params="--mount type=tmpfs,tmpfs-size=512m,target=/app/api"
				else
					echo "Warning: Insufficient RAM for tmpfs mount. /app/api will use disk storage."
				fi
			fi

			# Run container with special security options
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--network=host \
				--cap-drop=ALL \
				--cap-add=CHOWN \
				--cap-add=SETGID \
				--cap-add=SETUID \
				--cap-add=NET_RAW \
				--cap-add=NET_ADMIN \
				--cap-add=NET_BIND_SERVICE \
				--read-only \
				--tmpfs /tmp \
				--tmpfs /tmp/run:rw,noexec,nosuid,size=128m \
				--tmpfs /tmp/log:rw,noexec,nosuid,size=64m \
				--tmpfs /tmp/nginx:rw,noexec,nosuid,size=32m \
				-e PUID=200 \
				-e PGID=300 \
				-e TZ="$(cat /etc/timezone)" \
				-e PORT="${port}" \
				-v "${base_dir}/config:/data/config:rw" \
				-v "${base_dir}/db:/data/db:rw" \
				$mount_params \
				--restart unless-stopped \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_netalertx,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_netalertx" "$title" \
				"Docker Image: $dockerimage\nPort: $port (uses host network)\n\nNote: Uses custom PUID=200, PGID=300 for security"
		;;
		*)
			${module_options["module_netalertx,feature"]} ${commands[4]}
		;;
	esac
}
