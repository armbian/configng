module_options+=(
	["set_runtime_variables,author"]="@igorpecovnik"
	["set_runtime_variables,ref_link"]=""
	["set_runtime_variables,feature"]="set_runtime_variables"
	["set_runtime_variables,desc"]="Run time variables Migrated procedures from Armbian config."
	["set_runtime_variables,example"]="set_runtime_variables"
	["set_runtime_variables,status"]="Active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables() {

	missing_dependencies=()

	# Check if dialog tools are available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		if [[ -x "$(command -v dialog)" ]]; then
			DIALOG="dialog"
		elif [[ -x "$(command -v whiptail)" ]]; then
			DIALOG="whiptail"
		else
			# No dialog tool available, use text-based interface
			DIALOG="read"
		fi
	fi

	# Check if udevadm is available
	if ! [[ -x "$(command -v udevadm)" ]]; then
		missing_dependencies+=("udev")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# Check if curl is available (required for Docker API)
	if ! [[ -x "$(command -v curl)" ]]; then
		missing_dependencies+=("curl")
	fi

	# Check if unbuffer is available (required for real-time Docker pull progress)
	if ! [[ -x "$(command -v unbuffer)" ]]; then
		missing_dependencies+=("expect")
	fi

	# Check if stdbuf is available (required for line buffering)
	if ! [[ -x "$(command -v stdbuf)" ]]; then
		missing_dependencies+=("coreutils")
	fi

	# If any dependencies are missing, print a combined message and exit
	if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
		if is_package_manager_running; then
			pkg_install ${missing_dependencies[*]}
		fi
	fi

	# Re-check DIALOG after installing dependencies
	if [[ "$DIALOG" == "read" ]]; then
		if [[ -x "$(command -v dialog)" ]]; then
			DIALOG="dialog"
		elif [[ -x "$(command -v whiptail)" ]]; then
			DIALOG="whiptail"
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if srv_active NetworkManager; then
		NETWORK_RENDERER=NetworkManager
	else
		NETWORK_RENDERER=networkd
	fi

	DIALOG_CANCEL=1
	DIALOG_ESC=255

	# Running container under the actual user (handles sudo)
	# When run with sudo, get the real user's UID/GID, not root's
	if [[ -n "$SUDO_USER" ]]; then
		# Running with sudo - use the real user who invoked sudo
		DOCKER_USERUID=$(id -u "$SUDO_USER")
		DOCKER_GROUPUID=$(id -g "$SUDO_USER")
	elif [[ $EUID -eq 0 ]]; then
		# Running as root without sudo - try to detect an interactive non-root user
		# Try logname first (most reliable)
		local detected_user=$(logname 2>/dev/null)
		if [[ -z "$detected_user" ]] || [[ "$detected_user" == "root" ]]; then
			# Fall back to 'who am i' parsing
			detected_user=$(who am i 2>/dev/null | awk '{print $1}')
			if [[ -z "$detected_user" ]] || [[ "$detected_user" == "root" ]]; then
				# No interactive user detected - use sensible defaults
				# This allows root operations that don't involve Docker
				DOCKER_USERUID=1000
				DOCKER_GROUPUID=1000
			else
				# Use detected user from 'who am i'
				DOCKER_USERUID=$(id -u "$detected_user")
				DOCKER_GROUPUID=$(id -g "$detected_user")
			fi
		else
			# Use detected user from logname
			DOCKER_USERUID=$(id -u "$detected_user")
			DOCKER_GROUPUID=$(id -g "$detected_user")
		fi
	else
		# Running as regular user without sudo
		DOCKER_USERUID=$(id -u)
		DOCKER_GROUPUID=$(id -g)
	fi

	# we have our own lsb_release which does not use Python. Others shell install it here
	if [[ ! -f /usr/bin/lsb_release ]]; then
		if is_package_manager_running; then
			sleep 3
		fi
		pkg_install --update --allow-downgrades --no-install-recommends lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	[[ -f /etc/armbian-distribution-status ]] && DISTRO_STATUS="/etc/armbian-distribution-status"

	# Docker installatons read timezone and they will fail if this doesn't exist. This is often the case with some minimal Debian/Ubuntu installations.
	if [[ ! -f /etc/timezone ]]; then
		echo "America/New_York" | sudo tee /etc/timezone
	fi

	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc 2> /dev/null || grep "VERSION=" /etc/os-release | grep -oP '(?<=\().*(?=\))')
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"

	SOFTWARE_FOLDER="/armbian" # where we should keep 3rd party software
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	LOCALSUBNET=$(echo ${LOCALIPADD} | cut -d"." -f1-3).0/24

	# create local lan and docker lan whitelist for transmission
	TRANSMISSION_WHITELIST=$(echo ${LOCALIPADD} | cut -d"." -f1-3)".*"
	local docker_subnet=$(docker network inspect lsio 2> /dev/null | grep Subnet | xargs | cut -d" " -f2 | cut -d"/" -f1 | cut -d"." -f1-2)
	if [[ -n "${docker_subnet}" ]]; then
		TRANSMISSION_WHITELIST+=",${docker_subnet}.*.*"
	fi

	BACKTITLE="\Zb\Z7Support Armbian:\Zn https://github.com/sponsors/armbian"
	TITLE="armbian-config"
	[[ -z "${DEFAULT_ADAPTER// /}" ]] && DEFAULT_ADAPTER="lo"
	# zfs subsystem - determine if our kernel is not too recent
	ZFS_DKMS_VERSION=$(LC_ALL=C apt-cache policy zfs-dkms | grep Candidate | xargs | cut -d" " -f2 | cut -c-5)
	ZFS_KERNEL_MAX=$(wget -qO- https://raw.githubusercontent.com/openzfs/zfs/refs/tags/zfs-${ZFS_DKMS_VERSION}/META | grep Maximum | cut -d" " -f2)
	# sometimes Ubuntu sets higher version then existing tag. Lets probe previous version
	if [[ -z "${ZFS_KERNEL_MAX}" ]]; then
		local previous_version="$(printf "%03d" "$(expr "$(echo $ZFS_DKMS_VERSION | sed 's/\.//g')" - 1)")"
		local previous_version=$(echo "${previous_version:0:1}.${previous_version:1:1}.${previous_version:2:1}")
		ZFS_KERNEL_MAX=$(wget -qO- https://raw.githubusercontent.com/openzfs/zfs/refs/tags/zfs-${previous_version}/META | grep Maximum | cut -d" " -f2)
	fi
	# detect desktop
	check_desktop

}

#
# Retrieve info from currently installed kernel, update /etc/armbian-release if required
# (after switching kernel, but before a reboot, BRANCH can contain an outdated value)
#
function update_kernel_env() {
	local list_of_installed_kernels=$(dpkg -l | grep '^[hi]i' | grep linux-image | head -1)
	local new_branch=$(echo "$list_of_installed_kernels" | awk '{print $2}' | cut -d'-' -f3)
	# these don't necessarily match the system-wide values from /etc/armbian-release
	KERNELPKG_VERSION=$(echo "$list_of_installed_kernels" | awk '{print $3}')
	KERNELPKG_LINUXFAMILY=$(echo "$list_of_installed_kernels" | awk '{print $2}' | cut -d'-' -f4)

	[[ "$BRANCH" == "$new_branch" ]] && return

	# BRANCH has changed: update required
	if [[ -f /etc/armbian-release ]]; then
		if grep -q BRANCH /etc/armbian-release; then
			sed -i "s/BRANCH=.*/BRANCH=$new_branch/g" /etc/armbian-release
		else
			echo "BRANCH=$new_branch" >> /etc/armbian-release
		fi
	fi
	BRANCH=$new_branch
}
