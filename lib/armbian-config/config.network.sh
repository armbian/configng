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
	["module_simple_network,arch"]="x86-64 arm64 armhf riscv64"
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
					# wireless networking select SSID
					${module_options["module_simple_network,feature"]} ${commands[3]} "$2" "wifis"
					# DHCP or static
					if [[ -n "${SELECTED_SSID}" ]]; then
						${module_options["module_simple_network,feature"]} ${commands[2]} "$2" "wifis"
					fi
				else
					# Wired networking DHCP or static
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
			if [[ $? -eq 0 ]]; then
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
			fi
		;;
		"${commands[3]}")

			# init arrays
			list=()
			pair=()

			# base of channels
			declare -A CHANNELS=(
			['2412']='1'
			['2417']='2'
			['2422']='3'
			['2427']='4'
			['2432']='5'
			['2437']='6'
			['2442']='7'
			['2447']='8'
			['2452']='9'
			['2457']='10'
			['2462']='11'
			['2467']='12'
			['2472']='13'
			['5180']='36'
			['5200']='40'
			['5220']='44'
			['5240']='48'
			['5260']='52'
			['5280']='56'
			['5300']='60'
			['5320']='64'
			['5500']='100'
			['5520']='104'
			['5540']='108'
			['5560']='112'
			['5580']='116'
			['5600']='120'
			['5620']='124'
			['5640']='128'
			['5660']='132'
			['5680']='136'
			['5700']='140'
			['5720']='144'
			['5745']='149'
			['5765']='153'
			['5785']='157'
			['5805']='161'
			['5825']='165'
			)

			# Set IFS to ensure grep output split only at line end on for statement
			default_IFS=$IFS
			IFS='
			'
			# capture grep output in "iw" scan command in to array
			local iw_command=( \
			$(lc_all=C sudo iw dev $adapter scan \
			| grep -o 'BSS ..\:..\:..:..\:..\:..\|SSID: .*\|signal\: .* \|freq\: .*') \
			)
			# Resetting IFS to previous value
			IFS=$default_IFS

			COUNT=1

			# Read through grep output from "iw" scan command
			for line in "${iw_command[@]}"; do
				# set IFS to space & tab
				default_IFS=$IFS
				IFS=" 	"

				# first field should be BSS
				if [[ $line =~ BSS ]]; then
					bss_array=( $line )
					bssid=${bss_array[1]}
				fi

				# second field should be freq:
				if [[ $line =~ "freq:" ]]; then
					freq_array=( $line )
					freq=$(echo ${freq_array[1]} | cut -d"." -f1)
				fi

				# third field should be signal:
				if [[ $line =~ "signal:" ]]; then
					signal_array=( $line )
					rssi=$(echo ${signal_array[1]} | cut -d"." -f1)
				fi

				# fourth field should be SSID
				if [[ $line =~ "SSID" ]]; then
					ssid_array=( $line )
					# get rid of first array element so that we can print whole array, leaving just SSID name which may have spaces
					unset ssid_array[0]
					ssid=${ssid_array[@]}
				fi

				# Every 4th line we have all the input we need to write out the data
				if [ $COUNT -eq 4 ]; then
					channel=$(printf '%3s' "${CHANNELS[$freq]}")
					# construct new array for menu
					list+=("${bssid}" "$(printf "%-25s%6s%8s Mhz %7s" "${ssid:-"Invisible SSID"}" ${rssi} ${freq} ${channel})")
					# construct second array for comparission
					pair+=(${bssid}="${ssid}")
					COUNT=0
					unset bssid,ssid,freq,rssi,channel,ssid_array,signal_array,freq_array,bss_array,grep_output
				fi
			((COUNT++))
		done
		SELECTED_BSSID=$($DIALOG \
		--notags \
		--title "Select SSID" \
		--menu "\nSSID                     Signal   Frequency Channel" \
		$((${#list[@]}/2 + 10 )) 57 $((${#list[@]}/2 )) "${list[@]}" 3>&1 1>&2 2>&3)
		if [[ $? -eq 0 ]]; then
			# search for SSID
			for elt in "${pair[@]}"; do
				if [[ $elt == *$SELECTED_BSSID* && -n "{SELECTED_BSSID}" ]]; then
				SELECTED_SSID=$(echo "$elt" | cut -d"=" -f2)
				while true; do
					SELECTED_PASSWORD=$($DIALOG --title "Enter password for ${SELECTED_SSID}" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
					if [[ -z "$SELECTED_PASSWORD" || ${#SELECTED_PASSWORD} -ge 8 ]]; then
						break
					else
						$DIALOG --msgbox "Passphrase must be between 8 and 63 characters!" 7 51 --title "Error"
					fi
					done
				fi
			done
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
					list+=("${interface}" "$(printf "%-16s%18s%9s" ${interface} ${query:-unassigned} ${devicetype})")
				fi
			done
			adapter=$($DIALOG --notags --title "Select interface" --menu "\n Adaptor                 IP address     Type"  \
			$((${#list[@]}/2 + 10 )) 50 $((${#list[@]}/2 + 1)) "${list[@]}" 3>&1 1>&2 2>&3)
			if [[ $? -eq 0 ]]; then
				if $DIALOG --title "Action for ${adapter}" --yes-button "Configure" --no-button "Drop" --yesno "$1" 5 60; then
					ip link set ${adapter} up
				else
					${module_options["module_simple_network,feature"]} ${commands[9]} "${adapter}"
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
			# drop current settings
			${module_options["module_simple_network,feature"]} ${commands[9]} "${adapter}"
			# dhcp
			netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
			# wifi needs ap
			if [[ $3 == wifis ]]; then
				if [[ -z "${SELECTED_PASSWORD}" ]]; then
					netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".auth.key-management=none
				else
					netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".password="${SELECTED_PASSWORD}"
				fi
			fi
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp4=yes
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp6=yes
			netplan set --origin-hint ${yamlfile} $3.$adapter.macaddress=''$mac_address''
			netplan apply
		;;
		"${commands[8]}")
			# drop current settings
			${module_options["module_simple_network,feature"]} ${commands[9]} "${adapter}"
			# static
			netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
			# wifi needs ap
			if [[ $3 == wifis ]]; then
				if [[ -z "${SELECTED_PASSWORD}" ]]; then
					netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".auth.key-management=none
				else
					netplan set --origin-hint ${yamlfile} $3.$adapter.access-points."${SELECTED_SSID//./\\.}".password="${SELECTED_PASSWORD}"
				fi
			fi
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp4=no
			netplan set --origin-hint ${yamlfile} $3.$adapter.dhcp6=no
			netplan set --origin-hint ${yamlfile} $3.$adapter.macaddress=''$mac_address''
			netplan set --origin-hint ${yamlfile} $3.$adapter.addresses='['$address']'
			netplan set --origin-hint ${yamlfile} $3.$adapter.routes='[{"to":"'$route_to'", "via": "'$route_via'","metric":200}]'
			netplan set --origin-hint ${yamlfile} $3.$adapter.nameservers.addresses='['$nameservers']'
			netplan apply
		;;
		"${commands[9]}")
			# remove adapter from yaml file
			sed -i -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' \
			-e 's/.*//;x;/'${2}'/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
			# awk solution to cleanout empty wifis or ethernets section
			# which doesn't need additional dependencies
			cat /etc/netplan/${yamlfile}.yaml | awk 'BEGIN {
			re = "[^[:space:]-]"
			if (getline != 1)
				exit
			while (1) {
				last = $0
				last_nf = NF
				if (getline != 1) {
					if (last_nf != 1)
						print last
					exit
				}
				if (last_nf == 1 && match(last, re) == match($0, re))
					continue
				print last
				}
			} $1' > /etc/netplan/${yamlfile}.yaml.tmp
			mv /etc/netplan/${yamlfile}.yaml.tmp /etc/netplan/${yamlfile}.yaml
			chmod 600 /etc/netplan/${yamlfile}.yaml
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


module_options+=(
	["default_network_config,author"]="@igorpecovnik"
	["default_network_config,ref_link"]=""
	["default_network_config,feature"]="default_network_config"
	["default_network_config,desc"]="Revert network config back to Armbian defaults"
	["default_network_config,example"]="default_network_config"
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
		srv_stop hostapd
		srv_disable hostapd
		# reset netplan config
		netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp4=true
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.dhcp6=true
		netplan set --origin-hint ${yamlfile} ethernets.all-eth-interfaces.match.name=e*

		# exceptions
		if [[ "${NETWORK_RENDERER}" == "NetworkManager" ]]; then
			# uninstall packages
			pkg_remove hostapd
			netplan apply
			nmcli con down br0
		else
			# uninstall packages
			pkg_remove hostapd networkd-dispatcher
			# drop and delete bridge interface in case its there
			if [[ -n $(ip link show type bridge) ]]; then
				ip link set br0 down >/dev/null 2>&1
				brctl delbr br0 >/dev/null 2>&1
				networkctl reconfigure br0 >/dev/null 2>&1
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

module_options+=(
	["connect_bt_interface,author"]="@armbian"
	["connect_bt_interface,ref_link"]=""
	["connect_bt_interface,feature"]="connect_bt_interface"
	["connect_bt_interface,desc"]="Migrated procedures from Armbian config."
	["connect_bt_interface,example"]="connect_bt_interface"
	["connect_bt_interface,status"]="Active"
)
#
# connect to bluetooth device
#
function connect_bt_interface() {

	IFS=$'
'
	GLOBIGNORE='*'
	show_infobox <<< "
Discovering Bluetooth devices ... "
	BT_INTERFACES=($(hcitool scan | sed '1d'))

	local LIST=()
	for i in "${BT_INTERFACES[@]}"; do
		local a=$(echo ${i[0]//[[:blank:]]/} | sed -e 's/^\(.\{17\}\).*/\1/')
		local b=${i[0]//$a/}
		local b=$(echo $b | sed -e 's/^[ 	]*//')
		LIST+=("$a" "$b")
	done

	LIST_LENGTH=$((${#LIST[@]} / 2))
	if [ "$LIST_LENGTH" -eq 0 ]; then
		BT_ADAPTER=${WLAN_INTERFACES[0]}
		show_message <<< "
No nearby Bluetooth devices were found!"
	else
		exec 3>&1
		BT_ADAPTER=$(whiptail --title "Select interface" \
			--clear --menu "" $((6 + ${LIST_LENGTH})) 50 $LIST_LENGTH "${LIST[@]}" 2>&1 1>&3)
		exec 3>&-
		if [[ $BT_ADAPTER != "" ]]; then
			show_infobox <<< "
Connecting to $BT_ADAPTER "
			BT_EXEC=$(
				expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address
";
			sleep 1;send "remove $address
";sleep 1;expect -re $prompt;send "scan on
";sleep 8;send "scan off
";
			expect "Controller";send "trust $address
";sleep 2;send "pair $address
";sleep 2;send "connect $address
";
			send_user "
Should be paired now.
";sleep 2;send "quit
";expect eof'
			)
			echo "$BT_EXEC" > /tmp/bt-connect-debug.log
			if [[ $(echo "$BT_EXEC" | grep "Connection successful") != "" ]]; then
				show_message <<< "
Your device is ready to use!"
			else
				show_message <<< "
Error connecting. Try again!"
			fi
		fi
	fi

}


module_options+=(
	["see_ping,author"]="@Tearran"
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
	["default_wireless_network_config,author"]="@igorpecovnik"
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
	if srv_active hostapd; then
		srv_stop hostapd
		srv_disable hostapd
	fi

	# apply config
	netplan apply

	# exceptions
	if [[ "${NETWORK_RENDERER}" == "NetworkManager" ]]; then
		# uninstall packages
		pkg_remove hostapd
		srv_restart NetworkManager
	else
		# uninstall packages
		pkg_remove hostapd networkd-dispatcher
		brctl delif br0 $adapter 2> /dev/null
		networkctl reconfigure br0
	fi

}


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


module_options+=(
	["qr_code,author"]="@igorpecovnik"
	["qr_code,ref_link"]=""
	["qr_code,feature"]="qr_code"
	["qr_code,desc"]="Show or generate QR code for Google OTP"
	["qr_code,example"]="qr_code generate"
	["qr_code,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function qr_code() {

	clear
	if [[ "$1" == "generate" ]]; then
		google-authenticator -t -d -f -r 3 -R 30 -W -q
		cp /root/.google_authenticator /etc/skel
		update_skel
	fi
	export TOP_SECRET=$(head -1 /root/.google_authenticator)
	qrencode -m 2 -d 9 -8 -t ANSI256 "otpauth://totp/test?secret=$TOP_SECRET"
	echo -e '
Scan QR code with your OTP application on mobile phone
'
	read -n 1 -s -r -p "Press any key to continue"

}



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

