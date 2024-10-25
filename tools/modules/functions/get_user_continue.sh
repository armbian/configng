module_options+=(
	["get_user_continue,author"]="Joey Turner"
	["get_user_continue,ref_link"]=""
	["get_user_continue,feature"]="get_user_continue"
	["get_user_continue,desc"]="Display a Yes/No dialog box and process continue/exit"
	["get_user_continue,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["get_user_continue,doc_link"]=""
	["get_user_continue,status"]="Active"
)
#
# Function to display a Yes/No dialog box
#
function get_user_continue() {
	local message="$1"
	local next_action="$2"

	if $($DIALOG --yesno "$message" 15 80 3>&1 1>&2 2>&3); then
		$next_action
	else
		$next_action "No"
	fi
}

menu_options+=(
	["process_input(,author"]="Joey Turner"
	["process_input(,ref_link"]=""
	["process_input(,feature"]="process_input"
	["process_input(,desc"]="used to process the user's choice paired with process_input("
	["process_input(,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["process_input(,status"]="Active"
	["process_input(,doc_link"]=""
)
#
# Function to process the user's choice paired with get_user_continue
#
function process_input() {
	local input="$1"
	if [ "$input" = "No" ]; then
		# user canceled
		echo "User canceled. exiting"
		exit 0
	fi
}

