module_options+=(
	["module_desktop_repo,author"]="@igorpecovnik"
	["module_desktop_repo,feature"]="module_desktop_repo"
	["module_desktop_repo,desc"]="Set up custom APT repository for desktop environments"
	["module_desktop_repo,example"]="module_desktop_repo kde-neon"
	["module_desktop_repo,status"]="Active"
	["module_desktop_repo,arch"]="arm64 amd64 armhf riscv64"
)

#
# Set up custom APT repo if desktop requires one
# Usage: module_desktop_repo <de_name>
# Requires DESKTOP_REPO_URL, DESKTOP_REPO_KEY_URL, DESKTOP_REPO_KEYRING
# to be set (via module_desktop_yamlparse)
#
function module_desktop_repo() {
	local de="$1"

	case "$de" in
		help|"")
			echo "Usage: module_desktop_repo <de_name>"
			echo ""
			echo "Set up a custom APT repository for a desktop that requires one."
			echo "Must be called after module_desktop_yamlparse to set repo variables."
			echo ""
			echo "Examples:"
			echo "  module_desktop_yamlparse kde-neon"
			echo "  module_desktop_repo kde-neon"
			return 0
		;;
		*)
			# sanitize de name for safe use in file paths
			if [[ ! "$de" =~ ^[a-zA-Z0-9._-]+$ ]]; then
				echo "Error: invalid desktop name '${de}'" >&2
				return 1
			fi

			if [[ -n "$DESKTOP_REPO_URL" && -n "$DESKTOP_REPO_KEY_URL" && -n "$DESKTOP_REPO_KEYRING" ]]; then
				echo "Setting up repository for ${de}..." >&2

				# download and verify GPG key
				if ! curl -fsSL "$DESKTOP_REPO_KEY_URL" | gpg --yes --dearmor -o "$DESKTOP_REPO_KEYRING" 2>/dev/null; then
					echo "Error: failed to download GPG key from $DESKTOP_REPO_KEY_URL" >&2
					return 1
				fi

				if [[ ! -s "$DESKTOP_REPO_KEYRING" ]]; then
					echo "Error: GPG keyring is empty at $DESKTOP_REPO_KEYRING" >&2
					rm -f "$DESKTOP_REPO_KEYRING"
					return 1
				fi

				# add source
				cat > "/etc/apt/sources.list.d/${de}.list" <<- EOF
				deb [signed-by=${DESKTOP_REPO_KEYRING}] ${DESKTOP_REPO_URL} ${DISTROID} main
				EOF
			fi
		;;
	esac
}
