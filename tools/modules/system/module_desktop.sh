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
# Install Armbian desktop branding (wallpapers, icons, lightdm config, skel, postinst)
#
function install_desktop_branding() {
	local de="$1"
	local branding_dir="${script_dir}/../tools/include/branding"

	if [[ ! -d "$branding_dir" ]]; then
		echo "Warning: branding directory not found at $branding_dir" >&2
		return 0
	fi

	dialog_infobox "Desktop" "Installing Armbian branding for ${de}..."

	# lightdm configuration
	if [[ -d "$branding_dir/lightdm" ]]; then
		mkdir -p /etc/armbian/lightdm
		cp -R "$branding_dir/lightdm/." /etc/armbian/lightdm/
		cp -R /etc/armbian/lightdm/. /etc/lightdm/ 2>/dev/null || true
	fi

	# default user skeleton
	if [[ -d "$branding_dir/skel" ]]; then
		cp -R "$branding_dir/skel/." /etc/skel/
	fi

	# wallpapers
	if [[ -d "$branding_dir/wallpapers" ]]; then
		mkdir -p /usr/share/backgrounds/armbian
		cp "$branding_dir/wallpapers/"*.jpg /usr/share/backgrounds/armbian/
	fi

	# lightdm wallpapers
	if [[ -d "$branding_dir/wallpapers-lightdm" ]]; then
		mkdir -p /usr/share/backgrounds/armbian-lightdm
		cp "$branding_dir/wallpapers-lightdm/"*.jpg /usr/share/backgrounds/armbian-lightdm/
	fi

	# desktop icons
	if [[ -d "$branding_dir/icons" ]]; then
		mkdir -p /usr/share/icons/armbian
		cp "$branding_dir/icons/"* /usr/share/icons/armbian/
	fi

	# login logo
	if [[ -d "$branding_dir/pixmaps" ]]; then
		mkdir -p /usr/share/pixmaps/armbian
		cp "$branding_dir/pixmaps/"* /usr/share/pixmaps/armbian/
	fi

	# GNOME wallpaper properties
	if [[ -f "$branding_dir/armbian.xml" ]]; then
		mkdir -p /usr/share/gnome-background-properties
		cp "$branding_dir/armbian.xml" /usr/share/gnome-background-properties/
	fi

	# SDDM theme (for KDE)
	if [[ -d "$branding_dir/sddm/themes" && ("$de" == "kde-plasma" || "$de" == "kde-neon") ]]; then
		mkdir -p /usr/share/sddm/themes
		cp -R "$branding_dir/sddm/themes/"* /usr/share/sddm/themes/
	fi

	# DE-specific postinst script (skip inside containers / CI)
	if [[ -f "$branding_dir/postinst/${de}.sh" ]]; then
		if [[ -f /.dockerenv || -f /run/.containerenv || -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
			echo "Skipping ${de} postinst (running inside container/CI)" >&2
		else
			dialog_infobox "Desktop" "Running ${de} post-install configuration..."
			bash "$branding_dir/postinst/${de}.sh" || true
		fi
	fi
}

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

			# install armbian desktop branding
			install_desktop_branding "$de"

			# add user to groups
			echo "DEBUG: adding user '${user}' to groups" >&2
			for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
				echo "DEBUG: usermod -aG ${additionalgroup} ${user}" >&2
				usermod -aG ${additionalgroup} ${user} 2>/dev/null && echo "DEBUG: OK" >&2 || echo "DEBUG: FAILED (rc=$?)" >&2
			done
			echo "DEBUG: groups done" >&2
			# set up profile sync daemon on desktop systems
			local user_home
			echo "DEBUG: getent passwd ${user}" >&2
			user_home=$(getent passwd "${user}" | cut -d: -f6)
			echo "DEBUG: user_home=${user_home}" >&2
			if command -v psd > /dev/null 2>&1; then
				echo "DEBUG: psd found" >&2
				if ! grep -q overlay-helper /etc/sudoers; then
					echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
				fi
				touch "${user_home}/.activate_psd"
			fi
			# update skel
			echo "DEBUG: update_skel" >&2
			update_skel
			echo "DEBUG: update_skel done" >&2

			# stop display managers in case we are switching them
			if srv_active gdm3; then
				srv_stop gdm3
			elif srv_active lightdm; then
				srv_stop lightdm
			elif srv_active sddm; then
				srv_stop sddm
			fi

			# start new default display manager (skip in containers)
			if [[ ! -f /.dockerenv && ! -f /run/.containerenv && -z "${CI:-}" ]]; then
				if srv_active display-manager; then
					srv_restart display-manager
				else
					srv_start display-manager
				fi

				# enable auto login
				${module_options["module_desktop,feature"]} ${commands[5]}
			fi
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
					# gdm3 autologin - trixie+ uses daemon.conf, older uses custom.conf
					mkdir -p /etc/gdm3
					local gdm_conf="/etc/gdm3/custom.conf"
					[[ "$DISTROID" == "trixie" || "$DISTROID" == "forky" ]] && gdm_conf="/etc/gdm3/daemon.conf"
					cat <<- EOF > "$gdm_conf"
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
				gnome)            sed -i 's/AutomaticLoginEnable = true/AutomaticLoginEnable = false/' /etc/gdm3/custom.conf /etc/gdm3/daemon.conf 2>/dev/null ;;
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
					grep -qE '^[[:space:]]*AutomaticLoginEnable[[:space:]]*=[[:space:]]*true' /etc/gdm3/custom.conf /etc/gdm3/daemon.conf 2>/dev/null && return 0 || return 1
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
