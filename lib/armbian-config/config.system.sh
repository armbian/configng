
module_options+=(
["store_netplan_config,author"]="Igor Pecovnik"
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



module_options+=(
	["adjust_motd,author"]="@igorpecovnik"
	["adjust_motd,ref_link"]=""
	["adjust_motd,feature"]="Adjust motd"
	["adjust_motd,desc"]="Adjust welcome screen (motd)"
	["adjust_motd,example"]=""
	["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear)
				echo "Clear screen on login"
				;;
			header)
				echo "Show header with logo"
				;;
			sysinfo)
				echo "Display system information"
				;;
			tips)
				echo "Show Armbian team tips"
				;;
			commands)
				echo "Show recommended commands"
				;;
			*)
				echo "No description"
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
	CHOICES=$($DIALOG --separate-output --nocancel --title "Adjust welcome screen" --checklist "" 11 50 5 "${LIST[@]}" 3>&1 1>&2 2>&3)
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
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
# @description Storing Netplan configuration to temp folder
#
function store_netplan_config () {

	# store current configs to temporal folder
	restore_netplan_config_folder=$(mktemp -d /tmp/XXXXXXXXXX)
	rsync --quiet /etc/netplan/* ${restore_netplan_config_folder}/ 2>/dev/null
	trap restore_netplan_config 1 2 3 6

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
	["are_headers_installed,author"]="Gunjan Gupta"
	["are_headers_installed,ref_link"]=""
	["are_headers_installed,feature"]="are_headers_installed"
	["are_headers_installed,desc"]="Check if kernel headers are installed"
	["are_headers_installed,example"]="are_headers_installed"
	["are_headers_installed,status"]="Pending Review"
	["are_headers_installed,doc_link"]=""
)
#
# @description Install kernel headers
#
function are_headers_installed() {
	if [[ -f /etc/armbian-release ]]; then
		PKG_NAME="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		PKG_NAME="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	check_if_installed ${PKG_NAME}
	return $?
}


module_options+=(
	["manage_overlayfs,author"]="@igorpecovnik"
	["manage_overlayfs,ref_link"]=""
	["manage_overlayfs,feature"]="overlayfs"
	["manage_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["manage_overlayfs,example"]="manage_overlayfs enable|disable"
	["manage_overlayfs,status"]="Active"
)
#
# @description set/unset Armbian root filesystem to read only
#
function manage_overlayfs() {

	if [[ "$1" == "enable" ]]; then
		debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confold" -y install overlayroot cryptsetup cryptsetup-bin
		[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
		sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
		sed -i "s/^overlayroot_cfgdisk=.*/overlayroot_cfgdisk=\"enabled\"/" /etc/overlayroot.conf
	else
		overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
		debconf-apt-progress -- apt-get -y purge overlayroot cryptsetup cryptsetup-bin
	fi
	# reboot is mandatory
	reboot
}


module_options+=(
	["Headers_install,author"]="@Tearran"
	["Headers_install,ref_link"]=""
	["Headers_install,feature"]="Headers_install"
	["Headers_install,desc"]="Install kernel headers"
	["Headers_install,example"]="is_package_manager_running"
	["Headers_install,status"]="Pending Review"
	["Headers_install,doc_link"]=""
)
#
# @description Install kernel headers
#
function Headers_install() {
	if ! is_package_manager_running; then
		if [[ -f /etc/armbian-release ]]; then
			INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
		else
			INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
		fi
		debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
}




module_options+=(
	["set_header_remove,author"]="@igorpecovnik"
	["set_header_remove,ref_link"]=""
	["set_header_remove,feature"]="set_header_remove"
	["set_header_remove,desc"]="Migrated procedures from Armbian config."
	["set_header_remove,example"]="set_header_remove"
	["set_header_remove,doc_link"]=""
	["set_header_remove,status"]="Active"
	["set_header_remove,doc_ink"]=""
)
#
# remove kernel headers
#
function set_header_remove() {

	REMOVE_PKG="linux-headers-*"
	if [[ -n $(dpkg -l | grep linux-headers) ]]; then
		debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
		rm -rf /usr/src/linux-headers*
	else
		debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
	# cleanup
	apt clean
	debconf-apt-progress -- apt -y autoremove

}


module_options+=(
	["set_stable,author"]="@Tearran"
	["set_stable,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_stable,feature"]="set_stable"
	["set_stable,desc"]="Set Armbian to stable release"
	["set_stable,example"]="set_stable"
	["set_stable,status"]="Active"
)
#
# @description Set Armbian to stable release
#
function set_stable() {

	if ! grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}


