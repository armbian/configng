module_options+=(
	["module_jellyfin,author"]="@armbian"
	["module_jellyfin,maintainer"]="@igorpecovnik"
	["module_jellyfin,feature"]="module_jellyfin"
	["module_jellyfin,example"]="install remove purge status help"
	["module_jellyfin,desc"]="Install jellyfin container"
	["module_jellyfin,status"]="Preview"
	["module_jellyfin,doc_link"]="https://jellyfin.org/docs/general/quick-start/"
	["module_jellyfin,group"]="Media"
	["module_jellyfin,port"]="8096"
	["module_jellyfin,arch"]="x86-64 arm64"
	["module_jellyfin,dockerimage"]="lscr.io/linuxserver/jellyfin:latest"
	["module_jellyfin,dockername"]="jellyfin"
)
#
# Module Jellyfin
#
function module_jellyfin () {
	local title="Jellyfin"
	local dockerimage="${module_options["module_jellyfin,dockerimage"]}"
	local dockername="${module_options["module_jellyfin,dockername"]}"
	local port="${module_options["module_jellyfin,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyfin,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/jellyfin"

	# Hardware acceleration
	local hwacc=""
	if [[ "${LINUXFAMILY}" == "rk35xx" && "${BOOT_SOC}" == "rk3588" ]]; then
		# Add udev rules according to Jellyfin's recommendations for RKMPP
		cat > "/etc/udev/rules.d/50-rk3588-mpp.rules" <<- EOT
		KERNEL=="mpp_service", MODE="0660", GROUP="video"
		KERNEL=="rga", MODE="0660", GROUP="video"
		KERNEL=="system", MODE="0666", GROUP="video"
		KERNEL=="system-dma32", MODE="0666", GROUP="video"
		KERNEL=="system-uncached", MODE="0666", GROUP="video"
		KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video" RUN+="/usr/bin/chmod a+rw /dev/dma_heap"
		EOT
		udevadm control --reload-rules && udevadm trigger

		# Pack `hwacc` to expose MPP/VPU hardware to the container
		for dev in dri dma_heap mali0 rga mpp_service \
			iep mpp-service vpu_service vpu-service \
			hevc_service hevc-service rkvdec rkvenc vepu h265e ; do
			[ -e "/dev/$dev" ] && hwacc+=" --device /dev/$dev"
		done
	elif [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		hwacc="--device=/dev/video10:/dev/video10 --device=/dev/video11:/dev/video11 --device=/dev/video12:/dev/video12"
	elif [[ "${LINUXFAMILY}" == "x86" ]]; then
		hwacc="--device=/dev/dri:/dev/dri"
	fi

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				$hwacc \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p 8096:8096 \
				-p 8920:8920 \
				-p 7359:7359/udp \
				-p 1900:1900/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/tvseries:/data/tvshows" \
				-v "${base_dir}/movies:/data/movies" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# Drop udev rules upon removal
			rm -f "/etc/udev/rules.d/50-rk3588-mpp.rules"
			udevadm control --reload-rules && udevadm trigger
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_jellyfin,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove config if container/image removal succeeded, keep media
			rm -rf "${base_dir}/config" 2>/dev/null || true
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_jellyfin" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage\n\nHardware acceleration: Auto-detected for RK3588, BCM2711, and x86"
		;;
		*)
			${module_options["module_jellyfin,feature"]} ${commands[4]}
		;;
	esac
}
