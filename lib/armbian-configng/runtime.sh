# Exposing legacy Variables 

# lib/armbian-configng/runtime-conditions.sh

# File extention of the config file
config_format="conf"
# Path to the config file

config_file="$etcpath"/"$filename"/"$filename"."$config_format"

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then

    [[ -d "$etcpath"/"$filename" ]] || mkdir -p "$etcpath"/"$filename"
    # If not, create it
    echo "Creating $config_file..."
    touch "$config_file"

    # You can also set some default values here if needed
    cat EOF >> "$config_file"
SUBSYSTEM=="tty", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", SYMLINK+="ttyWWAN%E{ID_USB_INTERFACE_NUM}"
SUBSYSTEM=="net", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", NAME="lte0"
SUBSYSTEM=="tty", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="1c25", SYMLINK+="ttyWWAN%E{ID_USB_INTERFACE_NUM}"
SUBSYSTEM=="net", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="1c25", NAME="umts0"
SUBSYSTEM=="tty", ATTRS{idVendor}=="03f0", ATTRS{idProduct}=="251d", SYMLINK+="ttyWWAN%E{ID_USB_INTERFACE_NUM}"
SUBSYSTEM=="tty", ATTRS{idVendor}=="03f0", ATTRS{idProduct}=="1e1d", SYMLINK+="ttyWWAN%E{.ID_PORT}"
SUBSYSTEM=="tty", ATTRS{idVendor}=="413c", ATTRS{idProduct}=="819b", SYMLINK+="ttyWWAN%E{ID_USB_INTERFACE_NUM}"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1e0e", ATTRS{idProduct}=="9001", SYMLINK+="ttyWWAN%E{ID_USB_INTERFACE_NUM}"
SUBSYSTEM=="net", ATTRS{idVendor}=="1e0e", ATTRS{idProduct}=="9001", NAME="lte0"
dflag=
vflag=
cflag=
table="\Z2Application     Protocol      Port\n
HOSTNAMEFQDN=$(\
MYSQL_PASS=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c16)
i=0
j=1
IFS=" "
skupaj=${#PACKETS[@]}
IFS=" "
HOSTNAMESHORT="$1"
SMBUSER=$(whiptail --inputbox "What is your samba username?" 8 78 $SMBUSER --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
SMBPASS=$(whiptail --inputbox "What is your samba password?" 8 78 $SMBPASS --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
SMBGROUP=$(whiptail --inputbox "What is your samba group?" 8 78 $SMBGROUP --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
wgeturl="https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install"
PREFIX="https://hndl.urbackup.org/Server/latest/"
URL="https://hndl.urbackup.org/Server/latest/"$(wget -q $PREFIX -O - | html2text -width 120 | grep deb | awk ' { print $3 }' | grep $arch)
rmem_recommended=4194304
wmem_recommended=1048576
rmem_actual=$(sysctl net.core.rmem_max | awk -F" " '{print $3}')
wmem_actual=$(sysctl net.core.wmem_max | awk -F" " '{print $3}')
TEMP_DIR=$(mktemp -d || exit 1)
jdkBin=$(find /opt/jdk/*/bin ... -print -quit)
jdkLib=$(find /opt/jdk/*/lib ... -print -quit)
wgeturl=$(curl -s "https://api.github.com/repos/Radarr/Radarr/releases" | grep 'linux.tar.gz' | grep 'browser_download_url' | head -1 | cut -d \" -f 4)
Description=Radarr Daemon
After=network.target
User=root
Type=simple
ExecStart=/usr/bin/mono --debug /opt/Radarr/Radarr.exe -nobrowser
WantedBy=multi-user.target
Description=Sonarr (NzbDrone) Daemon
After=network.target
User=root
Type=simple
ExecStart=/usr/bin/mono --debug /opt/NzbDrone/NzbDrone.exe -nobrowser
WantedBy=multi-user.target
PREFIX="https://www.softether-download.com/files/softether/"
URL=$(wget -q $PREFIX -O - | html2text | grep rtm | awk ' { print $(NF) }' | tail -1)
SUFIX="${URL/-tree/}"
DLURL=$PREFIX$URL"/Linux/SoftEther_VPN_Server/32bit_-_ARM_EABI/softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz"
DLURL=$PREFIX$URL"/Linux/SoftEther_VPN_Server/32bit_-_Intel_x86/softether-vpnserver-$SUFIX-linux-x86-32bit.tar.gz"
Description=VPN service
Type=oneshot
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
RemainAfterExit=yes
WantedBy=multi-user.target
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/vpnserver
PREFIX="https://www.softether-download.com/files/softether/"
URL=$(wget -q $PREFIX -O - | html2text | grep rtm | awk ' { print $(NF) }' | tail -1)
SUFIX="${URL/-tree/}"
SECURE_MYSQL=$(expect -c "
packets="amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj p7zip unrar-free rpm nomarch lzop \
WWW_RECONFIG=$(expect -c "
TEMP_DIR=$(mktemp -d || exit 1)
i=0
TTY_X=$(($(stty size | awk '{print $2}')-6)) # determine terminal width
TTY_Y=$(($(stty size | awk '{print $1}')-6)) # determine terminal height
distribution=$(lsb_release -cs)
family=$(lsb_release -is)
DEFAULT_ADAPTER=$(ip -4 route ls | grep default | tail -1 | grep -Po '(?<=dev )(\S+)')
serverIP=$(ip -4 addr show dev $DEFAULT_ADAPTER | awk '/inet/ {print $2}' | cut -d'/' -f1)
SUBNET="$1.$2.$3."
hostnamefqdn=$(hostname -f)
mysql_pass=""
BACKTITLE="Softy - Armbian post deployment scripts, https://www.armbian.com"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIALOG_CANCEL=1
DIALOG_ESC=255
DATE=`date +%F`
DBBACKUPNAME="mysql-"$DATE
WEBBACKUPNAME="website-"$DATE
FILEBACKUPNAME="website-"$DATE
COPY_TO=/root/temp/$DATE
COPY_FROM=/var/www/clients
USER=
PASSWORD=
HOST=localhost
REMOTE=

EOF
    cat << EOF > "$config_file"
# PLEASE DO NOT EDIT THIS FILE
# This file is automatically generated by $filename
# Any changes made to this file will be overwritten the next time the script runs.
# To change the values of these variables, Setup a funtion to... 

# Default values for variables that can be read and modified by the User Interface.
# These variables can be toggled or their state can be changed as per user request.
VAR1=default_value1
VAR2=default_value2


EOF

    # And so on...
fi
