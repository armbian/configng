#!/bin/bash

module_options+=(
["check_ip_version,author"]="Joey Turner"
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



module_options+=(
["toggle_ipv6,author"]="Joey Turner"
["toggle_ipv6,ref_link"]=""
["toggle_ipv6,feature"]="toggle_ipv6"
["toggle_ipv6,desc"]="Toggle IPv6 on or off"
["toggle_ipv6,example"]="toggle_ipv6"
["toggle_ipv6,status"]="review"
["toggle_ipv6,doc_link"]=""
)
#
# Function to toggle IPv6 on or off
#
toggle_ipv6() {
    # Check if IPv6 is currently enabled
    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q 0; then
        # If IPv6 is enabled, disable it
        echo "Disabling IPv6..."
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
        echo "IPv6 is now disabled."
        # Confirm that IPv6 is disabled
        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q 1; then
             check_ip_version google.com 
        else
             check_ip_version google.com 
        fi
    else
        # If IPv6 is disabled, enable it
        echo "Enabling IPv6..."
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=0
        echo "IPv6 is now enabled."
        # Confirm that IPv6 is enabled
        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q 0; then
            check_ip_version google.com 
        else
            check_ip_version google.com 
        fi
    fi

    # Now call the function with a domain name

}

module_options+=(
["see_ping,author"]="Joey Turner"
["see_ping,ref_link"]="https://github.com/Tearran/configng/blob/main/config.ng.functions.sh#632"
["see_ping,feature"]="see_ping"
["see_ping,desc"]="Check the internet connection with fallback DNS"
["see_ping,example"]="see_ping"
["see_ping,doc_link"]=""
["see_ping,status"]="review"
)
#
# Function to check the internet connection
#
function see_ping() {
	# List of servers to ping
	servers=("1.1.1.1" "8.8.8.8")

	# Check for internet connection
	for server in "${servers[@]}"; do
	    if ping -q -c 1 -W 1 $server >/dev/null; then
	        echo "Internet connection: Present"
			break
	    else
	        echo "Internet connection: Failed"
			sleep 1
	    fi
	done

	if [[ $? -ne 0 ]]; then
		read -n -r 1 -s -p "Warning: Configuration cannot work properly without a working internet connection. \
		Press CTRL C to stop or any key to ignore and continue."
	fi

}

