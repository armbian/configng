
module_options+=(
	["check_ip_version,author"]="@Tearran"
	["check_ip_version,ref_link"]=""
	["check_ip_version,feature"]="check_ip_version"
	["check_ip_version,desc"]="Check if a domain is reachable via IPv4 and IPv6"
	["check_ip_version,example"]="check_ip_version google.com"
	["check_ip_version,status"]="review"
	["check_ip_version,doc_link"]=""
)
#
#
#
check_ip_version() {
	domain=${1:-armbian.com}

	if ping -c 1 $domain > /dev/null 2>&1; then
		echo "IPv4"
	elif ping6 -c 1 $domain > /dev/null 2>&1; then
		echo "IPv6"
	else
		echo "Unreachable"
	fi
}
