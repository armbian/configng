
module_options+=(
	["check_os_status,author"]="@Tearran"
	["check_os_status,ref_link"]=""
	["check_os_status,feature"]="check_os_status"
	["check_os_status,desc"]="Check if the current OS distribution is supported"
	["check_os_status,example"]="check_os_status"
	["check_os_status,doc_link"]=""
	["check_os_status,status"]="Active"
)

#
# Check if current OS distribution is officially supported
# Shows a warning and prompts for confirmation if OS is not in the supported list
# Usage: check_distro_status
#
function check_distro_status() {
	case "$1" in
		help)
			echo "Usage: check_os_status"
			echo "This function checks if the current OS is supported based on /etc/armbian-distribution-status."
			echo "It retrieves the current OS distribution and checks if it is listed as supported in the specified file."
		;;
		*)

			# Ensure OS detection succeeded
			if [[ -z "$DISTROID" ]]; then
				dialog_msgbox "OS Detection Error" \
					"Unable to detect the current OS distribution.\n\nPlease ensure you're running on a supported system." \
					8 60
				return 1
			fi

			# Check if the OS is listed as supported in the DISTRO_STATUS
			if grep -qE "^${DISTROID}=.*supported" "$DISTRO_STATUS" 2> /dev/null; then
				# OS is supported - return silently
				return 0
			fi

			# OS not supported - show warning and continue after a brief pause
			if [[ "$DIALOG" == "read" ]]; then
				echo "Warning: The current OS ($DISTROID) is not officially supported."
				echo "The tool may still work, but issues may not be addressed by maintainers."
				echo "Continuing in 3 seconds..."
				sleep 3
			else
				local warning_msg="Warning: The current OS ($DISTROID) is not officially supported.\n\n"
				warning_msg+="The tool might still work, but issues may not be accepted or\n"
				warning_msg+="addressed by the maintainers. You are welcome to contribute fixes."

				dialog_msgbox "OS Support Warning" "$warning_msg" 10 60
				sleep 3
			fi
		;;
	esac
}
