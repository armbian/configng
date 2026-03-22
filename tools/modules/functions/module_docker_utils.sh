#
# Armbian Docker utilities
#

#
# Ensure Docker is available
# Usage: docker_ensure_docker
# Returns: 0 if Docker is available, exits if it fails to install
#
docker_ensure_docker() {
	if ! module_docker status >/dev/null 2>&1; then
		module_docker install
		# Wait for Docker daemon to be ready after installation
		local max_wait=30
		local wait_count=0
		while [[ $wait_count -lt $max_wait ]]; do
			if docker info >/dev/null 2>&1; then
				return 0
			fi
			sleep 1
			((wait_count++))
		done
		dialog_msgbox "Error" "Docker installation failed or timed out.\n\nDocker daemon is not responding.\nPlease install Docker manually and try again." 10 60
		return 1
	fi
	return 0
}

#
# Get container ID by name
# Usage: docker_get_container_id <container_name>
# Outputs: Container ID or empty string if not found
#
docker_get_container_id() {
	local container_name="$1"
	docker container ls -a --filter "name=^${container_name}$" --format '{{.ID}}' 2>/dev/null || echo ""
}

#
# Get image reference by image pattern
# Usage: docker_get_image_ref <image_pattern>
# Outputs: Image reference (repo:tag) or empty string if not found
#
docker_get_image_ref() {
	local image_pattern="$1"
	docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "$image_pattern" | head -1 || echo ""
}

#
# Check if container and image are installed
# Usage: docker_is_installed <container_name> <image_pattern>
# Returns: 0 if both container and image exist, 1 otherwise
#
docker_is_installed() {
	local container_name="$1"
	local image_pattern="$2"
	local container=$(docker_get_container_id "$container_name")
	local image=$(docker_get_image_ref "$image_pattern")
	[[ "${container}" && "${image}" ]] && return 0 || return 1
}

#
# Manage base directory with error handling
# Usage: docker_manage_base_dir <create|remove> <base_dir>
# Returns: 0 on success, 1 on failure
#
docker_manage_base_dir() {
	local mode="$1"
	local base_dir="$2"

	docker_ensure_docker

	case "$mode" in
		create)
			if [[ ! -d "$base_dir" ]]; then
				if ! mkdir -p "$base_dir"; then
					dialog_msgbox "Error" "Failed to create directory:\n$base_dir" 8 50
					return 1
				fi
				# Set ownership to the Docker user
				chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir"
			fi
			;;
		remove)
			if [[ -n "$base_dir" && -d "$base_dir" && "$base_dir" != "/" ]]; then
				rm -rf "$base_dir"
			fi
			;;
		*)
			dialog_msgbox "Error" "Invalid mode: $mode\nUse 'create' or 'remove'" 8 50
			return 1
			;;
	esac

	return 0
}

#
# Backward compatibility wrapper
# Deprecated: Use docker_manage_base_dir instead
#
docker_create_base_dir() {
	docker_manage_base_dir create "$1"
}

#
# Parse module commands array
# Usage: docker_parse_commands <module_prefix>
# Outputs: Array reference to commands
#
docker_parse_commands() {
	local module_prefix="$1"
	local commands_var="${module_prefix},example"
	IFS=' ' read -r -a commands <<< "${module_options["$commands_var"]}"
	echo "${commands[@]}"
}

