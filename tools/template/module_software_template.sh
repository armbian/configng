declare -A module_options
module_options+=(
	["module_template,author"]="@igorpecovnik @Tearran"
	["module_template,id"]="module_template"
	["module_template,description"]="Example module unattended interface."
	["module_template,group_id"]="Testing"
	["module_template,commands"]="menu install remove status"
	["module_template,options"]="foo bar"
	["module_template,args00"]="fighter strong"
	["module_template,args01"]="bell set"
	["module_template,status"]="review"
)

# Helper function to dynamically retrieve valid arguments for a given option
function get_dynamic_args() {
	local module_id="$1"
	local option="$2"
	local options=("${!3}")
	for i in "${!options[@]}"; do
		if [[ "${options[$i]}" == "$option" ]]; then
			local args_key="${module_id},args$(printf "%02d" "$i")"
			echo "${module_options[$args_key]}"
			return 0
		fi
	done
	echo "Unknown option '$option'. Valid options are: ${options[*]}" >&2
	return 1
}

function module_template() {
	local module_id="module_template"

	# Convert commands and options to arrays dynamically
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["${module_id},commands"]}"
	local options
	IFS=' ' read -r -a options <<< "${module_options["${module_id},options"]}"

	# Handle the commands
    	case "$1" in
        	"${commands[0]}")  # help command
			echo -e "\nUsage: ${module_options["module_template,id"]} <command>"
			echo -e "Commands:  ${module_options["module_template,commands"]}"
			echo -e "Arguments: ${module_options["module_template,options"]}"
			echo "Available commands:"
			for cmd in "${commands[@]:1}"; do  # Skip the first element (help)
				echo -e "\t$cmd\t- ${cmd^} $title."  # Capitalize first letter
			done
			echo
            	;;
        	"${commands[1]}")  # install command
			if [[ -n "$2" ]]; then
				# Retrieve valid arguments dynamically for the provided option
				local dynamic_args
				if dynamic_args=$(get_dynamic_args "$module_id" "$2" options[@]); then

					IFS=' ' read -r -a args_array <<< "$dynamic_args"

					# Validate the provided argument ($3)
					if [[ -n "$3" ]]; then
						if [[ " ${args_array[*]} " =~ " $3 " ]]; then
							echo "Processing: Command: '$1', Option: '$2', Argument: '$3'"

							# Trigger actions dynamically
							echo "Dynamic action for '$2' -> '$3'. Add your specific logic here."
						else
						echo "Invalid argument '$3' for option '$2'. Valid arguments are: ${args_array[*]}"
						fi
					else
						echo "No argument provided for option '$2'. Valid arguments are: ${args_array[*]}"
					fi
				fi
			else
			echo "No option provided. Valid options are: ${options[*]}"
			fi
            	;;
        	"${commands[2]}")  # remove command
            		echo "Removing module..."
           	;;
        	"${commands[3]}")  # status command
            		echo "Checking status..."
            	;;
        	*)
            		echo "Unknown command: '$1'. Valid commands are: ${commands[*]}"
            	;;
    	esac
}

# Test the module with arguments
module_template "$@"
