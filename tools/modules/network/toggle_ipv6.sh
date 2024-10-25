
module_options+=(
	["toggle_ipv6,author"]="@Tearran"
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
