module_options+=(
	["manage_desktops,author"]="@igorpecovnik"
	["manage_desktops,ref_link"]=""
	["manage_desktops,feature"]="install_de"
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
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install gdm3
				;;
				kde-neon)
					echo "/usr/sbin/sddm" > /etc/X11/default-display-manager
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install sddm
				;;
				*)
					echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install lightdm
				;;
			esac

			# just make sure we have everything in order
			apt_install_wrapper dpkg --configure -a

			# install desktop
			export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
			apt_install_wrapper apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends install armbian-${DISTROID}-desktop-${desktop}

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
			service gdm3 stop
			service lightdm stop
			service sddm stop

			# start new default display manager
			service display-manager restart
		;;
		uninstall)
			# we are uninstalling all variants until build time packages are fixed to prevent installing one over another
			service display-manager stop
			apt_install_wrapper apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends purge armbian-${DISTROID}-desktop-$1 \
			xfce4-session gnome-session slick-greeter lightdm gdm3 sddm cinnamon-session i3-wm
			apt_install_wrapper apt-get -y autoremove
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
			service display-manager restart
		;;
		manual)
			case "$desktop" in
				gnome)    rm -f  /etc/gdm3/custom.conf ;;
				kde-neon) rm -f /etc/sddm.conf.d/autologin.conf ;;
				*)        rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			# restart after selection
			service display-manager restart
		;;
	esac

}

