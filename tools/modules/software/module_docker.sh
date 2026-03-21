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
				echo "Error: Docker service failed to start"
				echo ""
				echo "Service status:"
				systemctl status docker --no-pager 2>&1 || true
				echo ""
				echo "Recent logs:"
				journalctl -xeu docker.service --no-pager -n 50 2>&1 || true
				return 1
			fi

			# Wait for Docker daemon to be responsive with multiple checks
			local max_wait=60
			local wait_count=0
			local socket_path="/var/run/docker.sock"
			local retry_count=0
			local max_retries=2

			echo "Waiting for Docker daemon to start..."

			while [[ $wait_count -lt $max_wait ]]; do
				# Check if service failed during startup - try restart
				if systemctl is-failed --quiet docker 2>/dev/null; then
					if [[ $retry_count -lt $max_retries ]]; then
						echo "Docker service failed, attempting restart (attempt $((retry_count + 1))/$max_retries)..."
						srv_stop docker 2>/dev/null || true
						systemctl reset-failed docker 2>/dev/null || true
						sleep 2
						srv_start docker 2>/dev/null
						((retry_count++))
						continue
					else
						echo "Error: Docker service failed after $max_retries restart attempts"
						echo ""
						echo "Service status:"
						systemctl status docker --no-pager 2>&1 || true
						echo ""
						echo "Recent logs:"
						journalctl -xeu docker.service --no-pager -n 50 2>&1 || true
						return 1
					fi
				fi

				# Check 1: Socket exists
				if [[ ! -S "$socket_path" ]]; then
					echo "[$((wait_count + 1))/${max_wait}] Waiting for socket..."
					sleep 1
					((wait_count++))
					continue
				fi

				# Check 2: Service is active
				if ! systemctl is-active --quiet docker 2>/dev/null; then
					echo "[$((wait_count + 1))/${max_wait}] Waiting for service to be active..."
					sleep 1
					((wait_count++))
					continue
				fi

				# Check 3: API is responsive
				if docker info >/dev/null 2>&1; then
					echo "Docker daemon is ready!"
					break
				fi

				echo "[$((wait_count + 1))/${max_wait}] Waiting for API to respond..."
				sleep 1
				((wait_count++))
			done

			if [[ $wait_count -ge $max_wait ]]; then
				echo "Error: Docker daemon failed to start within ${max_wait}s"
				echo "Service status:"
				systemctl status docker --no-pager 2>&1 || true
				echo ""
				echo "Socket check:"
				ls -la "$socket_path" 2>&1 || true
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
				echo "Docker command not found"
				return 1
			fi

			if ! docker network ls --format "{{.Name}}" | grep -q "^lsio$"; then
				echo "lsio network not found"
				return 1
			fi

			echo "Docker installed and lsio network exists"
			return 0
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_docker,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_docker,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title (upstream for bookworm, distro for others)."
			echo -e "\tstatus\t- Check if Docker is installed and lsio network exists"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_docker,feature"]} ${commands[4]}
		;;
	esac
}

