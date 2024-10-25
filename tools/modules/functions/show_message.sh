module_options+=(
	["show_message,author"]="Joey Turner"
	["show_message,ref_link"]=""
	["show_message,feature"]="show_message"
	["show_message,desc"]="Display a message box"
	["show_message,example"]="show_message <<< 'hello world' "
	["show_message,doc_link"]=""
	["show_message,status"]="Active"
)
#
# Function to display a message box
#
function show_message() {
	# Read the input from the pipe
	input=$(cat)

	# Display the "OK" message box with the input data
	if [[ $DIALOG != "bash" ]]; then
		$DIALOG --title "$TITLE" --msgbox "$input" 0 0
	else
		echo -e "$input"
		read -p -r "Press [Enter] to continue..."
	fi
}

