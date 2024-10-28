
module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
["store_netplan_config,ref_link"]="store_netplan_config"
["store_netplan_config,feature"]="store_netplan_config"
["store_netplan_config,desc"]="Storing netplan config to tmp"
["store_netplan_config,example"]="store_netplan_config"
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

