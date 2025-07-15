#!/bin/bash

# This script is used to dynamically modify a JSON structure that represents a menu in the Armbian configuration tool.
# It performs several checks, such as checking if certain packages are installed and determining the network protocol used.
# Based on these checks, it appends information to the descriptions of menu and submenu items, and shows or hides certain submenu items.
# The modified JSON structure is stored in the variable 'json_data'.

set_colors 2 # Set the color to green

# Dynamically updates a JSON menu structure based on system checks.

#
# Initialize variables
system_info="$(uname -m)"
locale_setting="$LANG"
installed_software="$(see_current_apt)"
held_packages=$(apt-mark showhold)

module_options+=(
	["update_json_data,author"]="@Tearran"
	["update_json_data,ref_link"]=""
	["update_json_data,feature"]="update_json_data"
	["update_json_data,desc"]="Update JSON data with system information"
	["update_json_data,example"]="update_json_data"
	["update_json_data,status"]="review"
	["update_json_data,doc_link"]=""

)
#
# Update JSON data with system information
update_json_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg value "$2" \
		'(.menu[] | select(.id == $key).description) += " (" + $value + ")"')
}

module_options+=(
	["update_submenu_data,author"]="@Tearran"
	["update_submenu_data,ref_link"]=""
	["update_submenu_data,feature"]="update_submenu_data"
	["update_submenu_data,desc"]="Update submenu descriptions based on conditions"
	["update_submenu_data,example"]="update_submenu_data"
	["update_submenu_data,status"]="review"
	["update_submenu_data,doc_link"]=""
)
#
# Update submenu descriptions based on conditions
update_submenu_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg subkey "$2" --arg value "$3" \
		'(.menu[] | select(.id==$key).sub[] | select(.id == $subkey).description) += " (" + $value + ")"')
}


module_options+=(
	["update_sub_submenu_data,author"]="@Tearran"
	["update_sub_submenu_data,feature"]="update_sub_submenu_data"
	["update_sub_submenu_data,desc"]="Update sub-submenu descriptions based on conditions"
	["update_sub_submenu_data,example"]="update_sub_submenu_data MenuID SubID SubSubID CMD"
	["update_sub_submenu_data,status"]=""
)
#
# Update sub-submenu descriptions based on conditions
update_sub_submenu_data() {
	json_data=$(echo "$json_data" | jq --arg key "$1" --arg subkey "$2" --arg subsubkey "$3" --arg value "$4" \
		'(.menu[] | select(.id == $key).sub[] |
		select(.id == $subkey).sub[] |
		select(.id == $subsubkey).description) += " (" + $value + ")"')
}

#
# Check if network adapter is IPv6 or IPv4
network_adapter="$DEFAULT_ADAPTER"

#
# Main menu updates
update_json_data "System" "$system_info"
update_json_data "Network" "$network_adapter"
update_json_data "Localisation" "$locale_setting"
update_json_data "Software" "$installed_software"

# Conditional submenu updates based on network type
if [ "$network_adapter" = "IPv6" ]; then
	update_submenu_data "Network" "N08" "IPV6"
else
	update_submenu_data "Network" "N08" "IPV4"
fi


#
# Sub sub menu updates
#cockpit_port="$(systemctl cat cockpit.socket | grep ListenStream | awk -F= '{print $2}' | awk '{print $1}')"
#update_sub_submenu_data "Software" "Management" "M03" "https://localhost:$cockpit_port"
#emby_media_port="$(lsof -i -P -n | grep TCP | grep LISTEN | grep 'emby' | awk -F: '{print $2}' | awk '{print $1}')"
#update_sub_submenu_data "Software" "Media" "SW24" "https://localhost:$emby_media_port"
#plex_media_port="$(lsof -i -P -n | grep TCP | grep LISTEN | grep 'plex' | awk -F: '{print $2}' | awk '{print $1}' | head -n 1)"
#update_sub_submenu_data "Software" "Media" "SW22" "https://localhost:$plex_media_port"

# System
update_sub_submenu_data "System" "Access" "SSH002" "ssh://$LOCALIPADD:${module_options["module_openssh-server,port"]}"
#
update_sub_submenu_data "System" "Storage" "ZFS001" "$(module_zfs zfs_version)"
update_sub_submenu_data "System" "Storage" "ZFS002" "$(module_zfs zfs_installed_version)"
update_sub_submenu_data "System" "Storage" "NFS04" "$NFS_CLIENTS_NUMBER"

# Database
update_sub_submenu_data "Software" "Database" "DAT002" "Server: $LOCALIPADD"
update_sub_submenu_data "Software" "Database" "MYA002" "http://$LOCALIPADD:${module_options["module_phpmyadmin,port"]}"

# Finance
update_sub_submenu_data "Software" "Finance" "ABU002" "http://$LOCALIPADD:${module_options["module_actualbudget,port"]}"

