module_options+=(
	["module_headers,author"]="@armbian"
	["module_headers,feature"]="module_headers"
	["module_headers,desc"]="Install headers container"
	["module_headers,example"]="install remove status help"
	["module_headers,port"]=""
	["module_headers,status"]="Active"
	["module_headers,arch"]=""
)
#
# Mmodule_headers
#
function module_headers () {
	local title="headers"
	local condition=$(which "$title" 2>/dev/null)

	pkg_update

	if [[ -f /etc/armbian-release ]]; then
		source /etc/armbian-release
		# branch information is stored in armbian-release at boot time. When we change kernel branches, we need to re-read this and add it
		update_kernel_env
		local install_pkg="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		local install_pkg="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_headers,example"]}"

	case "$1" in
		"${commands[0]}")
			pkg_install ${install_pkg} build-essential git || exit 1
		;;
		"${commands[1]}")
			pkg_remove ${install_pkg} build-essential || exit 1
			rm -rf /usr/src/linux-headers*
		;;
		"${commands[2]}")
			pkg_installed ${install_pkg}
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_headers,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_headers,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_headers,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_desktop_packages,author"]="@igorpecovnik"
	["module_desktop_packages,feature"]="module_desktop"
	["module_desktop_packages,desc"]="Generate desktop packages list"
	["module_desktop_packages,de"]="budgie cinnamon deepin enlightenment gnome i3-wm kde-plasma mate xfce xmonad"
	["module_desktop_packages,release"]="bookworm noble plucky"
	["module_desktop_packages,status"]="Active"
	["module_desktop_packages,arch"]="x86-64"
)
#
# Module desktop packages
#
function module_desktop_packages() {
	local title="test"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local de
	IFS=' ' read -r -a de <<< "${module_options["module_desktop_packages,de"]}"

	# Common desktop packages
	local packages+=(
			"anacron"
			"cups"
			"eject"
			"printer-driver-all"
			"profile-sync-daemon"
			"system-config-printer"
			"terminator"
			"upower"
			"xarchiver"
		)

	case "$1" in
		"${de[0]}")
			# budgie
		;;
		"${de[1]}")
			# cinnamon
		;;
		"${de[2]}")
			# deepin
		;;
		"${de[3]}")
			# enlightenment
		;;
		"${de[4]}")
			# gnome
			local packages+=(
				"apt-xapian-index"
				"at-spi2-core"
				"colord"
				"dbus-x11"
				"dconf-cli"
				"dmz-cursor-theme"
				"foomatic-db-compressed-ppds"
				"fonts-noto-cjk"
				"fonts-ubuntu"
				"fonts-ubuntu-console"
				"gdebi"
				"gdm3"
				"gnome-control-center"
				"gnome-desktop3-data"
				"gnome-disk-utility"
				"gnome-disk-utility"
				"gnome-keyring"
				"gnome-menus"
				"gnome-packagekit"
				"gnome-screenshot"
				"gnome-session"
				"gnome-shell"
				"gnome-shell-extension-appindicator"
				"gnome-system-monitor"
				"gnome-terminal"
				"gvfs-backends"
				"inputattach"
				"libnotify-bin"
				"lm-sensors"
				"nautilus"
				"nautilus-extension-gnome-terminal"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"software-properties-gtk"
				"synaptic"
				"x11-apps"
				"x11-session-utils"
				"x11-utils"
				"x11-xserver-utils"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
				"xfonts-base"
				"xserver-xorg"
				"xwayland"
				"zenity"
			)
		;;
		"${de[5]}")
			# i3-wm
		;;
		"${de[6]}")
			# kde-plasma
		;;
		"${de[7]}")
			# mate
		;;
		"${de[8]}")
			# xfce
			local packages+=(
				"anacron"
				"apt-xapian-index"
				"blueman"
				"bluez"
				"bluez-cups"
				"bluez-tools"
				"brltty"
				"brltty-x11"
				"cifs-utils"
				"colord"
				"cups"
				"cups-bsd"
				"cups-client"
				"cups-filters"
				"dbus-x11"
				"dmz-cursor-theme"
				"evince"
				"evince-common"
				"fontconfig"
				"fontconfig-config"
				"fonts-noto-cjk"
				"fonts-ubuntu"
				"fonts-ubuntu-console"
				"foomatic-db-compressed-ppds"
				"gdebi"
				"ghostscript-x"
				"gnome-disk-utility"
				"gnome-font-viewer"
				"gnome-screenshot"
				"gnome-system-monitor"
				"gstreamer1.0-packagekit"
				"gstreamer1.0-plugins-base-apps"
				"gstreamer1.0-pulseaudio"
				"gtk2-engines"
				"gtk2-engines-murrine"
				"gtk2-engines-pixbuf"
				"gvfs-backends"
				"hplip"
				"ayatana-indicator-printers"
				"inputattach"
				"inxi"
				"keyutils"
				"laptop-detect"
				"libatk-adaptor"
				"libfontconfig1"
				"libfontembed1"
				"libfontenc1"
				"libgail-common"
				"libgl1-mesa-dri"
				"libgsettings-qt1"
				"libgtk2.0-bin"
				"libnotify-bin"
				"libpam-gnome-keyring"
				"libproxy1-plugin-gsettings"
				"libwmf0.2-7-gtk"
				"libxcursor1"
				"lightdm"
				"lm-sensors"
				"lxtask"
				"mesa-utils"
				"mousepad"
				"mousetweaks"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"openprinting-ppds"
				"orca"
				"p7zip-full"
				"pamix"
				"pasystray"
				"pavucontrol"
				"pavumeter"
				"policykit-1"
				"printer-driver-all"
				"profile-sync-daemon"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"qalculate-gtk"
				"redshift"
				"slick-greeter"
				"smbclient"
				"software-properties-gtk"
				"spice-vdagent"
				"synaptic"
				"system-config-printer"
				"system-config-printer-common"
				"terminator"
				"thunar-volman"
				"update-inetd"
				"update-manager"
				"update-manager-core"
				"viewnior"
				"x11-apps"
				"x11-utils"
				"x11-xserver-utils"
				"xapps-common"
				"xarchiver"
				"xauth"
				"xbacklight"
				"xcursor-themes"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
				"xfce4"
				"xfce4-notifyd"
				"xfce4-power-manager"
				"xfce4-screenshooter"
				"xfce4-terminal"
				"xfonts-100dpi"
				"xfonts-75dpi"
				"xfonts-base"
				"xfonts-encodings"
				"xfonts-scalable"
				"xfonts-utils"
				"xorg-docs-core"
				"xscreensaver"
				"xsensors"
				"xserver-xorg"
				"xserver-xorg-video-fbdev"
				"xwallpaper"
			)
			local architecture+=(
				"arm64"
				"amd64"
				"armhf"
				"riscv64"
			)
			local supported=(
				"supported"
			)
			local packages_uninstall=()
			local packages_remove=()
		;;
		"${de[9]}")
			# xmonad
		;;
	esac

	local release
	IFS=' ' read -r -a release <<< "${module_options["module_desktop_packages,release"]}"
	case "$2" in
		"${release[0]}")
			# bookworm
			local packages+=(
				"accountsservice"
				"gnome-calculator"
				"libu2f-udev"
			)
			local packages_remove+=(
				"libfontembed1"
				"update-manager"
				"update-manager-core"
			)
		;;
		"${release[1]}")
			# noble
			local packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
			)
			local packages_remove+=(
				"qalculate-gtk"
				"hplip"
				"indicator-printers"
				"libfontembed1"
				"policykit-1"
				"printer-driver-all"
				"qalculate-gtk"
			)
			local packages_uninstall+=(
				"ubuntu-session"
			)
		;;
		"${release[2]}")
			# plucky
			local packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
			)
			local packages_remove+=(
				"qalculate-gtk"
				"hplip"
				"indicator-printers"
				"libfontembed1"
				"policykit-1"
				"printer-driver-all"
				"qalculate-gtk"
				"libfontembed1"
				"pavumeter"
			)
			local packages_uninstall+=(
				"ubuntu-session"
			)
		;;
	esac

	# Remove packages_remove from packages
	filtered_packages=()
	for p in "${packages[@]}"; do
		# Check if $p is in packages_remove
		if [[ ! " ${packages_remove[@]} " =~ " $p " ]]; then
			filtered_packages+=("$p")
		fi
	done
	packages=("${filtered_packages[@]}")

	PACKAGES=${packages[@]}
	PACKAGES_UNINSTALL=${packages_uninstall[@]}
	SUPPORTED=${supported}
	ARCHITECTURE=${architecture}

}


module_options+=(
	["update_skel,author"]="@igorpecovnik"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="update_skel"
	["update_skel,desc"]="Update the /etc/skel files in users directories"
	["update_skel,example"]="update_skel"
	["update_skel,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function update_skel() {

	getent passwd |
		while IFS=: read -r username x uid gid gecos home shell; do
			if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ]; then
				continue
			fi
			tar -C /etc/skel/ -cf - . | su - "$username" -c "tar --skip-old-files -xf -"
		done

}



