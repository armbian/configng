#!/bin/bash


software_module_options+=(
["set_cockpit,author"]="Tearran"
["set_cockpit,ref_link"]=""
["set_cockpit,feature"]="set_cockpit"
["set_cockpit,desc"]="Manage Cockpit service"
["set_cockpit,example"]="install, remove, start, stop, help"
["set_cockpit,status"]="Review"
["set_cockpit,parent_id"]="Manage"
)
# @description Install Webmin or remove webmin
function set_cockpit() {
	local title="cockpit"
    local condition=$(which "$title-bridge" 2>/dev/null) # Check if the software is installed
    local service=$(systemctl is-active "$title" 2>/dev/null)

	case "$1" in
		install)
            see_current_apt update
        	apt -y install cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-networkmanager cockpit-packagekit
			;;

		remove)
			apt -y purge cockpit cockpit-bridge cockpit-ws cockpit-system cockpit-storaged cockpit-dashboard cockpit-networkmanager cockpit-packagekit
			;;

		start)
			systemctl enable --now cockpit.socket
			;;

		stop)
            systemctl stop cockpit cockpit.socket
            systemctl disable cockpit.socket
			;;
		help)
			echo -e "\nUsage: ${module_options["set_webmin,feature"]} <command>"
			echo "Commands:   ${module_options["set_webmin,example"]}"

			if [[ -z "$(which "$title-bridge" 2>/dev/null)" ]]; then
				echo -e "  install\t- Install $title."
			else
				# Show commands based on Webmin's status
				if [[ "$(systemctl is-active cockpit 2>/dev/null)" == "active" ]]; then
					echo -e "  stop\t\t- Stop the $title service."
				else
					echo -e "  start\t\t- Start the $title service."
				fi

				echo -e "  remove\t- Remove $title."
			fi
			;;

		*)
			echo -e "Invalid argument. Try:\n${module_options["set_cockpit,feature"]}  ${module_options["set_cockpit,example"]} "
			;;
	esac
}

