#!/bin/bash

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
["see_ping,author"]="Joey Turner"
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
	    if ping -q -c 1 -W 1 $server >/dev/null; then
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
["hotspot_setup,author"]="Joey Turner"
["hotspot_setup,ref_link"]=""
["hotspot_setup,feature"]="hotspot_setup"
["hotspot_setup,desc"]="Set up a WiFi hotspot on the device"
["hotspot_setup,example"]="hotspot_setup"
["hotspot_setup,status"]="review"
["hotspot_setup,doc_link"]=""
)

# Function to display an error message and exit
function error_exit {
    whiptail --msgbox "$1" 8 40
    exit 1
}

function hotspot_setup() {
# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

# Gather SSID and passphrase for the hotspot
SSID=$(whiptail --inputbox "Enter SSID for the Hotspot:" 8 40 3>&1 1>&2 2>&3)
if [ $? -ne 0 ]; then
    error_exit "SSID input cancelled."
fi

PASSPHRASE=$(whiptail --passwordbox "Enter Passphrase for the Hotspot:" 8 40 3>&1 1>&2 2>&3)
if [ $? -ne 0 ]; then
    error_exit "Passphrase input cancelled."
fi

# Confirm SSID and Passphrase
whiptail --msgbox "SSID: $SSID\nPassphrase: $PASSPHRASE" 8 40

# Update and install necessary packages
apt update
apt install -y hostapd dnsmasq

# Stop services while configuring
systemctl stop hostapd
systemctl stop dnsmasq

# Configure hostapd
cat > /etc/hostapd/hostapd.conf <<EOL
interface=wlan1
driver=nl80211
ssid=$SSID1
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

# Point hostapd to the configuration file
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat > /etc/dnsmasq.conf <<EOL
interface=wlan1
dhcp-range=192.168.50.10,192.168.50.50,12h
EOL

# Configure the network interfaces
cat >> /etc/network/interfaces <<EOL
allow-hotplug wlan1
iface wlan1 inet static
  address 192.168.50.1
  netmask 255.255.255.0
EOL

# Enable IP forwarding
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p

# Set up NAT
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Ensure iptables rule is loaded on boot
cat > /etc/rc.local <<EOL
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOL
chmod +x /etc/rc.local

# Start services
systemctl start hostapd
systemctl start dnsmasq

# Enable services on boot
systemctl enable hostapd
systemctl enable dnsmasq

whiptail --msgbox "Hotspot setup complete. Rebooting now." 8 40
reboot
}


module_options+=(
["choose_adapter,author"]="Igor Pecovnik"
["choose_adapter,ref_link"]=""
["choose_adapter,feature"]="choose_adapter"
["choose_adapter,desc"]="Displays available adapters"
["choose_adapter,example"]="choose_adapter"
["choose_adapter,doc_link"]=""
["choose_adapter,status"]="review"
)
#
# Function to check the internet connection
#
function choose_adapter() {

        local type=$1
        local getip=$2

        LIST=()
        HIDE_IP_PATTERN="^dummy0|^lo|^docker"
        for f in /sys/class/net/*; do
                interface=$(basename $f)
                if [[ $intf =~ $HIDE_IP_PATTERN ]]; then
                        continue
                else
                        QUERY=$(ip -br addr show dev $interface | grep "^$type" | awk '{print $1" " $3}')
                        [[ -n $QUERY ]] && LIST+=($QUERY)
                fi
        done
        LIST_LENGTH=$((${#LIST[@]}/2));
        SELECTED_ADAPTER=$(whiptail --title "Select interface" --menu "" $((${LIST_LENGTH} + 8)) 40 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
        if [[ -n $SELECTED_ADAPTER && "${getip}" != false ]]; then
        IP_ADDRESS=$(whiptail --title "Enter new IP for $SELECTED_ADAPTER" --inputbox "\nValid format: 1.2.3.4/5" 9 40 3>&1 1>&2 2>&3)
        fi

}

function wifi_connect() {

    choose_adapter "w" "false"

    LIST=()
    LIST=($(sudo iw dev ${SELECTED_ADAPTER} scan 2> /dev/null | grep 'SSID\|^BSS' | cut -d" " -f2 | sed "s/(.*//g" | xargs -n2 -d'\n' | awk '{print $2,$1}'))
    LIST_LENGTH=$((${#LIST[@]}/2));
    SELECTED_SSID=$(whiptail --title "Select SSID" --menu "rf" $((${LIST_LENGTH} + 6)) 50 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
    if [[ -n $SELECTED_SSID ]]; then
        SELECTED_PASSWORD=$(whiptail --title "Enter new password for $SELECTED_SSID" --passwordbox "" 7 50 3>&1 1>&2 2>&3)
        if [[ -n $SELECTED_PASSWORD ]]; then
        rm -f /etc/netplan/20-dhcp-wlan-interface
        netplan set --origin-hint 20-dhcp-wlan-interface renderer=networkd
        netplan set --origin-hint 20-dhcp-wlan-interface wifis.$SELECTED_ADAPTER.access-points."${SELECTED_SSID}".password=${SELECTED_PASSWORD}
        netplan set --origin-hint 20-dhcp-wlan-interface wifis.$SELECTED_ADAPTER.dhcp4=true
        netplan set --origin-hint 20-dhcp-wlan-interface wifis.$SELECTED_ADAPTER.dhcp6=true
        fi
    fi
}

module_options+=(
["netplan_wrapper,author"]="Igor Pecovnik"
["netplan_wrapper,ref_link"]=""
["netplan_wrapper,feature"]="netplan_wrapper"
["netplan_wrapper,desc"]="Displays available adapters"
["netplan_wrapper,example"]="netplan_wrapper"
["netplan_wrapper,doc_link"]=""
["netplan_wrapper,status"]="review"
)
#
# Function to check the internet connection
#
function netplan_wrapper() {

    local config=$1
    local type=$2
    local renderer=$3
    local adapter=$4
    local address=$5

    #rm -f /etc/netplan/${config}.yaml
    netplan set --origin-hint ${config} renderer=${renderer}
    netplan set --origin-hint ${config} ethernets.${adapter}.addresses=[$address]
    show_message <<< "$(sudo netplan get ${type})"

}