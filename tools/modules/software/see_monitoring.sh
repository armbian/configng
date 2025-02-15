#
module_options+=(
	["see_monitoring,id"]="0350"
	["see_monitoring,maintainer"]="Needed"
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]=""
	["see_monitoring,status"]="review"
	["see_monitoring,about"]=""
	["see_monitoring,doc_link"]="Missing"
	["see_monitoring,author"]="@Tearran"
	["see_monitoring,parent"]="software"
	["see_monitoring,group"]="Monitoring"
	["see_monitoring,port"]="Unset"
	["see_monitoring,arch"]="Missing"
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
