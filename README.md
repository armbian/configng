
# Armbian Configuration Utility
Updated: Tue Sep 10 08:13:32 PM CDT 2024

Utility for configuring your board, adjusting services, and installing applications. It comes with Armbian by default.

To start the Armbian configuration utility, use the following command:
~~~
sudo armbian-config
~~~

- ## **System** 
  - **S01** - Enable Armbian kernel/firmware upgrades
  - **S02** - Disable Armbian kernel upgrades
  - **S03** - Edit the boot environment
  - **S04** - Install Linux headers
  - **S05** - Remove Linux headers
  - **S06** - Install to internal storage
  - **S07** - Manage SSH login options
  - **S08** - Change shell system wide to BASH
  - **S09** - Change shell system wide to ZSH
  - **S10** - Switch to rolling release
  - **S11** - Switch to stable release


- ## **Network** 
  - **N01** - Configure network interfaces
  - **N13** - Install Bluetooth support
  - **N14** - Remove Bluetooth support
  - **N15** - Bluetooth Discover
  - **N16** - Toggle system IPv6/IPv4 internet protocol
  - **N17** - Announce system in the network (Avahi)
  - **N18** - Disable system announce in the network (Avahi)


- ## **Localisation** 
  - **L00** - Change Global timezone (WIP)
  - **L01** - Change Locales reconfigure the language and character set
  - **L02** - Change Keyboard layout
  - **L03** - Change APT mirrors


- ## **Software** 
  - **I00** - Update Application Repository
  - **I01** - System benchmaking and diagnostics


- ## **Help** 
  - **H00** - About This system. (WIP)
  - **H02** - List of Config function(WIP)

## Install 
Armbian installation 
~~~
sudo apt install armbian-config
~~~

3rd party Debian based distributions
~~~
{
    sudo wget https://apt.armbian.com/armbian.key -O key
    sudo gpg --dearmor < key | sudo tee /usr/share/keyrings/armbian.gpg > /dev/null
    sudo chmod go+r /usr/share/keyrings/armbian.gpg
    sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/armbian.gpg] http://apt.armbian.com $(lsb_release -cs) main  $(lsb_release -cs)-utils  $(lsb_release -cs)-desktop" | sudo tee /etc/apt/sources.list.d/armbian.list
    sudo apt update
    sudo apt install armbian-config
}
~~~

***

## CLI options
Command line options.

Use:
~~~
armbian-config --help
~~~

Outputs:
~~~
Usage:  armbian-configng [option] [arguments]

    --help [catagory]  -  Display this help message.
        Use [catagory] to filter specific menu options.

System - System wide and admin settings
    --cmd S01 - Enable Armbian kernel/firmware upgrades
    --cmd S02 - Disable Armbian kernel upgrades
    --cmd S03 - Edit the boot environment
    --cmd S04 - Install Linux headers
    --cmd S05 - Remove Linux headers
    --cmd S06 - Install to internal storage
    --cmd S07 - Manage SSH login options
    --cmd SS01 - Disable root login
    --cmd SS02 - Enable root login
    --cmd SS03 - Disable password login
    --cmd SS04 - Enable password login
    --cmd SS05 - Disable Public key authentication login
    --cmd SS06 - Enable Public key authentication login
    --cmd SS07 - Disable OTP authentication
    --cmd SS08 - Enable OTP authentication
    --cmd SS09 - Generate new OTP authentication QR code
    --cmd SS10 - Show OTP authentication QR code
    --cmd S08 - Change shell system wide to BASH
    --cmd S09 - Change shell system wide to ZSH
    --cmd S10 - Switch to rolling release
    --cmd S11 - Switch to stable release

Network - Fixed and wireless network settings
    --cmd N01 - Configure network interfaces
    --cmd N02 - Wired
    --cmd N06 - Show configuration
    --cmd N07 - Enable DHCP on all interfaces
    --cmd N08 - Set fixed IP address
    --cmd N09 - Disable IPV6
    --cmd N10 - Enable IPV6
    --cmd N11 - Disable wired networking
    --cmd N03 - Wireless
    --cmd N25 - Show configuration
    --cmd N26 - Disable wireless networking
    --cmd N27 - Disable IPV6
    --cmd N28 - Enable IPV6
    --cmd N29 - Enable DHCP on wireless network interface
    --cmd N04 - Show common configs
    --cmd N05 - Apply common configs
    --cmd N13 - Install Bluetooth support
    --cmd N14 - Remove Bluetooth support
    --cmd N15 - Bluetooth Discover
    --cmd N16 - Toggle system IPv6/IPv4 internet protocol
    --cmd N17 - Announce system in the network (Avahi)
    --cmd N18 - Disable system announce in the network (Avahi)

Localisation - Localisation
    --cmd L00 - Change Global timezone (WIP)
    --cmd L01 - Change Locales reconfigure the language and character set
    --cmd L02 - Change Keyboard layout
    --cmd L03 - Change APT mirrors

