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
	# No /v1.XX/ prefix on the Docker API URL below: the daemon
	# serves versions between MinAPIVersion and APIVersion, and any
	# hardcoded value ages out of that window. Docker 29.x already
	# has MinAPIVersion 1.44, so a pin at v1.41 returns HTTP 400
	# outright. Omitting the prefix makes the daemon pick its own
	# latest, which is backward-compatible for the endpoints we use.
	local socket_path="/var/run/docker.sock"

	# Ensure Docker is available
	docker_ensure_docker

	# Ensure unbuffer is available (for real-time pull progress)
	if ! command -v unbuffer >/dev/null 2>&1; then
		pkg_install expect
	fi

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
	# rc_file threads the true exit status of the subshell past the
	# `... | dialog_gauge ...` pipe. Without it, `exit_code=$?` only
	# captures dialog_gauge's rc (almost always 0), so every docker
	# run/rm/rmi/pull failure bubbled up as success — the caller
	# (e.g. module_owncloud install) then reported success for a
	# container that never started, and the test suite's downstream
	# `status` step was the first to notice. Each branch writes 0
	# on success / 1 on failure to rc_file; the post-pipe check
	# reads it and surfaces the real result.
	local rc_file=$(mktemp)
	echo 0 > "$rc_file"
	local title="Docker $operation"

	# surface_failure <friendly-title>
	# Unified failure handler: emits the captured stderr to the
	# *real* stderr (so --api / CI consumers see the docker error)
	# AND shows a TUI msgbox (for interactive sessions). Without the
	# echo-to-stderr, dialog_msgbox alone hides the error from any
	# non-TTY caller, since msgbox writes to the dialog tool's FD
	# and --api mode has no one to read it.
	surface_failure() {
		local heading="$1"
		local body="$2"
		local error_output=""
		[[ -s "$error_file" ]] && error_output=$(<"$error_file")
		echo "${heading}: ${target}" >&2
		[[ -n "$error_output" ]] && printf '%s\n' "$error_output" >&2
		dialog_msgbox "$heading" "${body}: $target\n\n${error_output}" 14 60
	}

	case "$operation" in
		pull)
			# Ensure Docker is installed
			docker_ensure_docker || { rm -f "$error_file" "$rc_file"; return 1; }

			# Check if image already exists
			local existing_image
			existing_image=$(docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "^${target}$" | head -1)

			if [[ -n "$existing_image" ]]; then
				# Image already exists, skip pull
				rm -f "$error_file" "$rc_file"
				return 0
			fi

			# Pull image with progress via Docker API
			local raw_response_file=$(mktemp)
			local http_code_file=$(mktemp)

			# Split `repo:tag` into separate `fromImage` + `tag` query
			# params. Modern dockerd returns HTTP 400 when fromImage
			# carries the tag inline — `docker pull owncloud/server:
			# 10.16.1` works from the CLI but the same request shaped
			# as `POST /images/create?fromImage=owncloud/server:
			# 10.16.1` is rejected. The canonical API form passes
			# image and tag as separate query params. Split on the
			# LAST `:` so a registry:port prefix
			# (registry.example.com:5000/repo:tag) stays in fromImage
			# and only the tag goes to `tag=`. Default missing tag
			# to `latest` to match docker CLI behavior.
			local pull_image pull_tag
			if [[ "$target" == *:* ]]; then
				pull_image="${target%:*}"
				pull_tag="${target##*:}"
			else
				pull_image="$target"
				pull_tag="latest"
			fi

			(
				echo "XXX"
				echo "0"
				echo "Pulling: $target"
				echo "XXX"

				unbuffer curl --silent --show-error \
					--unix-socket "$socket_path" \
					-X POST "http://localhost/images/create?fromImage=${pull_image}&tag=${pull_tag}" \
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
					echo "HTTP $http_code from Docker API" >> "$error_file"
					echo 1 > "$rc_file"
					exit 0
				fi

				# Check if response file has content
				if [[ ! -s "$raw_response_file" ]]; then
					echo "XXX"
					echo "0"
					echo "Error: Empty response from Docker API"
					echo "XXX"
					echo "empty response from Docker API" >> "$error_file"
					echo 1 > "$rc_file"
					exit 0
				fi

				# Parse and display progress from captured response.
				# NB the parens: `or` must be INSIDE select(), not
				# outside. `select(X) or Y` is a boolean expression
				# (select filters the stream, then `or` returns a
				# bool) which the downstream `| if .error then ...`
				# cannot index, producing
				#   jq: error ... Cannot index boolean with string "error"
				# for every JSON line in the Docker API pull stream.
				# The original select((X) or (Y)) was mis-parenthesised
				# and only ever worked when jq happened to emit
				# nothing (e.g. pulls that returned zero progress
				# lines).
				if ! jq -r --unbuffered '
						select((.status != null) or (.error != null)) |
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
					echo "failed to parse Docker API response" >> "$error_file"
					echo 1 > "$rc_file"
					exit 0
				fi

				echo "XXX"
				echo "100"
				echo "Pull complete!"
				echo "XXX"
			) | dialog_gauge "$title" "Pulling: $target" 8 80

			rm -f "$raw_response_file" "$http_code_file"

			exit_code=$(<"$rc_file")

			# Verify and show result
			if [[ $exit_code -ne 0 ]]; then
				surface_failure "Pull Failed" "Failed to pull"
				rm -f "$error_file" "$rc_file"
				return 1
			fi
			# Note: We trust the Docker API response. If HTTP 200 with no errors,
			# the pull succeeded. Additional verification can fail when running
			# in Docker-in-Docker scenarios due to image registration delays.
			;;

		rm)
			# Remove container - check if exists first
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${target}$"; then
				# Container doesn't exist, silently succeed
				rm -f "$error_file" "$rc_file"
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
					echo 1 > "$rc_file"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$(<"$rc_file")

			if [[ $exit_code -ne 0 ]]; then
				surface_failure "Docker rm Failed" "Failed to remove container"
				rm -f "$error_file" "$rc_file"
				return 1
			fi
			;;

		rmi)
			# Remove image - check if exists first
			if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q "^${target}$"; then
				# Image doesn't exist, silently succeed
				rm -f "$error_file" "$rc_file"
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
					echo 1 > "$rc_file"
				fi
			) | dialog_gauge "$title" "Removing: $target" 6 80

			exit_code=$(<"$rc_file")

			if [[ $exit_code -ne 0 ]]; then
				surface_failure "Docker rmi Failed" "Failed to remove image"
				rm -f "$error_file" "$rc_file"
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

					# Wait for container to be ready. Timeout is a soft
					# warning (progress bar shows 75% + message) — not a
					# failure. docker run succeeded, container is up;
					# some images take a while to become "ready" by
					# their own definition.
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
					echo 1 > "$rc_file"
				fi
			) | dialog_gauge "$title" "Starting: $target" 8 80

			exit_code=$(<"$rc_file")

			if [[ $exit_code -ne 0 ]]; then
				surface_failure "Docker run Failed" "Failed to start container"
				rm -f "$error_file" "$rc_file"
				return 1
			fi
			;;
	esac

	# Clean up
	rm -f "$error_file" "$rc_file"

	return 0
}

