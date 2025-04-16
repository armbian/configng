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
# Presents an interactive checklist for installing or removing ProFTPD-related packages.
#
# Dynamically retrieves all available ProFTPD packages, checks their installation status, and builds a checklist for user selection. Invokes the package selection handler to allow users to install or remove selected packages.
#
# Returns:
#
# * 0 if packages are found and the checklist is presented.
# * 1 if no ProFTPD-related packages are found.
#
# Example:
#
# ```bash
# _checklist_proftpd
# ```
function _checklist_proftpd() {
	local title="proftpd"

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["_checklist_proftpd,example"]}"

	## Dynamically manage ProFTPD packages
	echo "Fetching $title-related packages..."
	local package_list
	# get a list of all packages
	package_list=$(apt-cache search "$title" | awk '{print $1}')
	if [[ -z "$package_list" ]]; then
		echo "No $title-related packages found."
		return 1
	fi

	# Prepare checklist options dynamically
	local checklist_options=()
	for package in $package_list; do
		if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "^install ok installed$"; then
			checklist_options+=("$package" "Installed" "ON")
		else
			checklist_options+=("$package" "Not installed" "OFF")
		fi
	done

	process_package_selection "$title" "Select $title packages to install/remove:" checklist_options[@]
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
# Presents an interactive checklist for managing installation or removal of common browser packages.
#
# Fetches a predefined list of browser packages, retrieves their descriptions and installation status,
# and builds a checklist for user selection. If no browser packages are found, prints a message and returns an error.
#
# Returns:
#
# * 0 if the checklist is presented successfully.
# * 1 if no browser packages are found.
#
# Example:
#
# ```bash
# _checklist_browsers
# ```
function _checklist_browsers() {
	local title="Browsers"

	# List of base browser packages to manage
	#
	local browser_packages=(
		"firefox-esr"
		"chromium"
		"lynx"
		"google-chrome"
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
			if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "^install ok installed$"; then
				checklist_options+=("$package_name" "$package_description" "ON")
			else
				checklist_options+=("$package_name" "$package_description" "OFF")
			fi
		fi
	done
	if [[ ${#checklist_options[@]} -eq 0 ]]; then
		echo "No $title packages found."
		return 1
	fi

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]
}

module_options+=(
	["_checklist_editors,author"]="@Tearran"
	["_checklist_editors,maintainer"]="@Tearran"
	["_checklist_editors,feature"]="_checklist_editors"
	["_checklist_editors,example"]="nano code codium notepadqq"
	["_checklist_editors,desc"]="Editor installation and management (codium notepadqq and more)."
	["_checklist_editors,status"]="Active"
	["_checklist_editors,group"]="Internet"
	["_checklist_editors,arch"]="x86-64 arm64 armhf"
)
# Presents an interactive checklist for installing or removing editor packages such as nano, code, codium, and notepadqq.
#
# Fetches a predefined list of editor package names, retrieves their descriptions and installation status, and builds a checklist for user selection. If no matching packages are found, prints a message and returns an error.
#
# Returns:
#
# * 0 if at least one package is found and the checklist is displayed.
# * 1 if no editor packages are found.
#
# Example:
#
#   _checklist_editors
#   # Displays a checklist of available editor packages for installation or removal.
function _checklist_editors() {
	local title="Editors"
	local self="${module_options["_checklist_editors,feature"]}"
	local _packages
	IFS=' ' read -r -a _packages <<< "${module_options["$self,example"]}"

	# Manage editor installation/removal
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
			if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "^install ok installed$"; then
				checklist_options+=("$package_name" "$package_description" "ON")
			else
				checklist_options+=("$package_name" "$package_description" "OFF")
			fi
		fi
	done
	if [[ ${#checklist_options[@]} -eq 0 ]]; then
		echo "No $title packages found."
		return 1
	fi

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]
}

module_options+=(
	["_checklist_imaging,author"]="@Tearran"
	["_checklist_imaging,maintainer"]="@Tearran"
	["_checklist_imaging,feature"]="_checklist_imaging"
	["_checklist_imaging,example"]="inkscape gimp"
	["_checklist_imaging,desc"]="Imaging Editor installation and management (gimp inkscape)."
	["_checklist_imaging,status"]="Active"
	["_checklist_imaging,group"]="Internet"
	["_checklist_imaging,arch"]="x86-64 arm64 armhf"
)
# Presents an interactive checklist for installing or removing imaging editor packages (e.g., Inkscape, GIMP).
#
# Fetches a predefined list of imaging editor package names from module metadata, retrieves their descriptions and installation status, and builds a checklist for user selection. If no relevant packages are found, prints a message and returns an error.
#
# Returns:
#
# * 0 if at least one package is found and the checklist is presented.
# * 1 if no imaging editor packages are found.
#
# Example:
#
# ```bash
# _checklist_imaging
# ```
function _checklist_imaging() {
	local title="Imaging"
	local self="${module_options["_checklist_imaging,feature"]}"
	local _packages
	IFS=' ' read -r -a _packages <<< "${module_options["$self,example"]}"

	# Manage editor installation/removal
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
			if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "^install ok installed$"; then
				checklist_options+=("$package_name" "$package_description" "ON")
			else
				checklist_options+=("$package_name" "$package_description" "OFF")
			fi
		fi
	done
	if [[ ${#checklist_options[@]} -eq 0 ]]; then
		echo "No $title packages found."
		return 1
	fi

	process_package_selection "$title" "Select packages to install/remove:" checklist_options[@]
}

module_options+=(
	["module_aptwizard,author"]="@Tearran"
	["module_aptwizard,maintainer"]="@Tearran"
	["module_aptwizard,feature"]="module_aptwizard"
	["module_aptwizard,example"]="help Editors Browsers Proftpd Imaging"
	["module_aptwizard,desc"]="Apt wizard TUI deb packages similar to softy"
	["module_aptwizard,status"]="Active"
	["module_aptwizard,doc_link"]=""
	["module_aptwizard,group"]="aptwizard"
	["module_aptwizard,port"]=""
	["module_aptwizard,arch"]="x86-64 arm64 armhf"
)
# Dispatches aptwizard module commands to manage software packages by category.
#
# Acts as the main entry point for the aptwizard module, routing user commands to interactive checklists for managing editors, browsers, ProFTPD, or imaging packages. Also provides usage information and available commands.
#
# Arguments:
#
# * The command to execute (e.g., help, Editors, Browsers, Proftpd, Imaging).
#
# Outputs:
#
# * Prints usage information, available commands, or error messages to STDOUT.
#
# Example:
#
#   module_aptwizard help
#   module_aptwizard Editors
#   module_aptwizard Browsers
function module_aptwizard() {
	local title="Packages"
	local self="${module_options["module_aptwizard,feature"]}"
	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["$self,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: $self <command>"
			echo -e "Commands: ${module_options["$self,example"]}"
			echo "Available commands:"
			# Loop through all commands (starting from index 1)
			for ((i = 1; i < ${#commands[@]}; i++)); do
				printf "\t%-10s - Manage %s %s\n" "${commands[i]}" "${commands[i]}" "$title"
				#echo -e "\t${commands[i]}\t- Manage ${commands[i]} $title."
			done
			echo
		;;
		"${commands[1]}")
			_checklist_editors
		;;
		"${commands[2]}")
			_checklist_browsers
		;;

		"${commands[3]}")
			_checklist_proftpd
		;;
		"${commands[4]}")
			_checklist_imaging
		;;
		*)
			echo "Invalid command. Try one of: ${module_options["$self,example"]}"

		;;
	esac
}
