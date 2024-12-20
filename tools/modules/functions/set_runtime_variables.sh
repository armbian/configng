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

	# Check if whiptail is available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		missing_dependencies+=("whiptail")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# If any dependencies are missing, print a combined message and exit
	if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
		if is_package_manager_running; then
			pkg_install ${missing_dependencies[*]}
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if systemctl is-active NetworkManager 1> /dev/null; then
		NETWORK_RENDERER=NetworkManager
	else
		NETWORK_RENDERER=networkd
	fi

	DIALOG_CANCEL=1
	DIALOG_ESC=255

	# we have our own lsb_release which does not use Python. Others shell install it here
	if [[ ! -f /usr/bin/lsb_release ]]; then
		if is_package_manager_running; then
			sleep 3
		fi
		pkg_install --update --allow-downgrades --no-install-recommends lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	[[ -f /etc/armbian-distribution-status ]] && DISTRO_STATUS="/etc/armbian-distribution-status"

	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc || grep "VERSION=" /etc/os-release | grep -oP '(?<=\().*(?=\))')
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"

	SOFTWARE_FOLDER="/armbian" # where we should keep 3rd party software
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	LOCALSUBNET=$(echo ${LOCALIPADD} | cut -d"." -f1-3).0/24
	BACKTITLE="Contribute: https://github.com/armbian/configng"
	TITLE="Armbian configuration utility"
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

