
module_options+=(
	["install_docker,author"]="@schwar3kat"
	["install_docker,ref_link"]=""
	["install_docker,feature"]="install_docker"
	["install_docker,desc"]="Install docker from a repo using apt"
	["install_docker,example"]="install_docker engine"
	["install_docker,status"]="Active"
)
#
# Install Docker from repo using apt
# Setup sources list and GPG key then install the app. If you want a full desktop then $1=desktop
#
install_docker() {
	# Check if repo for distribution exists.
	URL="https://download.docker.com/linux/${DISTRO,,}/dists/$DISTROID"
	if wget --spider "${URL}" 2> /dev/null; then
		# Add Docker's official GPG key:
		wget -qO - https://download.docker.com/linux/${DISTRO,,}/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/docker.gpg > /dev/null
		if [[ $? -eq 0 ]]; then
			# Add the repository to Apt sources:
			cat <<- EOF > "/etc/apt/sources.list.d/docker.list"
			deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO,,} $DISTROID stable
			EOF
			apt_install_wrapper apt-get update
			# Install docker
			if [ "$1" = "engine" ]; then
				apt_install_wrapper apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			else
				apt_install_wrapper apt-get -y install docker-ce docker-ce-cli containerd.io
			fi
			systemctl enable docker.service > /dev/null 2>&1
			systemctl enable containerd.service > /dev/null 2>&1
			$DIALOG --msgbox "To test that Docker has installed successfully
run the following command: docker run hello-world" 9 70
		fi
	else
		$DIALOG --msgbox "ERROR ! ${DISTRO} $DISTROID distribution not found in repository!" 7 70
	fi
}

