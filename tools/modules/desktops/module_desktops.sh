module_options+=(
	["module_desktops,author"]="@igorpecovnik"
	["module_desktops,feature"]="module_desktops"
	["module_desktops,desc"]="Install and manage desktop environments (YAML-driven)"
	["module_desktops,example"]="install remove disable enable status auto manual login supported installed help upgrade downgrade tier at-tier set-tier"
	["module_desktops,status"]="Active"
	["module_desktops,arch"]=""
	["module_desktops,help_install"]="Install desktop (de=name tier=minimal|mid|full)"
	["module_desktops,help_remove"]="Remove desktop (de=name)"
	["module_desktops,help_disable"]="Disable display manager"
	["module_desktops,help_enable"]="Enable display manager"
	["module_desktops,help_status"]="Check if installed and at which tier (de=name)"
	["module_desktops,help_auto"]="Enable auto-login (de=name)"
	["module_desktops,help_manual"]="Disable auto-login (de=name)"
	["module_desktops,help_login"]="Check auto-login status (de=name)"
	["module_desktops,help_supported"]="JSON list or check one (de=name arch=X release=Y)"
	["module_desktops,help_installed"]="Returns 0 if any desktop is installed (no de=)"
	["module_desktops,help_upgrade"]="Upgrade installed desktop to a higher tier (de=name tier=mid|full)"
	["module_desktops,help_downgrade"]="Downgrade installed desktop to a lower tier (de=name tier=minimal|mid)"
	["module_desktops,help_tier"]="Print the installed tier of a desktop, or 'not installed' (de=name)"
	["module_desktops,help_at-tier"]="Silent gate: exit 0 if a desktop is installed AND at the given tier (de=name tier=X)"
	["module_desktops,help_set-tier"]="Move installed desktop to a target tier; auto-detects upgrade vs downgrade (de=name tier=X)"
)

