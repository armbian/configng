#
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
			if srv_active cockpit.socket; then
				echo -e "\tstop\t- Stop the $title service."
			else
				echo -e "\tstart\t- Start the $title service."
			fi
			if srv_enabled cockpit.socket; then
				echo -e "\tdisable\t- Disable $title from starting on boot."
			else
				echo -e "\tenable\t- Enable $title to start on boot."
			fi
			echo -e "\tstatus\t- Show the status of the $title service."
			echo -e "\tremove\t- Remove $title."
		fi
		echo
		;;
		"${commands[1]}")
		pkg_update
		pkg_install cockpit cockpit-ws cockpit-system cockpit-storaged
		echo "Cockpit installed successfully."
		;;
		"${commands[2]}")
		srv_disable cockpit cockpit.socket
		pkg_remove cockpit
		echo "Cockpit removed successfully."
		;;
		"${commands[3]}")
		srv_start cockpit.socket
		echo "Cockpit service started."
		;;
		"${commands[4]}")
		srv_stop cockpit.socket
		echo "Cockpit service stopped."
		;;
		"${commands[5]}")
		srv_enable cockpit.socket
		echo "Cockpit service enabled."
		;;
		"${commands[6]}")
		srv_disable cockpit.socket
		echo "Cockpit service disabled."
		;;
		"${commands[7]}")
		srv_status cockpit.socket
		;;
		"${commands[-1]}")
		## check cockpit status
		if srv_active cockpit.socket; then
			echo "Cockpit service is active."
			return 0
		elif ! srv_enabled cockpit.socket; then
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

