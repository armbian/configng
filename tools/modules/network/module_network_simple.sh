module_options+=(
	["module_simple_network,author"]="@igorpecovnik"
	["module_simple_network,maintainer"]="@igorpecovnik"
	["module_simple_network,feature"]="module_simple_network"
	["module_simple_network,example"]="simple advanced type stations select store restore dhcp static help"
	["module_simple_network,desc"]="Netplan wrapper"
	["module_simple_network,status"]="review"
	["module_simple_network,doc_link"]=""
	["module_simple_network,group"]="Network"
	["module_simple_network,port"]=""
	["module_simple_network,arch"]=""
)
#
# Function to select network adapter
#
function module_simple_network() {

	local title="network"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_simple_network,example"]}"

	# defaul yaml file
	yamlfile=armbian

	case "$1" in
		# simple
		"${commands[0]}")

			# store current configs to temporal folder
			${module_options["module_simple_network,feature"]} ${commands[5]} "$2"

			# select adapter
			${module_options["module_simple_network,feature"]} ${commands[4]} "$2"

			if [[ -n $adapter && $? == 0 ]]; then
				if [[ "$adapter" == w* && "$adapter" != wa* ]]; then
					# wireless networking
					${module_options["module_simple_network,feature"]} ${commands[3]} "$2" "wifis"
					# DHCP or static
					if [[ -n "${SELECTED_SSID}" ]]; then
						${module_options["module_simple_network,feature"]} ${commands[2]} "$2" "wifis"
					fi
				else
					# Wired networking
					# DHCP or static
					${module_options["module_simple_network,feature"]} ${commands[2]} "$2" "ethernets"
				fi
			fi
		;;
		"${commands[1]}")
			# advanced with bridge TBD
			${module_options["module_simple_network,feature"]} ${commands[0]} "advanced"
			echo "Advanced mode not ported to this script"
			exit 1
		;;
		"${commands[2]}")
			# static or dhcp
			local list=()
			list=("dhcp" "Auto IP assigning" "static" "Set IP manually")
			wiredmode=$($DIALOG --title "Select IP mode" --menu "" $((${#list[@]} / 2 + 8)) 60 $((${#list[@]} / 2)) "${list[@]}" 3>&1 1>&2 2>&3)
			mac_address=$(ip a s ${adapter} | grep link/ether | awk '{print $2}')
			mac_address=$($DIALOG --title "Spoof MAC address?" --inputbox "\nValid format: $mac_address" 9 40 "$mac_address" 3>&1 1>&2 2>&3)
			if [[ $? -eq 0 ]]; then
				if [[ "${wiredmode}" == "dhcp" ]]; then
					# set dhcp on adapter
					${module_options["module_simple_network,feature"]} ${commands[7]} "$2" "$3"
				elif [[ "${wiredmode}" == "static" ]]; then
					local ips=()
					for f in /sys/class/net/*; do
						local intf=$(basename $f)
						# skip unwanted
						if [[ $intf =~ ^dummy0|^lo|^docker|^virbr ]]; then
							continue
						else
							local tmp=$(ip -4 addr show dev $intf | grep $adapter | grep -v "$intf:avahi" | awk '/inet/ {print $2}' | uniq | head -1)
							[[ -n $tmp ]] && ips+=("$tmp")
						fi
					done
					address=${ips[0]} # use only 1st one
					[[ -z "${address}" ]] && address="1.2.3.4/5"
					address=$($DIALOG --title "Enter IP for $adapter" --inputbox "\nValid format: $address" 9 40 "$address" 3>&1 1>&2 2>&3)
					route_to="0.0.0.0/0"
					route_to=$($DIALOG --title "Use default route or set static" --inputbox "\nValid format: $route_to" 9 40 "$route_to" 3>&1 1>&2 2>&3)
					route_via=$(ip route show default | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]" | head -1 | xargs)
					route_via=$($DIALOG --title "Enter IP for gateway" --inputbox "\nValid format: $route_via" 9 40 "$route_via" 3>&1 1>&2 2>&3)
					nameservers="9.9.9.9,1.1.1.1"
					nameservers=$($DIALOG --title "Enter DNS server" --inputbox "\nValid format: $nameservers" 9 40 "$nameservers" 3>&1 1>&2 2>&3)
					# set fixed ip on adapter
					${module_options["module_simple_network,feature"]} ${commands[8]} "$2" "$3"
				fi
			fi
		;;
		"${commands[3]}")
			# station list
			local list=()
			ip link set ${adapter} down
			ip link set ${adapter} up
			local stationslist=$(mktemp /tmp/wifi.XXXXXX)
			trap '{ rm -rf -- "$stationslist"; }' EXIT
			for wificycles in $(seq 1 1 10); do
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
			while IFS=$'\t' read -r -a wifiArray ; do
				# if SSID is not blank, add to new list
				if [[ -n "${wifiArray[2]}" ]]; then
					list+=("${wifiArray[2]}" "$(printf "%-30s" "${wifiArray[2]}") ${wifiArray[1]} ${wifiArray[0]} Mhz")
				fi
			done < $stationslist
			rm -f $stationslist
			if [[ ${#list[@]} == 0 ]]; then
				${module_options["module_simple_network,feature"]} ${commands[6]}
			else
				SELECTED_SSID=$($DIALOG \
				--notags \
				--menu \
				"Select WiFi Network" $((${#list[@]}/3 + 14 )) 70 $((${#list[@]}/3 + 6)) "${list[@]}" 3>&1 1>&2 2>&3)
				if [[ -n "${SELECTED_SSID}" ]]; then
					SELECTED_PASSWORD=$($DIALOG --title "Enter new password for ${SELECTED_SSID}" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
				fi
			fi
		;;
		"${commands[4]}")
			# list adapters
			local list=()
			for f in /sys/class/net/*; do
				local interface=$(basename $f)
				if [[ $interface =~ ^dummy0|^lo|^docker|^virbr|^br ]]; then continue;
				else
					[[ $interface == w* && $interface != wa* ]] && devicetype="wifi" || devicetype="wired"
					local query=$(ip -4 -br addr show dev $interface | awk '{print $3}')
					list+=("${interface}" "$(printf "%-16s%18s%9s" ${interface} ${query:-unasigned} ${devicetype})")
				fi
			done
			adapter=$($DIALOG --notags --title "Select interface" --menu "\n Adaptor                 IP address     Type"  \
			$((${#list[@]}/2 + 10 )) 50 $((${#list[@]}/2 + 1)) "${list[@]}" 3>&1 1>&2 2>&3)
			if [[ $? -eq 0 ]]; then
				if $DIALOG --title "Action for ${adapter}" --yes-button "Configure" --no-button "Drop" --yesno "$1" 5 60; then
					:
				else
					sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' \
					-e 's/.*//;x;/'${adapter}'/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
					# delete empty section with help of yq - looking for a better way
					pkg_install yq
					yq -y 'del(.network.ethernets | select(length == 0)) | del(.network.wifis | select(length == 0))' \
					/etc/netplan/${yamlfile}.yaml > /etc/netplan/${yamlfile}.yaml.tmp
					mv /etc/netplan/${yamlfile}.yaml.tmp /etc/netplan/${yamlfile}.yaml
					chmod 600 /etc/netplan/${yamlfile}.yaml
					# delete empty section with help of yq - looking for a better way
					netplan apply
					${module_options["module_simple_network,feature"]} ${commands[4]} "$2"
				fi
			fi
		;;
		"${commands[5]}")
			# store current NetPlan configs
			restore_netplan_config_folder=$(mktemp -d /tmp/XXXXXXXXXX)
			trap '{ rm -rf -- "$restore_netplan_config"; }' EXIT
			rsync --quiet /etc/netplan/* ${restore_netplan_config_folder}/ 2>/dev/null
		;;
		"${commands[6]}")
			# restore current NetPlan configs
			if [[ -n ${restore_netplan_config_folder} ]]; then
				rm -f /etc/netplan/*
				rsync -ar ${restore_netplan_config_folder}/. /etc/netplan
			fi
		;;
		"${commands[7]}")
			# dhcp
			netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
			# wifi needs ap
			if [[ $3 == wifis ]]; then
				netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".password=${SELECTED_PASSWORD}
			fi
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp4=yes
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp6=yes
			netplan set --origin-hint ${yamlfile} $3.$adapter.macaddress=''$mac_address''
			netplan apply
		;;
		"${commands[8]}")
			# static
			netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
			# wifi needs ap
			if [[ $3 == wifis ]]; then
				netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".password=${SELECTED_PASSWORD}
			fi
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp4=no
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp6=no
			netplan set --origin-hint ${yamlfile} $3.$adapter.macaddress=''$mac_address''
			netplan set --origin-hint ${yamlfile} $3.$adapter.addresses='['$address']'
			netplan set --origin-hint ${yamlfile} $3.$adapter.routes='[{"to":"'$route_to'", "via": "'$route_via'","metric":200}]'
			netplan set --origin-hint ${yamlfile} $3.$adapter.nameservers.addresses='['$nameservers']'
			netplan apply
		;;
		"${commands[20]}")
			echo -e "\nUsage: ${module_options["module_simple_network,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_simple_network,example"]}"
			echo "Available commands:"
			echo -e "\tsimple\t\t- Select simple $title setup."
			echo -e "\tadvanced\t- Select advanced $title setup."
			echo -e "\tstations\t- Display wifi stations."
			echo -e "\tselect\t\t- Select adaptor."
			echo -e "\tstore\t\t- store NetPlan configs."
			echo -e "\trestore\t\t- Restore NetPlan configs."
			echo -e "\tdhcp\t\t- Set DHCP for adapter."
			echo -e "\tstatic\t\t- Set static for adapter."
			echo -e "\thelp\t\t- Display this."
			echo
		;;
		*)
			${module_options["module_simple_network,feature"]} ${commands[20]}
		;;
	esac

}
