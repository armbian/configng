
module_options+=(
	["module_see_ping,author"]="@Tearran"
	["module_see_ping,ref_link"]="https://github.com/Tearran/configng/blob/main/config.ng.functions.sh#632"
	["module_see_ping,feature"]="see_ping"
	["module_see_ping,desc"]="Check the internet connection with fallback DNS"
	["module_see_ping,example"]="see_ping"
	["module_see_ping,doc_link"]=""
	["module_see_ping,status"]="review"
)
#
# Function to check the internet connection
#
function module_see_ping() {
	# List of servers to ping
	servers=("1.1.1.1" "8.8.8.8")

	# Check for internet connection
	for server in "${servers[@]}"; do
		if ping -q -c 1 -W 1 $server > /dev/null; then
			echo "Internet connection: Present"
			break
		else
			echo "Internet connection: Failed"
			sleep 1
		fi
	done

	if [[ $? -ne 0 ]]; then
		read -n -r 1 -s -p "Warning: Configuration cannot work properly without a working internet connection. \
		Press CTRL C to stop or any key to ignore and continue."
	fi

}
