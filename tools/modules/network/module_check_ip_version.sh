
module_options+=(
	["module_check_ip_version,author"]="@Tearran"
	["module_check_ip_version,ref_link"]=""
	["module_check_ip_version,feature"]="check_ip_version"
	["module_check_ip_version,desc"]="Check if a domain is reachable via IPv4 and IPv6"
	["module_check_ip_version,example"]="module_check_ip_version google.com"
	["module_check_ip_version,status"]="review"
	["module_check_ip_version,doc_link"]=""
)
#
#
#
module_check_ip_version() {
	domain=${1:-armbian.com}

	if ping -c 1 $domain > /dev/null 2>&1; then
		echo "IPv4"
	elif ping6 -c 1 $domain > /dev/null 2>&1; then
		echo "IPv6"
	else
		echo "Unreachable"
	fi
}
