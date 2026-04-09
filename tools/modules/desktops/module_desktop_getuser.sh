module_options+=(
	["module_desktop_getuser,author"]="@igorpecovnik"
	["module_desktop_getuser,feature"]="module_desktop_getuser"
	["module_desktop_getuser,desc"]="Detect first regular user for desktop setup"
	["module_desktop_getuser,example"]="module_desktop_getuser"
	["module_desktop_getuser,status"]="Active"
	["module_desktop_getuser,arch"]="arm64 amd64 armhf riscv64"
)

#
# Detect first regular user (UID >= 1000) with a login shell
# Usage: module_desktop_getuser
# Returns: username on stdout, exit 1 if none found
#
function module_desktop_getuser() {
	case "$1" in
		help)
			echo "Usage: module_desktop_getuser"
			echo ""
			echo "Detect the first regular user (UID >= 1000) with a login shell."
			echo "Used for desktop auto-login, group membership, and skel setup."
			echo "Prefers SUDO_USER if set and not root."
			return 0
		;;
		*)
			local user=""
			if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
				user="$SUDO_USER"
			else
				user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /nologin|false/ {print $1; exit}' /etc/passwd)
			fi
			if [[ -z "$user" ]]; then
				echo "Error: no regular user found. Create a non-root user first." >&2
				return 1
			fi
			echo "$user"
		;;
	esac
}
