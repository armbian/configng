
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
