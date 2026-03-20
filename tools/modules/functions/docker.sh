#
# Armbian Docker utilities
#

#
# Docker pull with progress bar using dialog
# Uses Docker API via Unix socket for real-time progress
#
docker_pull_progress() {
	local image_name="$1"
	local api_version="v1.41"
	local socket_path="/var/run/docker.sock"

	# Check dependencies
	for cmd in curl jq dialog unbuffer stdbuf; do
		if ! command -v "$cmd" &> /dev/null; then
			dialog_msgbox "Dependency Error" "Required command '$cmd' is not installed.\nPlease install it to use this feature." 10 60
			return 1
		fi
	done

	# Argument validation
	if [[ -z "$image_name" ]]; then
		dialog_msgbox "Usage Error" "No image name provided.\n\nUsage: docker_pull_progress <image_name>" 10 60
		return 1
	fi

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

	# Pull image with progress bar using aggressive anti-buffering pipeline
	# unbuffer: tricks curl into line-buffering
	# stdbuf -oL: forces jq to line-buffer output
	# jq --unbuffered: flushes after each object
	#
	# Don't capture output - let dialog_gauge display directly
	# Use temporary file for error capture
	local error_file=$(mktemp)

	unbuffer curl --silent --show-error \
		--unix-socket "$socket_path" \
		-X POST "http://localhost/$api_version/images/create?fromImage=$image_name" \
		2> "$error_file" \
	| stdbuf -oL jq -r --unbuffered '
		# Show all status messages, not just ones with progress
		select(.status != null) |
		if .progressDetail.current and .progressDetail.total then
			# Have progress detail - calculate percentage
			"XXX\n" +
			((.progressDetail.current / .progressDetail.total) * 100 | floor | tostring) +
			"\n" + (.id // "Unknown") + ": " + .status +
			"\nXXX"
		else
			# No progress detail - show status with indeterminate progress
			"XXX\n" +
			"0\n" +
			(.id // "Docker") + ": " + .status +
			"\nXXX"
		end
	' 2>> "$error_file" \
	| dialog_gauge "Pulling" "$image_name" 8 70

	exit_code=$?

	# Clean up error file
	if [[ -s "$error_file" ]]; then
		local error_output=$(<"$error_file")
		rm -f "$error_file"
	else
		rm -f "$error_file"
		error_output=""
	fi

	if [[ $exit_code -eq 0 ]]; then
		# Verify image was pulled
		local image_id
		image_id=$(docker images -q "$image_name" 2>/dev/null | head -n 1)

		if [[ -n "$image_id" ]]; then
			dialog_msgbox "Success" "Successfully pulled $image_name!\n\nImage ID: ${image_id:0:12}" 10 60
		else
			dialog_msgbox "Warning" "Pull command completed but image not found.\nThis may indicate a partial pull." 10 60
			return 1
		fi
	else
		dialog_msgbox "Pull Failed" "Failed to pull image $image_name.\n\nExit code: $exit_code\n\n${error_output}" 12 60
		return 1
	fi

	return 0
}