module_options+=(
	["armbian_fw_manipulate,author"]="@igorpecovnik"
	["armbian_fw_manipulate,ref_link"]=""
	["armbian_fw_manipulate,feature"]="armbian_fw_manipulate"
	["armbian_fw_manipulate,desc"]="freeze/unhold/reinstall armbian related packages."
	["armbian_fw_manipulate,example"]="armbian_fw_manipulate unhold|freeze|reinstall"
	["armbian_fw_manipulate,status"]="Active"
)
#
# freeze/unhold/reinstall armbian firmware packages
#
armbian_fw_manipulate() {

	local function=$1
	local version=$2
	local branch=$3

	[[ -n $version ]] && local version="=${version}"

	# fallback to $BRANCH
	[[ -z "${branch}" ]] && branch="${BRANCH}"
	[[ -z "${branch}" ]] && branch="current" # fallback in case we switch to very old BSP that have no such info

	# packages to install
	local armbian_packages=(
		"linux-u-boot-${BOARD}-${branch}"
		"linux-image-${branch}-${LINUXFAMILY}"
		"linux-dtb-${branch}-${LINUXFAMILY}"
		"armbian-zsh"
		"armbian-bsp-cli-${BOARD}-${branch}"
	)

	# reinstall headers only if they were previously installed
	if are_headers_installed; then
		local armbian_packages+="linux-headers-${branch}-${LINUXFAMILY}"
	fi

	local packages=""
	for pkg in "${armbian_packages[@]}"; do
		if [[ "${function}" == reinstall ]]; then
			local pkg_search=$(apt search "$pkg" 2> /dev/null | grep "^$pkg")
			if [[ $? -eq 0 && -n "${pkg_search}" ]]; then
				if [[ "${pkg_search}" == *$version* ]] ; then
				packages+="$pkg${version} ";
				else
				packages+="$pkg ";
				fi
			fi
		else
			if check_if_installed $pkg; then
				packages+="$pkg${version} "
			fi
		fi
	done
	for pkg in "${packages[@]}"; do
		case $function in
			unhold) apt-mark unhold ${pkg} | show_infobox ;;
			hold) apt-mark hold ${pkg} | show_infobox ;;
			reinstall)
				apt_install_wrapper apt-get -y --simulate --download-only --allow-change-held-packages --allow-downgrades install ${pkg}
				if [[ $? == 0 ]]; then
					apt_install_wrapper apt-get -y purge "linux-u-boot-*" "linux-image-*" "linux-dtb-*" "linux-headers-*" "armbian-zsh-*" "armbian-bsp-cli-*" # remove all branches
					apt_install_wrapper apt-get -y --allow-change-held-packages install ${pkg}
					apt_install_wrapper apt-get -y autoremove
					apt_install_wrapper apt-get -y clean
				else
					exit 1
				fi


				;;
			*) return ;;
		esac
	done
}


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



module_options+=(
	["apt_install_wrapper,author"]="@igorpecovnik"
	["apt_install_wrapper,ref_link"]=""
	["apt_install_wrapper,feature"]="Install wrapper"
	["apt_install_wrapper,desc"]="Install wrapper"
	["apt_install_wrapper,example"]="apt_install_wrapper apt-get -y purge armbian-zsh"
	["apt_install_wrapper,status"]="Active"
)
#
# @description Use TUI / GUI for apt install if exists
#
function apt_install_wrapper() {

	if [ -t 0 ]; then
		debconf-apt-progress -- "$@"
	else
		# Terminal not defined - proceed without TUI
		"$@"
	fi
}


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



