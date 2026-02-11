module_options+=(
	["module_omv,author"]="@igorpecovnik"
	["module_omv,maintainer"]="@igorpecovnik"
	["module_omv,feature"]="module_omv"
	["module_omv,example"]="install remove status help"
	["module_omv,desc"]="Install OpenMediaVault (OMV)"
	["module_omv,status"]="Active"
	["module_omv,doc_link"]="https://docs.openmediavault.org/en/stable/"
	["module_omv,group"]="NAS"
	["module_omv,port"]="80"
	["module_omv,arch"]="amd64 arm64 armhf i386"
	["module_omv,release"]="bookworm"
)

function module_omv() {
	local title="OpenMediaVault"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_omv,example"]}"

	# Constants
	local omvKey="/usr/share/keyrings/openmediavault-archive-keyring.gpg"
	local omvKeyUrl="https://packages.openmediavault.org/public/archive.key"
	local omvSources="/etc/apt/sources.list.d/openmediavault.list"
	local omvRepo="https://packages.openmediavault.org/public"
	local resolvTmp="/tmp/omv_resolv.conf.bak"
	local forceIpv4="/etc/apt/apt.conf.d/99force-ipv4"
	local noTrans="/etc/apt/apt.conf.d/99no-translations"
	local omvCodename="sandworm"
	local arch codename

	# Helper function to cleanup temporary APT configs
	_omv_install_cleanup() {
		rm -f "${forceIpv4}" "${noTrans}"
	}

	case "$1" in
		"${commands[0]}")
			# Check if already installed
			if pkg_installed openmediavault 2>/dev/null; then
				echo "OpenMediaVault is already installed."
				return 0
			fi

			# Pre-installation checks
			# Check for desktop environment
			if dpkg -l gdm3 sddm lxdm xdm lightdm slim wdm 2>/dev/null | grep -q '^ii'; then
				echo "ERROR: This system is running a desktop environment!"
				echo "OMV installation is not supported on desktop systems."
				echo "See: https://forum.openmediavault.org"
				return 1
			fi

			# Check for Docker
			if [ -f "/.dockerenv" ]; then
				echo "ERROR: Docker detected. OMV does not work in Docker!"
				return 1
			fi

			# Check for LXC
			if grep -q 'machine-lxc' /proc/1/cgroup 2>/dev/null; then
				echo "ERROR: LXC detected. OMV does not work in LXC!"
				return 1
			fi

			# Check architecture
			arch="$(dpkg --print-architecture)"
			if [[ ! ${arch} =~ ^(amd64|arm64|armhf|i386)$ ]]; then
				echo "ERROR: Unsupported architecture: ${arch}"
				return 1
			fi

			# Check Debian version
			codename="$(lsb_release --codename --short 2>/dev/null || echo "unknown")"
			if [[ ! "${codename}" =~ ^(bookworm|trixie)$ ]]; then
				echo "ERROR: Unsupported Debian version: ${codename}"
				echo "Only Debian 12 (Bookworm) and 13 (Trixie) are supported."
				return 1
			fi

			# Set OMV codename based on Debian version
			if [[ "${codename}" == "trixie" ]]; then
				omvCodename="synchrony"
			fi

			echo "=== Installing ${title} on Debian ${codename} (${arch}) ==="

			# Save current resolv.conf for potential DNS recovery
			if [ -f "/etc/resolv.conf" ]; then
				cp -f /etc/resolv.conf "${resolvTmp}"
			fi

			# Force IPv4 for apt (optional, can be disabled if needed)
			echo 'Acquire::ForceIPv4 "true";' > "${forceIpv4}"

			# Disable translations for faster apt operations
			echo 'Acquire::Languages "none";' > "${noTrans}"

			echo "Updating package repositories..."
			if ! pkg_update; then
				echo "ERROR: Failed to update package repositories."
				_omv_install_cleanup
				return 1
			fi

			echo "Adding GPG key for OpenMediaVault..."
			if ! curl --max-time 60 -4 -fsSL "${omvKeyUrl}" | \
				gpg --yes --dearmor -o "${omvKey}"; then
				echo "ERROR: Failed to add GPG key."
				_omv_install_cleanup
				return 1
			fi

			echo "Adding OMV repository..."
			echo "deb [arch=${arch} signed-by=${omvKey}] ${omvRepo} ${omvCodename} main" | \
				tee "${omvSources}" > /dev/null

			echo "Updating repositories with OMV sources..."
			if ! pkg_update; then
				echo "ERROR: Failed to update repositories after adding OMV."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing prerequisites..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --no-install-recommends \
				postfix wget gnupg; then
				echo "ERROR: Failed to install prerequisites."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing OpenMediaVault keyring..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --no-install-recommends \
				openmediavault-keyring; then
				echo "ERROR: Failed to install OpenMediaVault keyring."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing OpenMediaVault..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --auto-remove --show-upgraded \
				--allow-downgrades --allow-change-held-packages \
				--no-install-recommends \
				--option DPkg::Options::="--force-confdef" \
				--option DPkg::Options::="--force-confold" \
				openmediavault; then
				echo "ERROR: Failed to install OpenMediaVault."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			# Verify installation
			if ! pkg_installed openmediavault 2>/dev/null; then
				echo "ERROR: Failed to install OpenMediaVault."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			# DNS validation - test if DNS is working
			echo "Testing DNS resolution..."
			if ! getent hosts omv-extras.org >/dev/null 2>&1; then
				echo "WARNING: DNS resolution is failing. Attempting to fix..."
				if [ -f "${resolvTmp}" ]; then
					cp -f "${resolvTmp}" /etc/resolv.conf
					echo "Restored original resolv.conf."
				fi
			fi

			# Cleanup
			_omv_install_cleanup
			rm -f "${resolvTmp}"

			# Populate configuration database
			if command -v omv-confdbadm >/dev/null 2>&1; then
				echo "Initializing OMV configuration..."
				omv-confdbadm populate
			fi

			# Defensively resolve a valid IP for the web interface
			web_ip="$(hostname -I | awk '{print $1}')"
			[[ -z "${web_ip}" ]] && web_ip="$(hostname -i | awk '{print $1}')"
			[[ -z "${web_ip}" ]] && web_ip="$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')"
			[[ -z "${web_ip}" ]] && web_ip="localhost"

			echo "=== ${title} installation completed successfully! ==="
			echo "Access the web interface at: http://${web_ip}"
			return 0
		;;
		"${commands[1]}")
			if ! pkg_installed openmediavault 2>/dev/null; then
				echo "OpenMediaVault is not installed."
				return 0
			fi

			echo "Removing OpenMediaVault..."

			# Try to stop services first
			if systemctl is-active --quiet openmediavault-engined 2>/dev/null; then
				systemctl stop openmediavault-engined
			fi

			# Remove the package
			DEBIAN_FRONTEND=noninteractive pkg_remove openmediavault

			# Remove repository configuration
			if [ -f "${omvSources}" ]; then
				echo "Removing OMV repository..."
				rm -f "${omvSources}"
			fi

			# Remove GPG key
			if [ -f "${omvKey}" ]; then
				echo "Removing OMV GPG key..."
				rm -f "${omvKey}"
			fi

			# Remove APT config files we created
			_omv_install_cleanup

			echo "OpenMediaVault removed successfully."
			return 0
		;;
		"${commands[2]}")
			if pkg_installed openmediavault 2>/dev/null; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_omv,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_omv,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title"
			echo -e "\tstatus\t- Check if $title is installed"
			echo -e "\tremove\t- Remove $title completely"
			echo
		;;
		*)
			${module_options["module_omv,feature"]} ${commands[3]}
		;;
	esac
}
