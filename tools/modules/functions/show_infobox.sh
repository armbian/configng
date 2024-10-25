module_options+=(
	["show_infobox,author"]="Joey Turner"
	["show_infobox,ref_link"]=""
	["show_infobox,feature"]="show_infobox"
	["show_infobox,desc"]="pipeline strings to an infobox "
	["show_infobox,example"]="show_infobox <<< 'hello world' ; "
	["show_infobox,doc_link"]=""
	["show_infobox,status"]="Active"
)
#
# Function to display an infobox with a message
#
function show_infobox() {
	export TERM=ansi
	local input
	local BACKTITLE="$BACKTITLE"
	local -a buffer # Declare buffer as an array
	if [ -p /dev/stdin ]; then
		while IFS= read -r line; do
			buffer+=("$line") # Add the line to the buffer
			# If the buffer has more than 10 lines, remove the oldest line
			if ((${#buffer[@]} > 18)); then
				buffer=("${buffer[@]:1}")
			fi
			# Display the lines in the buffer in the infobox

			TERM=ansi $DIALOG --title "$TITLE" --infobox "$(printf "%s
" "${buffer[@]}")" 16 90
			sleep 0.5
		done
	else

		input="$1"
		TERM=ansi $DIALOG --title "$TITLE" --infobox "$input" 6 80
	fi
	echo -ne '[3J' # clear the screen
}