module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
["store_netplan_config,ref_link"]=""
["store_netplan_config,feature"]="Storing netplan config to tmp"
["store_netplan_config,desc"]=""
["store_netplan_config,example"]=""
["store_netplan_config,status"]="Active"
)
#
# @description Restoring Netplan configuration from temp folder
#
function restore_netplan_config() {

	echo "Restoring NetPlan configs" | show_infobox
	# just in case
	if [[ -n ${restore_netplan_config_folder} ]]; then
		rm -f /etc/netplan/*
		rsync -ar ${restore_netplan_config_folder}/. /etc/netplan
	fi

}


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

module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install zfs filesystem support"
	["module_zfs,example"]="install remove status kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
)
#
# Module OpenZFS
#
function module_zfs () {
	local title="zfs"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	case "$1" in
		"${commands[0]}")
			# headers are needed, lets install then if they are not there already
			if ! module_armbian_firmware headers status; then
				module_armbian_firmware headers install
			fi
			pkg_install zfsutils-linux zfs-dkms
		;;
		"${commands[1]}")
			module_armbian_firmware headers remove
			pkg_remove zfsutils-linux zfs-dkms
		;;
		"${commands[2]}")
			pkg_installed zfsutils-linux
		;;
		"${commands[3]}")
			echo "${ZFS_KERNEL_MAX}"
		;;
		"${commands[4]}")
			echo "v${ZFS_DKMS_VERSION}"
		;;
		"${commands[5]}")
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null| head -1 | cut -d"-" -f2
			fi
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_zfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\kernel_max\t- Determine maximum version of kernel to support $title."
			echo -e "\zfs_version\t- Gets $title version from Git."
			echo -e "\zfs_installed_version\t- Read $title module info."
			echo
		;;
		*)
			${module_options["module_zfs,feature"]} ${commands[6]}
		;;
	esac
}

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

module_options+=(
	["module_openssh-server,author"]="@armbian"
	["module_openssh-server,maintainer"]="@igorpecovnik"
	["module_openssh-server,feature"]="module_openssh-server"
	["module_openssh-server,example"]="install remove purge status help"
	["module_openssh-server,desc"]="Install openssh-server container"
	["module_openssh-server,status"]="Active"
	["module_openssh-server,doc_link"]="https://docs.linuxserver.io/images/docker-openssh-server/#server-mode"
	["module_openssh-server,group"]="Network"
	["module_openssh-server,port"]="2222"
	["module_openssh-server,arch"]="x86-64 arm64"
)
#
# Module openssh-server
#
function module_openssh-server () {
	local title="openssh-server"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/openssh-server?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/openssh-server?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openssh-server,example"]}"

	OPENSSHSERVER_BASE="${SOFTWARE_FOLDER}/openssh-server"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "${OPENSSHSERVER_BASE}" ]] || mkdir -p "${OPENSSHSERVER_BASE}" || { echo "Couldn't create storage directory: ${OPENSSHSERVER_BASE}"; exit 1; }
			USER_NAME=$($DIALOG --title "Enter username" --inputbox "\nHit enter for defaults" 9 50 "upload" 3>&1 1>&2 2>&3)
			PUBLIC_KEY=$($DIALOG --title "Enter public key" --inputbox "" 9 50 "" 3>&1 1>&2 2>&3)
			MOUNT_POINT=$($DIALOG --title "Enter shared folder path" --inputbox "" 9 50 "${SOFTWARE_FOLDER}/swag/config/www" 3>&1 1>&2 2>&3)
			docker run -d \
			--name=openssh-server \
			--net=lsio \
			--hostname=openssh-server `#optional` \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e PUBLIC_KEY="${PUBLIC_KEY}"  \
			-e SUDO_ACCESS=false \
			-e PASSWORD_ACCESS=false  \
			-e USER_PASSWORD=password \
			-e USER_NAME="${USER_NAME}" \
			-p 2222:2222 \
			-v "${OPENSSHSERVER_BASE}/config:/config" \
			-v "${MOUNT_POINT}:/config/storage" \
			--restart unless-stopped \
			lscr.io/linuxserver/openssh-server:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' openssh-server >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs openssh-server\`)"
					exit 1
				fi
			done
			# read container version
			container_version=$(docker exec openssh-server /bin/bash -c "grep ^PRETTY_NAME= /etc/os-release | sed -E 's/PRETTY_NAME=\"([^\"]*) v[0-9].*/\\1/'")
			# install rsync
			docker exec openssh-server /bin/bash -c "
			apk update; apk add rsync;
			echo '' > /etc/motd;
			echo \"Welcome to your sandboxed Armbian SSH environment running $container_version\" >> /etc/motd;
			echo '' >> /etc/motd;
			"
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_openssh-server,feature"]} ${commands[1]}
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
			[[ -n "${OPENSSHSERVER_BASE}" && "${OPENSSHSERVER_BASE}" != "/" ]] && rm -rf "${OPENSSHSERVER_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_openssh-server,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openssh-server,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_openssh-server,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["manage_zsh,author"]="@igorpecovnik"
	["manage_zsh,ref_link"]=""
	["manage_zsh,feature"]="manage_zsh"
	["manage_zsh,desc"]="Set system shell to BASH"
	["manage_zsh,example"]="manage_zsh enable|disable"
	["manage_zsh,status"]="Active"
)
#
# @description Set system shell to ZSH
#
function manage_zsh() {

	local bash_location=$(grep /bash$ /etc/shells | tail -1)
	local zsh_location=$(grep /zsh$ /etc/shells | tail -1)

	if [[ "$1" == "enable" ]]; then

		sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
		sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

		pkg_update

		# install
		pkg_install armbian-zsh zsh-common zsh tmux

		update_skel

		# change shell for root
		usermod --shell "/bin/zsh" root
		# change shell for others
		sed -i 's/bash$/zsh/g' /etc/passwd

	else

		sed -i "s|^SHELL=.*|SHELL=/bin/bash|" /etc/default/useradd
		sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/bash|" /etc/adduser.conf

		# remove
		pkg_remove armbian-zsh zsh-common zsh tmux

		# change shell for root
		usermod --shell "/bin/bash" root
		# change shell for others
		sed -i 's/zsh$/bash/g' /etc/passwd

	fi

}

module_options+=(
	["module_armbian_firmware,author"]="@igorpecovnik"
	["module_armbian_firmware,feature"]="module_armbian_firmware"
	["module_armbian_firmware,example"]="select install show hold unhold repository headers help"
	["module_armbian_firmware,desc"]="Module for Armbian firmware manipulating."
	["module_armbian_firmware,status"]="review"
)

