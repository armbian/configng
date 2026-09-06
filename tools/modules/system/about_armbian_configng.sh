
module_options+=(
["about_armbian_configng,author"]="@igorpecovnik"
["about_armbian_configng,ref_link"]=""
["about_armbian_configng,feature"]="about_armbian_configng"
["about_armbian_configng,desc"]="Show general information about this tool"
["about_armbian_configng,example"]="about_armbian_configng"
["about_armbian_configng,status"]="Active"
)
#
# @description Show general information about this tool
#
# Sized to fit an 80x24 terminal without scrolling: dialog msgbox is
# auto-sized, and it clips rather than scrolls, so keep this at or under
# 15 lines and 70 columns.
#
function about_armbian_configng() {

	echo "Armbian Config: The Next Generation"
	echo ""
	echo "Configures an installed Armbian system: kernel and firmware, storage,"
	echo "network, users and services, plus optional third-party software."
	echo ""
	echo "  System         kernel, firmware, storage, users, services"
	echo "  Network        wired, wireless, hotspot, DNS, addressing"
	echo "  Localisation   locale, timezone, keyboard, hostname"
	echo "  Software       install and remove curated applications"
	echo ""
	echo "Every entry is scriptable:  armbian-config --api <module> <command>"
	echo ""
	echo "Docs    https://docs.armbian.com/armbian-config/"
	echo "Issues  https://github.com/armbian/configng/issues"
	echo "Donate  https://github.com/sponsors/armbian"

}
