module_options+=(
["store_netplan_config,author"]="Igor Pecovnik"
["store_netplan_config,ref_link"]=""
["store_netplan_config,feature"]="Storing netplan config to tmp"
["store_netplan_config,desc"]=""
["store_netplan_config,example"]=""
["store_netplan_config,status"]="Active"
)
#
# @description Restoring Netplan configuration from temp folder
#
function restore_netplan_config() {

	echo "Restoring NetPlan configs" | show_infobox
	# just in case
	if [[ -n ${restore_netplan_config_folder} ]]; then
		rm -f /etc/netplan/*
		rsync -ar ${restore_netplan_config_folder}/. /etc/netplan
	fi

}


module_options+=(
	["adjust_motd,author"]="igorpecovnik"
	["adjust_motd,ref_link"]=""
	["adjust_motd,feature"]="Adjust motd"
	["adjust_motd,desc"]="Adjust welcome screen (motd)"
	["adjust_motd,example"]=""
	["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear)
				echo "Clear screen on login"
				;;
			header)
				echo "Show header with logo"
				;;
			sysinfo)
				echo "Display system information"
				;;
			tips)
				echo "Show Armbian team tips"
				;;
			commands)
				echo "Show recommended commands"
				;;
			*)
				echo "No description"
				;;
		esac
	}

	# read status
	function motd_status() {
		source /etc/default/armbian-motd
		if [[ $MOTD_DISABLE == *$1* ]]; then
			echo "OFF"
		else
			echo "ON"
		fi
	}

	LIST=()
	for v in $(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"); do
		LIST+=("$v" "$(motd_desc $v)" "$(motd_status $v)")
	done

	INLIST=($(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"))
	CHOICES=$($DIALOG --separate-output --nocancel --title "Adjust welcome screen" --checklist "" 11 50 5 "${LIST[@]}" 3>&1 1>&2 2>&3)
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '
' | sort | uniq -u | tr '
' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
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

	get_user_continue "This action might disconnect you from network.

Are you sure network was configured correctly?" process_input
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
	["qr_code,author"]="Igor Pecovnik"
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
["store_netplan_config,author"]="Igor Pecovnik"
["store_netplan_config,ref_link"]=""
["store_netplan_config,feature"]="Storing netplan config to tmp"
["store_netplan_config,desc"]=""
["store_netplan_config,example"]=""
["store_netplan_config,status"]="Active"
)
#
# @description Storing Netplan configuration to temp folder
#
function store_netplan_config () {

	# store current configs to temporal folder
	restore_netplan_config_folder=$(mktemp -d /tmp/XXXXXXXXXX)
	rsync --quiet /etc/netplan/* ${restore_netplan_config_folder}/ 2>/dev/null
	trap restore_netplan_config 1 2 3 6

}


module_options+=(
	["update_skel,author"]="Igor Pecovnik"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="update_skel"
	["update_skel,desc"]="Update the /etc/skel files in users directories"
	["update_skel,example"]="update_skel"
	["update_skel,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function update_skel() {

	getent passwd |
		while IFS=: read -r username x uid gid gecos home shell; do
			if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ]; then
				continue
			fi
			tar -C /etc/skel/ -cf - . | su - "$username" -c "tar --skip-old-files -xf -"
		done

}


module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_embyserver"
	["update_skel,desc"]="Download a embyserver deb file from a URL and install using apt"
	["update_skel,example"]="install_embyserver"
	["update_skel,status"]="Active"
)
#
# Download a deb file from a URL and install using wget and apt with dialog progress bars
#
install_embyserver() {
	URL=$(curl -s https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest |
		grep "/emby-server-deb.*$(dpkg --print-architecture).deb" | cut -d : -f 2,3 | tr -d '"')
	cd ~/
	wget -O "emby-server.deb" $URL 2>&1 | stdbuf -oL awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' |
		$DIALOG --gauge "Please wait
Downloading ${URL##*/}" 8 70 0
	apt_install_wrapper apt-get -y install ~/emby-server.deb
	unlink emby-server.deb
	$DIALOG --msgbox "To test that Emby Server  has installed successfully
In a web browser go to http://localhost:8096 or 
http://127.0.0.1:8096 on this computer." 9 70
}


module_options+=(
	["are_headers_installed,author"]="Gunjan Gupta"
	["are_headers_installed,ref_link"]=""
	["are_headers_installed,feature"]="are_headers_installed"
	["are_headers_installed,desc"]="Check if kernel headers are installed"
	["are_headers_installed,example"]="are_headers_installed"
	["are_headers_installed,status"]="Pending Review"
	["are_headers_installed,doc_link"]=""
)
#
# @description Install kernel headers
#
function are_headers_installed() {
	if [[ -f /etc/armbian-release ]]; then
		PKG_NAME="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		PKG_NAME="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	check_if_installed ${PKG_NAME}
	return $?
}


