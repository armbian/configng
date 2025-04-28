module_options+=(
	["module_samba,author"]="@Tearran"
	["module_samba,maintainer"]="@Tearran"
	["module_samba,feature"]="module_samba"
	["module_samba,example"]="help install remove start stop enable disable configure default status"
	["module_samba,desc"]="Samba setup and service setting."
	["module_samba,status"]="Active"
	["module_samba,doc_link"]="https://www.samba.org/samba/docs/"
	["module_samba,group"]="Networking"
	["module_samba,port"]="445"
	["module_samba,arch"]="x86-64 arm64 armhf"
)

function module_samba() {
	local title="samba"
	local condition
	condition=$(command -v smbd)

	# Set the interface for dialog tools
	set_interface

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_samba,example"]}"

	case "$1" in
		"${commands[0]}"|"")
		## help/menu options for the module
		echo -e "\nUsage: ${module_options["module_samba,feature"]} <command>"
		# Full list of commands to referance is printed
		echo -e "Commands: ${module_options["module_samba,example"]}"
		echo "Available commands:"
		# Unlike the for mentioned `echo -e "Commands: ${module_options["module_samba,example"]}"``
		# comprehenive referance the Avalible commands are commands considered useable in UI/UX
		# intened use below.
		if [[ -z "$condition" ]]; then
			echo -e "\t${commands[1]}\t- ${commands[1]} $title."
		else
			if srv_active smbd; then
			echo -e "\t${commands[2]}\t- ${commands[2]} $title service."
			echo -e "\t${commands[3]}\t- ${commands[3]} $title from starting on boot."
			else
			echo -e "\t${commands[4]}\t- ${commands[4]} $title to start on boot."
			echo -e "\t${commands[5]}\t- ${commands[5]} $title. service."
			fi
			echo -e "\t${commands[6]}\t- ${commands[6]} $title. $title."
			# Note: Comment to hide advanced option from menu
			# while remaining avalible for advance options --api flag
			echo -e "\t${commands[8]}\t- $title ${commands[8]} conf"
			echo -e "\t${commands[9]}\t- $title ${commands[9]}."
		fi
		echo
		;;
		"${commands[1]}")
		# install samba
		pkg_install samba
		# Check if /etc/samba/smb.conf exists
		if [[ ! -f "/etc/samba/smb.conf" ]]; then
			if [[ -f "/usr/share/samba/smb.conf" ]]; then
				cp "/usr/share/samba/smb.conf" "/etc/samba/smb.conf"
			else
				echo "Warning: Missing configuration file. Use the <configure> option."
			fi
		fi

		echo "Samba installed successfully."
		;;
		"${commands[2]}")
		## added subshell to prevent srv_disable exiting befor removing is complete.
		srv_disable smbd
		pkg_remove samba
		echo "$title remove complete."
		;;
		"${commands[3]}")
		srv_start smbd
		echo "Samba service started."
		;;
		"${commands[4]}")
		srv_stop smbd
		echo "Samba service stopped."
		;;
		"${commands[5]}")
		srv_enable smbd
		echo "Samba service enabled."
		;;
		"${commands[6]}")
		srv_disable smbd
		echo "Samba service disabled."
		;;
		"${commands[7]}"|"${commands[8]}")
		echo "Using package default configuration..."

		# Check if the default Samba configuration file and directory exist
		if [[ -f "/usr/share/samba/smb.conf" && -d "/etc/samba" ]]; then
			echo "Found default configuration and target directory."
			cp /usr/share/samba/smb.conf /etc/samba/smb.conf
			echo "Default configuration copied to /etc/samba/smb.conf."
		else
			# Provide more specific error messages
			if [[ ! -f "/usr/share/samba/smb.conf" ]]; then
			echo "Error: Default configuration file /usr/share/samba/smb.conf not found."
			fi
			if [[ ! -d "/etc/samba" ]]; then
			echo "Error: Target directory /etc/samba does not exist."
			fi
			return 1
		fi
		;;
		"${commands[9]}")
		## check samba status
		if srv_active smbd; then
			echo "active."
			return 0
		elif ! srv_enabled smbd; then
			echo "inactive"
			return 1
		else
			echo "Samba service is in an unknown state."
			return 1
		fi
		;;
		*)
		# Full list of commands to referance is printed
		echo "Invalid command. Try: '${module_options["module_samba,example"]}'"
		;;
	esac
}
