module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="8080"
	["module_openhab,arch"]="x86-64 arm64 armhf"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {

	local title="openhab"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	case "$1" in
		"${commands[0]}")
			wget -qO - https://repos.azul.com/azul-repo.key | gpg --dearmor > "/usr/share/keyrings/azul.gpg"
			wget -qO - https://openhab.jfrog.io/artifactory/api/gpg/key/public | gpg --dearmor > "/usr/share/keyrings/openhab.gpg"
			echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" > "/etc/apt/sources.list.d/zulu.list"
			echo "deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main" > "/etc/apt/sources.list.d/openhab.list"
			pkg_update
			pkg_install zulu17-jdk
			pkg_install openhab openhab-addons
			systemctl daemon-reload 2> /dev/null
			srv_enable openhab.service 2> /dev/null
			srv_start openhab.service 2> /dev/null
			;;
		"${commands[1]}")
			pkg_remove zulu17-jdk openhab openhab-addons
			rm -f /usr/share/keyrings/openhab.gpg /usr/share/keyrings/azul.gpg
			rm -f /etc/apt/sources.list.d/zulu.list /etc/apt/sources.list.d/openhab.list
			;;
		"${commands[2]}")
			${module_options["module_openhab,feature"]} ${commands[1]}
		;;
		"${commands[3]}")
			if pkg_installed openhab; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_openhab,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openhab,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_haos,feature"]} ${commands[4]}
		;;
	esac
}