module_options+=(
	["manage_overlayfs,author"]="igorpecovnik"
	["manage_overlayfs,ref_link"]=""
	["manage_overlayfs,feature"]="overlayfs"
	["manage_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["manage_overlayfs,example"]="manage_overlayfs enable|disable"
	["manage_overlayfs,status"]="Active"
)
#
# @description set/unset Armbian root filesystem to read only
#
function manage_overlayfs() {

	if [[ "$1" == "enable" ]]; then
		debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confold" -y install overlayroot cryptsetup cryptsetup-bin
		[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
		sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
		sed -i "s/^overlayroot_cfgdisk=.*/overlayroot_cfgdisk=\"enabled\"/" /etc/overlayroot.conf
	else
		overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
		debconf-apt-progress -- apt-get -y purge overlayroot cryptsetup cryptsetup-bin
	fi
	# reboot is mandatory
	reboot
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
				LIST=($(iw dev ${adapter} scan 2> /dev/null | grep 'SSID\|^BSS' | cut -d" " -f2 | sed "s/(.*//g" | xargs -n2 -d'
' | awk '{print $2,$1}'))
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
							netplan set --origin-hint ${yamlfile} wifis.$adapter.access-points."${SELECTED_SSID//./\.}".password=${SELECTED_PASSWORD}
							netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp4=true
							netplan set --origin-hint ${yamlfile} wifis.$adapter.dhcp6=true
							show_message <<< "$(netplan get all)"
							$DIALOG --title " Changing network settings " --yes-button "Yes" --no-button "Cancel" --yesno \
							"This action might disconnect you from network.

Are you sure network was configured correctly?" 9 50
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
			[[ -f /etc/netplan/armbian.yaml ]] && LIST+=("spoof" "Spoof MAC address")
			LIST_LENGTH=$((${#LIST[@]} / 2))
			wiredmode=$($DIALOG --title "Select IP mode" --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			if [[ "${wiredmode}" == "spoof" && $? == 0 ]]; then
				local mac_address=$(ip a s ${adapter} | grep link/ether | awk '{print $2}')
				mac_address=$($DIALOG --title "Enter MAC for $adapter" --inputbox "
Valid format: $mac_address" 9 40 "$mac_address" 3>&1 1>&2 2>&3)
				if [[ -n $mac_address && $? == 0 ]]; then
					netplan set --origin-hint ${yamlfile} ethernets.$adapter.macaddress=''$mac_address''
					netplan apply
				fi
			elif [[ "${wiredmode}" == "dhcp" && $? == 0 ]]; then
				[[ -f /etc/netplan/${yamlfile}.yaml ]] && sed -i -e 'H;x;/^\(  *\)
\1/{s/
.*//;x;d;}' -e 's/.*//;x;/bridges/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
				netplan set --origin-hint ${yamlfile} renderer=${NETWORK_RENDERER}
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp4=no
				netplan set --origin-hint ${yamlfile} ethernets.$adapter.dhcp6=no
				netplan set --origin-hint ${yamlfile} bridges.br0.interfaces='['$adapter']'
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp4=yes
				netplan set --origin-hint ${yamlfile} bridges.br0.dhcp6=yes
				show_message <<< "$(netplan get all)"
				$DIALOG --title " Changing network settings " --yes-button "Yes" --no-button "Cancel" --yesno \
				"This action might disconnect you from network.

Are you sure network was configured correctly?" 9 50
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
				[[ -f /etc/netplan/${yamlfile}.yaml ]] && sed -i -e 'H;x;/^\(  *\)
\1/{s/
.*//;x;d;}' -e 's/.*//;x;/bridges/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
				address=$($DIALOG --title "Enter IP for $adapter" --inputbox "
Valid format: $address" 9 40 "$address" 3>&1 1>&2 2>&3)
				if [[ -n $address && $? == 0 ]]; then
					defaultroute=$(ip route show default | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]" | head -1 | xargs)
					defaultroute=$($DIALOG --title "Enter IP for default route" --inputbox "
Valid format: $defaultroute" 9 40 "$defaultroute" 3>&1 1>&2 2>&3)
					if [[ -n $defaultroute && $? == 0 ]]; then
						nameservers="9.9.9.9,1.1.1.1"
						nameservers=$($DIALOG --title "Enter DNS server" --inputbox "
Valid format: $nameservers" 9 40 "$nameservers" 3>&1 1>&2 2>&3)
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
						"This action might disconnect you from network.

Are you sure network was configured correctly?" 9 50
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


module_options+=(
	["Headers_install,author"]="Joey Turner"
	["Headers_install,ref_link"]=""
	["Headers_install,feature"]="Headers_install"
	["Headers_install,desc"]="Install kernel headers"
	["Headers_install,example"]="is_package_manager_running"
	["Headers_install,status"]="Pending Review"
	["Headers_install,doc_link"]=""
)
#
# @description Install kernel headers
#
function Headers_install() {
	if ! is_package_manager_running; then
		if [[ -f /etc/armbian-release ]]; then
			INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
		else
			INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
		fi
		debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
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
function toggle_ipv6() {
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
	["check_desktop,author"]="Igor Pecovnik"
	["check_desktop,ref_link"]=""
	["check_desktop,feature"]="check_desktop"
	["check_desktop,desc"]="Migrated procedures from Armbian config."
	["check_desktop,example"]="check_desktop"
	["check_desktop,status"]="Active"
	["check_desktop,doc_link"]=""
)
#
# read desktop parameters
#
function check_desktop() {

	DISPLAY_MANAGER=""
	DESKTOP_INSTALLED=""
	check_if_installed nodm && DESKTOP_INSTALLED="nodm"
	check_if_installed lightdm && DESKTOP_INSTALLED="lightdm"
	check_if_installed lightdm && DESKTOP_INSTALLED="gnome"
	[[ -n $(service lightdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="lightdm"
	[[ -n $(service nodm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="nodm"
	[[ -n $(service gdm status 2> /dev/null | grep -w active) ]] && DISPLAY_MANAGER="gdm"

}

module_options+=(
	["see_ping,author"]="Joey Turner"
	["see_ping,ref_link"]=""
	["see_ping,feature"]="see_ping"
	["see_ping,desc"]="Check the internet connection with fallback DNS"
	["see_ping,example"]="see_ping"
	["see_ping,doc_link"]=""
	["see_ping,status"]="Active"
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
	["show_menu,author"]="Joey Turner"
	["show_menu,ref_link"]=""
	["show_menu,feature"]="show_menu"
	["show_menu,desc"]="Display a menu from pipe"
	["show_menu,example"]="show_menu <<< armbianmonitor -h  ; "
	["show_menu,doc_link"]=""
	["show_menu,status"]="Active"
)
#
#
#
function show_menu() {

	# Get the input and convert it into an array of options
	inpu_raw=$(cat)
	# Remove the lines before -h
	input=$(echo "$inpu_raw" | sed 's/-\([a-zA-Z]\)/\1/' | grep '^  [a-zA-Z] ' | grep -v '\[')
	options=()
	while read -r line; do
		package=$(echo "$line" | awk '{print $1}')
		description=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
		options+=("$package" "$description")
	done <<< "$input"

	# Display the menu and get the user's choice
	[[ $DIALOG != "bash" ]] && choice=$($DIALOG --title "$TITLE" --menu "Choose an option:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)

	# Check if the user made a choice
	if [ $? -eq 0 ]; then
		echo "$choice"
	else
		exit 0
	fi

}



menu_options+=(
	["process_input(,author"]="Joey Turner"
	["process_input(,ref_link"]=""
	["process_input(,feature"]="process_input"
	["process_input(,desc"]="used to process the user's choice paired with process_input("
	["process_input(,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["process_input(,status"]="Active"
	["process_input(,doc_link"]=""
)
#
# Function to process the user's choice paired with get_user_continue
#
function process_input() {
	local input="$1"
	if [ "$input" = "No" ]; then
		# user canceled
		echo "User canceled. exiting"
		exit 0
	fi
}
module_options+=(
	["set_header_remove,author"]="Igor Pecovnik"
	["set_header_remove,ref_link"]=""
	["set_header_remove,feature"]="set_header_remove"
	["set_header_remove,desc"]="Migrated procedures from Armbian config."
	["set_header_remove,example"]="set_header_remove"
	["set_header_remove,doc_link"]=""
	["set_header_remove,status"]="Active"
	["set_header_remove,doc_ink"]=""
)
#
# remove kernel headers
#
function set_header_remove() {

	REMOVE_PKG="linux-headers-*"
	if [[ -n $(dpkg -l | grep linux-headers) ]]; then
		debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
		rm -rf /usr/src/linux-headers*
	else
		debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
	fi
	# cleanup
	apt clean
	debconf-apt-progress -- apt -y autoremove

}


module_options+=(
	["get_user_continue,author"]="Joey Turner"
	["get_user_continue,ref_link"]=""
	["get_user_continue,feature"]="get_user_continue"
	["get_user_continue,desc"]="Display a Yes/No dialog box and process continue/exit"
	["get_user_continue,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["get_user_continue,doc_link"]=""
	["get_user_continue,status"]="Active"
)
#
# Function to display a Yes/No dialog box
#
function get_user_continue() {
	local message="$1"
	local next_action="$2"

	if $($DIALOG --yesno "$message" 15 80 3>&1 1>&2 2>&3); then
		$next_action
	else
		$next_action "No"
	fi
}

menu_options+=(
	["process_input(,author"]="Joey Turner"
	["process_input(,ref_link"]=""
	["process_input(,feature"]="process_input"
	["process_input(,desc"]="used to process the user's choice paired with process_input("
	["process_input(,example"]="get_user_continue 'Do you wish to continue?' process_input"
	["process_input(,status"]="Active"
	["process_input(,doc_link"]=""
)
#
# Function to process the user's choice paired with get_user_continue
#
function process_input() {
	local input="$1"
	if [ "$input" = "No" ]; then
		# user canceled
		echo "User canceled. exiting"
		exit 0
	fi
}


module_options+=(
	["set_stable,author"]="Tearran"
	["set_stable,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_stable,feature"]="set_stable"
	["set_stable,desc"]="Set Armbian to stable release"
	["set_stable,example"]="set_stable"
	["set_stable,status"]="Active"
)
#
# @description Set Armbian to stable release
#
function set_stable() {

	if ! grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}


module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_docker"
	["update_skel,desc"]="Install docker from a repo using apt"
	["update_skel,example"]="install_docker engine"
	["update_skel,status"]="Active"
)
#
# Install Docker from repo using apt
# Setup sources list and GPG key then install the app. If you want a full desktop then $1=desktop
#
install_docker() {
	# Check if repo for distribution exists.
	URL="https://download.docker.com/linux/${DISTRO,,}/dists/$DISTROID"
	if wget --spider "${URL}" 2> /dev/null; then
		# Add Docker's official GPG key:
		wget -qO - https://download.docker.com/linux/${DISTRO,,}/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/docker.gpg > /dev/null
		if [[ $? -eq 0 ]]; then
			# Add the repository to Apt sources:
			cat <<- EOF > "/etc/apt/sources.list.d/docker.list"
			deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO,,} $DISTROID stable
			EOF
			apt_install_wrapper apt-get update
			# Install docker
			if [ "$1" = "engine" ]; then
				apt_install_wrapper apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			else
				apt_install_wrapper apt-get -y install docker-ce docker-ce-cli containerd.io
			fi
			systemctl enable docker.service > /dev/null 2>&1
			systemctl enable containerd.service > /dev/null 2>&1
			$DIALOG --msgbox "To test that Docker has installed successfully
run the following command: docker run hello-world" 9 70
		fi
	else
		$DIALOG --msgbox "ERROR ! ${DISTRO} $DISTROID distribution not found in repository!" 7 70
	fi
}


module_options+=(
	["parse_menu_items,author"]="Gunjan Gupta"
	["parse_menu_items,ref_link"]=""
	["parse_menu_items,feature"]="parse_menu_items"
	["parse_menu_items,desc"]="Parse json to get list of desired menu or submenu items"
	["parse_menu_items,example"]="parse_menu_items 'menu_options_array'"
	["parse_menu_items,doc_link"]=""
	["parse_menu_items,status"]="Active"
)
#
# Function to parse the menu items
#
parse_menu_items() {
	local -n options=$1
	while IFS= read -r id; do
		IFS= read -r description
		IFS= read -r condition
		# If the condition field is not empty and not null, run the function specified in the condition
		if [[ -n $condition && $condition != "null" ]]; then
			# If the function returns a truthy value, add the menu item to the menu
			if eval $condition; then
				options+=("$id" "  -  $description")
			fi
		else
			# If the condition field is empty or null, add the menu item to the menu
			options+=("$id" "  -  $description ")
		fi
	done < <(echo "$json_data" | jq -r '.menu[] | '${parent_id:+".. | objects | select(.id==\"$parent_id\") | .sub[]? |"}' select(.status != "Disabled") | "\(.id)
\(.description)
\(.condition)"' || exit 1)
}



module_options+=(
	["set_colors,author"]="Joey Turner"
	["set_colors,ref_link"]=""
	["set_colors,feature"]="set_colors"
	["set_colors,desc"]="Change the background color of the terminal or dialog box"
	["set_colors,example"]="set_colors 0-7"
	["set_colors,doc_link"]=""
	["set_colors,status"]="Active"
)
#
# Function to set the tui colors
#
function set_colors() {
	local color_code=$1

	if [ "$DIALOG" = "whiptail" ]; then
		set_newt_colors "$color_code"
		#echo "color code: $color_code" | show_infobox ;
	elif [ "$DIALOG" = "dialog" ]; then
		set_term_colors "$color_code"
	else
		echo "Invalid dialog type"
		return 1
	fi
}
#
# Function to set the colors for newt
#
function set_newt_colors() {
	local color_code=$1
	case $color_code in
		0) color="black" ;;
		1) color="red" ;;
		2) color="green" ;;
		3) color="yellow" ;;
		4) color="blue" ;;
		5) color="magenta" ;;
		6) color="cyan" ;;
		7) color="white" ;;
		8) color="black" ;;
		9) color="red" ;;
		*) return ;;
	esac
	export NEWT_COLORS="root=,$color"
}
#
# Function to set the colors for terminal
#
function set_term_colors() {
	local color_code=$1
	case $color_code in
		0) color="\e[40m" ;; # black
		1) color="\e[41m" ;; # red
		2) color="\e[42m" ;; # green
		3) color="\e[43m" ;; # yellow
		4) color="\e[44m" ;; # blue
		5) color="\e[45m" ;; # magenta
		6) color="\e[46m" ;; # cyan
		7) color="\e[47m" ;; # white
		*)
			echo "Invalid color code"
			return 1
			;;
	esac
	echo -e "$color"
}
#
# Function to reset the colors
#
function reset_colors() {
	echo -e "\e[0m"
}
module_options+=(
	["sanitize_input,author"]=""
	["sanitize_input,ref_link"]=""
	["sanitize_input,feature"]="sanitize_input"
	["sanitize_input,desc"]="sanitize input cli"
	["sanitize_input,example"]="sanitize_input"
	["sanitize_input,status"]="Pending Review"
	["sanitize_input,doc_link"]=""
)
#
# sanitize input cli
#
sanitize_input() {
	local sanitized_input=()
	for arg in "$@"; do
		if [[ $arg =~ ^[a-zA-Z0-9_=]+$ ]]; then
			sanitized_input+=("$arg")
		else
			echo "Invalid argument: $arg"
			exit 1
		fi
	done
	echo "${sanitized_input[@]}"
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
#
#
#
function default_wireless_network_config(){

	# defaul yaml file
	local yamlfile=${1:-armbian}
	local adapter=${2:-wlan0}

	# remove wifi from netplan
	if [[ -f /etc/netplan/${yamlfile}.yaml ]]; then
		sed -i -e 'H;x;/^\(  *\)
\1/{s/
.*//;x;d;}' -e 's/.*//;x;/'$adapter':/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
		sed -i -e 'H;x;/^\(  *\)
\1/{s/
.*//;x;d;}' -e 's/.*//;x;/- '$adapter'/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
		sed -i -e 'H;x;/^\(  *\)
\1/{s/
.*//;x;d;}' -e 's/.*//;x;/wifis:/{s/^\( *\).*/ \1/;x;d;}' /etc/netplan/${yamlfile}.yaml
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
	["armbian_fw_manipulate,author"]="Igor Pecovnik"
	["armbian_fw_manipulate,ref_link"]=""
	["armbian_fw_manipulate,feature"]="armbian_fw_manipulate"
	["armbian_fw_manipulate,desc"]="freeze/unhold/reinstall armbian related packages."
	["armbian_fw_manipulate,example"]="armbian_fw_manipulate unhold|freeze|reinstall"
	["armbian_fw_manipulate,status"]="Active"
)
#
# freeze/unhold/reinstall armbian firmware packages
#
armbian_fw_manipulate() {

	local function=$1
	local version=$2
	local branch=$3

	[[ -n $version ]] && local version="=${version}"

	# fallback to $BRANCH
	[[ -z "${branch}" ]] && branch="${BRANCH}"
	[[ -z "${branch}" ]] && branch="current" # fallback in case we switch to very old BSP that have no such info

	# packages to install
	local armbian_packages=(
		"linux-u-boot-${BOARD}-${branch}"
		"linux-image-${branch}-${LINUXFAMILY}"
		"linux-dtb-${branch}-${LINUXFAMILY}"
		"armbian-zsh"
		"armbian-bsp-cli-${BOARD}-${branch}"
	)

	# reinstall headers only if they were previously installed
	if are_headers_installed; then
		local armbian_packages+="linux-headers-${branch}-${LINUXFAMILY}"
	fi

	local packages=""
	for pkg in "${armbian_packages[@]}"; do
		if [[ "${function}" == reinstall ]]; then
			local pkg_search=$(apt search "$pkg" 2> /dev/null | grep "^$pkg")
			if [[ $? -eq 0 && -n "${pkg_search}" ]]; then
				if [[ "${pkg_search}" == *$version* ]] ; then
				packages+="$pkg${version} ";
				else
				packages+="$pkg ";
				fi
			fi
		else
			if check_if_installed $pkg; then
				packages+="$pkg${version} "
			fi
		fi
	done
	for pkg in "${packages[@]}"; do
		case $function in
			unhold) apt-mark unhold ${pkg} | show_infobox ;;
			hold) apt-mark hold ${pkg} | show_infobox ;;
			reinstall)
				apt_install_wrapper apt-get -y --simulate --download-only --allow-change-held-packages --allow-downgrades install ${pkg}
				if [[ $? == 0 ]]; then
					apt_install_wrapper apt-get -y purge "linux-u-boot-*" "linux-image-*" "linux-dtb-*" "linux-headers-*" "armbian-zsh-*" "armbian-bsp-cli-*" # remove all branches
					apt_install_wrapper apt-get -y --allow-change-held-packages install ${pkg}
					apt_install_wrapper apt-get -y autoremove
					apt_install_wrapper apt-get -y clean
				else
					exit 1
				fi


				;;
			*) return ;;
		esac
	done
}


module_options+=(
	["manage_desktops,author"]="@igorpecovnik"
	["manage_desktops,ref_link"]=""
	["manage_desktops,feature"]="install_de"
	["manage_desktops,desc"]="Install Desktop environment"
	["manage_desktops,example"]="manage_desktops xfce install"
	["manage_desktops,status"]="Active"
)
#
# Install desktop
#
function manage_desktops() {

	local desktop=$1
	local command=$2

	# get user who executed this script
	if [ $SUDO_USER ]; then local user=$SUDO_USER; else local user=$(whoami); fi

	case "$command" in
		install)

			# desktops has different default login managers
			case "$desktop" in
				gnome)
					echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install gdm3
				;;
				kde-neon)
					echo "/usr/sbin/sddm" > /etc/X11/default-display-manager
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install sddm
				;;
				*)
					echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
					#apt_install_wrapper DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install lightdm
				;;
			esac

			# just make sure we have everything in order
			apt_install_wrapper dpkg --configure -a

			# install desktop
			export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
			apt_install_wrapper apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends install armbian-${DISTROID}-desktop-${desktop}

			# add user to groups
			for additionalgroup in sudo netdev audio video dialout plugdev input bluetooth systemd-journal ssh; do
				usermod -aG ${additionalgroup} ${user} 2> /dev/null
			done

			# set up profile sync daemon on desktop systems
			which psd > /dev/null 2>&1
			if [[ $? -eq 0 && -z $(grep overlay-helper /etc/sudoers) ]]; then
				echo "${user} ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" >> /etc/sudoers
				touch /home/${user}/.activate_psd
			fi
			# update skel
			update_skel

			# enable auto login
			manage_desktops "$desktop" "auto"

			# stop display managers in case we are switching them
			service gdm3 stop
			service lightdm stop
			service sddm stop

			# start new default display manager
			service display-manager restart
		;;
		uninstall)
			# we are uninstalling all variants until build time packages are fixed to prevent installing one over another
			service display-manager stop
			apt_install_wrapper apt-get -o Dpkg::Options::="--force-confold" -y --install-recommends purge armbian-${DISTROID}-desktop-$1 \
			xfce4-session gnome-session slick-greeter lightdm gdm3 sddm cinnamon-session i3-wm
			apt_install_wrapper apt-get -y autoremove
			# disable autologins
			rm -f /etc/gdm3/custom.conf
			rm -f /etc/sddm.conf.d/autologin.conf
			rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
		;;
		auto)
			# desktops has different login managers and autologin methods
			case "$desktop" in
				gnome)
					# gdm3 autologin
					mkdir -p /etc/gdm3
					cat <<- EOF > /etc/gdm3/custom.conf
					[daemon]
					AutomaticLoginEnable = true
					AutomaticLogin = ${user}
					EOF
				;;
				kde-neon)
					# sddm autologin
					cat <<- EOF > "/etc/sddm.conf.d/autologin.conf"
					[Autologin]
					User=${user}
					EOF
				;;
				*)
					# lightdm autologin
					mkdir -p /etc/lightdm/lightdm.conf.d
					cat <<- EOF > "/etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf"
					[Seat:*]
					autologin-user=${user}
					autologin-user-timeout=0
					user-session=xfce
					EOF

				;;
			esac
			# restart after selection
			service display-manager restart
		;;
		manual)
			case "$desktop" in
				gnome)    rm -f  /etc/gdm3/custom.conf ;;
				kde-neon) rm -f /etc/sddm.conf.d/autologin.conf ;;
				*)        rm -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ;;
			esac
			# restart after selection
			service display-manager restart
		;;
	esac

}