function module_armbian_firmware() {
	local title="Armbian FW"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_firmware,example"]}"

	# BRANCH, KERNELPKG_VERSION, KERNELPKG_LINUXFAMILY may require being updated after kernel switch
	update_kernel_env

	case "$1" in

		# choose kernel from the list
		"${commands[0]}")

			# We are updating beta packages repository quite often. In order to make sure, update won't break, always update package list

			pkg_update

			# make sure to proceed if this variable is not defined. This can surface on some old builds
			[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,vendor,current,edge"

			# show warning when packages are put on hold and ask to release it
			if ${module_options["module_armbian_firmware,feature"]} ${commands[3]} "status"; then
				if $DIALOG --title "Warning!" --yesno "Firmware upgrade is disabled. Release hold and proceed?" 7 60; then
					${module_options["module_armbian_firmware,feature"]} ${commands[4]}
				else
					exit 0
				fi
			fi

			# by default we define which kernels are suitable
			if ! $DIALOG --title "Advanced options" --yesno --defaultno "Show only mainstream kernels on the list?" 7 60; then
				KERNEL_TEST_TARGET="legacy,vendor,current,edge"
			fi

			# read what is possible to install
			local kernel_test_target=$(\
				for kernel_test_target in ${KERNEL_TEST_TARGET//,/ }
				do
					# Exception for Rockchip
					if [[ "${BOARDFAMILY}" == "rockchip-rk3588" ]]; then
						if [[ "${kernel_test_target}" == "vendor" ]]; then
							echo "linux-image-${kernel_test_target}-rk35xx"
						elif [[ "${kernel_test_target}" =~ ^(current|edge)$ ]]; then
							echo "linux-image-${kernel_test_target}-rockchip64"
						fi
					else
						echo "linux-image-${kernel_test_target}-${LINUXFAMILY}"
					fi
				done
				)
			local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}' | head -1)

			# workaround in case current is not installed
			[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"

			# main search command
			local search_exec="apt-cache show ${kernel_test_target} \
			| grep -E \"Package:|Version:|version:|family\" \
			| grep -v \"Config-Version\" \
			| sed -n -e 's/^.*: //p' \
			| sed 's/\.$//g' \
			| xargs -n3 -d'\n' \
			| sed \"s/ /=/\" $grep_current_kernel"

			# construct a list of kernels with their Armbian release versions and kernel version
			IFS=$'\n'
			local LIST=()
			for line in $(eval ${search_exec}); do
				LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
			done
			unset IFS

			# generate selection menu
			local list_length=$((${#LIST[@]} / 2))
			if [ "$list_length" -eq 0 ]; then
				$DIALOG --backtitle "$BACKTITLE" --title " Warning " --msgbox "No other kernels available!" 7 31
			else
				if target_version=$(\
						$DIALOG \
						--separate-output \
						--title "Select kernel" \
						--menu "" \
						$((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" \
						3>&1 1>&2 2>&3)
				then
					# extract branch
					local branch=$(echo "${target_version}" | cut -d'-' -f3)
					local linuxfamily=$(echo "${target_version}" | cut -d'-' -f4 | cut -d'=' -f1)
					# call install function
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "${target_version/*=/}" "" "" "${linuxfamily}"
				fi
			fi

		;;

		# purge old and install new packages from desired branch and version
		"${commands[1]}")

			# We are updating beta packages repository quite often. In order to make sure, update won't break, always update package list
			pkg_update

			cat > "/etc/apt/preferences.d/armbian-upgrade-policy" <<- EOT
			Package: armbian-bsp* armbian-firmware* linux-*
			Pin: release a=${DISTROID}
			Pin-Priority: 1001
			EOT
			trap '{ rm -f -- "/etc/apt/preferences.d/armbian-upgrade-policy"; }' EXIT

			# input parameters
			local branch=$2
			local version="$( echo $3 | tr -d '\011\012\013\014\015\040')" # remove tabs and spaces from version
			local hide=$4
			local headers=$5
			local linuxfamily=$6

			# generate list
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${branch}" "${version}" "hide" "" "$headers" "$linuxfamily"

			# purge and install
			for pkg in ${packages[@]}; do
				# if test install is succesfull, proceed
				if [[ -z $(LC_ALL=C apt-get install --simulate --download-only --allow-downgrades --reinstall "${pkg}" 2>/dev/null | grep "not possible") ]]; then
					purge_pkg=$(echo $pkg | sed -e 's/linux-image.*/linux-image*/;s/linux-dtb.*/linux-dtb*/;s/linux-headers.*/linux-headers*/;s/armbian-firmware-*/armbian-firmware*/')
					pkg_remove "${purge_pkg}"
					pkg_install --allow-downgrades "${pkg}"
				else
					echo "Error: Package ${pkg} install not possible due to network / repository problem. Try again later and report to Armbian forums"
					exit 0
				fi
			done
			# at the end, also switch bsp
			# if branch is not defined, we use the one that is currently installed
			#[[ -z $branch ]] && local branch=$BRANCH
			#[[ -z $BRANCH ]] && local branch="current"
			#local bsp=$(dpkg -l | grep -E "armbian-bsp-cli" | awk '{print $2}' | sed "s/legacy\|vendor\|current\|edge/${branch}/g")
			#if apt-get install --simulate --download-only --allow-downgrades --reinstall "${bsp}" > /dev/null 2>&1; then
			#	pkg_remove "armbian-bsp-cli*"
			#	pkg_install --allow-downgrades "${bsp}"
			#fi
			# remove upgrade policy
			rm -f /etc/apt/preferences.d/armbian-upgrade-policy
			if test -t 0 && [[ "${headers}" != "true" ]]; then
				if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
					"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
					reboot
				fi
			fi
		;;

		# generate a list of possible packages to install
		"${commands[2]}")

			# input parameters
			local branch="${2:-$BRANCH}"
			local version="$( echo $3 | tr -d '\011\012\013\014\015\040')" # remove tabs and spaces from version
			local hide="$4"
			local repository="$5"
			local headers="$6"
			local linuxfamily="${7:-$KERNELPKG_LINUXFAMILY}"

			# if repository is not defined, we use stable one
			[[ -z $repository ]] && local repository="apt.armbian.com"

			# select Armbian packages we want to searching for
			armbian_packages=(
				"linux-image-${branch}-${linuxfamily}"
				"linux-dtb-${branch}-${linuxfamily}"
			)

			# install full firmware if it was installed previously
			#if dpkg -l | grep -E "armbian-firmware-full" >/dev/null; then
			#	armbian_packages+=("armbian-firmware-full")
			#	else
			#	armbian_packages+=("armbian-firmware")
			#fi

			# install headers only if they were previously installed
			if dpkg -l | grep -E "linux-headers" >/dev/null; then
				armbian_packages+=("linux-headers-${branch}-${linuxfamily}")
			fi

			# only install headers if parameter headers == true
			if  [[ "${headers}" == true ]]; then
				armbian_packages=("linux-headers-${branch}-${linuxfamily}")
			fi

			# when we select a specific version of Armbian, we need to make sure that version exists
			# for each package we want to install. In case desired version does not exists, it installs
			# package without specifying version. This prevent breaking install in case some
			# package version was removed from repository. Just in case.
			packages=""
			for pkg in ${armbian_packages[@]}; do

				# look into cache
				local cache_show=$(apt-cache show "$pkg" 2> /dev/null | grep -E "Package:|^Version:|family" \
					| sed -n -e 's/^.*: //p' \
					| sed 's/\.$//g' \
					| xargs -n2 -d'\n' \
					| grep "${pkg}")

				# use package + version if found else use package if found
				if [[ -n "${version}" && -n "${cache_show}" ]]; then
					if [[ -n $(echo "$cache_show" | grep "$version""$" ) ]]; then
						packages+="${pkg}=${version} ";
					fi
				elif [[ -n "${cache_show}" ]]; then
					packages+="${pkg} ";
				fi
			done

			# if this is called with a parameter hide, we only prepare this list but don't show its content
			[[ "$4" != "hide" ]] && echo ${packages[@]}

		;;

		# holds Armbian firmware packages or provides status
		"${commands[3]}")

			# input parameter
			local status=$2

			# generate a list of packages
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# we are only interested in which Armbian packages are put on hold
			if [[ "$status" == "status" ]]; then
				local get_hold=($(apt-mark showhold))
				local test_hold=($(for all_packages in ${packages[@]}; do
					for hold_packages in ${get_hold[@]}; do
					echo $all_packages | grep $hold_packages
					done
				done))
			[[ -z ${test_hold[@]} ]] && return 1 || return 0
			else
				# put Armbian packages on hold
				apt-mark hold ${packages[@]} >/dev/null 2>&1
			fi

		;;

		# unhold Armbian firmware packages
		"${commands[4]}")

			# generate a list of packages
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# release Armbian packages from hold
			apt-mark unhold ${packages[@]} >/dev/null 2>&1

		;;

		# switches repository to rolling / stable and performs update or provides status
		"${commands[5]}")

			# input parameters
			local repository=$2
			local status=$3

			local branch=${BRANCH}
			local linuxfamily=${LINUXFAMILY:-$KERNELPKG_LINUXFAMILY}

			local sources_files=()
			for file in "/etc/apt/sources.list.d/armbian.list" "/etc/apt/sources.list.d/armbian.sources"; do
				[[ -e "$file" ]] && sources_files+=("$file")
			done

			if grep -q 'apt.armbian.com' "${sources_files[@]}"; then
				if [[ "$repository" == "rolling" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "rolling" ]]; then
					sed -i 's|[a-zA-Z0-9.-]*\.armbian\.com|beta.armbian.com|g' "${sources_files[@]}"
					pkg_update
				fi
			else
				if [[ "$repository" == "stable" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "stable" ]]; then
					sed -i 's|[a-zA-Z0-9.-]*\.armbian\.com|apt.armbian.com|g' "${sources_files[@]}"
					pkg_update
				fi
			fi

			# if we are not only checking status, it reinstall firmware automatically
			[[ "$status" != "status" ]] && ${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "" "" "" "${linuxfamily}"
		;;

		# installs kernel headers
		"${commands[6]}")

			# input parameters
			local command=$2
			local version=${3:-$KERNELPKG_VERSION}

			if [[ "${command}" == "install" ]]; then
				if [[ -f /etc/armbian-image-release ]]; then
					# for armbian OS
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${BRANCH}" "${version}" "" "true" "${KERNELPKG_LINUXFAMILY}"
				else
					# for non armbian builds
					pkg_install "linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
				fi
			elif [[ "${command}" == "remove" ]]; then
				# remove headers packages
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${BRANCH}" "${version}" "hide" "" "true" "${KERNELPKG_LINUXFAMILY}"
				if [ "${#packages[@]}" -gt 0 ]; then
					if dpkg -l | grep -qw ${packages[@]/=*/}; then
						pkg_remove ${packages[@]/=*/}
					fi
				fi
			else
				# return 0 if packages are installed else 1
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${BRANCH}" "${version}" "hide" "" "true" "${KERNELPKG_LINUXFAMILY}"
				if pkg_installed ${packages[@]/=*/}; then
					return 0
				else
					return 1
				fi
			fi
		;;

		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_armbian_firmware,feature"]} <command> <switches>"
			echo -e "Commands:  ${module_options["module_armbian_firmware,example"]}"
			echo "Available commands:"
			echo -e "\tselect    \t- TUI to select $title.              \t switches: [ stable | rolling ]"
			echo -e "\tinstall   \t- Install $title.                    \t switches: [ \$branch | \$version ]"
			echo -e "\tshow      \t- Show $title packages.              \t switches: [ \$branch | \$version | hide ]"
			echo -e "\thold      \t- Mark $title packages as held back. \t switches: [status] returns true or false"
			echo -e "\tunhold    \t- Unset $title packages set as held back."
			echo -e "\trepository\t- Selects repository and performs update. \t switches: [ stable | rolling ]"
			echo -e "\theaders   \t- Kernel headers management.         \t\t switches: [ install | remove | status ]"
			echo
		;;
		*)
			${module_options["module_armbian_firmware,feature"]} ${commands[7]}
		;;
	esac
}

module_options+=(
	["module_armbian_rsyncd,author"]="@igorpecovnik"
	["module_armbian_rsyncd,maintainer"]="@igorpecovnik"
	["module_armbian_rsyncd,feature"]="module_armbian_rsyncd"
	["module_armbian_rsyncd,example"]="install remove status help"
	["module_armbian_rsyncd,desc"]="Install and configure Armbian rsyncd."
	["module_armbian_rsyncd,doc_link"]=""
	["module_armbian_rsyncd,group"]="Armbian"
	["module_armbian_rsyncd,status"]="Active"
	["module_armbian_rsyncd,port"]="873"
	["module_armbian_rsyncd,arch"]=""
)

function module_armbian_rsyncd() {
	local title="rsyncd"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_rsyncd,example"]}"

	case "$1" in
		"${commands[0]}")
			if export_path=$(dialog --title \
				"Where is Armbian file storage located?" \
				--inputbox "" 6 60 "/armbian/openssh-server/storage/" 3>&1 1>&2 2>&3); then

				# lets make temporally file
				rsyncd_config=$(mktemp)
				if target_sync=$($DIALOG --title "Select an Option" --checklist \
					"Choose your favorite programming language" 15 60 6 \
					"apt" "Armbian stable packages" ON \
					"dl" "Stable images" ON \
					"beta" "Armbian unstable packages" OFF \
					"archive" "Old images" OFF \
					"oldarhive" "Very old Archive" OFF \
					"cache" "Nighly and community images cache" OFF 3>&1 1>&2 2>&3); then

					for choice in $(echo ${target_sync} | tr -d '"'); do
						cat <<- EOF >> $rsyncd_config
						[$choice]
						path = $export_path/$choice
						max connections = 8
						uid = nobody
						gid = users
						list = yes
						read only = yes
						write only = no
						use chroot = yes
						lock file = /run/lock/rsyncd-$choice
						EOF
					done
					mv $rsyncd_config /etc/rsyncd.conf
					pkg_update
					pkg_install rsync >/dev/null 2>&1
					srv_enable rsync >/dev/null 2>&1
					srv_start rsync >/dev/null 2>&1
				fi
			fi
		;;
		"${commands[1]}")
			srv_stop rsync >/dev/null 2>&1
			rm -f /etc/rsyncd.conf
		;;
		"${commands[2]}")
			if srv_active rsyncd; then
				return 0
			elif ! srv_enabled rsync; then
				return 1
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_armbian_rsyncd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_rsyncd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status of $title."
			echo
		;;
		*)
			${module_options["module_armbian_rsyncd,feature"]} ${commands[3]}
		;;
	esac
	}


