module_options+=(
	["module_samba,author"]="@Tearran"
	["module_samba,maintainer"]="@Tearran"
	["module_samba,feature"]="module_samba"
	["module_samba,example"]="help install remove start stop enable disable configure"
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
		echo -e "Commands: ${module_options["module_samba,example"]}"
		echo "Available commands:"
		if [[ -z "$condition" ]]; then
			echo -e "  install\t- Install $title."
		else
			if srv_active smbd; then
			echo -e "\tstop\t- Stop the $title service."
			echo -e "\tdisable\t- Disable $title from starting on boot."
			else
			echo -e "\tenable\t- Enable $title to start on boot."
			echo -e "\tstart\t- Start the $title service."
			fi
			echo -e "\tremove\t- Remove $title."
			echo -e "\tconfigure\t- Configure $title."
		fi
		echo
		;;
		"${commands[1]}")
		## install samba
		pkg_update
		pkg_install samba

		# Backup the original Samba configuration file
		cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

		echo "Samba installed successfully."
		;;
		"${commands[2]}")
		## remove samba
		srv_disable smbd
		pkg_remove samba
		rm /etc/samba/smb.conf
		echo "Samba removed successfully."
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
		"${commands[7]}")
		## configure samba

		workgroup=$(_prompt_text_input "Enter the workgroup" "WORKGROUP")
		server_string=$(_prompt_text_input "Enter the server string" "Samba Server %v")
		netbios_name=$(_prompt_text_input "Enter the netbios name" "armbian")
		share_path=$(_prompt_text_input "Enter the path for the Samba share" "/srv/samba/anonymous")

		# Create a new Samba configuration file
		cat <<EOL > /etc/samba/smb.conf
[global]
	workgroup = $workgroup
	server string = $server_string
	netbios name = $netbios_name
	security = user
	map to guest = bad user
	dns proxy = no

[Anonymous]
	path = $share_path
	browseable = yes
	writable = yes
	guest ok = yes
	read only = no
EOL

		# Create a directory for the Samba share
		mkdir -p "$share_path"
		chown -R nobody:nogroup "$share_path"
		chmod -R 0775 "$share_path"

		# Restart Samba services
		systemctl restart smbd
		systemctl restart nmbd

		echo "Samba configured successfully."
		;;
		"${commands[8]}")
		## check samba status
		if srv_active smbd; then
			echo "Samba service is active."
			return 0
		elif ! srv_enabled smbd; then
			echo "Samba service is disabled."
			return 1
		else
			echo "Samba service is in an unknown state."
			return 1
		fi
		;;
		*)
		echo "Invalid command. Try: '${module_options["module_samba,example"]}'"
		;;
	esac
}
