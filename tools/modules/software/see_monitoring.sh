
module_options+=(
	["see_monitoring,author"]="@Tearran"
	["see_monitoring,ref_link"]=""
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]="see_monitoring"
	["see_monitoring,status"]="review"
	["see_monitoring,doc_link"]=""
)
#
# @decrition generate a menu for armbianmonitor
#
function see_monitoring() {
	if [ -f /usr/bin/htop ]; then
		choice=$(armbianmonitor -h | grep -Ev '^\s*-c\s|^\s*-M\s' | show_menu)

		armbianmonitor -$choice

	else
		echo "htop is not installed"
	fi
}
