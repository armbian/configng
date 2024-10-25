
module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
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

