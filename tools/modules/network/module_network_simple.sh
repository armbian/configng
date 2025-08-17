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