#
# Check if running inside a container
#
_desktop_in_container() {
	[[ -f /.dockerenv || -f /run/.containerenv || -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]
}

#
# Write the apt pin that forces apt.armbian.com .debs to win over
# Ubuntu's snap-transitional packages for desktop apps. Idempotent —
# writes via temp + atomic mv so a partial write never leaves apt with
# an unparseable preferences file.
#
# Lives at /etc/apt/preferences.d/armbian-desktops (note: NOT the
# legacy `armbian` filename, which is a dpkg conffile shipped by the
# BSP — that one gets preserved on upgrade once a user has it,
# leaving stale content on the system. By using a distinct filename
# managed entirely by armbian-config we can update the pin via
# configng upgrades alone, no BSP rebuild required).
#
# Priority 1001 (not 990) is mandatory: Ubuntu's snap-transitional
# packages have a higher epoch than Armbian's real .debs. 990 only
# permits upgrades; 1001 also permits the downgrade required to swap
# the snap-shim out for the real package. The Ubuntu-side priority
# of 50 keeps the snap-shim from ever being auto-selected when the
# real .deb is available.
#
# Non-fatal: a write failure warns and returns 1 but does not abort
# the install — apt without the pin will pick whatever wins by
# default, which is wrong but not catastrophic.
#
function _module_desktops_write_apt_pin() {
	local pin_file="/etc/apt/preferences.d/armbian-desktops"
	local pin_tmp="${pin_file}.tmp"

	# Packages where apt.armbian.com hosts a real .deb that should
	# always win over Ubuntu's snap-transitional / older Debian
	# version. Wildcards cover the codec / l10n meta-packages.
	local force_pkgs="chromium chromium-* firefox firefox-esr firefox-l10n-* thunderbird thunderbird-l10n-* google-chrome-stable code microsoft-edge-stable"

	# Subset to deprioritize from the Ubuntu archive — only those
	# that have a Ubuntu equivalent. `code` and `microsoft-edge-stable`
	# are Microsoft-only, no Ubuntu version to push down.
	local strip_pkgs="chromium chromium-* firefox firefox-esr firefox-l10n-* thunderbird thunderbird-l10n-* google-chrome-stable"

	if ! cat > "$pin_tmp" <<- EOF
	# Managed by armbian-config (module_desktops). Do not edit by hand.
	#
	# Force apt.armbian.com versions of these desktop packages over
	# Ubuntu's snap-transitional ones. Priority 1001 is required
	# (not 990) because the snap-shim packages have a higher epoch —
	# 990 only allows upgrades; 1001 also permits the downgrade
	# required to replace the snap-shim with the real .deb.
	Package: ${force_pkgs}
	Pin: release o=Armbian
	Pin-Priority: 1001

	# Push Ubuntu's snap-shim versions below the default 500 so they
	# are never auto-selected when the real apt.armbian.com .deb is
	# available.
	Package: ${strip_pkgs}
	Pin: release o=Ubuntu
	Pin-Priority: 50
	EOF
	then
		echo "Warning: failed to write ${pin_tmp}, desktop apt pin not installed" >&2
		rm -f "$pin_tmp"
		return 1
	fi

	if ! mv "$pin_tmp" "$pin_file"; then
		echo "Warning: failed to install ${pin_file}" >&2
		rm -f "$pin_tmp"
		return 1
	fi

	return 0
}

#
# Module to install and manage desktop environments (YAML-driven)
#
function module_desktops() {

	local de=""
	local query_arch=""
	local query_release=""
	local tier=""
	local selected
	for selected in "${@:2}"; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ "${split[0]}" == "de" ]] && de="${split[1]}"
		[[ "${split[0]}" == "arch" ]] && query_arch="${split[1]}"
		[[ "${split[0]}" == "release" ]] && query_release="${split[1]}"
		[[ "${split[0]}" == "tier" ]] && tier="${split[1]}"
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

			# tier= is required. The YAML schema has no flat default
			# packages list anymore — every install picks one of
			# minimal/mid/full and the parser refuses to run without
			# --tier. Reject early with a clear message instead of
			# letting the parser bail with a generic usage error.
			if [[ -z "$tier" ]]; then
				echo "Error: specify tier=minimal|mid|full" >&2
				return 1
			fi
			case "$tier" in
				minimal|mid|full) ;;
				*)
					echo "Error: invalid tier '${tier}', must be one of minimal|mid|full" >&2
					return 1
				;;
			esac

			local user
			user=$(module_desktop_getuser) || return 1

			module_desktop_yamlparse "$de" "$(dpkg --print-architecture)" "$DISTROID" "$tier" || return 1

			if [[ -z "$DESKTOP_PACKAGES" || -z "$DESKTOP_PRIMARY_PKG" ]]; then
				echo "Error: YAML definition for '${de}' tier '${tier}' has no packages" >&2
				return 1
			fi

			if [[ "$DESKTOP_SUPPORTED" != "yes" ]]; then
				echo "Warning: '${de}' is not supported on ${DISTROID}/$(dpkg --print-architecture)" >&2
			fi

			# Suppress interactive prompts end-to-end. apt + dpkg both
			# need coaxing:
			#   - DEBIAN_FRONTEND=noninteractive: stops apt opening a
			#     TUI for debconf questions.
			#   - `--force-confdef --force-confold` on pkg_install
			#     (below): when a conffile differs from both the
			#     shipped version AND any local edit, dpkg normally
			#     prompts "keep / replace / diff / shell". These
			#     flags say "always pick the default (=keep local)"
			#     silently. Without `--force-confdef`, `--force-confold`
			#     alone still prompts when both sides have diverged.
			#   - debconf-set-selections pre-seeds known interactive
			#     package questions: the `code` (Microsoft VSCode)
			#     postinst asks about adding Microsoft's apt repo —
			#     say no, apt.armbian.com already hosts code and a
			#     parallel source would race against our pin.
			export DEBIAN_FRONTEND=noninteractive
			debconf-set-selections 2>/dev/null <<- 'EOF' || true
			encfs encfs/security-information boolean true
			code code/add-microsoft-repo boolean false
			EOF

			# set up custom repo if needed
			if ! module_desktop_repo "$de"; then
				echo "Error: failed to set up repository for '${de}', aborting install" >&2
				return 1
			fi

			# Install the apt pin BEFORE pkg_update / pkg_install so apt
			# resolves the desktop package list with apt.armbian.com .debs
			# winning over Ubuntu's snap-transitional packages. Non-fatal:
			# the install continues even if the pin write fails.
			_module_desktops_write_apt_pin || true

			# update package list
			pkg_update

			# Reset the install tracker before invoking pkg_install. pkg_install
			# does an `apt-get -s install` dry-run and appends the resulting
			# list of packages-to-be-newly-installed to ACTUALLY_INSTALLED.
			# We persist this list below so that uninstall can remove the
			# exact set we added without touching pre-existing packages
			# (#799 design — restored after #815 dropped the persistence).
			ACTUALLY_INSTALLED=()

			# install packages. Bail out on failure: half-installing
			# a desktop and then flipping default.target to graphical
			# leaves the next boot pinned to a graphical target with
			# no working DM, which is a black-screen regression.
			if ! pkg_install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${DESKTOP_PACKAGES}; then
				echo "Error: ${de} package install failed; aborting before any system state is changed" >&2
				return 1
			fi

			# install and register display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				if ! pkg_install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$DESKTOP_DM"; then
					echo "Error: ${DESKTOP_DM} install failed; aborting before flipping systemd target" >&2
					return 1
				fi
				command -v "$DESKTOP_DM" > /etc/X11/default-display-manager 2>/dev/null || true
			fi

			# Armbian-only branding extras: install only when the Armbian
			# apt source is configured. armbian-plymouth-theme lives in
			# Armbian's own repo; on a non-Armbian system the apt install
			# would hard-fail with "Unable to locate package" and abort
			# the entire desktop install. Keep this gated and additive so
			# the rest of the desktop install path stays distro-agnostic.
			# Match either the legacy single-line .list file or the modern
			# deb822 .sources file.
			if [[ -f /etc/apt/sources.list.d/armbian.list \
				|| -f /etc/apt/sources.list.d/armbian.sources ]]; then
				pkg_install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" armbian-plymouth-theme || \
					echo "Warning: armbian-plymouth-theme not installed (package not found in armbian repo)" >&2
			fi

			# Save the install manifest for uninstall to consume.
			# Don't truncate an existing manifest if this run added nothing
			# new (e.g. a re-install of an already-installed DE at the
			# same tier) — keeping the previous manifest is more useful
			# than overwriting it with an empty file that would make
			# uninstall a no-op.
			mkdir -p /etc/armbian/desktop
			if [[ ${#ACTUALLY_INSTALLED[@]} -gt 0 ]]; then
				printf '%s\n' "${ACTUALLY_INSTALLED[@]}" > "/etc/armbian/desktop/${de}.packages"
				debug_log "module_desktops install: wrote ${#ACTUALLY_INSTALLED[@]} packages to /etc/armbian/desktop/${de}.packages"
			fi
			# Always write the tier marker file. This is the source of
			# truth for `module_desktops status` and for the upgrade /
			# downgrade commands' "what's currently installed" check.
			# Written even when ACTUALLY_INSTALLED is empty (re-install
			# at the same tier) so the marker stays accurate.
			printf '%s\n' "$tier" > "/etc/armbian/desktop/${de}.tier"
			debug_log "module_desktops install: wrote tier=${tier} to /etc/armbian/desktop/${de}.tier"

			# remove unwanted packages
			if [[ -n "$DESKTOP_PACKAGES_UNINSTALL" ]]; then
				apt-get remove -y --purge ${DESKTOP_PACKAGES_UNINSTALL} 2>/dev/null || true
			fi

			# install branding
			module_desktop_branding "$de"

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

			# display manager and auto-login (skip in containers).
			# Only flip default.target to graphical AFTER the DM has
			# actually started — if the start fails, the next boot
			# would otherwise pin to graphical.target with a broken
			# DM and the user gets a black screen.
			if ! _desktop_in_container; then
				for dm in gdm3 lightdm sddm; do
					systemctl is-active --quiet "$dm" 2>/dev/null && systemctl stop "$dm" 2>/dev/null
				done
				if systemctl start display-manager 2>/dev/null \
					|| systemctl start "$DESKTOP_DM" 2>/dev/null; then
					systemctl set-default graphical.target 2>/dev/null || true
					module_desktops auto de="$de"
				else
					echo "Warning: ${DESKTOP_DM} did not start; leaving default.target unchanged" >&2
				fi
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

			# Read the installed tier from the marker file so the
			# YAML fallback (when the manifest is missing) walks the
			# right tier's package list. Default to 'minimal' if no
			# marker exists, which is the safest fallback for the
			# pre-tier era.
			local installed_tier="minimal"
			if [[ -f "/etc/armbian/desktop/${de}.tier" ]]; then
				installed_tier=$(< "/etc/armbian/desktop/${de}.tier")
			fi
			module_desktop_yamlparse "$de" "$(dpkg --print-architecture)" "$DISTROID" "$installed_tier" || return 1

			# disable auto-login
			module_desktops manual de="$de" 2>/dev/null

			# Stop display manager and switch the default systemd
			# target back to multi-user. Without this step, the next
			# boot still tries to reach graphical.target — but the
			# display manager is about to be purged below, so the
			# system arrives at graphical.target with no DM, no
			# getty@tty1 (it Conflicts= with display-manager), and
			# the user gets a black tty1 with no login prompt.
			# Switching to multi-user.target now means the next boot
			# brings up the regular console login regardless.
			#
			# Isolate to multi-user.target on the running session so
			# the user gets a console prompt on tty1 immediately
			# after the uninstall, without needing to reboot first.
			# Starting getty@tty1.service on its own does not work
			# while graphical.target is still active, hence isolate.
			# isolate is destructive (kills any open GUI sessions),
			# but we are tearing down the GUI anyway.
			if ! _desktop_in_container; then
				systemctl stop display-manager 2>/dev/null || true
				systemctl set-default multi-user.target 2>/dev/null || true
				systemctl isolate multi-user.target 2>/dev/null || true
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
			rm -f "$desktop_pkg_file" "/etc/armbian/desktop/${de}.tier"

			# APT pin preferences written by module_desktop_repo apply
			# to all packages on the system, not just the DE's — leaving
			# the file behind would keep a third-party archive outranking
			# the distro even after the DE is gone. Drop it on uninstall.
			if [[ "$de" =~ ^[a-zA-Z0-9._-]+$ ]]; then
				rm -f "/etc/apt/preferences.d/${de}"
			fi

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
			# status — pure exit-code query. Returns 0 if the desktop
			# is installed, 1 if not. SILENT on both paths: this
			# command runs from every dialog menu entry's `condition`
			# field, dozens of times per menu render, and any stdout
			# output leaks into the dialog. To get the installed
			# tier name, use the `tier` command instead.
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi
			module_desktop_yamlparse "$de" || return 1
			if [[ -n "$DESKTOP_PRIMARY_PKG" ]] && dpkg -l "$DESKTOP_PRIMARY_PKG" 2>/dev/null | grep -q "^ii"; then
				return 0
			fi
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
					# gdm3 has NO conf.d drop-in support upstream or
					# in Debian/Ubuntu patches: it loads exactly one
					# file. So we have to edit it in place. The file
					# is /etc/gdm3/daemon.conf on Debian (any release)
					# and /etc/gdm3/custom.conf on Ubuntu — branch on
					# /etc/os-release ID=, not on release codename.
					local gdm_conf="/etc/gdm3/daemon.conf"
					if [[ -f /etc/os-release ]] && grep -q '^ID=ubuntu' /etc/os-release; then
						gdm_conf="/etc/gdm3/custom.conf"
					fi
					# Idempotent in-place edit of the [daemon] section.
					# Preserves any other sections / settings the user
					# may have customized.
					if [[ ! -f "$gdm_conf" ]]; then
						cat > "$gdm_conf" <<- EOF
						[daemon]
						AutomaticLoginEnable = true
						AutomaticLogin = ${user}
						EOF
					else
						# Make sure [daemon] section exists.
						grep -q '^\[daemon\]' "$gdm_conf" || \
							printf '\n[daemon]\n' >> "$gdm_conf"
						# Update or insert AutomaticLoginEnable.
						if grep -q '^AutomaticLoginEnable' "$gdm_conf"; then
							sed -i 's/^AutomaticLoginEnable.*/AutomaticLoginEnable = true/' "$gdm_conf"
						else
							sed -i '/^\[daemon\]/a AutomaticLoginEnable = true' "$gdm_conf"
						fi
						# Update or insert AutomaticLogin.
						if grep -q '^AutomaticLogin\b' "$gdm_conf"; then
							sed -i "s/^AutomaticLogin\b.*/AutomaticLogin = ${user}/" "$gdm_conf"
						else
							sed -i "/^\[daemon\]/a AutomaticLogin = ${user}" "$gdm_conf"
						fi
					fi
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
				gdm3)
					# Match any whitespace around the '=' so we don't
					# care whether the file has 'Enable=true' or
					# 'Enable = true'.
					for f in /etc/gdm3/custom.conf /etc/gdm3/daemon.conf; do
						[[ -f "$f" ]] || continue
						sed -i -E 's/^(AutomaticLoginEnable)[[:space:]]*=.*/\1 = false/' "$f"
					done
				;;
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
				gdm3)
					# Anchor at the line start so the stock custom.conf
					# template's commented sample line
					#   #  AutomaticLoginEnable = true
					# does not match. The previous unanchored regex
					# returned 0 (autologin enabled) on every fresh
					# noble install where the user had never touched
					# autologin, because the substring 'AutomaticLoginEnable
					# = true' was present inside the comment.
					grep -qE '^AutomaticLoginEnable[[:space:]]*=[[:space:]]*true' \
						/etc/gdm3/custom.conf /etc/gdm3/daemon.conf 2>/dev/null && return 0
				;;
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
				"Examples:\n  module_desktops install de=xfce tier=minimal\n  module_desktops install de=gnome tier=full\n  module_desktops upgrade de=xfce tier=mid\n  module_desktops downgrade de=xfce tier=minimal\n  module_desktops status de=xfce\n  module_desktops supported arch=arm64 release=trixie" "native"
		;;

		"${commands[11]}")
			# upgrade — install the delta from the currently
			# installed tier up to a higher target tier. Refuses
			# to "upgrade" to the same or a lower tier (use the
			# downgrade command for that).
			_module_desktops_change_tier upgrade "$de" "$tier"
			return $?
		;;

		"${commands[12]}")
			# downgrade — remove the delta from the currently
			# installed tier down to a lower target tier. The
			# removable set is intersected with the install
			# manifest so packages the user installed manually
			# (outside the desktop install path) are never
			# touched.
			_module_desktops_change_tier downgrade "$de" "$tier"
			return $?
		;;

		"${commands[13]}")
			# tier — value-returning getter, separate from
			# `status` which is a silent exit-code query. Prints
			# the installed tier name (minimal/mid/full) on
			# stdout, or "not installed" if no marker file
			# exists. Returns 0 if installed, 1 if not.
			# Use this from the CLI when you want the actual
			# tier; use `status` from menu condition gates.
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi
			module_desktop_yamlparse "$de" || return 1
			if [[ -n "$DESKTOP_PRIMARY_PKG" ]] && dpkg -l "$DESKTOP_PRIMARY_PKG" 2>/dev/null | grep -q "^ii"; then
				if [[ -f "/etc/armbian/desktop/${de}.tier" ]]; then
					cat "/etc/armbian/desktop/${de}.tier"
				else
					echo "minimal"
				fi
				return 0
			fi
			echo "not installed"
			return 1
		;;

		"${commands[14]}")
			# at-tier — silent gate. Exit 0 if the desktop is
			# installed AND the current tier marker matches the
			# target. Used by the dialog menu's `condition` field
			# to hide the "Change to <tier>" entry that matches
			# the currently-installed tier. Pure exit-code query;
			# no stdout output, just like `status`.
			if [[ -z "$de" || -z "$tier" ]]; then
				echo "Error: specify de=name tier=X" >&2
				return 1
			fi
			module_desktop_yamlparse "$de" || return 1
			[[ -n "$DESKTOP_PRIMARY_PKG" ]] || return 1
			dpkg -l "$DESKTOP_PRIMARY_PKG" 2>/dev/null | grep -q "^ii" || return 1
			local current="minimal"
			[[ -f "/etc/armbian/desktop/${de}.tier" ]] && current=$(< "/etc/armbian/desktop/${de}.tier")
			[[ "$current" == "$tier" ]]
		;;

		"${commands[15]}")
			# set-tier — direction-agnostic tier change. Reads
			# the current tier from the marker file and dispatches
			# to upgrade or downgrade based on which is higher.
			# Used by the dialog menu's "Change to <tier>" entries
			# so a single button can either upgrade or downgrade
			# without the menu having to know the current state.
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi
			if [[ -z "$tier" ]]; then
				echo "Error: specify tier=minimal|mid|full" >&2
				return 1
			fi
			case "$tier" in
				minimal|mid|full) ;;
				*)
					echo "Error: invalid tier '${tier}'" >&2
					return 1
				;;
			esac
			if [[ ! -f "/etc/armbian/desktop/${de}.tier" ]]; then
				echo "Error: ${de} is not installed" >&2
				return 1
			fi
			local current
			current=$(< "/etc/armbian/desktop/${de}.tier")
			if [[ "$current" == "$tier" ]]; then
				echo "${de} is already at tier '${tier}', nothing to do."
				return 0
			fi
			# Numeric ordering for direction detection.
			local _tier_n_minimal=1 _tier_n_mid=2 _tier_n_full=3
			local _cur_var="_tier_n_${current}"
			local _tgt_var="_tier_n_${tier}"
			if [[ "${!_tgt_var}" -gt "${!_cur_var}" ]]; then
				_module_desktops_change_tier upgrade "$de" "$tier"
			else
				_module_desktops_change_tier downgrade "$de" "$tier"
			fi
			return $?
		;;

		*)
			${module_options["module_desktops,feature"]} help
		;;
	esac
}