module_options+=(
	["apt_install_wrapper,author"]="igorpecovnik"
	["apt_install_wrapper,ref_link"]=""
	["apt_install_wrapper,feature"]="Install wrapper"
	["apt_install_wrapper,desc"]="Install wrapper"
	["apt_install_wrapper,example"]="apt_install_wrapper apt-get -y purge armbian-zsh"
	["apt_install_wrapper,status"]="Active"
)
#
# @description Use TUI / GUI for apt install if exists
#
function apt_install_wrapper() {

	if [ -t 0 ]; then
		debconf-apt-progress -- "$@"
	else
		# Terminal not defined - proceed without TUI
		"$@"
	fi
}


module_options+=(
	["change_system_hostname,author"]="igorpecovnik"
	["change_system_hostname,ref_link"]=""
	["change_system_hostname,feature"]="Change hostname"
	["change_system_hostname,desc"]="change_system_hostname"
	["change_system_hostname,example"]="change_system_hostname"
	["change_system_hostname,status"]="Active"
)
#
# @description Change system hostname
#
function change_system_hostname() {
	local new_hostname=$($DIALOG --title "Enter new hostnane" --inputbox "" 7 50 3>&1 1>&2 2>&3)
	[ $? -eq 0 ] && [ -n "${new_hostname}" ] && hostnamectl set-hostname "${new_hostname}"
}


