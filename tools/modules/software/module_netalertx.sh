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
)
#
# Module netalertx
#
# module_netalertx - Manage the lifecycle of the 'netalertx' Docker container.
#
# This function processes a command argument to perform one of several operations on
# the netalertx container, including installation, removal, purging, status checking,
# and help display. It verifies that Docker is installed (and installs it if necessary),
# prepares the storage environment, and handles container startup with a timeout mechanism.
#
# Globals:
#   module_options  - Associative array containing module metadata and example command strings.
#   SOFTWARE_FOLDER - Base directory path for software installations.
#   NETALERTX_BASE  - Set to the storage directory for netalertx configuration and database.
#
# Arguments:
#   $1  The command to execute. Recognized commands (as defined in module_options) include:
#         install  - Installs and starts the netalertx container.
#         remove   - Stops and removes the netalertx container and its image.
#         purge    - Removes the container and image, then deletes the storage directory.
#         status   - Checks if both the container and image exist; returns success (0) if true, failure (1) otherwise.
#         help     - Displays usage instructions and available commands.
#
# Outputs:
#   Prints messages to STDOUT/STDERR regarding operation progress, usage instructions, or error notifications.
#
# Returns:
#   Exits with status 0 on success (e.g., container running, valid status check)
#   or with status 1 on errors (e.g., failure to create the storage directory or container startup timeout).
#
# Example:
#   module_netalertx install   # Installs and runs the netalertx container.
#   module_netalertx status    # Checks the installation status of netalertx.
#
function module_netalertx () {
	local title="netalertx"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=netalertx" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'netalertx' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netalertx,example"]}"

	NETALERTX_BASE="${SOFTWARE_FOLDER}/netalertx"

	NETALERTX_NO_TMPFS=1

	case "$1" in
		"${commands[0]}")
			[[ -d "$NETALERTX_BASE" ]] || mkdir -p "$NETALERTX_BASE" || { echo "Couldn't create storage directory: $NETALERTX_BASE"; exit 1; }

			# Check if we should use tmpfs for /app/api (requires sufficient RAM)
			# Set NETALERTX_NO_TMPFS=1 to disable tmpfs and use disk instead
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

			docker run -d \
			--name=netalertx \
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
			-e PORT=20211 \
			-v "${NETALERTX_BASE}/config:/data/config:rw" \
			-v "${NETALERTX_BASE}/db:/data/db:rw" \
			$mount_params \
			--restart unless-stopped \
			ghcr.io/jokob-sk/netalertx:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' netalertx 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs netalertx\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
		;;
		"${commands[2]}")
			${module_options["module_netalertx,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_netalertx,feature"]} ${commands[1]}
			if [[ -n "${NETALERTX_BASE}" && "${NETALERTX_BASE}" != "/" ]]; then
				rm -rf "${NETALERTX_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_netalertx,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netalertx,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_netalertx,feature"]} ${commands[4]}
		;;
	esac
}