module_options+=(
["manage_dtoverlays,author"]="@viraniac"
["manage_dtoverlays,maintainer"]="@igorpecovnik,@The-going"
["manage_dtoverlays,ref_link"]=""
["manage_dtoverlays,feature"]="manage_dtoverlays"
["manage_dtoverlays,desc"]="Enable/disable device tree overlays"
["manage_dtoverlays,example"]=""
["manage_dtoverlays,status"]="Active"
["manage_dtoverlays,group"]="Kernel"
["manage_dtoverlays,port"]=""
["manage_dtoverlays,arch"]="aarch64 armhf"
)
#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		# Raspberry Pi has different name
		overlayconf="/boot/firmware/config.txt"
		local overlaydir=$(find /boot/dtb/ -maxdepth 1 -type d \( -name "overlay" -o -name "overlays" \) | head -n1)
		local overlay_prefix=$(awk -F= '/^overlay_prefix=/ {print $2}' "$overlayconf")
	else
		local overlaydir="$(find /boot/dtb/ -name overlay -and -type d)"
		local overlay_prefix=$(awk -F"=" '/overlay_prefix/ {print $2}' $overlayconf)
	fi
	if [[ -z $(find "$overlaydir" -name "*$overlay_prefix*" 2>/dev/null) && "$LINUXFAMILY" != "bcm2711" ]]; then
		echo "Invalid overlay_prefix $overlay_prefix"; exit 1
	fi

	[[ ! -f "${overlayconf}" || ! -d "${overlaydir}" ]] && echo -e "Incompatible OS configuration\nArmbian device tree configuration files not found" | show_message && return 1

	# check /boot/boot.scr scenario overlay(s)/${overlay_prefix}-${overlay_name}.dtbo
	# or overlay(s)/${overlay_name}.dtbo.
	# scenario:
	# 00 - The /boot/boot.scr script cannot load the overlays provided by Armbian.
	# 01 - It is possible to load only if the full name of the overlay is written.
	# 10 - Loading is possible only if the overlay name is written without a prefix.
	# 11 - Both spellings will be loaded.
	scenario=$(
		awk 'BEGIN{p=0;s=0}
			/load.*overlays?\/\${overlay_prefix}-\${overlay_file}.dtbo/{p=1}
			/load.*overlays?\/\${overlay_file}.dtbo/{s=1}
			END{print p s}
		' /boot/boot.scr
	)

	while true; do
		local options=()
		j=0

		if [[ "${scenario}" == "10" ]] || [[ "${scenario}" == "11" ]]; then
			# read overlays
			available_overlays=$(
				# Find the files that match the overlay prefix pattern.
				# Remove the overlay prefix, file extension, and path
				# in one pass. Sort it out.
				find "${overlaydir}"/ -name "$overlay_prefix"'*.dtbo' 2>/dev/null | \
				awk -F'/' -v p="${overlay_prefix}-" '{
					gsub(p, "", $NF)
					gsub(".dtbo", "", $NF)
					print $NF
				}' | sort
			)
		fi

		# Check the branch in case it is not available in /etc/armbian-release
		update_kernel_env

		# Add support for rk3588 vendor kernel overlays which don't have overlay prefix mostly
		builtin_overlays=""
		if [[ "${scenario}" == "01" ]] || [[ "${scenario}" == "11" ]]; then

			if [[ $BOARDFAMILY == "rockchip-rk3588" ]] && [[ $BRANCH == "vendor" ]]; then
				builtin_overlays=$(
					find "${overlaydir}"/ -name '*.dtbo' ! -name "$overlay_prefix"'*.dtbo' 2>/dev/null | \
					awk -F'/' -v p="${overlay_prefix}" '{
						if ($0 !~ p) {
							gsub(".dtbo", "", $NF)
							print $NF
						}
					}' | sort
				)
			fi
		fi

		if [[ "${scenario}" == "00" ]]; then
			$DIALOG --title " Manage devicetree overlays " \
				--no-button "Cancel" \
				--yes-button "Exit" \
				--yesno "    The overlays provided by Armbian cannot be loaded\n    by /boot/boot.scr script.\n" 11 44
				exit_status=$?
			if [ $exit_status == 0 ]; then
				exit 0
			fi
			break
		fi

		for overlay in ${available_overlays} ${builtin_overlays}; do
			local status="OFF"
			grep '^overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			# Raspberry Pi
			grep '^dtoverlay' ${overlayconf} | grep -qw ${overlay} && status=ON
			# handle case where overlay_prefix is part of overlay name
			if [[ -n $overlay_prefix ]]; then
				candidate="${overlay#$overlay_prefix}"
				candidate="${candidate#'-'}" # remove any trailing hyphen
			else
				candidate="$overlay"
			fi
			grep '^overlays' ${overlayconf} | grep -qw ${candidate} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$($DIALOG --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "\nUse <space> to toggle functions and save them.\nExit when you are done.\n\n    overlay_prefix=$overlay_prefix\n " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				# handle case where overlay_prefix is part of overlay name
				IFS=' ' read -r -a ovs <<< "$newoverlays"
				newoverlays=""
				# remove prefix, if any
				for ov in "${ovs[@]}"; do
					if [[ -n $overlay_prefix && $ov == "$overlay_prefix"* ]]; then
						ov="${ov#$overlay_prefix}"
					fi
					# remove '-' hyphen from beginning of ov, if any
					ov="${ov#-}"
					newoverlays+="$ov "
				done
				newoverlays="${newoverlays% }"
				# Raspberry Pi
				if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
					# Remove any existing Armbian config block
					if grep -q '^# Armbian config$' "$overlayconf"; then
						sed -i '/^# Armbian config$/,$d' "$overlayconf"
					fi
					# Append fresh marker and overlays atomically
					{
						echo "# Armbian config"
						while IFS= read -r ov; do
							printf 'dtoverlay=%s\n' "$ov"
						done <<< "$newoverlays"
					} >> "$overlayconf"
				else
					sed -i "s/^overlays=.*/overlays=$newoverlays/" ${overlayconf}
					if ! grep -q "^overlays" ${overlayconf}; then echo "overlays=$newoverlays" >> ${overlayconf}; fi
				fi
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					$DIALOG --title " Reboot required " --yes-button "Reboot" \
						--no-button "Cancel" --yesno "A reboot is required to apply the changes. Shall we reboot now?" 7 34
					if [[ $? = 0 ]]; then
						reboot
					fi
				fi
				break
				;;
			255)
				;;
		esac
	done
}


module_options+=(
["about_armbian_configng,author"]="@igorpecovnik"
["about_armbian_configng,ref_link"]=""
["about_armbian_configng,feature"]="about_armbian_configng"
["about_armbian_configng,desc"]="Show general information about this tool"
["about_armbian_configng,example"]="about_armbian_configng"
["about_armbian_configng,status"]="Active"
)
#
# @description Show general information about this tool
#
function about_armbian_configng() {

	echo "Armbian Config: The Next Generation"
	echo ""
	echo "How to make this tool even better?"
	echo ""
	echo "- propose new features or software titles"
	echo "  https://github.com/armbian/configng/issues/new?template=feature-reqests.yml"
	echo ""
	echo "- report bugs"
	echo "  https://github.com/armbian/configng/issues/new?template=bug-reports.yml"
	echo ""
	echo "- support developers with a small donation"
	echo "  https://github.com/sponsors/armbian"
	echo ""

}

# This module is used only for generating documentation. Where we use command from the menu directly, there is no module behind.
# We assume that when calling command directly, its multiarch
module_options+=(
	["module_generic,author"]="@armbian"
	["module_generic,maintainer"]="@armbian"
	["module_generic,status"]="Active"
	["module_generic,doc_link"]="https://forum.armbian.com/"
	["module_generic,arch"]="x86-64 aarch64 armhf riscv64"
)

