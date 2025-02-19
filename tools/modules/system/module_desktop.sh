module_options+=(
	["module_desktop,author"]="@igorpecovnik"
	["module_desktop,feature"]="module_desktop"
	["module_desktop,desc"]="XFCE desktop packages"
	["module_desktop,example"]="install remove disable enable status auto manual login help"
	["module_desktop,status"]="Active"
	["module_desktop,arch"]="x86-64"
)
#
# Module install and configure desktop
#
function module_desktop() {
	local title="test"
	local condition=$(which "$title" 2>/dev/null)

	# get user who executed this script
	if [ $SUDO_USER ]; then local user=$SUDO_USER; else local user=$(whoami); fi

	# read additional parameters from command line
	local parameter
	IFS=' ' read -r -a parameter <<< "${2}"
	for feature in de; do
	for selected in ${parameter[@]}; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
		done
	done

	local de="${de:-xfce}" # DE

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_desktop,example"]}"

	# generate and install packages
	module_desktop_packages "$de" "$DISTROID"

	case "$1" in
		"${commands[0]}")

			# update package list
			pkg_update

			# desktops has different default login managers
			case "$de" in
				gnome)
					echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES}
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES_UNINSTALL}
					pkg_install -o Dpkg::Options::="--force-confold" gdm3
				;;
				kde-neon)
					echo "/usr/sbin/sddm" > /etc/X11/default-display-manager
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES}
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES_UNINSTALL}
					pkg_install -o Dpkg::Options::="--force-confold" kde-standard
				;;
				*)
					echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES}
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES_UNINSTALL}
					pkg_install -o Dpkg::Options::="--force-confold" lightdm
				;;
			esac

			# install desktop
			pkg_install -o Dpkg::Options::="--force-confold" armbian-${DISTROID}-desktop-${de}

			# add user to groups
			for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
				usermod -aG ${additionalgroup} ${user} 2> /dev/null
			done
			# set up profile sync daemon on desktop systems
			which psd > /dev/null 2>&1
			if [[ $? -eq 0 && -z $(grep overlay-helper /etc/sudoers) ]]; then
				echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
				touch /home/${user}/.activate_psd
			fi
			# update skel
			update_skel

			# stop display managers in case we are switching them
			if srv_active gdm3; then
				srv_stop gdm3
			elif srv_active lightdm; then
				srv_stop lightdm
			elif srv_active sddm; then
				srv_stop sddm
			fi

			# start new default display manager
			srv_restart display-manager

			# enable auto login
			${module_options["module_desktop,feature"]} ${commands[5]}
		;;

		"${commands[1]}")
			# disable auto login
			${module_options["module_desktop,feature"]} ${commands[6]}
			# remove destkop
			srv_stop display-manager
			pkg_remove ${PACKAGES}
			pkg_remove armbian-${DISTROID}-desktop-${de}
		;;
		"${commands[2]}")
			# disable
			srv_stop display-manager
			srv_disable display-manager
		;;
		"${commands[3]}")
			# enable
			srv_enable display-manager
			srv_start display-manager
		;;
		"${commands[4]}")
			# status
			case "$de" in
				gnome)
					if srv_active gdm3; then
						return 0
					else
						return 1
					fi
				;;
				kde-neon)
					if srv_active sddm; then
						return 0
					else
						return 1
					fi
				;;
				*)
					if srv_active lightdm; then
						return 0
					else
						return 1
					fi
				;;
			esac
		;;
		"${commands[5]}")
			# autologin methods
			case "$de" in
				gnome)
					# gdm3 autologin
					mkdir -p /etc/gdm3
					cat <<- EOF > /etc/gdm3/custom.conf
					[daemon]
					AutomaticLoginEnable = true
					AutomaticLogin = ${user}
					EOF
				;;
				kde-neon)
					# sddm autologin
					mkdir -p "/etc/sddm.conf.d/"
					cat <<- EOF > "/etc/sddm.conf.d/autologin.conf"
					[Autologin]
					User=${user}
					EOF
				;;
				*)
					# lightdm autologin
					mkdir -p /etc/lightdm/lightdm.conf.d
					cat <<- EOF > "/etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf"
					[Seat:*]
					autologin-user=${user}
					autologin-user-timeout=0
					user-session=xfce
					EOF

				;;
			esac
			# restart after selection
			srv_restart display-manager
		;;
		"${commands[6]}")
			# manual login, disable auto-login
			case "$de" in
				gnome)    rm -f /etc/gdm3/custom.conf ;;
				kde-neon) rm -f /etc/sddm.conf.d/autologin.conf ;;
				*)        rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			# restart after selection
			srv_restart display-manager
		;;
		"${commands[7]}")
			# status
			if [[ -f /etc/gdm3/custom.conf ]] || [[ -f /etc/sddm.conf.d/autologin.conf ]] || [[ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[8]}")
			echo -e "\nUsage: ${module_options["module_desktop,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_desktop,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Generate packages for $title."
			echo -e "\tremove\t-  Generate packages for $title."
			echo -e "\tdisable\t- Generate packages for $title."
			echo -e "\tenable\t-  Generate packages for $title."
			echo -e "\tstatus\t-  Generate packages for $title."

			echo -e "\nAvailable switches:\n"
			echo -e "\tkvmprefix\t- Name prefix (default = kvmtest)"
			echo
		;;
		*)
			${module_options["module_desktop,feature"]} ${commands[8]}
		;;
	esac
}
