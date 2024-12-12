

declare -A module_options
declare -A module_options
module_options+=(
	["module_template,author"]="@Tearran"
	["module_template,ref_link"]="@armbian"
	["module_template,feature"]="module_template"
	["module_template,example"]="install remove help"
	["module_template,desc"]="Example module unattended interface."
	["module_template,status"]="review"
	["module_template,doc_link"]="" # Add the doc_link key
	["module_template,group"]="Temp" # Add the group key
	["module_template,port"]="8080" # Add the port key
	["module_template,arch"]="aarch64" # Add the arch key
)

function module_template() {
	local title="test"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_template,example"]}"

	case "$1" in
		"${commands[0]}")
		echo "Installing $title..."
		# Installation logic here
		;;
		"${commands[1]}")
		echo "Removing $title..."
		# Removal logic here
		;;
		"${commands[2]}")
			echo -e "\nUsage: ${module_options["module_template,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_template,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
		${module_options["module_template,feature"]} ${commands[2]}
		;;
	esac
	}

# uncomment to test the module
module_template "$1"




