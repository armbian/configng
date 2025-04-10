module_options+=(
	["module_zerotier,author"]="@jnovos"
	["module_zerotier,maintainer"]="@jnovos"
	["module_zerotier,feature"]="module_zerotier"
	["module_zerotier,ref_link"]="https://github.com/jnovos/configng/"
	["module_zerotier,desc"]="Install Zerotier"
	["module_zerotier,example"]="help install remove start stop enable disable status check"
	["module_zerotier,doc_link"]="https://docs.zerotier.com/wat"
	["module_zerotier,status"]="Active"
	["module_zerotier,group"]="VPN"
	["module_zerotier,arch"]="x86-64 arm64 armhf"
)

function module_zerotier() {
	local title="zerotier-one"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zerotier,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_zerotier,feature"]} <command>"
			echo -e "Commands: ${module_options["module_zerotier,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else
				if srv_active zerotier-one; then
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
			## install zerotier-one
			pkg_update
			curl -fsSL http://download.zerotier.com/contact%40zerotier.com.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/zerotier.gpg > /dev/null
			echo "deb http://download.zerotier.com/debian/$DISTROID $DISTROID main" | sudo tee /etc/apt/sources.list.d/zerotier.list
			pkg_update
			pkg_install zerotier-one
			echo "Zerotier installed successfully."
		;;
		"${commands[2]}")
			## remove zerotier-one
			srv_disable zerotier-one
			pkg_remove zerotier-one
			rm -R /var/lib/zerotier-one
			rm /etc/apt/trusted.gpg.d/zerotier.gpg
			rm /etc/apt/sources.list.d/zerotier.list
			pkg_update
			echo "Zerotier removed successfully."
		;;

		"${commands[3]}")
			srv_start zerotier-one
			echo "Zerotier service started."
		;;

		"${commands[4]}")
			srv_stop zerotier-one
			echo "Zerotier service stopped."
		;;

		"${commands[5]}")
			srv_enable zerotier-one
			echo "Zerotier service enabled."
		;;

		"${commands[6]}")
			srv_disable zerotier-one
			echo "Zerotier service disabled."
		;;

		"${commands[7]}")
			if srv_active zerotier-one ; then
				echo -e "\033[0;32m****** Active *****\033[0m"
			else
				echo -e "\033[0;31m****** Inactive *****\033[0m"
			fi
		;;

		"${commands[8]}")
			## check zerotier-one status
			if srv_active zerotier-one; then
				echo "Zerotier service is active."
				return 0
			elif ! srv_enabled zerotier-one ]]; then
				echo "Zerotier service is disabled."
				return 1
			else
				echo "Zerotier service is in an unknown state."
				return 1
			fi
		;;
		*)
			echo "Invalid command.try: '${module_options["module_zerotier,example"]}'"
		;;
	esac
}