menu_options+=(
	["get_headers_kernel,author"]="@igorpecovnik"
	["get_headers_kernel,ref_link"]=""
	["get_headers_kernel,feature"]="get_headers_install"
	["get_headers_kernel,desc"]="Migrated procedures from Armbian config."
	["get_headers_kernel,example"]="get_headers_install"
	["get_headers_kernel,status"]="Active"
	["get_headers_kernel,doc_link"]=""
)
#
# install kernel headers
#
function get_headers_install() {

	if [[ -f /etc/armbian-release ]]; then
		INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	debconf-apt-progress -- apt-get -y install ${INSTALL_PKG} || exit 1

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
		sudo service ssh restart
	else
		# If PrintLastLog is found, toggle between 'yes' and 'no'
		sed -i '/^#\?PrintLastLog /
{
	s/PrintLastLog yes/PrintLastLog no/;
	t;
	s/PrintLastLog no/PrintLastLog yes/
}' "${SDCARD}/etc/ssh/sshd_config"
		sudo service ssh restart
	fi

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
		local filter=$(grep "supported" /etc/armbian-distribution-status | cut -d"=" -f1)
	elif [[ "${upgrade_type}" == rolling ]]; then
		local filter=$(grep "eos\|csc" /etc/armbian-distribution-status | cut -d"=" -f1 | sed "s/sid/testing/g")
	else
		local filter=$(cat /etc/armbian-distribution-status | cut -d"=" -f1)
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
		[[ -f /etc/apt/sources.list.d/armbian.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get -y update
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" upgrade --without-new-pkgs
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade
		apt_install_wrapper apt-get -y --purge autoremove
	fi
}

module_options+=(
	["set_rolling,author"]="@Tearran"
	["set_rolling,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_rolling,feature"]="set_rolling"
	["set_rolling,desc"]="Set Armbian to rolling release"
	["set_rolling,example"]="set_rolling"
	["set_rolling,status"]="Active"
)
#
# @description Set Armbian to rolling release
#
function set_rolling() {

	if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}



module_options+=(
["manage_dtoverlays,author"]="Gunjan Gupta"
["manage_dtoverlays,ref_link"]=""
["manage_dtoverlays,feature"]="dtoverlays"
["manage_dtoverlays,desc"]="Enable/disable device tree overlays"
["manage_dtoverlays,example"]="manage_dtoverlays"
["manage_dtoverlays,status"]="Active"
)
#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	while true; do
		local options=()
		j=0
		available_overlays=$(ls -1 ${OVERLAY_DIR}/*.dtbo | sed "s#^${OVERLAY_DIR}/##" | sed 's/.dtbo//g' | grep $BOOT_SOC | tr '\n' ' ')
		for overlay in ${available_overlays}; do
			local status="OFF"
			grep '^fdt_overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$($DIALOG --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "\nUse <space> to toggle functions and save them.\nExit when you are done.\n " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				sed -i "s/^fdt_overlays=.*/fdt_overlays=$newoverlays/" ${overlayconf}
				if ! grep -q "^fdt_overlays" ${overlayconf}; then echo "fdt_overlays=$newoverlays" >> ${overlayconf}; fi
				sync
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
	["Headers_remove,author"]="@Tearran"
	["Headers_remove,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L160"
	["Headers_remove,feature"]="Headers_remove"
	["Headers_remove,desc"]="Remove Linux headers"
	["Headers_remove,example"]="Headers_remove"
	["Headers_remove,status"]="Pending Review"
	["Headers_remove,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Linux headers
#
function Headers_remove() {
	if ! is_package_manager_running; then
		REMOVE_PKG="linux-headers-*"
		if [[ -n $(dpkg -l | grep linux-headers) ]]; then
			debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
			rm -rf /usr/src/linux-headers*
		else
			debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
		fi
		# cleanup
		apt clean
		debconf-apt-progress -- apt -y autoremove
	fi
}



module_options+=(
["about_armbian_configng,author"]="@igorpecovnik"
["about_armbian_configng,ref_link"]=""
["about_armbian_configng,feature"]="Show info"
["about_armbian_configng,desc"]=""
["about_armbian_configng,example"]=""
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

module_options+=(
	["switch_kernels,author"]="@igorpecovnik"
	["switch_kernels,ref_link"]=""
	["switch_kernels,feature"]=""
	["switch_kernels,desc"]="Switching to alternative kernels"
	["switch_kernels,example"]=""
	["switch_kernels,status"]="Active"
)
#
# @description Switch between alternative kernels
#
function switch_kernels() {

	# we only allow switching kerneles that are in the test pool
	[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,current,edge"
	local kernel_test_target=$(for x in ${KERNEL_TEST_TARGET//,/ }; do echo "linux-image-$x-${LINUXFAMILY}"; done;)
	local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}')
	# just in case current is not installed
	[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"
	local search_exec="apt-cache show ${kernel_test_target} | grep -E \"Package:|Version:|version:|family\" | grep -v \"Config-Version\" | sed -n -e 's/^.*: //p' | sed 's/\.$//g' | xargs -n3 -d'
' | sed \"s/ /=/\" $grep_current_kernel"
	IFS=$'
'
	local LIST=()
	for line in $(eval ${search_exec}); do
		LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
	done
	unset IFS
	local list_length=$((${#LIST[@]} / 2))
	if [ "$list_length" -eq 0 ]; then
		dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "
No other kernels available!" 7 32
	else
		local target_version=$(whiptail --separate-output --title "Select kernel" --menu "ed" $((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ -n "${target_version}" ]; then
			local branch=${target_version##*image-}
			armbian_fw_manipulate "reinstall" "${target_version/*=/}" "${branch%%-*}"
		fi
	fi
}


