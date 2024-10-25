
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