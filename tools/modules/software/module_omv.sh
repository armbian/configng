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
	["module_omv,arch"]="amd64 arm64 armhf"
	["module_omv,release"]="bookworm"
)

function module_omv() {
	local title="openmediavault"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_omv,example"]}"

	case "$1" in
		"${commands[0]}")
			echo "Adding GPG key for OpenMediaVault..."
			curl --max-time 60 -4 -fsSL "https://packages.openmediavault.org/public/archive.key" | \
			gpg --dearmor -o /usr/share/keyrings/openmediavault-archive-keyring.gpg

			echo "Adding OMV sources.list..."
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] \
			https://packages.openmediavault.org/public sandworm main" | \
			tee /etc/apt/sources.list.d/openmediavault.list

			pkg_update

			echo "Installing OpenMediaVault packages..."
			DEBIAN_FRONTEND=noninteractive pkg_install --yes --auto-remove --show-upgraded \
			--allow-downgrades --allow-change-held-packages \
			--no-install-recommends \
			--option DPkg::Options::="--force-confdef" \
			--option DPkg::Options::="--force-confold" \
			openmediavault

		;;
		"${commands[1]}")
			if pkg_installed openmediavault 2>/dev/null; then
				DEBIAN_FRONTEND=noninteractive pkg_remove openmediavault
			fi
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
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_omv,feature"]} ${commands[3]}
		;;
	esac
}
