#!/bin/bash

module_options+=(
    ["module_cockpit,author"]="@cockpit-project"
    ["module_cockpit,maintainer"]="@Tearran"
    ["module_cockpit,feature"]="module_cockpit"
    ["module_cockpit,example"]="help install remove start stop enable disable port status"
    ["module_cockpit,desc"]="Cockpit setup and service setting."
    ["module_cockpit,ports"]="9090 9091"
    ["module_cockpit,status"]="review"
)

function module_cockpit() {
	local title="cockpit"
	local service="cockpit.socket"
	local condition=$(apt-cache search "^$title\$" 2>/dev/null | grep "^$title")

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_cockpit,example"]}"
	# Convert the ports string to an array
	local port
	IFS=' ' read -r -a port <<< "${module_options["module_cockpit,ports"]}"

	case "$1" in
		"${commands[0]}")
		echo -e "\nUsage: ${module_options["module_cockpit,feature"]} <command>"
		echo -e "Commands: ${module_options["module_cockpit,example"]}"
		echo "Available commands:"
		if [[ -z "$condition" ]]; then
			echo -e "  install\t- Install $title."
		else
			if [[ "$(systemctl is-active "$service" 2>/dev/null)" == "active" ]]; then
			echo -e "\tstop\t- Stop the $title service."
			echo -e "\tdisable\t- Disable $title from starting on boot."
			else
			echo -e "\tenable\t- Enable $title to start on boot."
			echo -e "\tstart\t- Start the $title service."
			fi
			echo -e "\tstatus\t- Show the status of the $title service."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tport\t- Cycle fallback ports ${module_options["module_cockpit,ports"]}"
			echo
		fi

		;;
		"${commands[1]}")
			## install cockpit
			apt update
			apt install -y cockpit cockpit-ws cockpit-system cockpit-storaged
			echo "Cockpit installed successfully."
		;;
		"${commands[2]}")
			## purge cockpit
			systemctl disable cockpit
			apt purge -y cockpit cockpit-ws cockpit-system cockpit-storaged
			apt autoremove --purge -y
			apt update
			echo "Cockpit purged successfully."
		;;
		"${commands[3]}")
			## start cockpit
			sudo systemctl enable --now cockpit.socket
			echo "Cockpit service started."
		;;
		"${commands[4]}")
			## stop cockpit
			sudo systemctl stop cockpit cockpit.socket
			echo "Cockpit service stopped."
		;;
		"${commands[5]}")
			## enable cockpit
			sudo systemctl enable cockpit.socket
			echo "Cockpit service enabled."
		;;
		"${commands[6]}")
			## disable cockpit
			sudo systemctl disable cockpit.socket
			echo "Cockpit service disabled."
		;;
		"${commands[7]}")
			# fallback port
			sudo systemctl stop cockpit.socket
			# Check if the directory exists, and create it if it doesn't
			if [[ $2 =~ ^[0-9]+$ ]]; then
				echo "argument is '$2'."

				return 0
				# Your code here
			fi
			if [ ! -d /etc/systemd/system/cockpit.socket.d ]; then
				mkdir -p /etc/systemd/system/cockpit.socket.d
			fi

			# Create the listen.conf file if it doesn't exist
			if [ ! -f /etc/systemd/system/cockpit.socket.d/listen.conf ]; then
				echo -e "[Socket]" > /etc/systemd/system/cockpit.socket.d/listen.conf
				echo -e "ListenStream=${port[0]}" > /etc/systemd/system/cockpit.socket.d/listen.conf
			else
				# Check the current ListenStream value
				current_port=$(grep -oP '(?<=ListenStream=).*' /etc/systemd/system/cockpit.socket.d/listen.conf)

				# Iterate over ports and update the ListenStream value if it matches port[0]
				for ((i=0; i<${#port[@]}; i++)); do
					if [ "$current_port" == "${port[$i]}" ]; then
						next_index=$(( (i + 1) % ${#port[@]} ))
						sed -i "s/^ListenStream=.*/ListenStream=${port[$next_index]}/" /etc/systemd/system/cockpit.socket.d/listen.conf
						break
					fi
				done
			fi

		# Reload systemd and restart the cockpit socket
		sudo systemctl daemon-reload
		sudo systemctl start cockpit.socket

		echo "Cockpit socket configuration updated and restarted on port ${port[$next_index]}"
		;;
		"${commands[8]}")
		## check cockpit status
		if [[ $(systemctl is-active cockpit) == "active" ]]; then
			echo "Cockpit service is active."
			return 0
		elif [[ $(systemctl is-enabled cockpit.socket) == "disabled" ]]; then
			echo "Cockpit service is disabled."
			return 1
		else
			echo "Cockpit service is in an unknown state."
			return 1
		fi
		;;
		*)
		echo "Invalid command. Try: '${module_options["module_cockpit,example"]}'"
		;;
	esac
}
