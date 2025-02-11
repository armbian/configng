
module_options+=(
	["check_desktop,author"]="@armbian"
	["check_desktop,ref_link"]=""
	["check_desktop,feature"]="check_desktop"
	["check_desktop,desc"]="Migrated procedures from Armbian config."
	["check_desktop,example"]="check_desktop"
	["check_desktop,status"]="Active"
	["check_desktop,doc_link"]=""
)
#
# read desktop parameters
#
function check_desktop() {

	unset DESKTOP_INSTALLED
	pkg_installed nodm && DESKTOP_INSTALLED="nodm"
	pkg_installed lightdm && DESKTOP_INSTALLED="lightdm"
	pkg_installed gdm3 && DESKTOP_INSTALLED="gnome"

	unset DISPLAY_MANAGER
	srv_active nodm && DISPLAY_MANAGER="nodm"
	srv_active lightdm && DISPLAY_MANAGER="lightdm"
	srv_active gdm && DISPLAY_MANAGER="gdm"
}