#
# Docker operation with progress display
# Supports: pull, rm (container), rmi (image), run (container)
#
# Usage:
#   docker_operation_progress pull <image_name>
#   docker_operation_progress rm <container_name>
#   docker_operation_progress rmi <image_name>
#   docker_operation_progress run <container_name> [docker_run_args...]
#
# Example for run:
#   docker_operation_progress run mycontainer --name mycontainer -d -p 80:80 nginx
#
docker_operation_progress() {
	local operation="$1"
	local target="$2"
	local api_version="v1.41"
	local socket_path="/var/run/docker.sock"

	# Ensure Docker is available
	docker_ensure_docker

	# Argument validation
	if [[ -z "$operation" || -z "$target" ]]; then
		dialog_msgbox "Usage Error" "Usage: docker_operation_progress <pull|rm|rmi> <target>\n\n  pull <image>   - Pull Docker image\n  rm <container> - Remove container\n  rmi <image>    - Remove image" 12 60
		return 1
	fi

	# Validate operation type
	case "$operation" in
		pull|rm|rmi|run)
			;;
		*)
			dialog_msgbox "Error" "Invalid operation: $operation\n\nValid operations: pull, rm, rmi, run" 10 50
			return 1
			;;
	esac

	# Check for socket access
	if [[ ! -r "$socket_path" || ! -w "$socket_path" ]]; then
		dialog_msgbox "Permission Error" "Cannot access Docker socket at $socket_path\n\nYou may need to be in the 'docker' group or run with sudo." 12 60
		return 1
	fi

	# Check if docker is running
	if ! docker info &> /dev/null; then
		dialog_msgbox "Docker Error" "Docker daemon is not running.\nPlease start Docker and try again." 10 60
		return 1
	fi

	local exit_code
	local error_file=$(mktemp)
	local title="Docker $operation"

	case "$operation" in
		pull)
			# Ensure Docker is installed
			docker_ensure_docker || return 1

			# Check if image already exists
			local existing_image
			existing_image=$(docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "^${target}$" | head -1)

			if [[ -n "$existing_image" ]]; then
				# Image already exists, skip pull
				return 0
			fi

			# Pull image with progress via Docker API
			local raw_response_file=$(mktemp)
			local http_code_file=$(mktemp)

			(
				echo "XXX"
				echo "0"
				echo "Pulling: $target"
				echo "XXX"

				unbuffer curl --silent --show-error \
					--unix-socket "$socket_path" \
					-X POST "http://localhost/$api_version/images/create?fromImage=$target" \
					-w "%{http_code}" \
					-o "$raw_response_file" \
					2> "$error_file" \
				> "$http_code_file"

				# Check HTTP response code
				local http_code=$(<"$http_code_file")
				if [[ "$http_code" != "200" ]]; then
					echo "XXX"
					echo "0"
					echo "Error: HTTP $http_code"
					echo "XXX"
					exit 1
				fi

				# Check if response file has content
				if [[ ! -s "$raw_response_file" ]]; then
					echo "XXX"
					echo "0"
					echo "Error: Empty response from Docker API"
					echo "XXX"
					exit 1
				fi

				# Parse and display progress from captured response
				if ! jq -r --unbuffered '
						select(.status != null) or (.error != null) |
						if .error then
							"ERROR\n" + .error + "\n"
						elif .progressDetail.current and .progressDetail.total then
							# Calculate actual percentage
							"XXX\n" +
							((.progressDetail.current / .progressDetail.total) * 100 | floor | tostring) +
							"\nLayer: " + (.id[0:12] // "Unknown") + "...  " + .status +
							"\nXXX"
						else
							# No progress detail - show status
							"XXX\n0\n" + (.id // "Preparing") + "...  " + .status + "\nXXX"
						end
					' "$raw_response_file" 2>> "$error_file"; then
					echo "XXX"
					echo "0"
					echo "Error: Failed to parse Docker API response"
					echo "XXX"
					exit 1
				fi

				echo "XXX"
				echo "100"
				echo "Pull complete!"
				echo "XXX"
			) | dialog_gauge "$title" "Pulling: $target" 8 80

			exit_code=$?

			rm -f "$raw_response_file" "$http_code_file"

			# Verify and show result
			if [[ $exit_code -eq 0 ]]; then
				local image_id
				image_id=$(docker images -q "$target" 2>/dev/null | head -n 1)

				if [[ -z "$image_id" ]]; then
					local error_output=""
					[[ -s "$error_file" ]] && error_output=$(<"$error_file")

					dialog_msgbox "Pull Failed" \
						"Failed to pull: $target\n\nThe pull operation completed but the image was not found.\n\nThis may be due to:\n- Network issues during download\n- Registry authentication errors\n- Invalid image name or tag\n- Docker API returned empty response\n\nError details:\n${error_output}" \
						14 70
					return 1
				fi
			else
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Pull Failed" "Failed to pull: $target\n\nExit code: $exit_code\n\n${error_output}" 14 60
				return 1
			fi
			;;

		rm)
			# Remove container - check if exists first
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${target}$"; then
				# Container doesn't exist, silently succeed
				return 0
			fi

			(
				echo "XXX"
				echo "0"
				echo "Removing container: $target"
				echo "XXX"

				# Remove container and show progress
				if docker rm -f "$target" 2> "$error_file"; then
					echo "XXX"
					echo "100"
					echo "Container removed successfully!"
					echo "XXX"
				else
					echo "XXX"
					echo "0"
					echo "Failed to remove container"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to remove container: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;

		rmi)
			# Remove image - check if exists first
			if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q "^${target}$"; then
				# Image doesn't exist, silently succeed
				return 0
			fi

			(
				echo "XXX"
				echo "0"
				echo "Removing image: $target"
				echo "XXX"

				# Remove image and show progress
				if docker rmi -f "$target" 2> "$error_file"; then
					echo "XXX"
					echo "100"
					echo "Image removed successfully!"
					echo "XXX"
				else
					echo "XXX"
					echo "0"
					echo "Failed to remove image"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to remove image: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;

		run)
			# Run container - $target is container name, rest are docker run args
			local docker_args=("${@:3}")
			(
				echo "XXX"
				echo "0"
				echo "Starting container: $target"
				echo "XXX"

				# Run the container and capture output
				if docker run "${docker_args[@]}" 2> "$error_file"; then
					echo "XXX"
					echo "50"
					echo "Container started. Waiting for ready..."
					echo "XXX"

					# Wait for container to be ready
					if wait_for_container_ready "$target" 2>/dev/null; then
						echo "XXX"
						echo "100"
						echo "Container is ready!"
						echo "XXX"
					else
						echo "XXX"
						echo "75"
						echo "Container started but readiness check timed out"
						echo "XXX"
					fi
				else
					echo "XXX"
					echo "0"
					echo "Failed to start container"
					echo "XXX"
				fi
			) | dialog_gauge "$title" "Starting: $target" 8 80

			exit_code=$?

			if [[ $exit_code -ne 0 ]]; then
				local error_output=""
				[[ -s "$error_file" ]] && error_output=$(<"$error_file")
				dialog_msgbox "Error" "Failed to start container: $target\n\n${error_output}" 10 60
				return 1
			fi
			;;
	esac

	# Clean up error file
	rm -f "$error_file"

	return 0
}