module_options+=(
	["see_current_apt,author"]="Joey Turner"
	["see_current_apt,ref_link"]=""
	["see_current_apt,feature"]="see_current_apt"
	["see_current_apt,desc"]="Check when apt list was last updated and suggest updating or update"
	["see_current_apt,example"]="see_current_apt || see_current_apt update"
	["see_current_apt,doc_link"]=""
	["see_current_apt,status"]="Active"
)
#
# Function to check when the package list was last updated
#
see_current_apt() {
	# Number of seconds in a day
	local update_apt="$1"
	local day=86400
	local ten_minutes=600
	# Get the current date as a Unix timestamp
	local now=$(date +%s)

	# Get the timestamp of the most recently updated file in /var/lib/apt/lists/
	local update=$(stat -c %Y /var/lib/apt/lists/* 2>/dev/null | sort -n | tail -1)

	# Check if the update timestamp was found
	if [[ -z "$update" ]]; then
		echo "No package lists found."
		return 1 # No package lists exist
	fi

	# Calculate the number of seconds since the last update
	local elapsed=$((now - update))

	# Check if any apt-related processes are running
	if ps -C apt-get,apt,dpkg > /dev/null; then
		echo "A package manager is currently running."
		export running_pkg="true"
		return 1 # The processes are running
	else
		export running_pkg="false"
	fi

	# Check if the package list is up-to-date
	if ((elapsed < ten_minutes)); then
		[[ "$update_apt" != "update" ]] && echo "The package lists are up-to-date."
		return 0 # The package lists are up-to-date
	else
		[[ "$update_apt" != "update" ]] && echo "Update the package lists." # Suggest updating
		[[ "$update_apt" == "update" ]] && apt_install_wrapper apt-get update
		return 0 # The package lists are not up-to-date
	fi
}


module_options+=(
	["see_monitoring,author"]="Joey Turner"
	["see_monitoring,ref_link"]=""
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]="see_monitoring"
	["see_monitoring,status"]="review"
	["see_monitoring,doc_link"]=""
)
#
# @decrition generate a menu for armbianmonitor
#
function see_monitoring() {
	if [ -f /usr/bin/htop ]; then
		choice=$(armbianmonitor -h | grep -Ev '^\s*-c\s|^\s*-M\s' | show_menu)

		armbianmonitor -$choice

	else
		echo "htop is not installed"
	fi
}



menu_options+=(
	["get_headers_kernel,author"]="Igor Pecovnik"
	["get_headers_kernel,ref_link"]=""
	["get_headers_kernel,feature"]="get_headers_install"
	["get_headers_kernel,desc"]="Migrated procedures from Armbian config."
	["get_headers_kernel,example"]="get_headers_install"
	["get_headers_kernel,status"]="Active"
	["get_headers_kernel,doc_link"]=""
)
#
# install kernel headers
#
function get_headers_install() {

	if [[ -f /etc/armbian-release ]]; then
		INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}"
	else
		INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
	fi

	debconf-apt-progress -- apt-get -y install ${INSTALL_PKG} || exit 1

}
module_options+=(
	["toggle_ssh_lastlog,author"]="tearran"
	["toggle_ssh_lastlog,ref_link"]=""
	["toggle_ssh_lastlog,feature"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,desc"]="Toggle SSH lastlog"
	["toggle_ssh_lastlog,example"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,status"]="Active"
)
#
# @description Toggle SSH lastlog
#
function toggle_ssh_lastlog() {

	if ! grep -q '^#\?PrintLastLog ' "${SDCARD}/etc/ssh/sshd_config"; then
		# If PrintLastLog is not found, append it with the value 'yes'
		echo 'PrintLastLog no' >> "${SDCARD}/etc/ssh/sshd_config"
		sudo service ssh restart
	else
		# If PrintLastLog is found, toggle between 'yes' and 'no'
		sed -i '/^#\?PrintLastLog /
{
	s/PrintLastLog yes/PrintLastLog no/;
	t;
	s/PrintLastLog no/PrintLastLog yes/
}' "${SDCARD}/etc/ssh/sshd_config"
		sudo service ssh restart
	fi

}


module_options+=(
	["execute_command,author"]="Joey Turner"
	["execute_command,ref_link"]=""
	["execute_command,feature"]="execute_command"
	["execute_command,desc"]="Needed by generate_menu"
	["execute_command,example"]=""
	["execute_command,doc_link"]=""
	["execute_command,status"]="Active"
)
#
# Function to execute the command
#
function execute_command() {
	local id=$1

	# Extract commands
	local commands=$(jq -r --arg id "$id" '
		.menu[] |
		.. |
		objects |
		select(.id == $id) |
		.command[]?' "$json_file")

	# Check if a about exists
	local about=$(jq -r --arg id "$id" '
		.menu[] |
		.. |
		objects |
		select(.id == $id) |
		.about?' "$json_file")

	# If a about exists, display it and wait for user confirmation
	if [[ "$about" != "null" && $INPUTMODE != "cmd" ]]; then
		get_user_continue "$about
Would you like to continue?" process_input
	fi

	# Execute each command
	for command in "${commands[@]}"; do
		[[ -n "$debug" ]] && echo "$command"
		eval "$command"
	done
}


module_options+=(
	["connect_bt_interface,author"]="Igor Pecovnik"
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
				expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address";
			sleep 1;send "remove $address";sleep 1;expect -re $prompt;send "scan on";sleep 8;send "scan off";
			expect "Controller";send "trust $address";sleep 2;send "pair $address";sleep 2;send "connect $address";
			send_user "
Should be paired now.";sleep 2;send "quit";expect eof'
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
	["release_upgrade,author"]="Igor Pecovnik"
	["release_upgrade,ref_link"]=""
	["release_upgrade,feature"]="Upgrade upstream distribution release"
	["release_upgrade,desc"]="Upgrade to next stable or rolling release"
	["release_upgrade,example"]="release_upgrade stable verify"
	["release_upgrade,status"]="Active"
)
#
# Upgrade distribution
#
function release_upgrade(){

	local upgrade_type=$1
	local verify=$2

	local distroid=${DISTROID}

	if [[ "${upgrade_type}" == stable ]]; then
		local filter=$(grep "supported" /etc/armbian-distribution-status | cut -d"=" -f1)
	elif [[ "${upgrade_type}" == rolling ]]; then
		local filter=$(grep "eos\|csc" /etc/armbian-distribution-status | cut -d"=" -f1 | sed "s/sid/testing/g")
	else
		local filter=$(cat /etc/armbian-distribution-status | cut -d"=" -f1)
	fi

	local upgrade=$(for j in $filter; do
		for i in $(grep "^${distroid}" /etc/armbian-distribution-status | cut -d";" -f2 | cut -d"=" -f2 | sed "s/,/ /g"); do
			if [[ $i == $j ]]; then
				echo $i
			fi
		done
	done | tail -1)

	if [[ -z "${upgrade}" ]]; then
		return 1;
	elif [[ -z "${verify}" ]]; then
		[[ -f /etc/apt/sources.list.d/ubuntu.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/ubuntu.sources
		[[ -f /etc/apt/sources.list.d/debian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/debian.sources
		[[ -f /etc/apt/sources.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list
		[[ "${upgrade}" == "testing" ]] && upgrade="sid" # our repo and everything is tied to sid
		[[ -f /etc/apt/sources.list.d/armbian.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get -y update
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" upgrade --without-new-pkgs
		apt_install_wrapper apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade
		apt_install_wrapper apt-get -y --purge autoremove
	fi
}


module_options+=(
	["is_package_manager_running,author"]="Igor Pecovnik"
	["is_package_manager_running,ref_link"]=""
	["is_package_manager_running,feature"]="is_package_manager_running"
	["is_package_manager_running,desc"]="Migrated procedures from Armbian config."
	["is_package_manager_running,example"]="is_package_manager_running"
	["is_package_manager_running,status"]="Active"
)
#
# check if package manager is doing something
#
function is_package_manager_running() {

	if ps -C apt-get,apt,dpkg > /dev/null; then
		[[ -z $scripted ]] && echo -e "
Package manager is running in the background. 

Can't install dependencies. Try again later." | show_infobox
		return 0
	else
		return 1
	fi

}


module_options+=(
	["set_rolling,author"]="Tearran"
	["set_rolling,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L1446"
	["set_rolling,feature"]="set_rolling"
	["set_rolling,desc"]="Set Armbian to rolling release"
	["set_rolling,example"]="set_rolling"
	["set_rolling,status"]="Active"
)
#
# @description Set Armbian to rolling release
#
function set_rolling() {

	if ! grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list; then
		sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
		apt_install_wrapper apt-get update
		armbian_fw_manipulate "reinstall"
	fi
}


module_options+=(
	["generate_top_menu,author"]="Joey Turner"
	["generate_top_menu,ref_link"]=""
	["generate_top_menu,feature"]="generate_top_menu"
	["generate_top_menu,desc"]="Build the main menu from a object"
	["generate_top_menu,example"]="generate_top_menu 'json_data'"
	["generate_top_menu,doc_link"]=""
	["generate_top_menu,status"]="Active"
)
#
# Function to generate the main menu from a JSON object
#
generate_top_menu() {
	local json_data="$1"
	local status="$ARMBIAN $KERNELID ($DISTRO $DISTROID)"
	local backtitle="$BACKTITLE"

	while true; do
		local menu_options=()

		parse_menu_items menu_options

		local OPTION=$($DIALOG --backtitle "$backtitle" --title "$TITLE" --menu "$status" 0 80 9 "${menu_options[@]}" \
			--ok-button Select --cancel-button Exit 3>&1 1>&2 2>&3)
		local exitstatus=$?

		if [ $exitstatus = 0 ]; then
			[ -z "$OPTION" ] && break
			[[ -n "$debug" ]] && echo "$OPTION"
			generate_menu "$OPTION"
		fi
	done
}


module_options+=(
	["set_runtime_variables,author"]="Igor Pecovnik"
	["set_runtime_variables,ref_link"]=""
	["set_runtime_variables,feature"]="set_runtime_variables"
	["set_runtime_variables,desc"]="Run time variables Migrated procedures from Armbian config."
	["set_runtime_variables,example"]="set_runtime_variables"
	["set_runtime_variables,status"]="Active"
)
#
# gather info about the board and start with loading menu variables
#
function set_runtime_variables() {

	missing_dependencies=()

	# Check if whiptail is available and set DIALOG
	if [[ -z "$DIALOG" ]]; then
		missing_dependencies+=("whiptail")
	fi

	# Check if jq is available
	if ! [[ -x "$(command -v jq)" ]]; then
		missing_dependencies+=("jq")
	fi

	# If any dependencies are missing, print a combined message and exit
	if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
		if is_package_manager_running; then
			sudo apt install ${missing_dependencies[*]}
		fi
	fi

	# Determine which network renderer is in use for NetPlan
	if systemctl is-active NetworkManager 1> /dev/null; then
		NETWORK_RENDERER=NetworkManager
	else
		NETWORK_RENDERER=networkd
	fi

	DIALOG_CANCEL=1
	DIALOG_ESC=255

	# we have our own lsb_release which does not use Python. Others shell install it here
	if [[ ! -f /usr/bin/lsb_release ]]; then
		if is_package_manager_running; then
			sleep 3
		fi
		debconf-apt-progress -- apt-get update
		debconf-apt-progress -- apt -y -qq --allow-downgrades --no-install-recommends install lsb-release
	fi

	[[ -f /etc/armbian-release ]] && source /etc/armbian-release && ARMBIAN="Armbian $VERSION $IMAGE_TYPE"
	DISTRO=$(lsb_release -is)
	DISTROID=$(lsb_release -sc)
	KERNELID=$(uname -r)
	[[ -z "${ARMBIAN// /}" ]] && ARMBIAN="$DISTRO $DISTROID"
	DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
	LOCALIPADD=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
	BACKTITLE="Contribute: https://github.com/armbian/configng"
	TITLE="Armbian configuration utility"
	[[ -z "${DEFAULT_ADAPTER// /}" ]] && DEFAULT_ADAPTER="lo"

	# detect desktop
	check_desktop

}


module_options+=(
["manage_dtoverlays,author"]="Gunjan Gupta"
["manage_dtoverlays,ref_link"]=""
["manage_dtoverlays,feature"]="dtoverlays"
["manage_dtoverlays,desc"]="Enable/disable device tree overlays"
["manage_dtoverlays,example"]="manage_dtoverlays"
["manage_dtoverlays,status"]="Active"
)
#
# @description Enable/disable device tree overlays
#
function manage_dtoverlays () {
	# check if user agree to enter this area
	local changes="false"
	local overlayconf="/boot/armbianEnv.txt"
	while true; do
		local options=()
		j=0
		available_overlays=$(ls -1 ${OVERLAY_DIR}/*.dtbo | sed "s#^${OVERLAY_DIR}/##" | sed 's/.dtbo//g' | grep $BOOT_SOC | tr '
' ' ')
		for overlay in ${available_overlays}; do
			local status="OFF"
			grep '^fdt_overlays' ${overlayconf} | grep -qw ${overlay} && status=ON
			options+=( "$overlay" "" "$status")
		done
		selection=$($DIALOG --title "Manage devicetree overlays" --cancel-button "Back" \
			--ok-button "Save" --checklist "
Use <space> to toggle functions and save them.
Exit when you are done.
 " \
			0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		exit_status=$?
		case $exit_status in
			0)
				changes="true"
				newoverlays=$(echo $selection | sed 's/"//g')
				sed -i "s/^fdt_overlays=.*/fdt_overlays=$newoverlays/" ${overlayconf}
				if ! grep -q "^fdt_overlays" ${overlayconf}; then echo "fdt_overlays=$newoverlays" >> ${overlayconf}; fi
				sync
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					$DIALOG --title " Reboot required " --yes-button "Reboot" \
						--no-button "Cancel" --yesno "A reboot is required to apply the changes. Shall we reboot now?" 7 34
					if [[ $? = 0 ]]; then
						reboot
					fi
				fi
				break
				;;
			255)
				;;
		esac
	done
}


