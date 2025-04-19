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
# Scaffold for app with specific, single, dummy or other candidates.
function _checklist_browsers() {
	local title="Browsers"

	# List browser packages to manage
	# be sure to use full apt name some may or may not have dumy packege names
	# example `apt-cache search firefox`` will show the package is firefox-esr
	local browser_packages=(
		"firefox-esr"
		"chromium"
		"lynx"
		"google-chrome"
	)


	if [[ -n "$1" && "$1" != "test" ]]; then
		# Clear the browser_packages array
		browser_packages=("$@")
	fi
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