Software - Run/Install 3rd party applications
    --cmd I00 - Update Application Repository
    --cmd I01 - System benchmaking and diagnostics

Help - About this app
    --cmd H00 - About This system. (WIP)
    --cmd H02 - List of Config function(WIP)
~~~

## Legacy options
Backward Compatible options.

Use:
~~~
armbian-config main=Help
~~~

Outputs:
~~~
Legacy Options (Backward Compatible)
Please use 'armbian-config --help' for more information.

Usage:  armbian-configng main=[arguments] selection=[options]

    armbian-configng main=System selection=Headers          -  Install headers:                                        
    armbian-configng main=System selection=Headers_remove   -  Remove headers:                                 
~~~

***

## Development

Development is divided into three sections:

Click for more info:

<details>
<summary><b>Jobs / JSON Object</b></summary>

A list of the jobs defined in the Jobs file.

 ### S01

Enable Armbian kernel/firmware upgrades

Jobs:

~~~
armbian_fw_manipulate unhold
~~~

### S02

Disable Armbian kernel upgrades

Jobs:

~~~
armbian_fw_manipulate hold
~~~

### S03

Edit the boot environment

Jobs:

~~~
nano /boot/armbianEnv.txt
~~~

### S04

Install Linux headers

Jobs:

~~~
Headers_install
~~~

### S05

Remove Linux headers

Jobs:

~~~
Headers_remove
~~~

### S06

Install to internal storage

Jobs:

~~~
armbian-install
~~~

### S07

Manage SSH login options

Jobs:

~~~
No commands available
~~~

### S08

Change shell system wide to BASH

Jobs:

~~~
export BASHLOCATION=$(grep /bash$ /etc/shells | tail -1)
sed -i "s|^SHELL=.*|SHELL=${BASHLOCATION}|" /etc/default/useradd
sed -i "s|^DSHELL=.*|DSHELL=${BASHLOCATION}|" /etc/adduser.conf
debconf-apt-progress -- apt-get -y purge armbian-zsh
update_skel
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /bash$ /etc/shells | tail -1)
~~~

### S09

Change shell system wide to ZSH

Jobs:

~~~
export ZSHLOCATION=$(grep /zsh$ /etc/shells | tail -1)
sed -i "s|^SHELL=.*|SHELL=${ZSHLOCATION}|" /etc/default/useradd
sed -i "s|^DSHELL=.*|DSHELL=${ZSHLOCATION}|" /etc/adduser.conf
debconf-apt-progress -- apt-get -y install armbian-zsh
update_skel
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /zsh$ /etc/shells | tail -1)
~~~

### S10

Switch to rolling release

Jobs:

~~~
set_rolling
~~~

### S11

Switch to stable release

Jobs:

~~~
set_stable
~~~

### N01

Configure network interfaces

Jobs:

~~~
No commands available
~~~

### N13

Install Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y install bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y --no-install-recommends install pulseaudio-module-bluetooth blueman
~~~

### N14

Remove Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y remove bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y remove pulseaudio-module-bluetooth blueman
debconf-apt-progress -- apt -y -qq autoremove
~~~

### N15

Bluetooth Discover

Jobs:

~~~
connect_bt_interface
~~~

### N16

Toggle system IPv6/IPv4 internet protocol

Jobs:

~~~
toggle_ipv6 | show_infobox
~~~

### N17

Announce system in the network (Avahi)

Jobs:

~~~
check_if_installed avahi-daemon
debconf-apt-progress -- apt-get -y install avahi-daemon libnss-mdns
cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/
cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/
service avahi-daemon restart
~~~

### N18

Disable system announce in the network (Avahi)

Jobs:

~~~
check_if_installed avahi-daemon
systemctl stop avahi-daemon avahi-daemon.socket
debconf-apt-progress -- apt-get -y purge avahi-daemon
~~~

### L00

Change Global timezone (WIP)

Jobs:

~~~
dpkg-reconfigure tzdata
~~~

### L01

Change Locales reconfigure the language and character set

Jobs:

~~~
dpkg-reconfigure locales
source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale
export LANGUAGE=$LANG
~~~

### L02

Change Keyboard layout

Jobs:

~~~
dpkg-reconfigure keyboard-configuration ; setupcon 
update-initramfs -u
~~~

### L03

Change APT mirrors

Jobs:

~~~
get_user_continue "This is only a frontend test" process_input
~~~

### I00

Update Application Repository

Jobs:

~~~
debconf-apt-progress -- apt update
~~~

### I01

System benchmaking and diagnostics

Jobs:

~~~
see_monitoring
~~~

### H00

About This system. (WIP)

Jobs:

~~~
show_message <<< "This app is to help execute procedures to configure your system

Some options may not work on manually modified systems"
~~~

### H02

List of Config function(WIP)

Jobs:

~~~
show_message <<< see_use
~~~

