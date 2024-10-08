module_options+=(
	["see_monitoring,author"]="Joey Turner"
	["see_monitoring,ref_link"]=""
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]="see_monitoring"
	["see_monitoring,status"]="review"
	["see_monitoring,doc_link"]=""
)
#
# @decrition generate a menu for armbianmonitor
#
function see_monitoring() {
	if [ -f /usr/bin/htop ]; then
		choice=$(armbianmonitor -h | grep -Ev '^\s*-c\s|^\s*-M\s' | show_menu)

		armbianmonitor -$choice

	else
		echo "htop is not installed"
	fi
}

module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_plexmediaserver"
	["update_skel,desc"]="Install plexmediaserver from repo using apt"
	["update_skel,example"]="install_plexmediaserver"
	["update_skel,status"]="Active"
)
#
# Install plexmediaserver using apt
#
install_plexmediaserver() {
	if [ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]; then
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/plexmediaserver.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
	else
		sed -i "/downloads.plex.tv/s/^#//g" /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
	fi
	# Note: for compatibility with existing source file in some builds format must be gpg not asc
	# and location must be /usr/share/keyrings
	wget -qO- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plexmediaserver.gpg > /dev/null 2>&1
	apt_install_wrapper apt-get update
	apt_install_wrapper apt-get -y install plexmediaserver
	$DIALOG --msgbox "To test that Plex Media Server  has installed successfully\nIn a web browser go to http://localhost:32400/web or \nhttp://127.0.0.1:32400/web on this computer." 9 70
}

module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_embyserver"
	["update_skel,desc"]="Download a embyserver deb file from a URL and install using apt"
	["update_skel,example"]="install_embyserver"
	["update_skel,status"]="Active"
)
#
# Download a deb file from a URL and install using wget and apt with dialog progress bars
#
install_embyserver() {
	URL=$(curl -s https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest |
		grep "/emby-server-deb.*$(dpkg --print-architecture).deb" | cut -d : -f 2,3 | tr -d '"')
	cd ~/
	wget -O "emby-server.deb" $URL 2>&1 | stdbuf -oL awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' |
		$DIALOG --gauge "Please wait\nDownloading ${URL##*/}" 8 70 0
	apt_install_wrapper apt-get -y install ~/emby-server.deb
	unlink emby-server.deb
	$DIALOG --msgbox "To test that Emby Server  has installed successfully\nIn a web browser go to http://localhost:8096 or \nhttp://127.0.0.1:8096 on this computer." 9 70
}

module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_docker"
	["update_skel,desc"]="Install docker from a repo using apt"
	["update_skel,example"]="install_docker engine"
	["update_skel,status"]="Active"
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
			$DIALOG --msgbox "To test that Docker has installed successfully\nrun the following command: docker run hello-world" 9 70
		fi
	else
		$DIALOG --msgbox "ERROR ! ${DISTRO} $DISTROID distribution not found in repository!" 7 70
	fi
}


