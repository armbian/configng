module_options+=(
	["get_user_continue_secure,author"]="Joey Turner"
	["get_user_continue_secure,ref_link"]=""
	["get_user_continue_secure,feature"]="get_user_continue_secure"
	["get_user_continue_secure,desc"]="Secure version of get_user_continue"
	["get_user_continue_secure,example"]="get_user_continue_secure 'Do you wish to continue?' process_input"
	["get_user_continue_secure,doc_link"]=""
	["get_user_continue_secure,status"]="review"
)
#
# Secure version of get_user_continue
# 
function get_user_continue_secure() {
	local message="$1"
	local next_action="$2"

	# Define a list of allowed functions
	local allowed_functions=("process_input" "other_function")
	# Check if the next_action is in the list of allowed functions
	found=0
	for func in "${allowed_functions[@]}"; do
		if [[ "$func" == "$next_action" ]]; then
			found=1
			break
		fi
	done

	if [[ "$found" -eq 1 ]]; then
		if $($DIALOG --yesno "$message" 10 80 3>&1 1>&2 2>&3); then
			$next_action
		else
			$next_action "No"
		fi
	else
		echo "Error: Invalid function"

		exit 1
	fi
}