module_options+=(
	["check_if_installed,author"]="Igor Pecovnik"
	["check_if_installed,ref_link"]=""
	["check_if_installed,feature"]="check_if_installed"
	["check_if_installed,desc"]="Migrated procedures from Armbian config."
	["check_if_installed,example"]="check_if_installed nano"
	["check_if_installed,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function check_if_installed() {

	local DPKG_Status="$(dpkg -s "$1" 2> /dev/null | awk -F": " '/^Status/ {print $2}')"
	if [[ "X${DPKG_Status}" = "X" || "${DPKG_Status}" = *deinstall* || "${DPKG_Status}" = *not-installed* ]]; then
		return 1
	else
		return 0
	fi

}


module_options+=(
	["Headers_remove,author"]="Joey Turner"
	["Headers_remove,ref_link"]="https://github.com/armbian/config/blob/master/debian-config-jobs#L160"
	["Headers_remove,feature"]="Headers_remove"
	["Headers_remove,desc"]="Remove Linux headers"
	["Headers_remove,example"]="Headers_remove"
	["Headers_remove,status"]="Pending Review"
	["Headers_remove,doc_link"]="https://github.com/armbian/config/wiki#System"
)
#
# @description Remove Linux headers
#
function Headers_remove() {
	if ! is_package_manager_running; then
		REMOVE_PKG="linux-headers-*"
		if [[ -n $(dpkg -l | grep linux-headers) ]]; then
			debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
			rm -rf /usr/src/linux-headers*
		else
			debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
		fi
		# cleanup
		apt clean
		debconf-apt-progress -- apt -y autoremove
	fi
}


module_options+=(
	["show_infobox,author"]="Joey Turner"
	["show_infobox,ref_link"]=""
	["show_infobox,feature"]="show_infobox"
	["show_infobox,desc"]="pipeline strings to an infobox "
	["show_infobox,example"]="show_infobox <<< 'hello world' ; "
	["show_infobox,doc_link"]=""
	["show_infobox,status"]="Active"
)
#
# Function to display an infobox with a message
#
function show_infobox() {
	export TERM=ansi
	local input
	local BACKTITLE="$BACKTITLE"
	local -a buffer # Declare buffer as an array
	if [ -p /dev/stdin ]; then
		while IFS= read -r line; do
			buffer+=("$line") # Add the line to the buffer
			# If the buffer has more than 10 lines, remove the oldest line
			if ((${#buffer[@]} > 18)); then
				buffer=("${buffer[@]:1}")
			fi
			# Display the lines in the buffer in the infobox

			TERM=ansi $DIALOG --title "$TITLE" --infobox "$(printf "%s
" "${buffer[@]}")" 16 90
			sleep 0.5
		done
	else

		input="$1"
		TERM=ansi $DIALOG --title "$TITLE" --infobox "$input" 6 80
	fi
	echo -ne '[3J' # clear the screen
}


module_options+=(
	["show_message,author"]="Joey Turner"
	["show_message,ref_link"]=""
	["show_message,feature"]="show_message"
	["show_message,desc"]="Display a message box"
	["show_message,example"]="show_message <<< 'hello world' "
	["show_message,doc_link"]=""
	["show_message,status"]="Active"
)
#
# Function to display a message box
#
function show_message() {
	# Read the input from the pipe
	input=$(cat)

	# Display the "OK" message box with the input data
	if [[ $DIALOG != "bash" ]]; then
		$DIALOG --title "$TITLE" --msgbox "$input" 0 0
	else
		echo -e "$input"
		read -p -r "Press [Enter] to continue..."
	fi
}


module_options+=(
["about_armbian_configng,author"]="Igor Pecovnik"
["about_armbian_configng,ref_link"]=""
["about_armbian_configng,feature"]="Show info"
["about_armbian_configng,desc"]=""
["about_armbian_configng,example"]=""
["about_armbian_configng,status"]="Active"
)
#
# @description Show general information about this tool
#
funtion about_armbian_configng() {

	echo "Armbian Config: The Next Generation"
	echo ""
	echo "How to make this tool even better?"
	echo ""
	echo "- propose new features or software titles"
	echo "  https://github.com/armbian/configng/issues/new?template=feature-reqests.yml"
	echo ""
	echo "- report bugs"
	echo "  https://github.com/armbian/configng/issues/new?template=bug-reports.yml"
	echo ""
	echo "- support developers with a small donation"
	echo "  https://github.com/sponsors/armbian"
	echo ""

}


module_options+=(
	["switch_kernels,author"]="Igor"
	["switch_kernels,ref_link"]=""
	["switch_kernels,feature"]=""
	["switch_kernels,desc"]="Switching to alternative kernels"
	["switch_kernels,example"]=""
	["switch_kernels,status"]="Active"
)
#
# @description Switch between alternative kernels
#
function switch_kernels() {

	# we only allow switching kerneles that are in the test pool
	[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,current,edge"
	local kernel_test_target=$(for x in ${KERNEL_TEST_TARGET//,/ }; do echo "linux-image-$x-${LINUXFAMILY}"; done;)
	local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}')
	# just in case current is not installed
	[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"
	local search_exec="apt-cache show ${kernel_test_target} | grep -E \"Package:|Version:|version:|family\" | grep -v \"Config-Version\" | sed -n -e 's/^.*: //p' | sed 's/\.$//g' | xargs -n3 -d'
' | sed \"s/ /=/\" $grep_current_kernel"
	IFS=$'
'
	local LIST=()
	for line in $(eval ${search_exec}); do
		LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
	done
	unset IFS
	local list_length=$((${#LIST[@]} / 2))
	if [ "$list_length" -eq 0 ]; then
		dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "
No other kernels available!" 7 32
	else
		local target_version=$(whiptail --separate-output --title "Select kernel" --menu "ed" $((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ -n "${target_version}" ]; then
			local branch=${target_version##*image-}
			armbian_fw_manipulate "reinstall" "${target_version/*=/}" "${branch%%-*}"
		fi
	fi
}


module_options+=(
	["get_user_continue_secure,author"]="Joey Turner"
	["get_user_continue_secure,ref_link"]=""
	["get_user_continue_secure,feature"]="get_user_continue_secure"
	["get_user_continue_secure,desc"]="Secure version of get_user_continue"
	["get_user_continue_secure,example"]="get_user_continue_secure 'Do you wish to continue?' process_input"
	["get_user_continue_secure,doc_link"]=""
	["get_user_continue_secure,status"]="review"
)
#
# Secure version of get_user_continue
# 
function get_user_continue_secure() {
	local message="$1"
	local next_action="$2"

	# Define a list of allowed functions
	local allowed_functions=("process_input" "other_function")
	# Check if the next_action is in the list of allowed functions
	found=0
	for func in "${allowed_functions[@]}"; do
		if [[ "$func" == "$next_action" ]]; then
			found=1
			break
		fi
	done

	if [[ "$found" -eq 1 ]]; then
		if $($DIALOG --yesno "$message" 10 80 3>&1 1>&2 2>&3); then
			$next_action
		else
			$next_action "No"
		fi
	else
		echo "Error: Invalid function"

		exit 1
	fi
}


module_options+=(
	["update_skel,author"]="Kat Schwarz"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="install_plexmediaserver"
	["update_skel,desc"]="Install plexmediaserver from repo using apt"
	["update_skel,example"]="install_plexmediaserver"
	["update_skel,status"]="Active"
)
#
# Install plexmediaserver using apt
#
install_plexmediaserver() {
	if [ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]; then
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/plexmediaserver.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
	else
		sed -i "/downloads.plex.tv/s/^#//g" /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
	fi
	# Note: for compatibility with existing source file in some builds format must be gpg not asc
	# and location must be /usr/share/keyrings
	wget -qO- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plexmediaserver.gpg > /dev/null 2>&1
	apt_install_wrapper apt-get update
	apt_install_wrapper apt-get -y install plexmediaserver
	$DIALOG --msgbox "To test that Plex Media Server  has installed successfully
In a web browser go to http://localhost:32400/web or 
http://127.0.0.1:32400/web on this computer." 9 70
}


module_options+=(
	["generate_menu,author"]="Tearran"
	["generate_menu,ref_link"]=""
	["generate_menu,feature"]="generate_menu"
	["generate_menu,desc"]="Generate a submenu from a parent_id"
	["generate_menu,example"]="generate_menu 'parent_id'"
	["generate_menu,doc_link"]=""
	["generate_menu,status"]="Active"
)
#
# Function to generate the submenu
#
function generate_menu() {
	local parent_id="$1"
	local top_parent_id="$2"
	local backtitle="$BACKTITLE"
	local status=""

	while true; do
		# Get the submenu options for the current parent_id
		local submenu_options=()
		parse_menu_items submenu_options

		local OPTION=$($DIALOG --backtitle "$BACKTITLE" --title "$top_parent_id $parent_id" --menu "$status" 0 80 9 "${submenu_options[@]}" \
			--ok-button Select --cancel-button Back 3>&1 1>&2 2>&3)

		local exitstatus=$?

		if [ $exitstatus = 0 ]; then
			[ -z "$OPTION" ] && break

			# Check if the selected option has a submenu
			local submenu_count=$(jq -r --arg id "$OPTION" '.menu[] | .. | objects | select(.id==$id) | .sub? | length' "$json_file")
			submenu_count=${submenu_count:-0} # If submenu_count is null or empty, set it to 0
			if [ "$submenu_count" -gt 0 ]; then
				# If it does, generate a new menu for the submenu
				[[ -n "$debug" ]] && echo "$OPTION"
				generate_menu "$OPTION" "$parent_id"
			else
				# If it doesn't, execute the command
				[[ -n "$debug" ]] && echo "$OPTION"
				execute_command "$OPTION"
			fi
		fi
	done
}


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
function check_ip_version() {
	domain=${1:-armbian.com}

	if ping -c 1 $domain > /dev/null 2>&1; then
		echo "IPv4"
	elif ping6 -c 1 $domain > /dev/null 2>&1; then
		echo "IPv6"
	else
		echo "Unreachable"
	fi
}


