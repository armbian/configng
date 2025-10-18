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
	["module_docker,arch"]="x86-64 arm64 armhf"
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
			# Check if repo for distribution exists.
			URL="https://download.docker.com/linux/${DISTRO,,}/dists/$DISTROID"
			if wget --spider "${URL}" 2> /dev/null; then
				# Add Docker's official GPG key:
				wget -qO - https://download.docker.com/linux/${DISTRO,,}/gpg \
				| gpg --dearmor | sudo tee /usr/share/keyrings/docker.gpg > /dev/null
				if [[ $? -eq 0 ]]; then
					# Add the repository to Apt sources:
					cat <<- EOF > "/etc/apt/sources.list.d/docker.list"
					deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
					https://download.docker.com/linux/${DISTRO,,} $DISTROID stable
					EOF
					pkg_update
					# Install docker
					if [ "$2" = "engine" ]; then
						pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
					else
						pkg_install docker-ce docker-ce-cli containerd.io
					fi

					groupadd docker 2>/dev/null || true
					if [[ -n "${SUDO_USER}" ]]; then
						usermod -aG docker "${SUDO_USER}"
					fi
					srv_enable docker containerd
					srv_start docker
					docker network create lsio 2> /dev/null
				fi
			else
				$DIALOG --msgbox "ERROR ! ${DISTRO} $DISTROID distribution not found in repository!" 7 70
			fi
		;;
		"${commands[1]}")
			pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
		;;
		"${commands[2]}")
			rm -rf /var/lib/docker
			rm -rf /var/lib/containerd
		;;
		"${commands[3]}")
			if [ "$2" = "docker-ce" ]; then
				if pkg_installed docker-ce; then
					return 0
				else
					return 1
				fi
			fi
			if [ "$2" = "docker-compose-plugin" ]; then
				if pkg_installed docker-compose-plugin; then
					return 0
				else
					return 1
				fi
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_docker,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_docker,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
		${module_options["module_docker,feature"]} ${commands[4]}
		;;
	esac
}

