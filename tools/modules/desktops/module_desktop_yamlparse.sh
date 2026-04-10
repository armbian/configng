module_options+=(
	["module_desktop_yamlparse,author"]="@igorpecovnik"
	["module_desktop_yamlparse,feature"]="module_desktop_yamlparse"
	["module_desktop_yamlparse,desc"]="Parse desktop YAML definitions"
	["module_desktop_yamlparse,example"]="module_desktop_yamlparse xfce"
	["module_desktop_yamlparse,status"]="Active"
	["module_desktop_yamlparse,arch"]="arm64 amd64 armhf riscv64"
)

#
# Parse YAML desktop definition via Python helper
# Usage: module_desktop_yamlparse <de_name> [arch] [release]
# Sets: DESKTOP_PACKAGES, DESKTOP_PACKAGES_UNINSTALL, DESKTOP_PRIMARY_PKG,
#       DESKTOP_DM, DESKTOP_STATUS, DESKTOP_SUPPORTED, DESKTOP_DESC,
#       DESKTOP_REPO_URL, DESKTOP_REPO_KEY_URL, DESKTOP_REPO_KEYRING
#
function module_desktop_yamlparse() {
	local de="$1"
	local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
	local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"
	local arch="${2:-$(dpkg --print-architecture)}"
	local release="${3:-$DISTROID}"

	case "$de" in
		help|"")
			echo "Usage: module_desktop_yamlparse <de_name> [arch] [release]"
			echo ""
			echo "Parse a desktop YAML definition and set package variables."
			echo "Variables set: DESKTOP_PACKAGES, DESKTOP_PACKAGES_UNINSTALL,"
			echo "  DESKTOP_PRIMARY_PKG, DESKTOP_DM, DESKTOP_STATUS,"
			echo "  DESKTOP_SUPPORTED, DESKTOP_DESC, DESKTOP_REPO_*"
			echo ""
			echo "Examples:"
			echo "  module_desktop_yamlparse xfce"
			echo "  module_desktop_yamlparse kde-neon arm64 noble"
			return 0
		;;
		*)
			if [[ ! -f "$parser" ]]; then
				echo "Error: YAML parser not found at $parser" >&2
				return 1
			fi

			# reset variables
			DESKTOP_PACKAGES=""
			DESKTOP_PACKAGES_UNINSTALL=""
			DESKTOP_PRIMARY_PKG=""
			DESKTOP_DM=""
			DESKTOP_STATUS=""
			DESKTOP_SUPPORTED=""
			DESKTOP_DESC=""
			DESKTOP_REPO_URL=""
			DESKTOP_REPO_KEY_URL=""
			DESKTOP_REPO_KEYRING=""

			local _output
			_output=$(python3 "$parser" "$yaml_dir" "$de" "$release" "$arch" 2>&1) || {
				echo "Error: failed to parse YAML for '${de}': ${_output}" >&2
				return 1
			}
			eval "$_output" || return 1
		;;
	esac
}

#
# List available desktops via Python helper
# Usage: module_desktop_yamlparse_list [arch] [release]
#
function module_desktop_yamlparse_list() {
	local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
	local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"
	local arch="${1:-$(dpkg --print-architecture)}"
	local release="${2:-$DISTROID}"

	python3 "$parser" "$yaml_dir" "--list" "$release" "$arch"
}
