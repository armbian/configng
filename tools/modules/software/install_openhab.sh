
module_options+=(
	["openhab,author"]="@igorpecovnik"
	["openhab,ref_link"]=""
	["openhab,feature"]="install_openhab"
	["openhab,desc"]="Install openhab from a repo using apt"
	["openhab,example"]="install_openhab"
	["openhab,status"]="Active"
)
#
# Install openHAB from repo using apt
#
openhab() {

	case "$1" in
		install)

			# keys
			wget -qO - https://repos.azul.com/azul-repo.key | gpg --dearmor > "/usr/share/keyrings/azul.gpg"
			wget -qO - https://openhab.jfrog.io/artifactory/api/gpg/key/public | gpg --dearmor > "/usr/share/keyrings/openhab.gpg"
			# repos
			echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" > "/etc/apt/sources.list.d/zulu.list"
			echo "deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main" > "/etc/apt/sources.list.d/openhab.list"

			apt_install_wrapper apt-get update

			# Optional preinstall top 10 tools
			apt_install_wrapper apt-get -y install zulu17-jdk
			apt_install_wrapper apt-get -y install openhab openhab-addons
			systemctl daemon-reload
			systemctl enable openhab.service
			systemctl start openhab.service

			;;

		uninstall)

			apt_install_wrapper apt-get -y remove zulu17-jdk openhab openhab-addons
			systemctl disable openhab.service
			rm -f /usr/share/keyrings/openhab.gpg /usr/share/keyrings/azul.gpg
			rm -f /etc/apt/sources.list.d/zulu.list /etc/apt/sources.list.d/openhab.list

			;;
	esac
}
