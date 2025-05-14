
module_options+=(
	["network_config,author"]="@igorpecovnik"
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
			if srv_active hostapd && grep -q "^interface=$adapter" "/etc/hostapd/hostapd.conf"; then
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
			LIST=()
				ip link set ${adapter} up
				local stationslist=$(mktemp /tmp/wifi.XXXXXX)
				for wificycles in $(seq 1 1 10); do
				LIST=()
					iw ${adapter} scan 2> /dev/null | \
					grep 'freq:\|SSID:\|signal:' \
					| sed 's/.*:"//;s/"//' \
					| xargs -n3 -d'\n' \
					| sort -k4 -nr \
					| sed "s/freq: //g" \
					| sed "s/signal: //g" \
					| sed "s/SSID: //g" \
					> $stationslist
					if [[ $? -eq 0 && $(cat "${stationslist}" | wc -l) -gt 0 ]]; then
						break
					fi
					sleep 1
				done | $DIALOG --title "" --infobox "Scanning. Please wait" 4 26
				# construct second array
				while IFS=$'\t' read -r -a wifiArray
				do
					# if SSID is not blank, add to new list
					if [[ -n "${wifiArray[2]}" ]]; then
					LIST+=("${wifiArray[2]}" "$(printf "%-30s" "${wifiArray[2]}") ${wifiArray[1]} ${wifiArray[0]} Mhz")
					fi
				done < $stationslist
				rm -f $stationslist
				if [[ ${#LIST[@]} == 0 ]]; then
					restore_netplan_config
				else
					SELECTED_SSID=$($DIALOG --notags --backtitle "" --menu "Select WiFi Network" $((${#LIST[@]}/3 + 14 )) 70 $((${#LIST[@]}/3 + 6)) "${LIST[@]}" 3>&1 1>&2 2>&3)
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
				if [[ -f /etc/netplan/armbian.yaml && "$(netplan get bridges)" != "null" ]]; then
				ip link set ${adapter} up
				default_wireless_network_config "${yamlfile}" "${adapter}"
				pkg_install --no-install-recommends hostapd networkd-dispatcher bridge-utils
				SELECTED_SSID=$($DIALOG --title "Enter SSID for AP" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
				if [[ -n "${SELECTED_SSID}" && $? == 0 ]]; then
					SELECTED_PASSWORD=$($DIALOG --title "Enter new password for $SELECTED_SSID" --passwordbox "\nDefault password: 12345678\n" 9 50 "12345678" 3>&1 1>&2 2>&3)
					if [[ -n "${SELECTED_PASSWORD}" && $? == 0 ]]; then
						# start bridged AP
						netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
						netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
						netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
						netplan set --origin-hint ${yamlfile} bridges.br0.dhcp4=yes
						netplan set --origin-hint ${yamlfile} bridges.br0.dhcp6=yes
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
						srv_unmask hostapd
						srv_enable hostapd
						srv_start hostapd
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
										srv_restart hostapd
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
				else
				show_message <<< "AP (access point) mode is available after you set wired network to static or DHCP mode"
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
			[[ -f /etc/netplan/armbian.yaml ]] && LIST+=("spoof" "Spoof MAC address")
			LIST_LENGTH=$((${#LIST[@]} / 2))
			wiredmode=$($DIALOG --title "Select IP mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			wired_exit=$?
			if [[ "${wiredmode}" == "spoof" && $wired_exit == 0 ]]; then
				local mac_address=$(ip a s ${adapter} | grep link/ether | awk '{print $2}')
				mac_address=$($DIALOG --title "Enter MAC for $adapter" --inputbox "\nValid format: $mac_address" 9 40 "$mac_address" 3>&1 1>&2 2>&3)
				if [[ -n $mac_address && $? == 0 ]]; then
					netplan set --origin-hint ${yamlfile} ethernets.$adapter.macaddress=''$mac_address''
					netplan apply
				fi
			elif [[ "${wiredmode}" == "dhcp" && $wired_exit == 0 ]]; then
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
					[[ "${NETWORK_RENDERER}" == "NetworkManager" ]] && srv_restart NetworkManager
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
							[[ "${NETWORK_RENDERER}" == "NetworkManager" ]] && srv_restart NetworkManager
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
