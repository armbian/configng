module_options+=(
	["show_menu,author"]="Joey Turner"
	["show_menu,ref_link"]=""
	["show_menu,feature"]="show_menu"
	["show_menu,desc"]="Display a menu from pipe"
	["show_menu,example"]="show_menu <<< armbianmonitor -h  ; "
	["show_menu,doc_link"]=""
	["show_menu,status"]="Active"
)
#
#
#
function show_menu() {

	# Get the input and convert it into an array of options
	inpu_raw=$(cat)
	# Remove the lines before -h
	input=$(echo "$inpu_raw" | sed 's/-\([a-zA-Z]\)/\1/' | grep '^  [a-zA-Z] ' | grep -v '\[')
	options=()
	while read -r line; do
		package=$(echo "$line" | awk '{print $1}')
		description=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
		options+=("$package" "$description")
	done <<< "$input"

	# Display the menu and get the user's choice
	[[ $DIALOG != "bash" ]] && choice=$($DIALOG --title "$TITLE" --menu "Choose an option:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)

	# Check if the user made a choice
	if [ $? -eq 0 ]; then
		echo "$choice"
	else
		exit 0
	fi

}

