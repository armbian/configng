
module_options+=(
    ["check_os_status,author"]="@Tearran"
    ["check_os_status,feature"]="check_os_status"
    ["check_os_status,example"]="help"
    ["check_os_status,desc"]="Check if the current OS is supported based on /etc/armbian-distribution-status"
    ["check_os_status,status"]="Active"
)

function check_os_status() {
	case "$1" in
		help)
			echo "Usage: check_os_status"
			echo "This function checks if the current OS is supported based on /etc/armbian-distribution-status."
			echo "It retrieves the current OS distribution and checks if it is listed as supported in the specified file."
			;;
		*)
			FILE="/etc/armbian-distribution-status"

			# Detect the current OS distribution codename
			CURRENT_OS=$(lsb_release -cs 2>/dev/null || grep "VERSION=" /etc/os-release | grep -oP '(?<=\().*(?=\))')

			# Ensure OS detection succeeded
			if [[ -z "$CURRENT_OS" ]]; then
			echo "Error: Unable to detect the current OS distribution."
			exit 1
			fi

			# Check if the OS is listed as supported in the file
			if grep -qE "^${CURRENT_OS}=.*supported" "$FILE"; then
			echo "The current OS ($CURRENT_OS) is supported."

			else
			BACKTITLE="Error: The current OS ($CURRENT_OS) is not supported or not listed"
			set_colors 1
			get_user_continue "Error: The current OS ($CURRENT_OS) is not supported or not listed" process_input
			#exit 1
			fi

		;;
    	esac
}
