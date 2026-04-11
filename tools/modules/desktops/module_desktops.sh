module_options+=(
	["module_desktops,author"]="@igorpecovnik"
	["module_desktops,feature"]="module_desktops"
	["module_desktops,desc"]="Install and manage desktop environments (YAML-driven)"
	["module_desktops,example"]="install remove disable enable status auto manual login supported installed help"
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
	["module_desktops,help_installed"]="Returns 0 if any desktop is installed (no de=)"
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

			if [[ -z "$DESKTOP_PACKAGES" || -z "$DESKTOP_PRIMARY_PKG" ]]; then
				echo "Error: YAML definition for '${de}' has no packages" >&2
				return 1
			fi

			if [[ "$DESKTOP_SUPPORTED" != "yes" ]]; then
				echo "Warning: '${de}' is not supported on ${DISTROID}/$(dpkg --print-architecture)" >&2
			fi

			# suppress interactive prompts
			echo "encfs encfs/security-information boolean true" | debconf-set-selections 2>/dev/null || true

			# set up custom repo if needed
			if ! module_desktop_repo "$de"; then
				echo "Error: failed to set up repository for '${de}', aborting install" >&2
				return 1
			fi

			# update package list
			pkg_update

			# Reset the install tracker before invoking pkg_install. pkg_install
			# does an `apt-get -s install` dry-run and appends the resulting
			# list of packages-to-be-newly-installed to ACTUALLY_INSTALLED.
			# We persist this list below so that uninstall can remove the
			# exact set we added without touching pre-existing packages
			# (#799 design — restored after #815 dropped the persistence).
			ACTUALLY_INSTALLED=()

			# install packages
			pkg_install -o Dpkg::Options::="--force-confold" ${DESKTOP_PACKAGES}

			# install and register display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				pkg_install -o Dpkg::Options::="--force-confold" "$DESKTOP_DM"
				command -v "$DESKTOP_DM" > /etc/X11/default-display-manager 2>/dev/null || true
			fi

			# Save the install manifest for uninstall to consume.
			# Don't truncate an existing manifest if this run added nothing
			# new (e.g. a re-install of an already-installed DE) — keeping
			# the previous manifest is more useful than overwriting it with
			# an empty file that would make uninstall a no-op.
			if [[ ${#ACTUALLY_INSTALLED[@]} -gt 0 ]]; then
				mkdir -p /etc/armbian/desktop
				printf '%s\n' "${ACTUALLY_INSTALLED[@]}" > "/etc/armbian/desktop/${de}.packages"
				debug_log "module_desktops install: wrote ${#ACTUALLY_INSTALLED[@]} packages to /etc/armbian/desktop/${de}.packages"
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

			unset _DESKTOPS_INSTALLED_CACHE
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

			# Remove the exact set of packages that were newly installed by
			# the install path. This list was captured at install time from
			# `apt-get -s install` and saved to /etc/armbian/desktop/<de>.packages
			# by the install branch below — see #799 for the original design.
			# It correctly excludes packages that were already on the system
			# before the desktop install (so we don't yank shared deps).
			local desktop_pkg_file="/etc/armbian/desktop/${de}.packages"
			local to_remove=() pkg
			if [[ -f "$desktop_pkg_file" ]]; then
				while IFS= read -r pkg; do
					[[ -z "$pkg" ]] && continue
					to_remove+=("$pkg")
				done < "$desktop_pkg_file"
			else
				# Fallback for desktops installed before the tracking file
				# existed: walk the YAML package list, keeping only what's
				# currently installed. This is less precise (it can keep
				# packages the system had pre-install) but it's the best we
				# can do without the manifest.
				echo "Warning: no install manifest at ${desktop_pkg_file}, falling back to YAML package list" >&2
				for pkg in $DESKTOP_PACKAGES $DESKTOP_DM; do
					[[ "$pkg" == "none" ]] && continue
					if dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
						to_remove+=("$pkg")
					fi
				done
			fi

			if [[ ${#to_remove[@]} -gt 0 ]]; then
				pkg_remove "${to_remove[@]}"
			fi
			rm -f "$desktop_pkg_file"

			# remove AppImages
			module_appimage remove app=armbian-imager

			# Reclaim disk space: clear apt's downloaded .deb cache. A full
			# DE removal frees hundreds of MB of installed files; the
			# matching .deb archives in /var/cache/apt/archives are no
			# longer needed and would otherwise just sit there.
			pkg_clean

			unset _DESKTOPS_INSTALLED_CACHE
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
					# map DE name to actual xsession file in /usr/share/xsessions/
					local session="$de"
					[[ "$session" == "i3-wm" ]] && session="i3"
					mkdir -p /etc/lightdm/lightdm.conf.d
					cat > /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf <<- EOF
					[Seat:*]
					autologin-user=${user}
					autologin-user-timeout=0
					user-session=${session}
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
				local yaml_dir="${desktops_dir}/yaml"
				local parser="${desktops_dir}/scripts/parse_desktop_yaml.py"
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
			# installed — returns 0 if any known desktop is installed.
			# Cached in _DESKTOPS_INSTALLED_CACHE for the lifetime of one armbian-config
			# session so the menu condition can be re-evaluated cheaply per render.
			# Cache is invalidated by `install` and `remove` below.
			if [[ -n "${_DESKTOPS_INSTALLED_CACHE-}" ]]; then
				[[ "$_DESKTOPS_INSTALLED_CACHE" == "yes" ]]
				return $?
			fi
			local yaml_dir="${desktops_dir}/yaml"
			local parser="${desktops_dir}/scripts/parse_desktop_yaml.py"
			local primaries pkgs
			primaries=$(python3 "$parser" "$yaml_dir" --primaries "$DISTROID" "$(dpkg --print-architecture)" 2>/dev/null) || {
				_DESKTOPS_INSTALLED_CACHE=no
				return 1
			}
			# Collapse '<name>\t<pkg>\n...' to a space-separated package list
			pkgs=$(awk -F'\t' '{print $2}' <<< "$primaries" | tr '\n' ' ')
			if [[ -n "${pkgs// /}" ]] && dpkg-query -W -f='${Status}\n' $pkgs 2>/dev/null | grep -q "install ok installed"; then
				_DESKTOPS_INSTALLED_CACHE=yes
				return 0
			fi
			_DESKTOPS_INSTALLED_CACHE=no
			return 1
		;;

		"${commands[10]}")
			show_module_help "module_desktops" "Desktops" \
				"Examples:\n  module_desktops install de=xfce\n  module_desktops supported\n  module_desktops supported arch=arm64 release=trixie\n  module_desktops supported de=gnome" "native"
		;;

		*)
			${module_options["module_desktops,feature"]} help
		;;
	esac
}
