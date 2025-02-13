module_options+=(
	["manage_desktops,author"]="@igorpecovnik"
	["manage_desktops,ref_link"]=""
	["manage_desktops,feature"]="manage_desktops"
	["manage_desktops,desc"]="Install Desktop environment"
	["manage_desktops,example"]="manage_desktops xfce install"
	["manage_desktops,status"]="Active"
)
#
# Install desktop
#
function manage_desktops() {

	local desktop=$1
	local command=$2

	# get user who executed this script
	if [ $SUDO_USER ]; then local user=$SUDO_USER; else local user=$(whoami); fi

	case "$command" in
		install)

			# desktops has different default login managers
			case "$desktop" in
				gnome)
					echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
					#pkg_install gdm3
				;;
				kde-neon)
					echo "/usr/sbin/sddm" > /etc/X11/default-display-manager
					#pkg_install sddm
				;;
				*)
					echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
					#pkg_install lightdm
				;;
			esac

			# just make sure we have everything in order
			pkg_configure -a

			# install desktop
			pkg_install -o Dpkg::Options::="--force-confold" --install-recommends armbian-${DISTROID}-desktop-${desktop}

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

			# enable auto login
			manage_desktops "$desktop" "auto"

			# stop display managers in case we are switching them
			srv_stop gdm3 lightdm sddm

			# start new default display manager
			srv_restart display-manager
		;;
		uninstall)
			# we are uninstalling all variants until build time packages are fixed to prevent installing one over another
			srv_stop display-manager
			pkg_remove -o Dpkg::Options::="--force-confold" armbian-${DISTROID}-desktop-$1 \
				xfce4-session gnome-session slick-greeter lightdm gdm3 sddm cinnamon-session i3-wm
			# disable autologins
			rm -f /etc/gdm3/custom.conf
			rm -f /etc/sddm.conf.d/autologin.conf
			rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		;;
		auto)
			# desktops has different login managers and autologin methods
			case "$desktop" in
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
		manual)
			case "$desktop" in
				gnome)    rm -f  /etc/gdm3/custom.conf ;;
				kde-neon) rm -f /etc/sddm.conf.d/autologin.conf ;;
				*)        rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			# restart after selection
			srv_restart display-manager
		;;
	esac

}

