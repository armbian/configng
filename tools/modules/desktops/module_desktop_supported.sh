module_options+=(
	["module_desktop_supported,author"]="@igorpecovnik"
	["module_desktop_supported,feature"]="module_desktop_supported"
	["module_desktop_supported,desc"]="Check if a desktop is supported on this system"
	["module_desktop_supported,example"]="module_desktop_supported xfce"
	["module_desktop_supported,status"]="Active"
	["module_desktop_supported,arch"]="arm64 amd64 armhf riscv64"
)

#
# Check if a desktop is supported on given arch/release
# Usage: module_desktop_supported <de_name> [arch] [release]
# Returns: 0 if supported, 1 if not
#
function module_desktop_supported() {
	local de="$1"
	local arch="${2:-$(dpkg --print-architecture)}"
	local release="${3:-$DISTROID}"

	case "$de" in
		help|"")
			echo "Usage: module_desktop_supported <de_name> [arch] [release]"
			echo ""
			echo "Check if a desktop environment is supported on a given architecture and release."
			echo "Returns exit code 0 if supported, 1 if not."
			echo ""
			echo "Examples:"
			echo "  module_desktop_supported xfce              # check on current host"
			echo "  module_desktop_supported kde-neon arm64 noble  # check specific arch/release"
			return 0
		;;
		*)
			module_desktop_yamlparse "$de" "$arch" "$release" 2>/dev/null || return 1
			[[ "$DESKTOP_AVAILABLE" == "yes" ]]
		;;
	esac
}