</details>


<details>
<summary><b>Jobs API / Helper Functions</b></summary>

These helper functions facilitate various operations related to job management, such as creation, updating, deletion, and listing of jobs, acting as a practical API for developers.

| Description | Example | Credit |
|:----------- | ------- |:------:|
| Wrapping Netplan commands | netplan_wrapper | Igor Pecovnik 
| Generate a Help message legacy cli commands. | see_cli_legacy | Joey Turner 
| Run time variables Migrated procedures from Armbian config. | set_runtime_variables | Igor Pecovnik 
| Set Armbian to rolling release | set_rolling | Tearran 
| Generate this markdown table of all module_options | see_function_table_md | Joey Turner 
| Display a menu from pipe | show_menu <<< armbianmonitor -h  ;  | Joey Turner 
| Build the main menu from a object | generate_top_menu 'json_data' | Joey Turner 
| Migrated procedures from Armbian config. | is_package_manager_running | Igor Pecovnik 
| Migrated procedures from Armbian config. | check_desktop | Igor Pecovnik 
| Generate Document files. | generate_readme | Joey Turner 
| Needed by generate_menu |  | Joey Turner 
| Display a Yes/No dialog box and process continue/exit | get_user_continue 'Do you wish to continue?' process_input | Joey Turner 
| Display a message box | show_message <<< 'hello world'  | Joey Turner 
| Migrated procedures from Armbian config. | connect_bt_interface | Igor Pecovnik 
| Menu for armbianmonitor features | see_monitoring | Joey Turner 
| Show or generate QR code for Google OTP | qr_code generate | Igor Pecovnik 
| Check if kernel headers are installed | are_headers_installed | Gunjan Gupta 
| Check when apt list was last updated | see_current_apt | Joey Turner 
| Migrated procedures from Armbian config. | check_if_installed nano | Igor Pecovnik 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | Joey Turner 
| Remove Linux headers | Headers_remove | Joey Turner 
| Displays available adapters | choose_adapter | Igor Pecovnik 
| Update submenu descriptions based on conditions | update_submenu_data | Joey Turner 
| sanitize input cli | sanitize_input |  
| Check if a domain is reachable via IPv4 and IPv6 | check_ip_version google.com | Joey Turner 
| Migrated procedures from Armbian config. | set_header_remove | Igor Pecovnik 
| Generate a submenu from a parent_id | generate_menu 'parent_id' | Joey Turner 
| Generate a markdown list json objects using jq. | see_jq_menu_list | Joey Turner 
| Generate jobs from JSON file. | generate_jobs_from_json | Joey Turner 
| Install kernel headers | is_package_manager_running | Joey Turner 
| Set up a WiFi hotspot on the device | hotspot_setup | Joey Turner 
| Toggle IPv6 on or off | toggle_ipv6 | Joey Turner 
| Generate JSON-like object file. | generate_json | Joey Turner 
| Change the background color of the terminal or dialog box | set_colors 0-7 | Joey Turner 
| Serve the edit and debug server. | serve_doc | Joey Turner 
| Update JSON data with system information | update_json_data | Joey Turner 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | Joey Turner 
| Parse json to get list of desired menu or submenu items | parse_menu_items 'menu_options_array' | Gunjan Gupta 
| Show the usage of the functions. | see_use | Joey Turner 
| List and connect to wireless network | wifi_connect | Igor Pecovnik 
| Generate a Help message for cli commands. | see_cmd_list [catagory] | Joey Turner 
| freeze/unhold/reinstall armbian related packages. | armbian_fw_manipulate unhold|freeze|reinstall | Igor Pecovnik 
| Check the internet connection with fallback DNS | see_ping | Joey Turner 
| Update the /etc/skel files in users directories | update_skel | Igor Pecovnik 
| Set Armbian to stable release | set_stable | Tearran 
| Secure version of get_user_continue | get_user_continue_secure 'Do you wish to continue?' process_input | Joey Turner 


</details>


<details>
<summary><b>Runtime / Board Statuses</b></summary>

(WIP)

This section outlines the runtime environment to check configurations and statuses for dynamically managing jobs based on JSON data.

(WIP)

</details>


## Testing and contributing

<details>
<summary><b>Get Development</b></summary>

Install the dependencies:
~~~
sudo apt install git jq whiptail
~~~

Get Development and contribute:
~~~
{
    git clone https://github.com/armbian/configng
    cd configng
    ./armbian-configng --help
}
~~~

Install and test Development deb:
~~~
{
    sudo apt install whiptail
    latest_release=$(curl -s https://api.github.com/repos/armbian/configng/releases/latest)
    deb_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
    curl -LO "$deb_url"
    deb_file=$(echo "$deb_url" | awk -F"/" '{print $NF}')
    sudo dpkg -i "$deb_file"
    sudo dpkg --configure -a
    sudo apt --fix-broken install
}
~~~

</details>

