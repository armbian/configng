module_options+=(
	["module_desktops,author"]="@igorpecovnik"
	["module_desktops,feature"]="module_desktops"
	["module_desktops,desc"]="Install and manage desktop environments (YAML-driven)"
	["module_desktops,example"]="install remove disable enable status auto manual login supported help"
	["module_desktops,status"]="Active"
	["module_desktops,arch"]=""
	["module_desktops,help_install"]="Install desktop (de=name)"
	["module_desktops,help_remove"]="Remove desktop (de=name)"
	["module_desktops,help_disable"]="Disable display manager"
	["module_desktops,help_enable"]="Enable display manager"
	["module_desktops,help_status"]="Check if installed (de=name)"
	["module_desktops,help_auto"]="Enable auto-login (de=name)"
	["module_desktops,help_manual"]="Disable auto-login (de=name)"
	["module_desktops,help_login"]="Check auto-login status (de=name)"
	["module_desktops,help_supported"]="JSON list or check one (de=name arch=X release=Y)"
)

#
# Check if running inside a container
#
_desktop_in_container() {
	[[ -f /.dockerenv || -f /run/.containerenv || -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]
}

#
# Module to install and manage desktop environments (YAML-driven)
#
function module_desktops() {

	local de=""
	local query_arch=""
	local query_release=""
	local selected
	for selected in "${@:2}"; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ "${split[0]}" == "de" ]] && de="${split[1]}"
		[[ "${split[0]}" == "arch" ]] && query_arch="${split[1]}"
		[[ "${split[0]}" == "release" ]] && query_release="${split[1]}"
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_desktops,example"]}"

	case "$1" in
		"${commands[0]}")
			# install
			if [[ -z "$de" ]]; then
				local available=$(module_desktop_yamlparse_list | cut -f1 | tr '\n' ', ' | sed 's/,$//')
				echo "Error: specify de=name. Available: ${available}" >&2
				return 1
			fi

			local user
			user=$(module_desktop_getuser) || return 1

			module_desktop_yamlparse "$de" || return 1

			if [[ "$DESKTOP_SUPPORTED" != "yes" ]]; then
				echo "Warning: '${de}' is not supported on ${DISTROID}/$(dpkg --print-architecture)" >&2
			fi

			# suppress interactive prompts
			echo "encfs encfs/security-information boolean true" | debconf-set-selections 2>/dev/null || true

			# set up custom repo if needed
			module_desktop_repo "$de"

			# update package list
			pkg_update

			# install packages
			pkg_install -o Dpkg::Options::="--force-confold" ${DESKTOP_PACKAGES}

			# install and register display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				pkg_install -o Dpkg::Options::="--force-confold" "$DESKTOP_DM"
				which "$DESKTOP_DM" > /etc/X11/default-display-manager 2>/dev/null || true
			fi

			# remove unwanted packages
			if [[ -n "$DESKTOP_PACKAGES_UNINSTALL" ]]; then
				apt-get remove -y --purge ${DESKTOP_PACKAGES_UNINSTALL} 2>/dev/null || true
			fi

			# install branding
			module_desktop_branding "$de"

			# install Armbian Imager AppImage
			module_appimage install app=armbian-imager

			# add user to desktop groups
			for group in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
				usermod -aG "$group" "$user" 2>/dev/null || true
			done

			# set up profile sync daemon
			local user_home
			user_home=$(getent passwd "$user" | cut -d: -f6)
			if command -v psd > /dev/null 2>&1; then
				grep -q overlay-helper /etc/sudoers 2>/dev/null || \
					echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
				touch "${user_home}/.activate_psd"
			fi

			# update skel to existing users
			module_update_skel install

			# display manager and auto-login (skip in containers)
			if ! _desktop_in_container; then
				for dm in gdm3 lightdm sddm; do
					systemctl is-active --quiet "$dm" 2>/dev/null && systemctl stop "$dm" 2>/dev/null
				done
				systemctl start display-manager 2>/dev/null || \
					systemctl start "$DESKTOP_DM" 2>/dev/null || true
				module_desktops auto de="$de"
			fi

			echo "${de} installed."
		;;

		"${commands[1]}")
			# remove
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi

			module_desktop_yamlparse "$de" || return 1

			# disable auto-login
			module_desktops manual de="$de" 2>/dev/null

			# stop display manager
			if ! _desktop_in_container; then
				systemctl stop display-manager 2>/dev/null || true
			fi

			# remove display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				pkg_remove "$DESKTOP_DM"
			fi

			# remove primary DE package (autopurge handles dependencies)
			if [[ -n "$DESKTOP_PRIMARY_PKG" ]]; then
				pkg_remove "$DESKTOP_PRIMARY_PKG"
			fi

			# remove AppImages
			module_appimage remove app=armbian-imager

			echo "${de} removed."
		;;

		"${commands[2]}")
			# disable
			systemctl stop display-manager 2>/dev/null || true
			systemctl disable display-manager 2>/dev/null || true
		;;

		"${commands[3]}")
			# enable
			systemctl enable display-manager 2>/dev/null || true
			systemctl start display-manager 2>/dev/null || true
		;;

		"${commands[4]}")
			# status
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi
			module_desktop_yamlparse "$de" || return 1
			[[ -n "$DESKTOP_PRIMARY_PKG" ]] && dpkg -l "$DESKTOP_PRIMARY_PKG" 2>/dev/null | grep -q "^ii" && return 0
			return 1
		;;

		"${commands[5]}")
			# auto-login
			if [[ -z "$de" ]]; then echo "Error: specify de=name" >&2; return 1; fi
			local user
			user=$(module_desktop_getuser) || return 1
			module_desktop_yamlparse "$de" || return 1

			case "$DESKTOP_DM" in
				gdm3)
					mkdir -p /etc/gdm3
					local gdm_conf="/etc/gdm3/custom.conf"
					[[ "$DISTROID" == "trixie" || "$DISTROID" == "forky" ]] && gdm_conf="/etc/gdm3/daemon.conf"
					cat > "$gdm_conf" <<- EOF
					[daemon]
					AutomaticLoginEnable = true
					AutomaticLogin = ${user}
					EOF
				;;
				sddm)
					mkdir -p /etc/sddm.conf.d
					cat > /etc/sddm.conf.d/autologin.conf <<- EOF
					[Autologin]
					User=${user}
					EOF
				;;
				lightdm)
					mkdir -p /etc/lightdm/lightdm.conf.d
					cat > /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf <<- EOF
					[Seat:*]
					autologin-user=${user}
					autologin-user-timeout=0
					user-session=${de}
					EOF
				;;
			esac
			_desktop_in_container || systemctl restart display-manager 2>/dev/null || true
		;;

		"${commands[6]}")
			# manual login (disable auto-login)
			if [[ -z "$de" ]]; then echo "Error: specify de=name" >&2; return 1; fi
			module_desktop_yamlparse "$de" || return 1

			case "$DESKTOP_DM" in
				gdm3)    sed -i 's/AutomaticLoginEnable = true/AutomaticLoginEnable = false/' /etc/gdm3/custom.conf /etc/gdm3/daemon.conf 2>/dev/null ;;
				sddm)    rm -f /etc/sddm.conf.d/autologin.conf ;;
				lightdm) rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			_desktop_in_container || systemctl restart display-manager 2>/dev/null || true
		;;

		"${commands[7]}")
			# login status (check auto-login)
			if [[ -z "$de" ]]; then echo "Error: specify de=name" >&2; return 1; fi
			module_desktop_yamlparse "$de" || return 1

			case "$DESKTOP_DM" in
				gdm3)    grep -qE 'AutomaticLoginEnable\s*=\s*true' /etc/gdm3/custom.conf /etc/gdm3/daemon.conf 2>/dev/null && return 0 ;;
				sddm)    [[ -f /etc/sddm.conf.d/autologin.conf ]] && return 0 ;;
				lightdm) [[ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]] && return 0 ;;
			esac
			return 1
		;;

		"${commands[8]}")
			# supported
			local use_arch="${query_arch:-$(dpkg --print-architecture)}"
			local use_release="${query_release:-$DISTROID}"

			if [[ -z "$de" ]]; then
				local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
				local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"
				local result
				result=$(python3 "$parser" "$yaml_dir" "--list-json" "$use_release" "$use_arch")
				echo "$result"
				[[ "$result" == "[]" ]] && return 1
				return 0
			fi

			module_desktop_supported "$de" "$use_arch" "$use_release" && echo "true" && return 0
			echo "false"
			return 1
		;;

		"${commands[9]}")
			show_module_help "module_desktops" "Desktops" \
				"Examples:\n  module_desktops install de=xfce\n  module_desktops supported\n  module_desktops supported arch=arm64 release=trixie\n  module_desktops supported de=gnome" "native"
		;;

		*)
			${module_options["module_desktops,feature"]} help
		;;
	esac
}