#
# _module_desktops_change_tier <upgrade|downgrade> <de> <target_tier>
#
# Move an installed desktop from its current tier to a target tier.
# upgrade installs the delta of (target - current); downgrade removes
# the delta of (current - target). Refuses wrong-direction calls.
#
# The downgrade path intersects the removable set with the install
# manifest at /etc/armbian/desktop/<de>.packages, so any package the
# user installed manually after the desktop install (and which
# happens to also be named in the YAML) is never touched.
#
_module_desktops_change_tier() {
	local direction="$1"
	local de="$2"
	local target="$3"

	if [[ -z "$de" ]]; then
		echo "Error: specify de=name" >&2
		return 1
	fi
	if [[ -z "$target" ]]; then
		echo "Error: specify tier=minimal|mid|full" >&2
		return 1
	fi
	case "$target" in
		minimal|mid|full) ;;
		*)
			echo "Error: invalid tier '${target}', must be one of minimal|mid|full" >&2
			return 1
		;;
	esac

	# Numeric ordering for comparison.
	local _tier_n_minimal=1 _tier_n_mid=2 _tier_n_full=3
	local _target_n_var="_tier_n_${target}"
	local target_n="${!_target_n_var}"

	if [[ ! -f "/etc/armbian/desktop/${de}.tier" ]]; then
		echo "Error: ${de} is not installed (no tier marker at /etc/armbian/desktop/${de}.tier)" >&2
		return 1
	fi
	local current
	current=$(< "/etc/armbian/desktop/${de}.tier")
	local _current_n_var="_tier_n_${current}"
	local current_n="${!_current_n_var}"
	if [[ -z "$current_n" ]]; then
		echo "Error: unrecognised tier '${current}' in /etc/armbian/desktop/${de}.tier" >&2
		return 1
	fi

	if [[ "$current" == "$target" ]]; then
		echo "${de} is already at tier '${target}', nothing to do."
		return 0
	fi
	if [[ "$direction" == "upgrade" && "$target_n" -lt "$current_n" ]]; then
		echo "Error: cannot upgrade ${de} from '${current}' to '${target}' (target is lower); use 'downgrade' instead" >&2
		return 1
	fi
	if [[ "$direction" == "downgrade" && "$target_n" -gt "$current_n" ]]; then
		echo "Error: cannot downgrade ${de} from '${current}' to '${target}' (target is higher); use 'upgrade' instead" >&2
		return 1
	fi

	# Parse the YAML twice — once at current tier, once at target.
	# Save and restore the parser output variables across the two
	# calls so the install path's globals are not stomped on.
	local _arch="$(dpkg --print-architecture)"
	local _release="$DISTROID"

	module_desktop_yamlparse "$de" "$_arch" "$_release" "$current" || return 1
	local current_arr=()
	read -ra current_arr <<< "$DESKTOP_PACKAGES"

	module_desktop_yamlparse "$de" "$_arch" "$_release" "$target" || return 1
	local target_arr=()
	read -ra target_arr <<< "$DESKTOP_PACKAGES"

	# Compute the set difference. Use awk with two file arguments
	# (stdin redirection from process substitution), reading the
	# arrays one element per line via printf so each entry is its
	# own awk record. Plain '$current_pkgs' would put every package
	# on one line and break the comparison.
	local to_install=()
	local to_remove=()
	if [[ "$direction" == "upgrade" ]]; then
		# packages in target but not in current
		while IFS= read -r pkg; do
			[[ -n "$pkg" ]] && to_install+=("$pkg")
		done < <(awk 'NR==FNR{a[$0]=1; next} !($0 in a)' \
			<(printf '%s\n' "${current_arr[@]}") \
			<(printf '%s\n' "${target_arr[@]}"))
	else
		# downgrade: packages in current but not in target,
		# intersected with the install manifest so user-installed
		# packages are never touched.
		local manifest_pkgs=()
		if [[ -f "/etc/armbian/desktop/${de}.packages" ]]; then
			while IFS= read -r pkg; do
				[[ -n "$pkg" ]] && manifest_pkgs+=("$pkg")
			done < "/etc/armbian/desktop/${de}.packages"
		fi
		local candidates=()
		while IFS= read -r pkg; do
			[[ -n "$pkg" ]] && candidates+=("$pkg")
		done < <(awk 'NR==FNR{a[$0]=1; next} !($0 in a)' \
			<(printf '%s\n' "${target_arr[@]}") \
			<(printf '%s\n' "${current_arr[@]}"))
		# intersect candidates with manifest_pkgs
		local manifest_set=" ${manifest_pkgs[*]} "
		for pkg in "${candidates[@]}"; do
			if [[ "$manifest_set" == *" $pkg "* ]]; then
				to_remove+=("$pkg")
			fi
		done
	fi

	# Apply the change.
	if [[ "$direction" == "upgrade" ]]; then
		if [[ ${#to_install[@]} -eq 0 ]]; then
			echo "${de}: nothing to install for upgrade ${current} -> ${target}"
		else
			echo "Upgrading ${de} from ${current} to ${target} (${#to_install[@]} new packages)"
			ACTUALLY_INSTALLED=()
			if ! pkg_install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "${to_install[@]}"; then
				echo "Error: pkg_install failed during upgrade" >&2
				return 1
			fi
			# append the newly-installed packages to the manifest
			if [[ ${#ACTUALLY_INSTALLED[@]} -gt 0 ]]; then
				mkdir -p /etc/armbian/desktop
				printf '%s\n' "${ACTUALLY_INSTALLED[@]}" >> "/etc/armbian/desktop/${de}.packages"
			fi
		fi
	else
		if [[ ${#to_remove[@]} -eq 0 ]]; then
			echo "${de}: nothing to remove for downgrade ${current} -> ${target}"
		else
			echo "Downgrading ${de} from ${current} to ${target} (${#to_remove[@]} packages to remove)"
			if ! pkg_remove "${to_remove[@]}"; then
				echo "Error: pkg_remove failed during downgrade" >&2
				return 1
			fi
			# rewrite the manifest, removing the just-removed packages
			if [[ -f "/etc/armbian/desktop/${de}.packages" ]]; then
				local removed_set=" ${to_remove[*]} "
				local kept=()
				while IFS= read -r pkg; do
					[[ -z "$pkg" ]] && continue
					if [[ "$removed_set" != *" $pkg "* ]]; then
						kept+=("$pkg")
					fi
				done < "/etc/armbian/desktop/${de}.packages"
				if [[ ${#kept[@]} -gt 0 ]]; then
					printf '%s\n' "${kept[@]}" > "/etc/armbian/desktop/${de}.packages"
				else
					rm -f "/etc/armbian/desktop/${de}.packages"
				fi
			fi
		fi
	fi

	# Update the tier marker
	printf '%s\n' "$target" > "/etc/armbian/desktop/${de}.tier"
	debug_log "module_desktops ${direction}: ${de} ${current} -> ${target}"
	return 0
}
