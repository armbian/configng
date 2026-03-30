module_options+=(
	["module_code-server,author"]="@igorpecovnik"
	["module_code-server,maintainer"]="@igorpecovnik"
	["module_code-server,feature"]="module_code-server"
	["module_code-server,example"]="install remove purge status help"
	["module_code-server,desc"]="Install VS Code in browser container"
	["module_code-server,status"]="Active"
	["module_code-server,doc_link"]="https://github.com/linuxserver/docker-code-server"
	["module_code-server,group"]="Development"
	["module_code-server,port"]="8443"
	["module_code-server,arch"]="x86-64 arm64"
	["module_code-server,dockerimage"]="lscr.io/linuxserver/code-server:latest"
	["module_code-server,dockername"]="code-server"
)
#
# Module Code-server
#
# Code-server is VS Code running on a remote server, accessible through
# the browser. This module manages the Docker container deployment with
# persistent storage for configuration and workspace data.
#
# Environment variables:
#   PASSWORD          - Optional password for web UI (not recommended)
#   HASHED_PASSWORD   - Optional hashed password for web UI
#   SUDO_PASSWORD     - Optional password for sudo access
#   PROXY_DOMAIN      - Optional proxy domain for reverse proxy
#   DEFAULT_WORKSPACE - Optional default workspace directory
#   PWA_APPNAME       - Optional PWA app name
#
function module_code-server () {
	local title="Code-server"
	local dockerimage="${module_options["module_code-server,dockerimage"]}"
	local dockername="${module_options["module_code-server,dockername"]}"
	local port="${module_options["module_code-server,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_code-server,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local config_dir="${base_dir}/config"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config directory
			mkdir -p "$config_dir" || {
				dialog_msgbox "Directory Creation Failed" \
					"Failed to create required directories.\n\nCheck permissions and try again." 8 50
				return 1
			}

			# Run container with LinuxServer.io recommended settings
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8443" \
				-v "${config_dir}:/config" \
				--restart=unless-stopped \
				"$dockerimage"

		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_code-server,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_code-server" "$title" \
				"Web Interface: http://localhost:${port}\n\nDocker Image: $dockerimage\n\nConfig Directory: ${config_dir}\n\nOptional Environment Variables:\n  PASSWORD - Set web UI password (not recommended)\n  HASHED_PASSWORD - Set hashed password\n  SUDO_PASSWORD - Set sudo password\n  PROXY_DOMAIN - Proxy domain for reverse proxy\n  DEFAULT_WORKSPACE - Default workspace directory\n  PWA_APPNAME - PWA application name"
		;;
		*)
			${module_options["module_code-server,feature"]} ${commands[4]}
		;;
	esac
}