module_options+=(
	["change_system_hostname,author"]="@igorpecovnik"
	["change_system_hostname,ref_link"]=""
	["change_system_hostname,feature"]="Change hostname"
	["change_system_hostname,desc"]="change_system_hostname"
	["change_system_hostname,example"]="change_system_hostname"
	["change_system_hostname,status"]="Active"
)
#
# @description Change system hostname
#
function change_system_hostname() {
	local new_hostname=$($DIALOG --title "Enter new hostnane" --inputbox "" 7 50 3>&1 1>&2 2>&3)
	[ $? -eq 0 ] && [ -n "${new_hostname}" ] && hostnamectl set-hostname "${new_hostname}"
}


module_options+=(
	["toggle_ssh_lastlog,author"]="@Tearran"
	["toggle_ssh_lastlog,ref_link"]=""
	["toggle_ssh_lastlog,feature"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,desc"]="Toggle SSH lastlog"
	["toggle_ssh_lastlog,example"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,status"]="Active"
)
#
# @description Toggle SSH lastlog
#
function toggle_ssh_lastlog() {

	if ! grep -q '^#\?PrintLastLog ' "${SDCARD}/etc/ssh/sshd_config"; then
		# If PrintLastLog is not found, append it with the value 'yes'
		echo 'PrintLastLog no' >> "${SDCARD}/etc/ssh/sshd_config"
		srv_restart ssh
	else
		# If PrintLastLog is found, toggle between 'yes' and 'no'
		sed -i '/^#\?PrintLastLog /
{
	s/PrintLastLog yes/PrintLastLog no/;
	t;
	s/PrintLastLog no/PrintLastLog yes/
}' "${SDCARD}/etc/ssh/sshd_config"
		srv_restart ssh
	fi

}


module_options+=(
	["module_armbian_runners,author"]="@igorpecovnik"
	["module_armbian_runners,feature"]="module_armbian_runners"
	["module_armbian_runners,desc"]="Manage self hosted runners"
	["module_armbian_runners,example"]="install remove remove_online purge status help"
	["module_armbian_runners,port"]=""
	["module_armbian_runners,status"]="Active"
	["module_armbian_runners,arch"]=""
)

#
# Module Armbian self hosted Github runners
#
function module_armbian_runners () {

	local title="runners"
	local condition=$(which "$title" 2>/dev/null)

	# read parameters from command install
	local parameter
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for feature in gh_token runner_name start stop label_primary label_secondary organisation owner repository; do
			for selected in ${parameter[@]}; do
				IFS='=' read -r -a split <<< "${selected}"
				[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
			done
		done
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_runners,example"]}"

	case "$1" in

		"${commands[0]}")

			# Prompt using dialog if parameters are missing AND in interactive mode
			if [[ -t 1 ]]; then
				if [[ -z "$gh_token" ]]; then
					gh_token=$($DIALOG --inputbox "Enter your GitHub token:" 8 60 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$runner_name" ]]; then
					runner_name=$($DIALOG --inputbox "Enter runner name:" 8 60 "armbian" 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$start" ]]; then
					start=$($DIALOG --inputbox "Enter start index:" 8 60 "01" 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$stop" ]]; then
					stop=$($DIALOG --inputbox "Enter stop index:" 8 60 "01" 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$label_primary" ]]; then
					label_primary=$($DIALOG --inputbox "Enter primary label(s):" 8 60 "alfa" 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$label_secondary" ]]; then
					label_secondary=$($DIALOG --inputbox "Enter secondary label(s):" 8 60 "fast,images" 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$organisation" ]]; then
					organisation=$($DIALOG --inputbox "Enter GitHub organisation:" 8 60 "armbian" 3>&1 1>&2 2>&3)
				fi
			fi

			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[6]}
				exit 1
			fi

			# default values if not defined
			local gh_token="${gh_token}"
			local runner_name="${runner_name:-armbian}"
			local start="${start:-01}"
			local stop="${stop:-01}"
			local label_primary="${label_primary:-alfa}"
			local label_secondary="${label_secondary:-fast,images}"
			local organisation="${organisation:-armbian}"
			local owner="${owner}"
			local repository="${repository}"

			# workaround. Remove when parameters handling is fixed
			local label_primary=$(echo $label_primary | sed "s/_/,/g") # convert
			local label_secondary=$(echo $label_secondary | sed "s/_/,/g") # convert

			# we can generate per org or per repo
			local registration_url="${organisation}"
			local prefix="orgs"
			if [[ -n "${owner}" && -n "${repository}" ]]; then
				registration_url="${owner}/${repository}"
				prefix=repos
			fi

			# Docker preinstall is needed for our build framework
			pkg_installed docker-ce || module_docker install
			pkg_update
			pkg_install jq curl libicu-dev mktorrent rsync

			# download latest runner package
			local temp_dir=$(mktemp -d)
			trap '{ rm -rf -- "$temp_dir"; }' EXIT
			[[ "$ARCH" == "x86_64" ]] && local arch=x64 || local arch=arm64
			local LATEST=$(curl -sL https://api.github.com/repos/actions/runner/tags | jq -r '.[0].zipball_url' | rev | cut -d"/" -f1 | rev | sed "s/v//g")
			curl --progress-bar --create-dir --output-dir ${temp_dir} -o \
			actions-runner-linux-${ARCH}-${LATEST}.tar.gz -L \
			https://github.com/actions/runner/releases/download/v${LATEST}/actions-runner-linux-${arch}-${LATEST}.tar.gz

			# make runners each under its own user
			for i in $(seq -w $start $stop)
			do
				local token=$(curl -s \
				-X POST \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}"\
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/${prefix}/${registration_url}/actions/runners/registration-token | jq -r .token)

				${module_options["module_armbian_runners,feature"]} ${commands[1]} ${runner_name} "${i}"

				adduser --quiet --disabled-password --shell /bin/bash \
				--home /home/actions-runner-${i} --gecos "actions-runner-${i}" actions-runner-${i}

				# add to sudoers
				if ! sudo grep -q "actions-runner-${i}" /etc/sudoers; then
					echo "actions-runner-${i} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
				fi
				usermod -aG docker actions-runner-${i}
				tar xzf ${temp_dir}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz -C /home/actions-runner-${i}
				chown -R actions-runner-${i}:actions-runner-${i} /home/actions-runner-${i}

				# 1st runner has different labels
				local label=$label_secondary
				if [[ "$i" == "${start}" ]]; then
					local label=$label_primary
				fi

				runuser -l actions-runner-${i} -c \
				"./config.sh --url https://github.com/${registration_url} \
				--token ${token} --labels ${label} --name ${runner_name}-${i} --unattended"
				if [[ -f /home/actions-runner-${i}/svc.sh ]]; then
					sh -c "cd /home/actions-runner-${i} ; \
					sudo ./svc.sh install actions-runner-${i} 2>/dev/null; \
					sudo ./svc.sh start actions-runner-${i} >/dev/null"
				fi
			done

		;;
		"${commands[1]}")
			# delete if previous already exists
			echo "Removing runner $3 on GitHub"
			${module_options["module_armbian_runners,feature"]} ${commands[2]} "$2-$3"
			echo "Removing runner $3 locally"
			runner_home=$(getent passwd "actions-runner-${3}" | cut -d: -f6)
			if [[ -f "${runner_home}/svc.sh" ]]; then
				sh -c "cd ${runner_home} ; sudo ./svc.sh stop actions-runner-$3 >/dev/null; sudo ./svc.sh uninstall actions-runner-$3 >/dev/null"
			fi
			userdel -r -f actions-runner-$3 2>/dev/null
			groupdel actions-runner-$3 2>/dev/null
			sed -i "/^actions-runner-$3.*/d" /etc/sudoers
			[[ ${runner_home} != "/" ]] && rm -rf "${runner_home}"
		;;
		"${commands[2]}")
			DELETE=$2
			x=1
			while [ $x -le 9 ] # need to do it different as it can be more then 9 pages
			do
			RUNNER=$(
			curl -s -L \
			-H "Accept: application/vnd.github+json" \
			-H "Authorization: Bearer ${gh_token}" \
			-H "X-GitHub-Api-Version: 2022-11-28" \
			https://api.github.com/${prefix}/${registration_url}/actions/runners\?page\=${x} \
			| jq -r '.runners[] | .id, .name' | xargs -n2 -d'\n' | sed -e 's/ /,/g')

			while IFS= read -r DATA; do
				RUNNER_ID=$(echo $DATA | cut -d"," -f1)
				RUNNER_NAME=$(echo $DATA | cut -d"," -f2)
				# deleting a runner
				if [[ $RUNNER_NAME == ${DELETE} ]]; then
					echo "Delete existing: $RUNNER_NAME"
					curl -s -L \
					-X DELETE \
					-H "Accept: application/vnd.github+json" \
					-H "Authorization: Bearer ${gh_token}"\
					-H "X-GitHub-Api-Version: 2022-11-28" \
					https://api.github.com/${prefix}/${registration_url}/actions/runners/${RUNNER_ID}
				fi
			done <<< $RUNNER
			x=$(( $x + 1 ))
			done
		;;
		"${commands[3]}")
			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[6]}
				exit 1
			fi
			for i in $(seq -w $start $stop); do
				${module_options["module_armbian_runners,feature"]} ${commands[1]} ${runner_name}
			done
		;;
		"${commands[4]}")
			if [[ $(systemctl list-units --type=service 2>/dev/null | grep actions.runner) -gt 0 ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_runners,feature"]} <command> [switches]"
			echo -e "Commands:  install purge"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install or reinstall $title."
			echo -e "\tpurge\t\t- Purge $title."
			echo -e "\tstatus\t\t- Status of $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tgh_token\t- token with rights to admin runners."
			echo -e "\trunner_name\t- name of the runner (series)."
			echo -e "\tstart\t\t- start of serie (01)."
			echo -e "\tstop\t\t- stop (01)."
			echo -e "\tlabel_primary\t- runner tags for first runner (alfa)."
			echo -e "\tlabel_secondary\t- runner tags for all others (images)."
			echo -e "\torganisation\t- GitHub organisation name (armbian)."
			echo -e "\towner\t\t- GitHub owner."
			echo -e "\trepository\t- GitHub repository (if adding only for repo)."
			echo ""
		;;
		*)
			${module_options["module_armbian_runners,feature"]} ${commands[6]}
		;;
	esac
}


module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
["store_netplan_config,ref_link"]="store_netplan_config"
["store_netplan_config,feature"]="store_netplan_config"
["store_netplan_config,desc"]="Storing netplan config to tmp"
["store_netplan_config,example"]="store_netplan_config"
["store_netplan_config,status"]="Active"
)
#
# @description Storing Netplan configuration to temp folder
#
function store_netplan_config () {

	# store current configs to temporal folder
	restore_netplan_config_folder=$(mktemp -d /tmp/XXXXXXXXXX)
	rsync --quiet /etc/netplan/* ${restore_netplan_config_folder}/ 2>/dev/null
	trap restore_netplan_config 1 2 3 6

}



module_options+=(
	["release_upgrade,author"]="@igorpecovnik"
	["release_upgrade,ref_link"]=""
	["release_upgrade,feature"]="Upgrade upstream distribution release"
	["release_upgrade,desc"]="Upgrade to next stable or rolling release"
	["release_upgrade,example"]="release_upgrade stable verify"
	["release_upgrade,status"]="Active"
)
#
# Upgrade distribution
#
release_upgrade(){

	local upgrade_type=$1
	local verify=$2

	local distroid=${DISTROID}

	if [[ "${upgrade_type}" == stable ]]; then
		local filter=$(grep "supported" /etc/armbian-distribution-status | cut -d"=" -f1 | grep -v "^${distroid}")
	elif [[ "${upgrade_type}" == rolling ]]; then
		local filter=$(grep "eos\|csc" /etc/armbian-distribution-status | cut -d"=" -f1 | sed "s/sid/testing/g" | grep -v "^${distroid}")
	else
		local filter=$(cat /etc/armbian-distribution-status | cut -d"=" -f1 | grep -v "^${distroid}")
	fi

	local upgrade=$(for j in $filter; do
		for i in $(grep "^${distroid}" /etc/armbian-distribution-status | cut -d";" -f2 | cut -d"=" -f2 | sed "s/,/ /g"); do
			if [[ $i == $j ]]; then
				echo $i
			fi
		done
	done | tail -1)

	if [[ -z "${upgrade}" ]]; then
		return 1;
	elif [[ -z "${verify}" ]]; then
		[[ -f /etc/apt/sources.list.d/ubuntu.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/ubuntu.sources
		[[ -f /etc/apt/sources.list.d/debian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/debian.sources
		[[ -f /etc/apt/sources.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list
		[[ "${upgrade}" == "testing" ]] && upgrade="sid" # our repo and everything is tied to sid
		[[ -f /etc/apt/sources.list.d/armbian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.sources
		[[ -f /etc/apt/sources.list.d/armbian.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.list
		pkg_update
		pkg_upgrade -o Dpkg::Options::="--force-confold" --without-new-pkgs
		pkg_fix || return 1 # Hacks for Ubuntu
		pkg_full_upgrade -o Dpkg::Options::="--force-confold"
		pkg_fix || return 1 # Hacks for Ubuntu
		pkg_full_upgrade -o Dpkg::Options::="--force-confold"
		pkg_fix || return 1 # Hacks for Ubuntu
		pkg_remove # remove all auto-installed packages
	fi
}


module_options+=(

["adjust_motd,author"]="@igorpecovnik"
["adjust_motd,ref_link"]=""
["adjust_motd,feature"]="about_armbian_configng"
["adjust_motd,desc"]="Adjust welcome screen (motd)"
["adjust_motd,example"]="adjust_motd clear, header, sysinfo, tips, commands"
["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear|00-clear)
				echo "Clear screen on login"
				;;
			header|10-armbian-header)
				echo "Show header with logo and version info"
				;;
			ap-info|15-ap-info)
				echo "Display active Wi-Fi access point (SSID, channel)"
				;;
			ip-info|20-ip-info)
				echo "Show LAN/WAN IPv4 and IPv6 addresses"
				;;
			containers-info|25-containers-info)
				echo "List running Docker containers"
				;;
			sysinfo|30-armbian-sysinfo)
				echo "Display performance and system information"
				;;
			tips|35-armbian-tips)
				echo "Show helpful tips and Armbian resources"
				;;
			commands|41-commands)
				echo "Show recommended commands"
				;;
			autoreboot-warn|98-armbian-autoreboot-warn)
				echo "Warn about pending automatic reboot after update"
				;;
			*)
				echo "No description available"
				;;
		esac
	}

	# read status
	function motd_status() {
		source /etc/default/armbian-motd
		if [[ $MOTD_DISABLE == *$1* ]]; then
			echo "OFF"
		else
			echo "ON"
		fi
	}

	LIST=()
	for v in $(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"); do
		LIST+=("$v" "$(motd_desc $v)" "$(motd_status $v)")
	done

	INLIST=($(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"))
	CHOICES=$($DIALOG --separate-output --nocancel --title "Adjust welcome screen" --checklist "" 14 76 8 "${LIST[@]}" 3>&1 1>&2 2>&3)
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
}

module_options+=(
	["module_overlayfs,author"]="@igorpecovnik"
	["module_overlayfs,maintainer"]="@igorpecovnik"
	["module_overlayfs,feature"]="module_overlayfs"
	["module_overlayfs,example"]="install remove status help"
	["module_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["module_overlayfs,status"]="Active"
	["module_overlayfs,doc_link"]="https://docs.kernel.org/filesystems/overlayfs.html"
	["module_overlayfs,group"]="System"
	["module_overlayfs,port"]=""
	["module_overlayfs,arch"]=""
)
#
# Armbian root filesystem to read only
#
function module_overlayfs() {
	local title="overlayfs"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_overlayfs,example"]}"

	case "$1" in
		"${commands[0]}")
			pkg_install -o Dpkg::Options::="--force-confold" overlayroot cryptsetup cryptsetup-bin
			[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
			sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[1]}")
			overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
			pkg_remove overlayroot cryptsetup cryptsetup-bin
			if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
			"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
			reboot
			fi
		;;
		"${commands[2]}")
			if command -v overlayroot-chroot > /dev/null 2>&1; then
				return 1
			else
				return 0
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_overlayfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_overlayfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;
		*)
			${module_options["module_overlayfs,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["manage_odroid_board,author"]="@GeoffClements"
	["manage_odroid_board,ref_link"]=""
	["manage_odroid_board,feature"]="Odroid board"
	["manage_odroid_board,desc"]="Select optimised Odroid board configuration"
	["manage_odroid_board,example"]="select"
	["manage_odroid_board,status"]="Stable"
	["manage_odroid_board,arch"]="armhf"
)
#
# @description Select optimised board configuration
#
function manage_odroid_board() {

	local board_list=("Odroid XU4" "Odroid XU3" "Odroid XU3 Lite" "Odroid HC1/HC2")
	local board_id=("xu4" "xu3" "xu3l" "hc1")
	local -a list
	local state

	local env_file=/boot/armbianEnv.txt
	local current_board=$(grep -oP '^board_name=\K.*' ${env_file})
	local target_board=${current_board}

	for board_num in $(seq 0 $((${#board_list[@]} - 1))); do
		if [[ "${board_id[${board_num}]}" == "${current_board}" ]]; then
			state=on
		else
			state=off
		fi
	list+=("${board_id[${board_num}]}" "${board_list[${board_num}]}" "${state}")
	done

	if target_board=$($DIALOG --notags --title "Select optimised board configuration" \
	--radiolist "" 10 42 4 "${list[@]}" 3>&1 1>&2 2>&3); then
		sed -i "s/^board_name=.*/board_name=${target_board}/" ${env_file} 2> /dev/null && \
		grep -q "^board_name=${target_board}" ${env_file} 2>/dev/null || \
		echo "board_name=${target_board}" >> ${env_file}
		sed -i "s/^BOARD_NAME.*/BOARD_NAME=\"Odroid ${target_board^^}\"/" /etc/armbian-release

		if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
		"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
		reboot
		fi
	fi
}

module_options+=(
	["module_nfs,author"]="@igorpecovnik"
	["module_nfs,feature"]="module_nfs"
	["module_nfs,desc"]="Install nfs client"
	["module_nfs,example"]="install remove servers mounts help"
	["module_nfs,port"]=""
	["module_nfs,status"]="Active"
	["module_nfs,arch"]=""
)
#
# Module nfs client
#
function module_nfs () {
	local title="nfs"
	local condition=$(which "$title" 2>/dev/null)?

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfs,example"]}"

	nfs_BASE="${SOFTWARE_FOLDER}/nfs"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common
		;;
		"${commands[1]}")
			pkg_remove nfs-common
		;;
		"${commands[2]}")

			if ! pkg_installed nmap; then pkg_install nmap; fi
			if ! pkg_installed nfs-common; then pkg_install nfs-common; fi

			local subnet=$($DIALOG --title "Choose subnet to search for NFS server" --inputbox "\nValid format: <IP Address>/<Subnet Mask Length>" 9 60 "${LOCALSUBNET}" 3>&1 1>&2 2>&3)
			LIST=($(nmap -oG - -p2049 ${subnet} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there. adding timeout kill as it can hang if server doesn't share to this client
					LIST=($(timeout --kill 10s 5s showmount -e "${nfs_server}" 2>/dev/null | tail -n +2 | cut -d" " -f1 | sort))
					VERIFIED_LIST=()
					local tempfolder=$(mktemp -d)
					local alreadymounted=$(df | grep $nfs_server | cut -d" " -f1 | xargs)
					for i in "${LIST[@]}"; do
						mount -n -t nfs $nfs_server:$i ${tempfolder} 2>/dev/null
						if [[ $? -eq 0 ]]; then
							if echo "${alreadymounted}" | grep -vq $i; then
							VERIFIED_LIST+=($i)
							fi
							umount ${tempfolder}
						fi
					done
					VERIFIED_LIST_LENGTH=$((${#VERIFIED_LIST[@]}))
					if shares=$(dialog --no-items \
						--title "Network filesystem (NFS) shares on ${nfs_server}" \
						--menu "" \
						$((${VERIFIED_LIST_LENGTH} + 6)) \
						80 \
						$((${VERIFIED_LIST_LENGTH})) \
						${VERIFIED_LIST[@]} 3>&1 1>&2 2>&3)
						then
							if mount_folder=$(dialog --title \
							"Where do you want to mount $shares ?" \
							--inputbox "" \
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
								if mount_options=$(dialog --title \
								"Which mount options do you want to use?" \
							--inputbox "" \
							6 80 "auto,noatime 0 0" 3>&1 1>&2 2>&3); then
								mkdir -p ${mount_folder}
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								srv_daemon_reload
								mount ${mount_folder}
								show_message <<< $(mount -t nfs4 | cut -d" " -f1)
							fi
							fi
						fi
					fi
		;;
		"${commands[3]}")
			local list=($(mount --type=nfs4 | cut -d" " -f1))
			if shares=$(dialog --no-items \
						--title "Mounted NFS shares" \
						--menu "" \
						$((${#list[@]} + 6)) \
						80 \
						$((${#list[@]})) \
						${list[@]} 3>&1 1>&2 2>&3); then
						echo "Chosen $mount"
			read
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_nfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tservers\t- Find and mount shares $title."
			echo
		;;
		*)
			${module_options["module_nfs,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_armbian_kvmtest,author"]="@igorpecovnik"
	["module_armbian_kvmtest,feature"]="module_armbian_kvmtest"
	["module_armbian_kvmtest,desc"]="Deploy Armbian KVM instances"
	["module_armbian_kvmtest,example"]="install remove save drop restore list help"
	["module_armbian_kvmtest,port"]=""
	["module_armbian_kvmtest,status"]="Active"
	["module_armbian_kvmtest,arch"]="x86-64"
)
#
# Module deploy Armbian QEMU KVM instances
# module_armbian_kvmtest - Manage the lifecycle of Armbian KVM virtual machines.
#
# This function deploys, configures, and manages Armbian-based KVM instances. It supports a suite of
# commands (install, remove, save, drop, restore, list, help) to handle the entire virtual machine lifecycle.
# Depending on the command, the function performs operations such as downloading cloud-based Armbian images,
# resizing and mounting VM disk images, customizing network settings, and executing provisioning scripts.
#
# Globals:
#   module_options - An associative array with module metadata (author, features, command examples, etc.).
#
# Arguments:
#   The first argument specifies the command to execute (e.g., install, remove, save, drop, restore, list, help).
#   Additional arguments should be provided as key=value pairs to customize the operation. Supported keys include:
#     instances     - Number of VM instances to deploy (default: "01").
#     provisioning  - Path to a provisioning script to be run on the first boot of each VM.
#     firstconfig   - File with initial configuration commands for the VMs.
#     startingip    - Starting IP address (with underscores replacing dots, e.g., 192_168_1_100).
#     gateway       - Gateway IP address (with underscores replacing dots, e.g., 192_168_1_1).
#     keyword       - Image filter keyword; supports comma-separated values (converted internally to a regex).
#     arch          - Architecture of the VM image (default: "x86").
#     kvmprefix     - Prefix used for naming VMs (default: "kvmtest").
#     network       - Network configuration (default: "default", or set to "bridge=[bridge]" if a bridge is specified).
#     bridge        - Overrides the default network by specifying a network bridge.
#     memory        - Memory allocation for each VM, in MB (default: "3072").
#     vcpus         - Number of virtual CPUs allocated per VM (default: "2").
#     size          - Additional disk space in GB to allocate to each VM (default: "10").
#
# Outputs:
#   The function prints deployment progress, image URLs (when listing), and usage instructions to STDOUT.
#
# Returns:
#   This function does not return a value; it executes commands with side effects.
#
# Example:
#   To deploy three VMs using a custom provisioning script, increased memory, and specific IP settings:
#     module_armbian_kvmtest install instances=03 memory=4096 vcpus=4 startingip=192_168_1_100 gateway=192_168_1_1 provisioning=/path/to/script keyword=Focal
#
#   To remove all deployed VMs:
#     module_armbian_kvmtest remove
function module_armbian_kvmtest () {

	local title="kvmtest"
	local condition=$(which "$title" 2>/dev/null)

	# read additional parameters from command line
	local parameter
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for feature in instances provisioning firstconfig startingip gateway keyword arch kvmprefix network bridge memory vcpus size; do
			for selected in ${parameter[@]}; do
				IFS='=' read -r -a split <<< "${selected}"
				[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
			done
		done
	done

	# if we provide startingip and gateway, set network
	if [[ -n "${startingip}" && -n "${gateway}" ]]; then
		PRESET_NET_CHANGE_DEFAULTS="1"
	fi

	local startingip=$(echo $startingip | sed "s/_/./g")
	local gateway=$(echo $gateway | sed "s/_/./g")

	local arch="${arch:-x86}" # VM architecture
	local network="${network:-default}"
	if [[ -n "${bridge}" ]]; then network="bridge=${bridge}"; fi
	local instances="${instances:-01}" # number of instances
	local size="${size:-10}" # number of instances
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local memory="${memory:-3072}"
	local vcpus="${vcpus:-2}"
	local startingip="${startingip:-10.0.60.60}"
	local gateway="${gateway:-10.0.60.1}"
	local keyword=$(echo $keyword | sed "s/,/|/g") # convert

	qcowimages=(
		"https://dl.armbian.com/nightly/uefi-${arch}/Bullseye_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Bookworm_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Trixie_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Focal_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Jammy_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Noble_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Plucky_cloud_minimal-qcow2"
	)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "$1" in

		"${commands[0]}")

			# Install portainer with KVM support and / KVM support only
			# TBD - need to be added to armbian-config
			pkg_install virtinst libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils dnsmasq

			# start network
			virsh net-start default 2>/dev/null
			virsh net-autostart default

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				curl --progress-bar -L "$qcowimage" > "${tempfolder}/$(basename "$qcowimage" | sed "s/-qcow2/.qcow2/g")"
			done

			# we will mount qcow image
			modprobe nbd max_part=8

			mounttempfolder=$(mktemp -d)
			trap '{ umount "$mounttempfolder" 2>/dev/null; rm -rf -- "$tempfolder"; }' EXIT
			# Deploy several instances
			for i in $(seq -w 01 $instances); do
				for qcowimage in ${qcowimages[@]}; do
					[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
					local filename=$(basename $qcowimage | sed "s/-qcow2/.qcow2/g") # identify filename
					local domain=$i-${kvmprefix}-$(basename $qcowimage | sed "s/-qcow2//g") # without qcow2
					local image="$i"-"${kvmprefix}"-"${filename}" # get image name
					cp ${tempfolder}/${filename} ${destination}/${image} # make a copy under different number
					sync
					qemu-img resize ${destination}/${image} +"${size}G" # expand
					qemu-nbd --connect=/dev/nbd0 ${destination}/${image} # connect to qemu image
					printf "fix\n" | sudo parted ---pretend-input-tty /dev/nbd0 print >/dev/null # fix resize
					mount /dev/nbd0p3 ${mounttempfolder} # 3rd partition on uefi images is rootfs
					# Check if it reads
					cat ${mounttempfolder}/etc/os-release | grep ARMBIAN_PRETTY_NAME | cut -d"=" -f2 | sed 's/"//g'
					# commands for changing follows here
					j=$(( j + 1 ))
					local ip_address=$(awk -F\. '{ print $1"."$2"."$3"."$4+'$j' }' <<< $startingip )

					# script that is executed at firstrun
					if [[ -f ${provisioning} ]]; then
						echo "INSTANCE=$i" > ${mounttempfolder}/root/provisioning.sh
						cat "${provisioning}" >> ${mounttempfolder}/root/provisioning.sh
						chmod +x ${mounttempfolder}/root/provisioning.sh
					fi

					# first config
					if [[ ${firstconfig} ]]; then
						if [[ -f ${firstconfig} ]]; then
							cat "${firstconfig}" >> ${mounttempfolder}/root/.not_logged_in_yet
						fi
					else
					echo "first config"
					cat <<- EOF >> ${mounttempfolder}/root/.not_logged_in_yet
					PRESET_NET_CHANGE_DEFAULTS="${PRESET_NET_CHANGE_DEFAULTS}"
					PRESET_NET_ETHERNET_ENABLED="1"
					PRESET_NET_USE_STATIC="1"
					PRESET_NET_STATIC_IP="${ip_address}"
					PRESET_NET_STATIC_MASK="255.255.255.0"
					PRESET_NET_STATIC_GATEWAY="${gateway}"
					PRESET_NET_STATIC_DNS="9.9.9.9 8.8.4.4"
					SET_LANG_BASED_ON_LOCATION="y"
					PRESET_LOCALE="sl_SI.UTF-8"
					PRESET_TIMEZONE="Europe/Ljubljana"
					PRESET_ROOT_PASSWORD="armbian"
					PRESET_USER_NAME="armbian"
					PRESET_USER_PASSWORD="armbian"
					PRESET_USER_KEY=""
					PRESET_DEFAULT_REALNAME="Armbian user"
					PRESET_USER_SHELL="bash"
					EOF
					fi

					umount /dev/nbd0p3 # unmount
					qemu-nbd --disconnect /dev/nbd0 >/dev/null # disconnect from qemu image
					# install and start VM
					sleep 3
					virt-install \
					--name ${domain} \
					--memory ${memory} \
					--vcpus ${vcpus} \
					--autostart \
					--disk ${destination}/${image},bus=sata \
					--import \
					--os-variant ubuntu24.04 \
					--network ${network} \
					--noautoconsole
				done
			done
		;;
		"${commands[1]}")
			for i in {1..10}; do
				for j in $(virsh list --all --name | grep ${kvmprefix}); do
					virsh shutdown $j 2>/dev/null
					for snapshot in $(virsh snapshot-list $j \
					| tail -n +3 | head -n -1 | cut -d' ' -f2); do virsh snapshot-delete $j $snapshot; done
				done
				sleep 2
				if [[ -z "$(virsh list --name | grep ${kvmprefix})" ]]; then break; fi
			done
			if [[ $i -lt 10 ]]; then
				for j in $(virsh list --all --name | grep ${kvmprefix}); do virsh undefine $j --remove-all-storage; done
			fi
		;;
		"${commands[2]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# create snapshots
				virsh snapshot-create-as --domain ${j} --name "initial-state"
			done
		;;
		"${commands[3]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# drop snapshots
				virsh snapshot-delete "${j}" "initial-state"
			done
		;;
		"${commands[4]}")
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				virsh shutdown $j 2>/dev/null
				virsh snapshot-revert --domain $j --snapshotname "initial-state" --running
				virsh shutdown $j 2>/dev/null
				for i in {1..20}; do
					sleep 2
					if [[ "$(virsh domstate $j | grep "shut off")" == "shut off" ]]; then break; fi
				done
				virsh start $j 2>/dev/null
			done
		;;
		"${commands[5]}")
			for qcowimage in ${qcowimages[@]}; do
				[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
				echo $qcowimage
			done
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_kvmtest,feature"]} <command> [switches]"
			echo -e "Commands:  ${module_options["module_armbian_kvmtest,example"]}"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove all virtual machines $title."
			echo -e "\tsave\t- Save state of all VM $title."
			echo -e "\trestore\t- Restore all saved state of VM $title."
			echo -e "\tdrop\t- Drop all saved states of VM $title."
			echo -e "\tlist\t- Show available VM machines $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tkvmprefix\t- Name prefix (default = kvmtest)"
			echo -e "\tmemory\t\t- KVM memory (default = 2048)"
			echo -e "\tvcpus\t\t- Virtual CPUs (default = 2)"
			echo -e "\tbridge\t\t- Use network bridge br0,br1,... instead of default inteface"
			echo -e "\tinstances\t- Repetitions if more then 1"
			echo -e "\tprovisioning\t- File of command that is executed at first run."
			echo -e "\tfirstconfig\t- Armbian first config."
			echo -e "\tkeyword\t\t- Select only certain image, example: Focal_Jammy VM image."
			echo -e "\tarch\t\t- architecture of VM image."
			echo
		;;
		*)
			${module_options["module_armbian_kvmtest,feature"]} ${commands[6]}
		;;
	esac
}


module_options+=(
	["module_nfsd,author"]="@igorpecovnik"
	["module_nfsd,feature"]="module_nfsd"
	["module_nfsd,desc"]="Install nfsd server"
	["module_nfsd,example"]="install remove manage add status clients servers help"
	["module_nfsd,port"]=""
	["module_nfsd,status"]="Active"
	["module_nfsd,arch"]=""
)
#
# Module nfsd
#
function module_nfsd () {
	local title="nfsd"
	local condition=$(which "$title" 2>/dev/null)?

	local service_name=nfs-server.service

	# we will store our config in subfolder
	mkdir -p /etc/exports.d/

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfsd,example"]}"

	NFSD_BASE="${SOFTWARE_FOLDER}/nfsd"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common nfs-kernel-server
			# add some exports
			${module_options["module_nfsd,feature"]} ${commands[2]}
			srv_restart $service_name
		;;
		"${commands[1]}")
			pkg_remove nfs-kernel-server
		;;
		"${commands[2]}")
			while true; do
				LIST=() IFS=$'\n' LIST=($(grep "^[^#;]" /etc/exports.d/armbian.exports))
				LIST_LENGTH=${#LIST[@]}
				if [[ "${LIST_LENGTH}" -ge 1 ]]; then
					line=$(dialog --no-items \
					--title "Select export to edit" \
					--ok-label "Add" \
					--cancel-label "Apply" \
					--extra-button \
					--extra-label "Delete" \
					--menu "" \
					$((${LIST_LENGTH} + 6)) \
					80 \
					$((${LIST_LENGTH})) \
					${LIST[@]} 3>&1 1>&2 2>&3)
					exitstatus=$?
					case "$exitstatus" in
						0)
							${module_options["module_nfsd,feature"]} ${commands[3]}
						;;
						1)
							break
						;;
						3)
							sed -i '\?^'$line'?d' /etc/exports.d/armbian.exports
						;;
					esac
				else
					${module_options["module_nfsd,feature"]} ${commands[3]}
					break
				fi
			done
			srv_restart $service_name
		;;
		"${commands[3]}")
			# choose between most common options
			LIST=()
			LIST=("ro" "Allow read only requests" On)
			LIST+=("rw" "Allow read and write requests" OFF)
			LIST+=("sync" "Immediate sync all writes" On)
			LIST+=("fsid=0" "Check man pages" OFF)
			LIST+=("no_subtree_check" "Disables subtree checking, improves reliability" On)
			LIST_LENGTH=$((${#LIST[@]}/3))
			if add_folder=$(dialog --title \
							"Which folder do you want to export?" \
							--inputbox "" \
							6 80 "${SOFTWARE_FOLDER}" 3>&1 1>&2 2>&3); then
				if add_ip=$(dialog --title \
							"Which IP or range can access this folder?" \
							--inputbox "\nExamples: 192.168.1.1, 192.168.1.0/24" \
							8 80 "${LOCALSUBNET}" 3>&1 1>&2 2>&3); then
					if add_options=$(dialog --separate-output \
							--nocancel \
							--title "NFS volume options" \
							--checklist "" \
							$((${LIST_LENGTH} + 6)) 80 ${LIST_LENGTH} "${LIST[@]}" 3>&1 1>&2 2>&3); then
							echo "$add_folder $add_ip($(echo $add_options | tr ' ' ','))" \
							>> /etc/exports.d/armbian.exports
							[[ -n "${add_folder}" ]] && mkdir -p "${add_folder}"
					fi
				fi
			fi
		;;
		"${commands[4]}")
			pkg_installed nfs-kernel-server
		;;
		"${commands[5]}")
			show_message <<< $(printf '%s\n' "${NFS_CLIENTS_CONNECTED[@]}")
		;;
		"${commands[6]}")

			if ! pkg_installed nmap; then
				pkg_install nmap
			fi

			LIST=($(nmap -oG - -p2049 ${LOCALSUBNET} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there
					LIST=($(showmount -e "${nfs_server}" | tail -n +2 | cut -d" " -f1 | sort))
					VERIFIED_LIST=()
					local tempfolder=$(mktemp -d)
					local alreadymounted=$(df | grep $nfs_server | cut -d" " -f1 | xargs)
					for i in "${LIST[@]}"; do
						mount -n -t nfs $nfs_server:$i ${tempfolder} 2>/dev/null
						if [[ $? -eq 0 ]]; then
							if echo "${alreadymounted}" | grep -vq $i; then
							VERIFIED_LIST+=($i)
							fi
							umount ${tempfolder}
						fi
					done
					VERIFIED_LIST_LENGTH=$((${#VERIFIED_LIST[@]}))
					if shares=$(dialog --no-items \
						--title "Network filesystem (NFS) shares on ${nfs_server}" \
						--menu "" \
						$((${VERIFIED_LIST_LENGTH} + 6)) \
						80 \
						$((${VERIFIED_LIST_LENGTH})) \
						${VERIFIED_LIST[@]} 3>&1 1>&2 2>&3)
						then
							if mount_folder=$(dialog --title \
							"Where do you want to mount $shares ?" \
							--inputbox "" \
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
								if mount_options=$(dialog --title \
								"Which mount options do you want to use?" \
							--inputbox "" \
							6 80 "auto,noatime 0 0" 3>&1 1>&2 2>&3); then
								mkdir -p ${mount_folder}
								read
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								srv_daemon_reload
								mount ${mount_options}
							fi
							fi
						fi
					fi
		;;
		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_nfsd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfsd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tmanage\t- Edit exports in $title."
			echo -e "\tadd\t- Add exports to $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_nfsd,feature"]} ${commands[7]}
		;;
	esac
}

