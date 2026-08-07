module_options+=(
	["module_proxmox,author"]="@igorpecovnik"
	["module_proxmox,maintainer"]="@igorpecovnik"
	["module_proxmox,feature"]="module_proxmox"
	["module_proxmox,example"]="install remove purge status help"
	["module_proxmox,desc"]="Proxmox VE on top of the Armbian kernel (Debian trixie)"
	["module_proxmox,status"]="Active"
	["module_proxmox,doc_link"]="https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie"
	["module_proxmox,group"]="Management"
	["module_proxmox,port"]="8006"
	["module_proxmox,arch"]="x86-64 arm64"
)

#
# Install Proxmox VE from the official repo, WITHOUT the Proxmox kernel.
#
# The proxmox-ve meta-package hard-depends on proxmox-default-kernel, so we
# install pve-manager instead: it pulls the full PVE userspace (pve-cluster,
# qemu-server, pve-container, ifupdown2, ...) but has no kernel dependency,
# leaving the running Armbian kernel (which already ships KVM) in place.
#
function module_proxmox() {
	local title="Proxmox VE"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_proxmox,example"]}"

	local key_url="https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg"
	local key_file="/usr/share/keyrings/proxmox-archive-keyring.gpg"
	local key_sha256="136673be77aba35dcce385b28737689ad64fd785a797e57897589aed08db6e45"
	local repo_file="/etc/apt/sources.list.d/pve-install-repo.sources"

	case "$1" in

		"${commands[0]}")
			## install

			# Proxmox VE 9 packages are built for Debian 13 (trixie) only.
			if [[ "${DISTROID}" != "trixie" ]]; then
				dialog_msgbox "${title} not supported" \
					"Proxmox VE 9 requires Debian 13 (trixie).\n\nDetected release: ${DISTROID:-unknown}.\nInstallation aborted." 9 60
				return 1
			fi

			# Official packages exist for amd64 and arm64 only.
			local host_arch
			host_arch=$(dpkg --print-architecture)
			case "${host_arch}" in
				amd64 | arm64) ;;
				*)
					dialog_msgbox "${title} not supported" \
						"Proxmox VE is available for amd64 and arm64 only.\n\nDetected architecture: ${host_arch}.\nInstallation aborted." 9 60
					return 1
					;;
			esac

			# PVE needs the hostname to resolve to a real (non-loopback) IP for its
			# cluster stack + web-UI cert. When it only resolves to loopback, offer
			# to fix the hostname right here: change_system_hostname sets a new name
			# that isn't pinned to a loopback line in /etc/hosts, so nss-myhostname
			# then resolves it to the LAN IP (which is what the user's manual
			# armbian-config hostname change did). Re-check after each attempt.
			local host_ip
			host_ip=$(hostname --ip-address 2>/dev/null | awk '{print $1}')
			while [[ -z "${host_ip}" || "${host_ip}" == 127.* || "${host_ip}" == "::1" ]]; do
				local hn_choice
				hn_choice=$(dialog_menu " Hostname check " \
					"The hostname does not resolve to a non-loopback IP (got: ${host_ip:-none}).\n\nProxmox needs the hostname to map to a LAN IP, otherwise the web UI and clustering may not work." \
					16 70 3 -- \
					"fix"      "Set the hostname now (recommended)" \
					"continue" "Continue anyway (fix it later)" \
					"cancel"   "Abort installation")
				case "${hn_choice}" in
					fix)
						change_system_hostname
						host_ip=$(hostname --ip-address 2>/dev/null | awk '{print $1}')
						;;
					continue)
						# A loopback address is useless for the web-UI URL; fall back to a placeholder.
						host_ip=""
						break
						;;
					*)
						return 1
						;;
				esac
			done

			# Add the Proxmox release key and verify its checksum. Stage to a temp
			# file first and only publish it to key_file once verified, so a failed
			# download or checksum mismatch can't clobber an already-valid keyring
			# that the repo config + pkg_update still rely on.
			pkg_install curl ca-certificates
			install -m 0755 -d /usr/share/keyrings
			local key_tmp
			key_tmp="$(mktemp)"
			if ! curl -fsSL "${key_url}" -o "${key_tmp}" \
				|| ! echo "${key_sha256}  ${key_tmp}" | sha256sum -c - >/dev/null 2>&1; then
				rm -f "${key_tmp}"
				dialog_msgbox "Key verification failed" \
					"The Proxmox release key could not be downloaded or its checksum did not match the expected value.\n\nInstallation aborted." 9 60
				return 1
			fi
			install -m 0644 "${key_tmp}" "${key_file}"
			rm -f "${key_tmp}"

			# no-subscription repository (DEB822 format).
			cat <<- EOF > "${repo_file}"
			Types: deb
			URIs: http://download.proxmox.com/debian/pve
			Suites: trixie
			Components: pve-no-subscription
			Signed-By: ${key_file}
			EOF

			pkg_update
			pkg_full_upgrade

			# Preseed postfix so its install does not block on a debconf prompt.
			debconf-set-selections <<- EOF
			postfix postfix/main_mailer_type select Local only
			postfix postfix/mailname string $(hostname -f 2>/dev/null || hostname)
			EOF

			# Install the PVE userspace WITHOUT the Proxmox kernel (see header note).
			pkg_install pve-manager postfix open-iscsi chrony

			# Proxmox's default storage stack expects ZFS. Provide it through the
			# Armbian ZFS module (kernel headers + zfs-dkms + tools, built against
			# the running kernel) when it is not already present.
			if ! module_zfs status >/dev/null 2>&1; then
				module_zfs install
			fi

			if pkg_installed pve-manager; then
				# Bracket IPv6 literals so host:port stays valid in the URL.
				local host_disp="${host_ip:-<board-ip>}"
				[[ "${host_disp}" == *:* ]] && host_disp="[${host_disp}]"
				dialog_msgbox "${title} installed" \
					"Proxmox VE is installed on the Armbian kernel.\n\nWeb UI: https://${host_disp}:${module_options["module_proxmox,port"]}\nLog in as 'root' with your system password." 10 66
			fi
		;;

		"${commands[1]}")
			## remove
			pkg_installed pve-manager && pkg_remove pve-manager
			# Drop the rest of the stack pulled in by pve-manager, if present.
			for p in proxmox-ve qemu-server pve-container pve-qemu-kvm pve-cluster; do
				pkg_installed "$p" && pkg_remove "$p"
			done
			rm -f "${repo_file}"
			pkg_update
		;;

		"${commands[2]}")
			## purge
			${module_options["module_proxmox,feature"]} "${commands[1]}"
			rm -f "${key_file}"
			rm -rf /etc/pve /var/lib/pve-cluster /var/lib/pve-manager /var/lib/rrdcached/db/pve2-*
			pkg_update
		;;

		"${commands[3]}")
			## status
			if pkg_installed pve-manager; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[4]}")
			show_module_help "module_proxmox" "${title}" \
				"Architecture: ${module_options["module_proxmox,arch"]} | OS: Debian trixie | Keeps the Armbian kernel" \
				"native"
		;;

		*)
			${module_options["module_proxmox,feature"]} "${commands[4]}"
		;;
	esac
}
