module_options+=(
	["module_webmin,author"]="@Tearran"
	["module_webmin,maintainer"]="@Tearran"
	["module_webmin,feature"]="module_webmin"
	["module_webmin,example"]="help install remove start stop enable disable status check"
	["module_webmin,desc"]="Webmin setup and service setting."
	["module_webmin,status"]="Active"
	["module_webmin,doc_link"]="https://webmin.com/docs/"
	["module_webmin,group"]="Management"
	["module_webmin,port"]="10000"
	["module_webmin,arch"]="x86-64 arm64 armhf"
)

function module_webmin() {
	local title="webmin"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_webmin,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_webmin,feature"]} <command>"
			echo -e "Commands: ${module_options["module_webmin,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else

			if srv_active webmin; then
				echo -e "\tstop\t- Stop the $title service."
				echo -e "\tdisable\t- Disable $title from starting on boot."
			else
				echo -e "\tenable\t- Enable $title to start on boot."
				echo -e "\tstart\t- Start the $title service."
			fi
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."

			fi
			echo
		;;
		"${commands[1]}")
			## install webmin
			pkg_update
			pkg_install wget apt-transport-https
			echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list
			wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor | tee /usr/share/keyrings/webmin-archive-keyring.gpg > /dev/null
			pkg_update
			pkg_install webmin
			echo "Webmin installed successfully."
		;;
		"${commands[2]}")
			## remove webmin
			srv_disable webmin
			pkg_remove webmin
			rm /etc/apt/sources.list.d/webmin.list
			rm /usr/share/keyrings/webmin-archive-keyring.gpg
			pkg_update
			echo "Webmin removed successfully."
		;;

		"${commands[3]}")
			srv_start webmin
			echo "Webmin service started."
			;;

		"${commands[4]}")
			srv_stop webmin
			echo "Webmin service stopped."
			;;

		"${commands[5]}")
			srv_enable webmin
			echo "Webmin service enabled."
			;;

		"${commands[6]}")
			srv_disable webmin
			echo "Webmin service disabled."
			;;

		"${commands[7]}")
			srv_status webmin
			;;

		"${commands[8]}")
			## check webmin status
			if srv_active webmin; then
				echo "Webmin service is active."
				return 0
			elif ! srv_enabled webmin ]]; then
				echo "Webmin service is disabled."
				return 1
			else
				echo "Webmin service is in an unknown state."
				return 1
			fi
			;;
		*)
		echo "Invalid command.try: '${module_options["module_webmin,example"]}'"

		;;
	esac
}