# Media
update_sub_submenu_data "Software" "Media" "OMV002" "http://$LOCALIPADD:${module_options["module_omv,port"]}"
update_sub_submenu_data "Software" "Media" "MED002" "http://$LOCALIPADD:${module_options["module_plexmediaserver,port"]}"
update_sub_submenu_data "Software" "Media" "EMB002" "http://$LOCALIPADD:${module_options["module_embyserver,port"]}"
update_sub_submenu_data "Software" "Media" "FIL002" "http://$LOCALIPADD:${module_options["module_filebrowser,port"]}"
update_sub_submenu_data "Software" "Media" "STR002" "http://$LOCALIPADD:${module_options["module_stirling,port"]}"
update_sub_submenu_data "Software" "Media" "STC002" "http://$LOCALIPADD:${module_options["module_syncthing,port"]%% *}" # removing second port from url
update_sub_submenu_data "Software" "Media" "NCT002" "https://$LOCALIPADD:${module_options["module_nextcloud,port"]}"
update_sub_submenu_data "Software" "Media" "OWC002" "http://$LOCALIPADD:${module_options["module_owncloud,port"]}"
update_sub_submenu_data "Software" "Media" "JMS002" "http://$LOCALIPADD:${module_options["module_jellyfin,port"]}"
update_sub_submenu_data "Software" "Media" "IMM002" "http://$LOCALIPADD:${module_options["module_immich,port"]}"
update_sub_submenu_data "Software" "Media" "NAV002" "http://$LOCALIPADD:${module_options["module_navidrome,port"]}"

# Containers
update_sub_submenu_data "Software" "Containers" "POR002" "http://$LOCALIPADD:${module_options["module_portainer,port"]%% *}" # removing second port from url

# Backup
update_sub_submenu_data "Software" "Backup" "DPL002" "http://$LOCALIPADD:${module_options["module_duplicati,port"]%% *}" # removing second port from url

# Printing
update_sub_submenu_data "Software" "Printing" "OCT002" "http://$LOCALIPADD:${module_options["module_octoprint,port"]}"

# DevTools
[[ -f /etc/rsyncd.conf ]] && update_sub_submenu_data "Software" "DevTools" "DEV011" "$(grep -oP '(?<=^\[).*(?=\])' /etc/rsyncd.conf | xargs)"

# Home automation
update_sub_submenu_data "Software" "HomeAutomation" "HAB002" "http://$LOCALIPADD:${module_options["module_openhab,port"]}"
update_sub_submenu_data "Software" "HomeAutomation" "HAS002" "http://$LOCALIPADD:${module_options["module_haos,port"]}"
update_sub_submenu_data "Software" "HomeAutomation" "DOM002" "http://$LOCALIPADD:${module_options["module_domoticz,port"]}"
update_sub_submenu_data "Software" "HomeAutomation" "EVCC02" "http://$LOCALIPADD:${module_options["module_evcc,port"]}"

# DNS
update_sub_submenu_data "Software" "DNS" "PIH003" "http://$LOCALIPADD:${module_options["module_pi_hole,port"]%% *}/admin" # removing second port from url
update_sub_submenu_data "Software" "DNS" "ADG002" "http://$LOCALIPADD:${module_options["module_adguardhome,port"]%% *}" # removing second port from url

# Monitoring
update_sub_submenu_data "Software" "Monitoring" "UPK002" "http://$LOCALIPADD:${module_options["module_uptimekuma,port"]}"
update_sub_submenu_data "Software" "Monitoring" "NTD002" "http://$LOCALIPADD:${module_options["module_netdata,port"]}"
update_sub_submenu_data "Software" "Monitoring" "GRA002" "http://$LOCALIPADD:${module_options["module_grafana,port"]}"
update_sub_submenu_data "Software" "Monitoring" "NAX002" "http://$LOCALIPADD:${module_options["module_netalertx,port"]}"
update_sub_submenu_data "Software" "Monitoring" "PRO002" "http://$LOCALIPADD:${module_options["module_prometheus,port"]}"

# Management
update_sub_submenu_data "Software" "Management" "CPT002" "https://$LOCALIPADD:${module_options["module_cockpit,port"]}"
update_sub_submenu_data "Software" "Management" "HPG002" "http://$LOCALIPADD:${module_options["module_homepage,port"]}"
update_sub_submenu_data "Software" "Management" "NBOX02" "http://$LOCALIPADD:${module_options["module_netbox,port"]}"

# Downloaders
update_sub_submenu_data "Software" "Downloaders" "DOW002" "http://$LOCALIPADD:${module_options["module_qbittorrent,port"]%% *}" # removing second port from url
update_sub_submenu_data "Software" "Downloaders" "DEL002" "http://$LOCALIPADD:${module_options["module_deluge,port"]%% *}" # removing second port from url
update_sub_submenu_data "Software" "Downloaders" "TRA002" "http://$LOCALIPADD:${module_options["module_transmission,port"]%% *}" # removing second port from url
update_sub_submenu_data "Software" "Downloaders" "SABN02" "http://$LOCALIPADD:${module_options["module_sabnzbd,port"]}"
update_sub_submenu_data "Software" "Downloaders" "MDS002" "http://$LOCALIPADD:${module_options["module_medusa,port"]}"
update_sub_submenu_data "Software" "Downloaders" "SON002" "http://$LOCALIPADD:${module_options["module_sonarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "RAD002" "http://$LOCALIPADD:${module_options["module_radarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "BAZ002" "http://$LOCALIPADD:${module_options["module_bazarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "LID002" "http://$LOCALIPADD:${module_options["module_lidarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "RDR002" "http://$LOCALIPADD:${module_options["module_readarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "DOW026" "http://$LOCALIPADD:${module_options["module_prowlarr,port"]}"
update_sub_submenu_data "Software" "Downloaders" "JEL002" "http://$LOCALIPADD:${module_options["module_jellyseerr,port"]}"

# web
update_sub_submenu_data "Software" "WebHosting" "GHOST2" "http://$LOCALIPADD:${module_options["module_ghost,port"]}/ghost"
