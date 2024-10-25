
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
