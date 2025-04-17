module_options+=(
	["_software_help_module,author"]="@Tearran"
	["_software_help_module,maintainer"]="@Tearran"
	["_software_help_module,feature"]="_software_help_module"
	["_software_help_module,example"]="<Title> <Module Name> <For Invalid command (true)>"
	["_software_help_module,desc"]="Imaging Editor installation and management (gimp inkscape)."
	["_software_help_module,status"]="Active"
	["_software_help_module,group"]="Internet"
	["_software_help_module,arch"]="x86-64 arm64 armhf"
)
#
_software_help_module(){


	local title="$1"
	local self="$2"

	# Check if title or self is missing
	if [[ -z "$title" || "$self" == "" ]]; then
		echo "Error: Missing inputs for function. Provide both <Title> and <Module Name>."
		echo -e "Example: ./bin/armbian-config --api _software_help_module \"Samba services\" module_samba"
		return 1
	fi
	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["$self,example"]}"

	[[ "$3" == "true" ]] && echo "Invalid command. Try one of: ${module_options["$self,example"]}"
	echo -e "\nUsage: $self <command>"
	echo -e "Commands: ${module_options["$self,example"]}"
	echo "Available commands:"
	# Loop through all commands (starting from index 1)
	for ((i = 1; i < ${#commands[@]}; i++)); do
		printf "\t%-10s - %s %s\n" "${commands[i]}" "${commands[i]}" "$title"
		#echo -e "\t${commands[i]}\t- Manage ${commands[i]} $title."
	done
	echo

}
