
module_options+=(
	["check_os_status,author"]="@Tearran"
	["check_os_status,feature"]="check_os_status"
	["check_os_status,example"]="help"
	["check_os_status,desc"]="Check if the current OS is supported based on /etc/armbian-distribution-status"
	["check_os_status,status"]="Active"
)

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
			echo "Error: Unable to detect the current OS distribution."
			exit 1
			fi

			# Check if the OS is listed as supported in the DISTRO_STATUS
			if grep -qE "^${DISTROID}=.*supported" "$DISTRO_STATUS"; then
			echo "The current OS ($DISTROID) is supported."

			else
			BACKTITLE="Warning: The current OS ($DISTROID) is not supported or not listed"
			set_colors 1
			get_user_continue "Warning:
			The current OS ($DISTROID) is not a supported distribution:
			while the tool might still work well,
			please be aware that issues may not be addressed by the maintainers.
			You are welcome to contribute fixes for any problems you encounter.

			Would you like to continue?
			" process_input
			fi
		;;
	esac
}
