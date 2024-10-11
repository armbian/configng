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
# Function to revert network configuration to Armbian defaults
#
function default_network_config() {

	local yamlfile=10-dhcp-all-interfaces

	# store current configs to temporal folder
	store_netplan_config

	get_user_continue "This action might disconnect you from network.\n\nAre you sure network was configured correctly?" process_input
	if [[ $? == 0 ]]; then
		# remove all configs
		rm -f /etc/netplan/*.yaml
		# disable hostapd
		systemctl stop hostapd 2> /dev/null
		systemctl disable hostapd 2> /dev/null
		# reset netplan config
		netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp4=true
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp6=true
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.match.name=e*

		# exceptions
		if [[ "${NETWORK_RENDERER}" == "NetworkManager" ]]; then
			# uninstall packages
			apt_install_wrapper apt-get -y purge hostapd
			netplan apply
			nmcli con down br0
		else
			# uninstall packages
			apt_install_wrapper apt-get -y purge hostapd networkd-dispatcher
			# drop and delete bridge interface in case its there
			if [[ -n $(ip link show type bridge) ]]; then
				ip link set br0 down
				brctl delbr br0
				networkctl reconfigure br0
			fi
			# remove networkd-dispatcher hook
			rm -f /etc/networkd-dispatcher/carrier.d/armbian-ap
			netplan apply
		fi
	else
		restore_netplan_config
	fi
}

module_options+=(
	["default_wireless_network_config,author"]="Igor Pecovnik"
	["default_wireless_network_config,ref_link"]=""
	["default_wireless_network_config,feature"]="default_wireless_network_config"
	["default_wireless_network_config,desc"]="Stop hostapd, clean config"
	["default_wireless_network_config,example"]="default_wireless_network_config"
	["default_wireless_network_config,doc_link"]=""
	["default_wireless_network_config,status"]="review"
)
function default_wireless_network_config(){

	# defaul yaml file
	local yamlfile=${1:-armbian}
	local adapter=${2:-wlan0}

	# remove wifi from netplan
	if [[ -f /etc/netplan/${yamlfile}.yaml ]]; then
		sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/'$adapter':/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
		sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/- '$adapter'/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
		sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/wifis:/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
	fi

	# remove networkd-dispatcher hook
	rm -f /etc/networkd-dispatcher/carrier.d/armbian-ap
	# remove network-manager dispatcher hook
	rm -f /etc/NetworkManager/dispatcher.d/armbian-ap

	# hostapd needs more cleaning
	if systemctl is-active hostapd 1> /dev/null; then
		systemctl stop hostapd 2> /dev/null
		systemctl disable hostapd 2> /dev/null
	fi

	# apply config
	netplan apply

	# exceptions
	if [[ "${NETWORK_RENDERER}" == "NetworkManager" ]]; then
			# uninstall packages
			apt_install_wrapper apt-get -y --no-install-recommends purge hostapd
			systemctl restart NetworkManager
		else
			# uninstall packages
			apt_install_wrapper apt-get -y --no-install-recommends purge hostapd networkd-dispatcher
			brctl delif br0 $adapter 2> /dev/null
			networkctl reconfigure br0
	fi

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

	# store current configs to temporal folder
	store_netplan_config

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
	adapter=$($DIALOG --title "Select interface" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
	if [[ -n $adapter && $? == 0 ]]; then
		#
		# Wireless networking
		#
		if [[ "$adapter" == w* ]]; then

			LIST=()
			if systemctl is-active --quiet service hostapd; then
				LIST+=("stop" "Disable access point")
			else
				LIST=("sta" "Connect to access point")
				LIST+=("ap" "Become an access point")
			fi
			LIST_LENGTH=$((${#LIST[@]} / 2))
			wifimode=$($DIALOG --title "Select wifi mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			case $wifimode in
			stop)
				# disable hostapd and cleanup config
				default_wireless_network_config "${yamlfile}" "${adapter}"
			;;

			sta)
				ip link set ${adapter} up
				default_wireless_network_config "${yamlfile}" "${adapter}"
				LIST=()
				LIST=($(iw dev ${adapter} scan 2> /dev/null | grep 'SSID\|^BSS' | cut -d" " -f2 | sed "s/(.*//g" | xargs -n2 -d'\n' | awk '{print $2,$1}'))
				sleep 1
				LIST_LENGTH=$((${#LIST[@]} / 2))
				if [[ ${#LIST[@]} == 0 ]]; then
					restore_netplan_config
				else
					SELECTED_SSID=$($DIALOG --title "Select SSID" --menu "rf" $((${LIST_LENGTH} + 6)) 50 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
					if [[ -n $SELECTED_SSID ]]; then
						SELECTED_PASSWORD=$($DIALOG --title "Enter new password for $SELECTED_SSID" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
						if [[ -n $SELECTED_PASSWORD ]]; then
							# connect to AP
							netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
							netplan set --origin-hint ${yamlfile} wifis.$adapter.access-points."${SELECTED_SSID//./\\.}".password=${SELECTED_PASSWORD}
							netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp4=true
							netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp6=true
							show_message <<< "$(netplan get all)"
							$DIALOG --title " Changing network settings " --yes-button "Yes" --no-button "Cancel" --yesno \
							"This action might disconnect you from network.\n\nAre you sure network was configured correctly?" 9 50
							if [[ $? = 0 ]]; then
								netplan apply
							else
								restore_netplan_config
							fi
						fi
					fi
				fi
			;;

			ap)
				ip link set ${adapter} up
				default_wireless_network_config "${yamlfile}" "${adapter}"
				! check_if_installed hostapd && apt_install_wrapper apt-get -y --no-install-recommends install hostapd networkd-dispatcher
				SELECTED_SSID=$($DIALOG --title "Enter SSID for AP" --inputbox "" 7 50 3>&1 1>&2 2>&3)
				if [[ -n "${SELECTED_SSID}" && $? == 0 ]]; then
					SELECTED_PASSWORD=$($DIALOG --title "Enter new password for $SELECTED_SSID" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
					if [[ -n "${SELECTED_PASSWORD}" && $? == 0 ]]; then
						# start bridged AP
						netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
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
						netplan apply
						# Start hostapd services
						systemctl unmask hostapd 2>/dev/null
						systemctl enable hostapd 2>/dev/null
						systemctl start hostapd 2>/dev/null
						# Sometimes it fails to add to the bridge
						brctl addif br0 $adapter 2>/dev/null
						# Add hooks to hack wrong if type
						if [[ "${NETWORK_RENDERER}" == "NetworkManager" ]]; then
							mkdir -p /etc/NetworkManager/dispatcher.d
							cat <<- EOF > "/etc/NetworkManager/dispatcher.d/armbian-ap"
							#!/bin/bash
							# Added by armbian-config
							interface=\$1
							status=\$2
							case "\$status" in
								up)
									if [[ "\$interface" == "br0" ]]; then
										service hostapd restart
										brctl addif br0 $adapter
									fi
								;;
								down)
									if [[ "\$interface" == "br0" ]]; then
										brctl delif br0 $adapter
									fi
								;;
							esac
							EOF
							chmod +x /etc/NetworkManager/dispatcher.d/armbian-ap
						else
							# workarounding bug in netplan for failing to add wireless adaptor to bridge
							# this might not be needed on all versions
							mkdir -p /etc/networkd-dispatcher/carrier.d/
							cat <<- EOF > "/etc/networkd-dispatcher/carrier.d/armbian-ap"
							#!/bin/sh
							brctl addif br0 $adapter
							netplan apply
							exit 0
							EOF
							chmod +x /etc/networkd-dispatcher/carrier.d/armbian-ap
						fi
					fi
				fi
			;;

			*)
				echo -n "unknown"
				exit
			;;
			esac

		else

			#
			# Wired networking
			#

			# remove default configuration
			rm -f /etc/netplan/10-dhcp-all-interfaces.yaml

			LIST=("dhcp" "Auto IP assigning")
			LIST+=("static" "Set IP manually")
			wiredmode=$($DIALOG --title "Select IP mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			if [[ "${wiredmode}" == "dhcp" && $? == 0 ]]; then
				[[ -f /etc/netplan/${yamlfile}.yaml ]] && sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/bridges/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
				netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
				netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp4=yes
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp6=yes
				show_message <<< "$(netplan get all)"
				$DIALOG --title " Changing network settings " --yes-button "Yes" --no-button "Cancel" --yesno \
				"This action might disconnect you from network.\n\nAre you sure network was configured correctly?" 9 50
				if [[ $? = 0 ]]; then
					# apply NetPlan
					netplan apply
					[[ "${NETWORK_RENDERER}" == "NetworkManager" ]] && systemctl restart NetworkManager;
				else
					restore_netplan_config
				fi
			elif [[ "${wiredmode}" == "static" ]]; then
				local ips=()
				for f in /sys/class/net/*; do
					local intf=$(basename $f)
					# skip unwanted
					if [[ $intf =~ ^dummy0|^lo|^docker|^virbr ]]; then
						continue
					else
						local tmp=$(ip -4 addr show dev $intf | grep -v "$intf:avahi" | awk '/inet/ {print $2}' | uniq)
						[[ -n $tmp ]] && ips+=("$tmp")
					fi
				done
				#address=${ips[@]}
				address=${ips[0]} # use only 1st one
				[[ -z "${address}" ]] && address="1.2.3.4/5"
				# clean values from config
				[[ -f /etc/netplan/${yamlfile}.yaml ]] && sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/bridges/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
				address=$($DIALOG --title "Enter IP for $adapter" --inputbox "\nValid format: $address" 9 40 "$address" 3>&1 1>&2 2>&3)
				if [[ -n $address && $? == 0 ]]; then
					defaultroute=$(ip route show default | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]" | head -1 | xargs)
					defaultroute=$($DIALOG --title "Enter IP for default route" --inputbox "\nValid format: $defaultroute" 9 40 "$defaultroute" 3>&1 1>&2 2>&3)
					if [[ -n $defaultroute && $? == 0 ]]; then
						nameservers="9.9.9.9,1.1.1.1"
						nameservers=$($DIALOG --title "Enter DNS server" --inputbox "\nValid format: $nameservers" 9 40 "$nameservers" 3>&1 1>&2 2>&3)
					else
						restore_netplan_config
					fi
					if [[ -n $nameservers && $? == 0 ]]; then
						netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
						netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
						netplan set --origin-hint ${yamlfile} bridges.br0.addresses='['$address']'
						netplan set --origin-hint ${yamlfile} bridges.br0.routes='[{"to":"0.0.0.0/0", "via": "'$defaultroute'","metric":200}]'
						netplan set --origin-hint ${yamlfile} bridges.br0.nameservers.addresses='['$nameservers']'
					else
						restore_netplan_config
					fi
					if [[ $? == 0 ]]; then
						show_message <<< "$(netplan get all)"
						$DIALOG --title " Changing network settings " --yes-button "Yes" --no-button "Cancel" --yesno \
						"This action might disconnect you from network.\n\nAre you sure network was configured correctly?" 9 50
						if [[ $? = 0 ]]; then
							# apply NetPlan
							netplan apply
							[[ "${NETWORK_RENDERER}" == "NetworkManager" ]] && systemctl restart NetworkManager;
						else
							restore_netplan_config
						fi
					fi
				else
					restore_netplan_config
				fi
			else
				restore_netplan_config
			fi
		fi
	else
		restore_netplan_config
	fi
}
