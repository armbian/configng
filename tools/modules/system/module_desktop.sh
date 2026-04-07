module_options+=(
	["module_desktop,author"]="@igorpecovnik"
	["module_desktop,feature"]="module_desktop"
	["module_desktop,desc"]="Install and manage desktop environments"
	["module_desktop,example"]="install remove disable enable status auto manual login help"
	["module_desktop,status"]="Active"
	["module_desktop,arch"]="x86-64"
	["module_desktop,help_install"]="Install desktop environment (de=xfce|gnome|cinnamon|mate|i3-wm|budgie|kde-plasma|kde-neon)"
	["module_desktop,help_remove"]="Remove desktop environment"
	["module_desktop,help_disable"]="Disable display manager"
	["module_desktop,help_enable"]="Enable display manager"
	["module_desktop,help_status"]="Check if display manager is running"
	["module_desktop,help_auto"]="Enable auto-login"
	["module_desktop,help_manual"]="Disable auto-login"
	["module_desktop,help_login"]="Check auto-login status"
)
#
# Module install and configure desktop
#
function module_desktop() {

	# get user who executed this script, fall back to first non-root human user
	local user
	if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
		user="$SUDO_USER"
	else
		user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /nologin|false/ {print $1; exit}' /etc/passwd)
	fi
	if [[ -z "$user" || ! -d "/home/${user}" ]]; then
		echo "Error: No valid user found for desktop setup." >&2
		return 1
	fi

	# read desktop environment from command line parameters (de=xfce, de=gnome, etc.)
	local de="xfce"
	local parameter
	IFS=' ' read -r -a parameter <<< "${2}"
	for selected in "${parameter[@]}"; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ "${split[0]}" == "de" ]] && de="${split[1]}"
	done

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_desktop,example"]}"

	# generate and install packages
	module_desktop_packages "$de" "$DISTROID"

	local desktop_pkg_file="/etc/armbian/desktop/${de}.packages"

	case "$1" in
		"${commands[0]}")

			# update package list
			pkg_update

			# reset tracking of newly installed packages
			ACTUALLY_INSTALLED=()
			# set up bianbu repo if needed
			if [[ "$de" == "bianbu" ]]; then
				local bianbu_ver="v1.0.15"
				local bianbu_url="https://archive.spacemit.com/bianbu-ports"
				local bianbu_keyring="/usr/share/keyrings/bianbu-archive-keyring.gpg"

				# import GPG key
				curl -fsSL "${bianbu_url}/bianbu-archive-keyring.gpg" -o "$bianbu_keyring"

				# add sources
				cat > /etc/apt/sources.list.d/bianbu.list <<- EOF
				deb [signed-by=${bianbu_keyring}] ${bianbu_url}/ mantic-spacemit/snapshots/${bianbu_ver} main universe multiverse restricted
				deb [signed-by=${bianbu_keyring}] ${bianbu_url}/ mantic-porting/snapshots/${bianbu_ver} main universe multiverse restricted
				deb [signed-by=${bianbu_keyring}] ${bianbu_url}/ mantic-customization/snapshots/${bianbu_ver} main universe multiverse restricted
				EOF

				# pin spacemit packages higher
				cat > /etc/apt/preferences.d/bianbu <<- EOF
				Package: *
				Pin: release o=spacemit,a=mantic-spacemit
				Pin-Priority: 1200

				Package: *
				Pin: release o=spacemit,a=mantic-porting
				Pin-Priority: 1100

				Package: *
				Pin: release o=spacemit,a=mantic-customization
				Pin-Priority: 1100
				EOF

				pkg_update
			fi

			# desktops has different default login managers
			case "$de" in
				gnome)
					echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES}
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES_UNINSTALL}
					pkg_install -o Dpkg::Options::="--force-confold" gdm3
				;;
				kde-neon|kde-plasma)
					echo "/usr/sbin/sddm" > /etc/X11/default-display-manager
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES}
					pkg_install -o Dpkg::Options::="--force-confold" ${PACKAGES_UNINSTALL}
					pkg_install -o Dpkg::Options::="--force-confold" sddm
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

			# save list of newly installed packages
			echo "DEBUG desktop: ACTUALLY_INSTALLED has ${#ACTUALLY_INSTALLED[@]} entries" >&2
			echo "DEBUG desktop: saving to $desktop_pkg_file" >&2
			mkdir -p /etc/armbian/desktop
			printf '%s\n' "${ACTUALLY_INSTALLED[@]}" > "$desktop_pkg_file"
			echo "DEBUG desktop: saved $(wc -l < "$desktop_pkg_file") lines to $desktop_pkg_file" >&2

			# add user to groups
			for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
				usermod -aG ${additionalgroup} ${user} 2> /dev/null
			done
			# set up profile sync daemon on desktop systems
			local user_home
			user_home=$(getent passwd "${user}" | cut -d: -f6)
			if command -v psd > /dev/null 2>&1; then
				if ! grep -q overlay-helper /etc/sudoers; then
					echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
				fi
				touch "${user_home}/.activate_psd"
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
			if srv_active display-manager; then
				srv_restart display-manager
			else
				srv_start display-manager
			fi

			# enable auto login
			${module_options["module_desktop,feature"]} ${commands[5]}
		;;

		"${commands[1]}")
			# disable auto login
			${module_options["module_desktop,feature"]} ${commands[6]}
			# remove desktop
			srv_active display-manager && srv_stop display-manager
			if [[ -f "$desktop_pkg_file" ]]; then
				# remove only packages that were newly installed
				pkg_remove $(cat "$desktop_pkg_file")
				rm -f "$desktop_pkg_file"
			else
				# fallback: no tracking file, remove full list
				pkg_remove ${PACKAGES}
			fi
			# remove desktop meta-package and display manager, let autoremove handle deps
			case "$de" in
				gnome)            pkg_remove gdm3 ;;
				kde-neon|kde-plasma) pkg_remove sddm ;;
				*)        pkg_remove lightdm ;;
			esac
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
				kde-neon|kde-plasma)
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
				kde-neon|kde-plasma)
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
				gnome)            rm -f /etc/gdm3/custom.conf ;;
				kde-neon|kde-plasma) rm -f /etc/sddm.conf.d/autologin.conf ;;
				*)        rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			# restart after selection
			srv_restart display-manager
		;;
		"${commands[7]}")
			# login status - check per DE
			case "$de" in
				gnome)
					grep -q '^\s*AutomaticLoginEnable\s*=\s*true' /etc/gdm3/custom.conf 2>/dev/null && return 0 || return 1
				;;
				kde-neon|kde-plasma)
					[[ -f /etc/sddm.conf.d/autologin.conf ]] && return 0 || return 1
				;;
				*)
					[[ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]] && return 0 || return 1
				;;
			esac
		;;
		"${commands[8]}")
			show_module_help "module_desktop" "Desktop" \
				"Available desktops: ${module_options["module_desktop_packages,de"]}\nExample: module_desktop install de=gnome" "native"
		;;
		*)
			show_module_help "module_desktop" "Desktop" \
				"Available desktops: ${module_options["module_desktop_packages,de"]}\nExample: module_desktop install de=gnome" "native"
		;;
	esac
}
