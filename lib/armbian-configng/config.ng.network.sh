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
		if ping -q -c 1 -W 1 $server > /dev/null; then
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

module_options+=(
	["default_network_config,author"]="Igor Pecovnik"
	["default_network_config,ref_link"]=""
	["default_network_config,feature"]="default_network_config"
	["default_network_config,desc"]="Revert network config back to Armbian defaults"
	["default_network_config,example"]="default_network_config"
	["default_network_config,doc_link"]=""
	["default_network_config,status"]="review"
)
#
# Function to revert network configuration to defaults
#
function default_network_config() {

	local renderer=networkd
	local yamlfile=10-dhcp-all-interfaces

	# remove all configs
	rm -f /etc/netplan/*.yaml
	netplan set --origin-hint ${yamlfile} renderer=${renderer}
	netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp4=true
	netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp6=true
	netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.match.name=e*
	show_message <<< "$(sudo netplan get ${type})"

}

module_options+=(
	["network_config,author"]="Igor Pecovnik"
	["network_config,ref_link"]=""
	["network_config,feature"]="network_config"
	["network_config,desc"]="Netplan wrapper"
	["network_config,example"]="network_config"
	["network_config,doc_link"]=""
	["network_config,status"]="review"
)
#
# Function to select network adapter
#
function network_config() {

	# defaul yaml file
	local yamlfile=${1:-armbian}

	# delete default automatic DHCP on all wired networks setup
	rm -f /etc/netplan/10-dhcp-all-interfaces.yaml

	LIST=()
	HIDE_IP_PATTERN="^dummy0|^lo|^docker|^virbr|^br"
	for f in /sys/class/net/*; do
		interface=$(basename $f)
		if [[ $interface =~ $HIDE_IP_PATTERN ]]; then
			continue
		else
			[[ $interface == w* ]] && devicetype="wifi" || devicetype="wired"
			QUERY=$(ip -br addr show dev $interface | awk '{ print $1, " " , ($3==""?"unassigned":$3)"['$devicetype']" }')
			[[ -n $QUERY ]] && LIST+=($QUERY)
		fi
	done
	LIST_LENGTH=$((${#LIST[@]} / 2))
	adapter=$(whiptail --title "Select interface" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
	if [[ -n $adapter && $? == 0 ]]; then
		#
		# Wireless networking
		#
		if [[ "$adapter" == w* ]]; then
			# wireless
			LIST=("sta" "Connect to access point")
			LIST+=("ap" "Become an access point")
			LIST_LENGTH=$((${#LIST[@]} / 2))
			wifimode=$(whiptail --title "Select wifi mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			if [[ "${wifimode}" == "sta" && $? == 0 ]]; then
				ip link set ${adapter} up
				systemctl stop hostapd 1> /dev/null
				systemctl disable hostapd 1> /dev/null
				LIST=()
				LIST=($(iw dev ${adapter} scan 2> /dev/null | grep 'SSID\|^BSS' | cut -d" " -f2 | sed "s/(.*//g" | xargs -n2 -d'\n' | awk '{print $2,$1}'))
				sleep 2
				LIST_LENGTH=$((${#LIST[@]} / 2))
				SELECTED_SSID=$(whiptail --title "Select SSID" --menu "rf" $((${LIST_LENGTH} + 6)) 50 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
				if [[ -n $SELECTED_SSID ]]; then
					SELECTED_PASSWORD=$(whiptail --title "Enter new password for $SELECTED_SSID" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
					if [[ -n $SELECTED_PASSWORD ]]; then
						# connect to AP
						netplan set --origin-hint ${yamlfile} renderer=${renderer}
						netplan set --origin-hint ${yamlfile} wifis.$adapter.access-points."${SELECTED_SSID}".password=${SELECTED_PASSWORD}
						netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp4=true
						netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp6=true
						show_message <<< "$(netplan get all)"
					fi
				fi
			elif [[ "${wifimode}" == "ap" ]]; then

				check_if_installed hostapd && debconf-apt-progress -- apt-get -y --no-install-recommends hostapd

				SELECTED_SSID=$(whiptail --title "Enter SSID for AP" --inputbox "" 7 50 3>&1 1>&2 2>&3)
				if [[ -n "${SELECTED_SSID}" && $? == 0 ]]; then
					SELECTED_PASSWORD=$(whiptail --title "Enter new password for $SELECTED_SSID" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
					if [[ -n "${SELECTED_PASSWORD}" && $? == 0 ]]; then
						# start bridged AP
						netplan set --origin-hint ${yamlfile} renderer=${renderer}
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
						netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
						cat <<- EOF > "/etc/hostapd/hostapd.conf"
							interface=$adapter
							driver=nl80211
							ssid=$SELECTED_SSID
							hw_mode=g
							channel=7
							wmm_enabled=0
							macaddr_acl=0
							auth_algs=1
							ignore_broadcast_ssid=0
							wpa=2
							wpa_passphrase=$SELECTED_PASSWORD
							wpa_key_mgmt=WPA-PSK
							wpa_pairwise=TKIP
							rsn_pairwise=CCMP
						EOF
						# Start services
						systemctl stop hostapd
						sleep 2
						systemctl start hostapd
						# Enable services on boot
						systemctl enable hostapd
						show_message <<< "$(netplan get all)"
					fi
				fi
			fi

		else

			#
			# Wireless networking
			#
			LIST=("dhcp" "Auto IP assigning")
			LIST+=("static" "Set IP manually")
			wiredmode=$(whiptail --title "Select IP mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			if [[ "${wiredmode}" == "dhcp" && $? == 0 ]]; then
				netplan set --origin-hint ${yamlfile} renderer=${renderer}
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
				netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp4=yes
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp6=yes
				show_message <<< "$(netplan get all)"
			elif [[ "${wiredmode}" == "static" ]]; then
				address=$(ip -br addr show dev $adapter | awk '{print $3}')
				[[ -z "${address}" ]] && address="1.2.3.4/5"
				address=$(whiptail --title "Enter IP for $adapter" --inputbox "\nValid format: $address" 9 40 "$address" 3>&1 1>&2 2>&3)
				if [[ -n $address && $? == 0 ]]; then
					defaultroute=$(ip route show default | grep "$adapter" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]" | head 1 | xargs)
					defaultroute=$(whiptail --title "Enter IP for default route" --inputbox "\nValid format: $defaultroute" 9 40 "$defaultroute" 3>&1 1>&2 2>&3)
					if [[ -n $defaultroute && $? == 0 ]]; then
						nameservers="9.9.9.9,1.1.1.1"
						nameservers=$(whiptail --title "Enter DNS server" --inputbox "\nValid format: $nameservers" 9 40 "$nameservers" 3>&1 1>&2 2>&3)
					fi
					if [[ -n $nameservers && $? == 0 ]]; then
						netplan set --origin-hint ${yamlfile} renderer=${renderer}
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
						netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
						netplan set --origin-hint ${yamlfile} bridges.br0.addresses='['$address']'
						netplan set --origin-hint ${yamlfile} bridges.br0.routes='[{"to":"0.0.0.0/0", "via": "'$defaultroute'","metric":200}]'
						netplan set --origin-hint ${yamlfile} bridges.br0.nameservers.addresses='['$nameservers']'
					fi
				fi
			fi
		fi
	fi
}
