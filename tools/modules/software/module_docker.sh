module_options+=(
	["module_docker,author"]="@schwar3kat"
	["module_docker,maintainer"]="@igorpecovnik"
	["module_docker,feature"]="module_docker"
	["module_docker,example"]="install remove purge status help"
	["module_docker,desc"]="Install docker from a repo using apt"
	["module_docker,status"]="Active"
	["module_docker,doc_link"]="https://docs.docker.com"
	["module_docker,group"]="Containers"
	["module_docker,port"]=""
	["module_docker,arch"]="x86-64 arm64 armhf riscv64"
)
#
# Install Docker from repo using apt
#
function module_docker() {

	local title="docker"
	local condition=$(which "$title" 2>/dev/null)
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_docker,example"]}"

	case "$1" in
		"${commands[0]}")
			# Install docker from distribution maintained packages

			# Stop and disable Docker first to ensure clean state
			srv_stop docker 2>/dev/null || true
			srv_disable docker 2>/dev/null || true
			srv_stop containerd 2>/dev/null || true
			srv_disable containerd 2>/dev/null || true

			# Kill any remaining Docker processes
			killall dockerd containerd 2>/dev/null || true
			sleep 2

			# Reset systemd failure state
			systemctl reset-failed docker 2>/dev/null || true
			systemctl reset-failed containerd 2>/dev/null || true

			pkg_update
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				# Install docker-ce (upstream) for bookworm
				pkg_install ca-certificates curl gnupg
				install -m 0755 -d /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
				chmod a+r /etc/apt/keyrings/docker.asc
				echo \
					"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
					${DISTROID} stable" | \
					tee /etc/apt/sources.list.d/docker.list > /dev/null
				pkg_update
				pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			else
				if pkg_installed docker-ce; then pkg_remove docker-ce; fi
				if pkg_installed docker-ce-cli; then pkg_remove docker-ce-cli; fi
				if pkg_installed containerd.io; then pkg_remove containerd.io; fi
				if pkg_installed docker-buildx-plugin; then pkg_remove docker-buildx-plugin; fi
				if pkg_installed docker-compose-plugin; then pkg_remove docker-compose-plugin; fi
				rm -f /etc/apt/sources.list.d/docker.list
				# install new
				pkg_install docker.io docker-cli docker-compose
			fi
			groupadd docker 2>/dev/null || true
			if [[ -n "${SUDO_USER}" ]]; then
				usermod -aG docker "${SUDO_USER}"
			fi

			srv_enable docker containerd

			# Start Docker and capture exit status
			if ! srv_start docker 2>/dev/null; then
				dialog_msgbox "Docker Installation Failed" \
					"Docker service failed to start.\n\nService status:\n$(systemctl status docker --no-pager 2>&1 || true)\n\nRecent logs:\n$(journalctl -xeu docker.service --no-pager -n 50 2>&1 || true)" \
					20 80
				return 1
			fi

			# Wait for Docker daemon to be responsive with multiple checks
			local max_wait=60
			local wait_count=0
			local socket_path="/var/run/docker.sock"
			local retry_count=0
			local max_retries=2
			local status_message="Initializing..."

			# Use dialog_gauge for visual progress
			(
				while [[ $wait_count -lt $max_wait ]]; do
					# Check if service failed during startup - try restart
					if systemctl is-failed --quiet docker 2>/dev/null; then
						if [[ $retry_count -lt $max_retries ]]; then
							status_message="Service failed, restarting (attempt $((retry_count + 1))/$max_retries)..."
							srv_stop docker 2>/dev/null || true
							systemctl reset-failed docker 2>/dev/null || true
							sleep 2
							srv_start docker 2>/dev/null
							((retry_count++))
							echo "XXX"
							echo "$((wait_count * 100 / max_wait))"
							echo "$status_message"
							echo "XXX"
							continue
						else
							echo "Error: Docker service failed after $max_retries restart attempts" >&2
							exit 1
						fi
					fi

					# Check 1: Socket exists
					if [[ ! -S "$socket_path" ]]; then
						status_message="Waiting for Docker socket..."
						echo "XXX"
						echo "$((wait_count * 100 / max_wait))"
						echo "$status_message"
						echo "XXX"
						sleep 1
						((wait_count++))
						continue
					fi

					# Check 2: API is responsive (this is the real test)
					if docker info >/dev/null 2>&1; then
						echo "XXX"
						echo "100"
						echo "Docker daemon is ready!"
						echo "XXX"
						exit 0
					fi

					status_message="Waiting for Docker API ([$((wait_count + 1))/${max_wait}])..."
					echo "XXX"
					echo "$((wait_count * 100 / max_wait))"
					echo "$status_message"
					echo "XXX"
					sleep 1
					((wait_count++))
				done

				if [[ $wait_count -ge $max_wait ]]; then
					echo "Error: Docker daemon failed to start within ${max_wait}s" >&2
					exit 1
				fi
			) | dialog_gauge "Docker Installation" "Starting Docker daemon..." 8 80

			local daemon_exit_code=$?

			if [[ $daemon_exit_code -ne 0 ]]; then
				dialog_msgbox "Docker Installation Failed" \
					"Docker daemon failed to start.\n\nService status:\n$(systemctl status docker --no-pager 2>&1 || true)\n\nSocket check:\n$(ls -la "$socket_path" 2>&1 || true)" \
					20 80
				return 1
			fi

			if ! docker network ls --format "{{.Name}}" | grep -q "^lsio$"; then
				docker network create lsio
			fi
		;;
		"${commands[1]}")
			docker network rm lsio 2>/dev/null || true
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
				rm -f /etc/apt/sources.list.d/docker.list
			else
				pkg_remove docker.io docker-cli docker-compose
			fi
			# Remove docker0 bridge interface if it exists
			if ip link show docker0 &>/dev/null; then
				ip link delete docker0
			fi
		;;
		"${commands[2]}")
			${module_options["module_docker,feature"]} ${commands[1]}
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				rm -f /etc/apt/sources.list.d/docker.list
				rm -f /etc/apt/keyrings/docker.asc
			fi
			rm -rf /var/lib/docker
			rm -rf /var/lib/containerd
		;;
		"${commands[3]}")
			if ! command -v docker >/dev/null 2>&1; then
				return 1
			fi

			if ! docker network ls --format "{{.Name}}" | grep -q "^lsio$"; then
				return 1
			fi

			return 0
		;;
		"${commands[4]}")
			docker_show_module_help "module_docker" "$title" \
				"Architecture: ${module_options["module_docker,arch"]}"
		;;
		*)
			${module_options["module_docker,feature"]} ${commands[4]}
		;;
	esac
}