#
# Configure SWAG reverse proxy for a service
# Usage: docker_configure_swag_proxy <servicename> [port]
#
# Parameters:
#   servicename - Name of the service (e.g., "transmission", "sonarr")
#   port - Optional: Override the default port in the proxy config
#
# Returns: 0 on success, 1 if proxy config not found or enabling failed
#
docker_configure_swag_proxy() {
	local servicename="$1"
	local port="$2"

	# Check if SWAG container exists
	if ! docker container ls -a --format "{{.Names}}" | grep -q "^swag$"; then
		return 2
	fi

	# Check if SWAG has proxy config for this service (sample or actual)
	local proxy_sample="/config/nginx/proxy-confs/${servicename}.subfolder.conf.sample"
	local proxy_actual="/config/nginx/proxy-confs/${servicename}.subfolder.conf"

	if docker exec swag test -f "$proxy_sample" 2>/dev/null; then
		# Copy sample to actual config if it doesn't exist
		if ! docker exec swag test -f "$proxy_actual" 2>/dev/null; then
			docker exec swag cp "$proxy_sample" "$proxy_actual" 2>/dev/null
		fi

		# If port is specified, update it in the config
		if [[ -n "$port" ]]; then
			docker exec swag sed -i "s/set \\\$upstream_port [0-9]*/set \\\$upstream_port ${port}/g" "$proxy_actual" 2>/dev/null
		fi

		# Enable the proxy configuration
		if docker exec swag touch "/config/nginx/proxy-confs/${servicename}.subfolder.conf.enabled" 2>/dev/null; then
			# Reload nginx to apply
			docker exec swag nginx -s reload >/dev/null 2>&1
			return 0
		fi
		return 1
	fi

	return 1
}
