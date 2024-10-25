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
	$DIALOG --msgbox "To test that Plex Media Server  has installed successfully
In a web browser go to http://localhost:32400/web or 
http://127.0.0.1:32400/web on this computer." 9 70
}

