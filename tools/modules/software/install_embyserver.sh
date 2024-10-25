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
		$DIALOG --gauge "Please wait
Downloading ${URL##*/}" 8 70 0
	apt_install_wrapper apt-get -y install ~/emby-server.deb
	unlink emby-server.deb
	$DIALOG --msgbox "To test that Emby Server  has installed successfully
In a web browser go to http://localhost:8096 or 
http://127.0.0.1:8096 on this computer." 9 70
}

