module_options+=(
	["init_vars,author"]="@tearran"
	["init_vars,feature"]="init_vars"
	["init_vars,example"]="help show"
	["init_vars,desc"]="Gther systme info store varibles"
	["init_vars,status"]="Active"
	["init_vars,group"]="Development"
)
# ./init_vars.sh - Armbian Config V2 module

init_vars() {
	case "${1:-}" in
		show)
			_init_vars_main
			_show_vars
			;;
		help|-h|--help)
			_about_init_vars
			;;
		"")
			_init_vars_main
			;;
		*)
			echo "Unknown command: ${1}"
			_about_init_vars
			return 1
	esac
}

_init_vars_main() {
	# ==== PROJECT IDENTITY ====
	PROJECT_NAME="configng-tools"
	PROJECT_VERSION="0.0.0"
	DIALOG="${DIALOG:-whiptail}"
	# ==== OS INFORMATION ====
	OS_RELEASE="/etc/armbian-release"
	OS_INFO="/etc/os-release"

	# Source OS info if readable (non-fatal)
	# shellcheck disable=SC1091
	[[ -r "$OS_INFO" ]] && source "$OS_INFO" || true
	# shellcheck disable=SC1091
	[[ -r "$OS_RELEASE" ]] && source "$OS_RELEASE" || true

	# ==== TUI VARIABLES ====
	BACKTITLE="${BACKTITLE:-"Contribute: https://github.com/${PROJECT_NAME}"}"
	TITLE="${TITLE:-"${VENDOR:-${PROJECT_NAME}} configuration utility"}"

	# ==== SYSTEM INFORMATION ====
	# Legacy / runtime variables (OS info)
	DISTRO="${ID:-Unknown}"
	DISTROID="${VERSION_CODENAME:-Unknown}"
	ARCHID=$(uname -m)
	KERNELID="$(uname -r)"
	HOSTNAME="$(hostname)"

	# ==== NETWORK INFORMATION ====
	# Detect default IPv4 adapter (best-effort)
	DEFAULT_ADAPTER="$(ip -4 route ls 2>/dev/null | awk '/default/ {
		for (i=1;i<=NF;i++) if ($i == "dev") print $(i+1)
		exit
	}' || echo "")"

	# Get IPv4 address for the adapter (if present)
	LOCALIPADD=""
	[[ -n "${DEFAULT_ADAPTER:-}" ]] && LOCALIPADD="$(ip -4 addr show dev "${DEFAULT_ADAPTER}" 2>/dev/null | 
				awk '/inet/ {print $2}' | cut -d'/' -f1 | head -n 1 || echo "")"

	# Derive local subnet (best-effort)
	LOCALSUBNET=""
	[[ -n "${LOCALIPADD:-}" ]] && LOCALSUBNET="$(echo "${LOCALIPADD}" | cut -d"." -f1-3).0/24"

	# Get default gateway
	DEFAULT_GATEWAY="$(ip -4 route list exact 0.0.0.0/0 2>/dev/null | 
					awk '{print $3}' || echo "")"

	# Check internet connectivity with timeout
	HAS_INTERNET="no"
	ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && HAS_INTERNET="yes"

	# Get DNS servers as a string
	DNS_SERVERS="$(grep -v '^#' /etc/resolv.conf 2>/dev/null | 
				grep nameserver | awk '{print $2}' | paste -sd "," || echo "")"

}

_show_vars() {
	# Output variables for sourcing
	echo "# Generated environment variables - $(date)"
	echo "PROJECT_NAME=\"${PROJECT_NAME}\""
	echo "PROJECT_VERSION=\"${PROJECT_VERSION}\""
	echo "BACKTITLE=\"${BACKTITLE}\""
	echo "TITLE=\"${TITLE}\""
	echo "DISTRO=\"${DISTRO}\""
	echo "DISTROID=\"${DISTROID}\""
	echo "ARCHID=\"${ARCHID}\""
	echo "KERNELID=\"${KERNELID}\""
	echo "HOSTNAME=\"${HOSTNAME}\""
	echo "DEFAULT_ADAPTER=\"${DEFAULT_ADAPTER}\""
	echo "LOCALIPADD=\"${LOCALIPADD}\""
	echo "LOCALSUBNET=\"${LOCALSUBNET}\""
	echo "DEFAULT_GATEWAY=\"${DEFAULT_GATEWAY}\""
	echo "HAS_INTERNET=\"${HAS_INTERNET}\""
	echo "DNS_SERVERS=\"${DNS_SERVERS}\""
	echo "OS_RELEASE=\"${OS_RELEASE}\""
	echo "OS_INFO=\"${OS_INFO}\""
	echo "DIALOG=\"${DIALOG}\""
	
	# Echo OS and Armbian release variables in a way that makes them sourceable
	echo "# OS release variables from $OS_INFO"
	if [[ -r "$OS_INFO" ]]; then
		grep -v "^#" "$OS_INFO" | grep "=" | while IFS= read -r line; do
			varname=$(echo "$line" | cut -d= -f1)
			# Use parameter expansion to get the value
			echo "$varname=\"${!varname:-}\""
		done
	else
		echo "# $OS_INFO not readable"
	fi
	
	echo "# Armbian release variables from $OS_RELEASE"
	if [[ -r "$OS_RELEASE" ]]; then
		grep -v "^#" "$OS_RELEASE" | grep "=" | while IFS= read -r line; do
			varname=$(echo "$line" | cut -d= -f1)
			# Use parameter expansion to get the value
			echo "$varname=\"${!varname:-}\""
		done
	else
		echo "# $OS_RELEASE not readable"
	fi
}

_about_init_vars() {
	cat <<EOF
Usage: init_vars <command> [options]

Commands:
	show        - Show all environment variables in sourceable format
	help        - Show this help message

Examples:
	# Initialize environment variables without display
	init_vars

	# Show all environment variables
	init_vars show

	# Source variables directly into current shell
	. <(init_vars show)

	# Evaluate variables in current shell
	eval "\$(init_vars show)"

	# Show help
	init_vars help

Notes:
	- When sourced (not run directly), variables are set but not displayed
	- Includes all variables from /etc/os-release and /etc/armbian-release
	- Intended for use with the config-v2 menu and scripting

EOF
}

### START ./init_vars.sh - Armbian Config V2 test entrypoint

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# --- Capture and assert help output ---
	help_output="$(init_vars help)"
	echo "$help_output" | grep -q "Usage: init_vars" || {
		echo "fail: Help output does not contain expected usage string"
		echo "test complete"
		exit 1
	}
	# --- end assertion ---
	init_vars "$@"

fi

### END ./init_vars.sh - Armbian Config V2 test entrypoint
