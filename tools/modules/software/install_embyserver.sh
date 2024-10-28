
module_options+=(
	["install_embyserver,author"]="@schwar3kat"
	["install_embyserver,ref_link"]=""
	["install_embyserver,feature"]="install_embyserver"
	["install_embyserver,desc"]="Install embyserver from repo using apt"
	["install_embyserver,example"]="install_embyserver"
	["install_embyserver,status"]="Active"
)
#
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
