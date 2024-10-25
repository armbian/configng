
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

	DISPLAY_MANAGER=""
	DESKTOP_INSTALLED=""
	check_if_installed nodm && DESKTOP_INSTALLED="nodm"
	check_if_installed lightdm && DESKTOP_INSTALLED="lightdm"
	check_if_installed lightdm && DESKTOP_INSTALLED="gnome"
	[[ -n $(service lightdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="lightdm"
	[[ -n $(service nodm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="nodm"
	[[ -n $(service gdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="gdm"

}
