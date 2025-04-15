module_options+=(
	["_checklist_proftpd,author"]="@Tearran"
	["_checklist_proftpd,maintainer"]="@Tearran"
	["_checklist_proftpd,feature"]="_checklist_proftpd"
	["_checklist_proftpd,example"]=""
	["_checklist_proftpd,desc"]="Dynamic ProFTPD package management with install/remove toggle."
	["_checklist_proftpd,status"]="Active"
	["_checklist_proftpd,group"]="Internet"
	["_checklist_proftpd,arch"]="x86-64 arm64 armhf"
)

function _checklist_proftpd() {
	local title="ProFTPD"

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["_checklist_proftpd,example"]}"

	## Dynamically manage ProFTPD packages
	echo "Fetching ProFTPD-related packages..."
	local package_list
	# get a list of all packages
	package_list=$(apt-cache search proftpd | awk '{print $1}')

	# Prepare checklist options dynamically
	local checklist_options=()
	for package in $package_list; do
		if dpkg -l | grep -q "^ii.*$package"; then
			checklist_options+=("$package" "Installed" "ON")
		else
			checklist_options+=("$package" "Not installed" "OFF")
		fi
	done

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]

}


module_options+=(
	["_checklist_browsers,author"]="@Tearran"
	["_checklist_browsers,maintainer"]="@Tearran"
	["_checklist_browsers,feature"]="_checklist_browsers"
	["_checklist_browsers,example"]=""
	["_checklist_browsers,desc"]="Browser installation and management (Firefox-ESR and Chromium and more)."
	["_checklist_browsers,status"]="Active"
	["_checklist_browsers,group"]="Internet"
	["_checklist_browsers,arch"]="x86-64 arm64 armhf"
)

function _checklist_browsers() {
	local title="Browsers"

	# List of base browser packages to manage
	local browser_packages=(
		"firefox-esr"
		"chromium"
		"lynx"
	)

	# Manage browser installation/removal
	echo "Fetching browser package details..."

	# Prepare checklist options dynamically with descriptions
	local checklist_options=()
	for base_package in "${browser_packages[@]}"; do
		# Find the main package and exclude auxiliary or irrelevant ones
		local main_package
		main_package=$(apt-cache search "^${base_package}$" | awk -F' - ' '{print $1 " - " $2}')

		# Check if the main package exists and fetch its description
		if [[ -n "$main_package" ]]; then
			local package_name package_description
			package_name=$(echo "$main_package" | awk -F' - ' '{print $1}')
			package_description=$(echo "$main_package" | awk -F' - ' '{print $2}')

			# Check if the package is installed and set its state
			if dpkg -l | grep -q "^ii.*$package_name"; then
				checklist_options+=("$package_name" "$package_description" "ON")
			else
				checklist_options+=("$package_name" "$package_description" "OFF")
			fi
		fi
	done

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]

}

module_options+=(
	["_checklist_editors,author"]="@Tearran"
	["_checklist_editors,maintainer"]="@Tearran"
	["_checklist_editors,feature"]="_checklist_editors"
	["_checklist_editors,example"]=""
	["_checklist_editors,desc"]="Editor installation and management (vscodum notpadqq and more)."
	["_checklist_editors,status"]="Active"
	["_checklist_editors,group"]="Internet"
	["_checklist_editors,arch"]="x86-64 arm64 armhf"
)
#
function _checklist_eitors() {
	local title="editors"

	# List of base browser packages to manage
	local _packages=(
		"nano"
		"code"
		"codium"
		"notepadqq"
	)

	# Manage browser installation/removal
	echo "Fetching $title package details..."

	# Prepare checklist options dynamically with descriptions
	local checklist_options=()
	for base_package in "${_packages[@]}"; do
		# Find the main package and exclude auxiliary or irrelevant ones
		local main_package
		main_package=$(apt-cache search "^${base_package}$" | awk -F' - ' '{print $1 " - " $2}')

		# Check if the main package exists and fetch its description
		if [[ -n "$main_package" ]]; then
			local package_name package_description
			package_name=$(echo "$main_package" | awk -F' - ' '{print $1}')
			package_description=$(echo "$main_package" | awk -F' - ' '{print $2}')

			# Check if the package is installed and set its state
			if dpkg -l | grep -q "^ii.*$package_name"; then
				checklist_options+=("$package_name" "$package_description" "ON")
			else
				checklist_options+=("$package_name" "$package_description" "OFF")
			fi
		fi
	done

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]

}
