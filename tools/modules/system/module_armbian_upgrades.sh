declare -A module_options
module_options+=(
	["module_armbian_upgrades,author"]="@igorpecovnik"
	["module_armbian_upgrades,feature"]="module_armbian_upgrades"
	["module_armbian_upgrades,desc"]="Install and configure automatic updates"
	["module_armbian_upgrades,example"]="install remove configure status defaults help"
	["module_armbian_upgrades,port"]=""
	["module_armbian_upgrades,status"]="Active"
	["module_armbian_upgrades,arch"]=""
)
#
# Module configure automatic updates
#
function module_armbian_upgrades () {

	local title="package updates"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_upgrades,example"]}"

	case "$1" in

		"${commands[0]}")
			pkg_update
			pkg_install -o Dpkg::Options::="--force-confold" unattended-upgrades
			# set Armbian defaults
			${module_options["module_armbian_upgrades,feature"]} ${commands[4]}
		;;
		"${commands[1]}")
			pkg_remove unattended-upgrades
		;;
		"${commands[2]}")
			# read values from 20auto-upgrades
			if [[ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]]; then
				Unattended_Upgrade=$(
					awk -F'"' '/APT::Periodic::Unattended-Upgrade/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20auto-upgrades
					)
				Update_Package_Lists=$(
					awk -F'"' '/APT::Periodic::Update-Package-Lists/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20auto-upgrades
					)
				Download_Upgradeable_Packages=$(
					awk -F'"' '/APT::Periodic::Download-Upgradeable-Packages/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20auto-upgrades
					)
			fi
			# read values from 50unattended-upgrades
			if [[ -f "/etc/apt/apt.conf.d/50unattended-upgrades" ]]; then
				AutoFixInterruptedDpkg=$(
					awk -F'"' '/Unattended-Upgrade::AutoFixInterruptedDpkg/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50unattended-upgrades
					)
				Remove_New_Unused_Dependencies=$(
					awk -F'"' '/Unattended-Upgrade::Remove-New-Unused-Dependencies/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50unattended-upgrades
					)
				Automatic_Reboot=$(
					awk -F'"' '/Unattended-Upgrade::Automatic-Reboot "/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50unattended-upgrades
					)
				Automatic_Reboot_WithUsers=$(
					awk -F'"' '/Unattended-Upgrade::Automatic-Reboot-WithUsers/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50unattended-upgrades
					)
				Remove_Unused_Dependencies=$(
					awk -F'"' '/Unattended-Upgrade::Remove-Unused-Dependencies/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50unattended-upgrades
					)
			fi
			# toggle options
			if target_sync=$($DIALOG --title "Select an Option" --notags --checklist \
				"\nConfigure unattended-upgrade options:" 16 73 8 \
				"Unattended-Upgrade" "Automatic security and package updates system." ${Unattended_Upgrade:-ON} \
				"Update-Package-Lists" "Automatically updates the list of available packages." ${Update_Package_Lists:-OFF} \
				"Download-Upgradeable-Packages" "Downloads upgradeable packages without installing them." ${Download_Upgradeable_Packages:-OFF} \
				"AutoFixInterruptedDpkg" "Fixes interrupted package installations during upgrades." ${AutoFixInterruptedDpkg:-OFF} \
				"Remove-New-Unused-Dependencies" "Removes dependencies no longer required after upgrades." ${Remove_New_Unused_Dependencies:-OFF} \
				"Automatic-Reboot" "Reboots the system automatically if required after upgrades.    " ${Automatic_Reboot:-OFF} \
				"Automatic-Reboot-WithUsers" "Reboots even if users are logged in." ${Automatic_Reboot_WithUsers:-OFF} \
				"Remove-Unused-Dependencies" "Removes packages that are no longer required after upgrades." ${Remove_Unused_Dependencies:-OFF} 3>&1 1>&2 2>&3); then
				# set all to 0 or false
				sed -i 's/"[0-9]"/"0"/g' /etc/apt/apt.conf.d/20auto-upgrades
				sed -i 's/"true"/"false"/g' /etc/apt/apt.conf.d/50unattended-upgrades
				for choice in $(echo ${target_sync} | tr -d '"'); do
					sed -i "s/\($choice \"\)0\(\";\)/\11\2/" /etc/apt/apt.conf.d/20auto-upgrades
					sed -i "s/\($choice \"\)false\(\";\)/\1true\2/" /etc/apt/apt.conf.d/50unattended-upgrades
				done
			fi
			srv_restart unattended-upgrades
		;;
		"${commands[3]}")
			if pkg_installed unattended-upgrades; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")

			# global options
			cat > "/etc/apt/apt.conf.d/20auto-upgrades" <<- EOT
			APT::Periodic::Update-Package-Lists "1";
			APT::Periodic::Download-Upgradeable-Packages "1";
			APT::Periodic::AutocleanInterval "7";
			APT::Periodic::Unattended-Upgrade "1";
			EOT

			# unattended-upgrades
			cat > "/etc/apt/apt.conf.d/50unattended-upgrades" <<- EOT
			// armbian-config generated
			Unattended-Upgrade::Origins-Pattern {
				"o=${DISTRO},n=${DISTROID},l=${DISTRO}";
				"o=${DISTRO},n=${DISTROID}-updates,l=${DISTRO}";
				"o=${DISTRO},n=${DISTROID}-security,l=${DISTRO}-Security";
				"o=armbian.github.io/configurator,c=main,l=armbian.github.io/configurator";
			};
			// black list
			// Unattended-Upgrade::Package-Blacklist {
			//    "armbian-";
			//    "linux-";
			//};

			// This option allows you to control if on a unclean dpkg exit
			// unattended-upgrades will automatically run
			//   dpkg --force-confold --configure -a
			// The default is true, to ensure updates keep getting installed
			Unattended-Upgrade::AutoFixInterruptedDpkg "true";

			// Do automatic removal of newly unused dependencies after the upgrade
			Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

			// Do automatic removal of unused packages after the upgrade
			// (equivalent to apt-get autoremove)
			Unattended-Upgrade::Remove-Unused-Dependencies "true";

			// Automatically reboot *WITHOUT CONFIRMATION* if
			//  the file /var/run/reboot-required is found after the upgrade
			Unattended-Upgrade::Automatic-Reboot "true";

			// Automatically reboot even if there are users currently logged in
			// when Unattended-Upgrade::Automatic-Reboot is set to true
			Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
			EOT

		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_armbian_upgrades,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_upgrades,example"]}"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install Armbian $title."
			echo -e "\tremove\t\t- Remove Armbian $title."
			echo -e "\tconfigure\t- Configure Armbian $title."
			echo -e "\tstatus\t\t- Status of Armbian $title."
			echo -e "\tdefaults\t- Set to Armbian defalt $title config."
			echo
		;;
		*)
			${module_options["module_armbian_upgrades,feature"]} ${commands[5]}
		;;
	esac
}
