module_options+=(
	["module_cockpit,author"]="@tearran"
	["module_cockpit,maintainer"]="@igorpecovnik"
	["module_cockpit,feature"]="module_cockpit"
	["module_cockpit,example"]="help install remove start stop enable disable status check"
	["module_cockpit,desc"]="Cockpit setup and service setting."
	["module_cockpit,status"]="Stable"
	["module_cockpit,doc_link"]="https://cockpit-project.org/guide/latest/"
	["module_cockpit,group"]="Management"
	["module_cockpit,port"]="9090"
	["module_cockpit,arch"]="x86-64 arm64 armhf"
)

function module_cockpit() {
	local title="cockpit"
	local condition=$(dpkg -s "cockpit" 2>/dev/null | sed -n "s/Status: //p")
	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_cockpit,example"]}"

	case "$1" in
		"${commands[0]}")
		## help/menu options for the module
		echo -e "\nUsage: ${module_options["module_cockpit,feature"]} <command>"
		echo -e "Commands: ${module_options["module_cockpit,example"]}"
		echo "Available commands:"
		if [[ -z "$condition" ]]; then
			echo -e "  install\t- Install $title."
		else
			if [[ "$(systemctl is-active cockpit.socket 2>/dev/null)" == "active" ]]; then
				echo -e "\tstop\t- Stop the $title service."
			else
			echo -e "\tstart\t- Start the $title service."
			fi
			if [[ $(systemctl is-enabled cockpit.socket) == "enabled" ]]; then
			echo -e "\tdisable\t- Disable $title from starting on boot."
			elif [[ $(systemctl is-enabled cockpit.socket) == "disabled" ]]; then
			echo -e "\tenable\t- Enable $title to start on boot."

			fi
			echo -e "\tstatus\t- Show the status of the $title service."
			echo -e "\tremove\t- Remove $title."
		fi
		echo
		;;
		"${commands[1]}")
		## install cockpit
		pkg_update
		pkg_install cockpit cockpit-ws cockpit-system cockpit-storaged
		echo "Cockpit installed successfully."
		;;
		"${commands[2]}")
		## remove cockpit
		systemctl disable cockpit cockpit.socket
		pkg_remove cockpit
		echo "Cockpit removed successfully."
		;;
		"${commands[3]}")
		## start cockpit

		systemctl start cockpit.socket
		echo "Cockpit service started."
		;;
		"${commands[4]}")
		## stop cockpit

		systemctl stop cockpit.socket
		echo "Cockpit service stopped."
		;;
		"${commands[5]}")
		## enable cockpit
		#systemctl enable cockpit
		systemctl enable cockpit.socket
		echo "Cockpit service enabled."
		;;
		"${commands[6]}")
		## disable cockpit
		#systemctl disable cockpit
		systemctl disable cockpit.socket
		echo "Cockpit service disabled."
		;;
		"${commands[7]}")
		## status cockpit
		#systemctl status cockpit
		systemctl status cockpit.socket
		;;
		"${commands[-1]}")
		## check cockpit status
		if [[ $(systemctl is-active cockpit.socket) == "active" ]]; then
			echo "Cockpit service is active."
			return 0
		elif [[ $(systemctl is-enabled cockpit.socket) == "disabled" ]]; then
			echo "Cockpit service is disabled."
			return 0
		else
			return 1
		fi
		;;
		*)
		echo "Invalid command. Try: '${module_options["module_cockpit,example"]}'"
		;;
	esac
}

