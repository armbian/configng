

module_options+=(
	["module_webmin,author"]="@Tearran"
	["module_webmin,feature"]="module_webmin"
	["module_webmin,example"]="help install remove start stop enable disable status check"
	["module_webmin,desc"]="Webmin setup and service setting."
	["module_webmin,status"]="review"
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

			if [[ "$(systemctl is-active webmin 2>/dev/null)" == "active" ]]; then
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
			apt update
			apt install -y wget apt-transport-https
			echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list
			wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor | tee /usr/share/keyrings/webmin-archive-keyring.gpg > /dev/null
			apt update
			apt install -y webmin --install-recommends
			echo "Webmin installed successfully."
		;;
		"${commands[2]}")
			## remove webmin
			systemctl disable webmin
			apt purge -y webmin
			apt autoremove --purge -y
			rm /etc/apt/sources.list.d/webmin.list
			rm /usr/share/keyrings/webmin-archive-keyring.gpg
			apt update
			echo "Webmin removed successfully."
		;;

		"${commands[3]}")
			## start webmin
			sudo systemctl start webmin
			echo "Webmin service started."
			;;

		"${commands[4]}")
			## stop webmin
			sudo systemctl stop webmin
			echo "Webmin service stopped."
			;;

		"${commands[5]}")
			## enable webmin
			sudo systemctl enable webmin
			echo "Webmin service enabled."
			;;

		"${commands[6]}")
			## disable webmin
			sudo systemctl disable webmin
			echo "Webmin service disabled."
			;;

		"${commands[7]}")
			## status webmin
			sudo systemctl status webmin
			;;

		"${commands[8]}")
			## check webmin status
			if [[ $(systemctl is-active webmin) == "active" ]]; then
				echo "Webmin service is active."
				return 0
			elif [[ $(systemctl is-enabled webmin) == "disabled" ]]; then
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


#module_webmin "$1"
