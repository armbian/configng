
# Armbian Configuration Utility

<img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg">

Utility for configuring your board, adjusting services, and installing applications. It comes with Armbian by default.

To start the Armbian configuration utility, use the following command:
~~~
sudo armbian-config
~~~

- ## **System** 

  - ### Enable Armbian firmware upgrades


  - ### Disable Armbian kernel upgrades


  - ### Edit the boot environment


  - ### Install Linux headers


  - ### Remove Linux headers


  - ### Install to internal storage


  - ### Manage SSH login options
    - ### Disable root login
    - ### Enable root login
    - ### Disable password login
    - ### Enable password login
    - ### Disable Public key authentication login
    - ### Enable Public key authentication login
    - ### Disable OTP authentication
    - ### Enable OTP authentication
    - ### Generate new OTP authentication QR code
    - ### Show OTP authentication QR code
    - ### Disable last login banner
    - ### Enable last login banner


  - ### Change shell system wide to BASH


  - ### Change shell system wide to ZSH


  - ### Switch to rolling release


  - ### Switch to stable release


  - ### Enable read only filesystem


  - ### Disable read only filesystem


  - ### Adjust welcome screen (motd)


  - ### Install alternative kernels


  - ### Manage device tree overlays




- ## **Network** 

  - ### Configure network interfaces
    - ### Add / change interface
    - ### Revert to Armbian defaults
    - ### Show configuration
    - ### Show active status




- ## **Localisation** 

  - ### Change Global timezone


  - ### Change Locales reconfigure the language and character set


  - ### Change Keyboard layout


  - ### Change System Hostname




- ## **Software** 

  - ### Desktop Environments
    - ### Improve application search speed


  - ### Network tools
    - ### Install realtime console network usage monitor (nload)
    - ### Remove realtime console network usage monitor (nload)
    - ### Install bandwidth measuring tool (iperf3)
    - ### Remove bandwidth measuring tool (iperf3)
    - ### Install IP LAN monitor (iptraf-ng)
    - ### Remove IP LAN monitor (iptraf-ng)
    - ### Install hostname broadcast via mDNS (avahi-daemon)
    - ### Remove hostname broadcast via mDNS (avahi-daemon)


  - ### DNS blockers
    - ### Install Pi-hole DNS ad blocker
    - ### Set Pi-hole web admin password
    - ### Remove Pi-hole DNS ad blocker


  - ### Development
    - ### Install tools for cloning and managing repositories (git)
    - ### Remove tools for cloning and managing repositories (git)


  - ### Home Automation
    - ### Install openHAB
    - ### Remove openHAB


  - ### System benchmaking and diagnostics


  - ### Containerlization and Virtual Machines
    - ### Install Docker Minimal
    - ### Install Docker Engine
    - ### Remove Docker
    - ### Purge all Docker images, containers, and volumes
    - ### Install Portainer
    - ### Remove Portainer


  - ### Media Servers and Editors
    - ### Install Plex Media server
    - ### Remove Plex Media server
    - ### Install Emby server
    - ### Remove Emby server


  - ### Monitoring
    - ### Install Uptime Kuma
    - ### Uninstall Uptime Kuma


  - ### Remote Management tools
    - ### Install Cockpit web-based management tool
    - ### Purge Cockpit web-based management tool
    - ### Start Cockpit Service
    - ### Stop Cockpit Service
    - ### Webmin web-based management tool




- ## **Help** 

  - ### Contribute

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

  System - System wide and admin settings (x86_64)
    --cmd SY001 - Enable Armbian firmware upgrades
    --cmd SY002 - Disable Armbian kernel upgrades
    --cmd SY003 - Edit the boot environment
    --cmd SY004 - Install Linux headers
    --cmd SY005 - Remove Linux headers
    --cmd SY006 - Install to internal storage
    SY007 - Manage SSH login options
	--cmd SY101 - Disable root login
	--cmd SY102 - Enable root login
	--cmd SY103 - Disable password login
	--cmd SY104 - Enable password login
	--cmd SY105 - Disable Public key authentication login
	--cmd SY106 - Enable Public key authentication login
	--cmd SY107 - Disable OTP authentication
	--cmd SY108 - Enable OTP authentication
	--cmd SY109 - Generate new OTP authentication QR code
	--cmd SY110 - Show OTP authentication QR code
	--cmd SY111 - Disable last login banner
	--cmd SY112 - Enable last login banner
    --cmd SY008 - Change shell system wide to BASH
    --cmd SY009 - Change shell system wide to ZSH
    --cmd SY010 - Switch to rolling release
    --cmd SY011 - Switch to stable release
    --cmd SY012 - Enable read only filesystem
    --cmd SY013 - Disable read only filesystem
    --cmd SY014 - Adjust welcome screen (motd)
    --cmd SY015 - Install alternative kernels
    --cmd SY017 - Manage device tree overlays

  Network - Fixed and wireless network settings (eth0)
    NE001 - Configure network interfaces
	--cmd NE002 - Add / change interface
	--cmd NE003 - Revert to Armbian defaults
	--cmd NE004 - Show configuration
	--cmd NE005 - Show active status

  Localisation - Localisation (C.UTF-8)
    --cmd LO001 - Change Global timezone
    --cmd LO002 - Change Locales reconfigure the language and character set
    --cmd LO003 - Change Keyboard layout
    --cmd LO005 - Change System Hostname

  Software - Run/Install 3rd party applications (Update the package lists.)
    Desktops - Desktop Environments
	--cmd Xapian - Improve application search speed
    Netconfig - Network tools
	--cmd NET001 - Install realtime console network usage monitor (nload)
	--cmd NET002 - Remove realtime console network usage monitor (nload)
	--cmd NET003 - Install bandwidth measuring tool (iperf3)
	--cmd NET004 - Remove bandwidth measuring tool (iperf3)
	--cmd NET005 - Install IP LAN monitor (iptraf-ng)
	--cmd NET006 - Remove IP LAN monitor (iptraf-ng)
	--cmd NET007 - Install hostname broadcast via mDNS (avahi-daemon)
	--cmd NET008 - Remove hostname broadcast via mDNS (avahi-daemon)
    DNS - DNS blockers
	--cmd DNS001 - Install Pi-hole DNS ad blocker
	--cmd DNS002 - Set Pi-hole web admin password
	--cmd DNS003 - Remove Pi-hole DNS ad blocker
    DevTools - Development
	--cmd DEV001 - Install tools for cloning and managing repositories (git)
	--cmd DEV002 - Remove tools for cloning and managing repositories (git)
    HomeAutomation - Home Automation
	--cmd HA001 - Install openHAB
	--cmd HA002 - Remove openHAB
    --cmd Benchy - System benchmaking and diagnostics
    Containers - Containerlization and Virtual Machines
	--cmd CON001 - Install Docker Minimal
	--cmd CON002 - Install Docker Engine
	--cmd CON003 - Remove Docker
	--cmd CON004 - Purge all Docker images, containers, and volumes
	--cmd CON005 - Install Portainer
	--cmd CON006 - Remove Portainer
    Media - Media Servers and Editors
	--cmd MED001 - Install Plex Media server
	--cmd MED002 - Remove Plex Media server
	--cmd MED003 - Install Emby server
	--cmd MED004 - Remove Emby server
    Monitoring - Monitoring
	--cmd MON001 - Install Uptime Kuma
	--cmd MON002 - Uninstall Uptime Kuma
    Management - Remote Management tools
	--cmd MAN001 - Install Cockpit web-based management tool
	--cmd MAN002 - Purge Cockpit web-based management tool
	--cmd MAN003 - Start Cockpit Service
	--cmd MAN004 - Stop Cockpit Service
	--cmd MAN005 - Webmin web-based management tool

  Help - About this tool
    --cmd HE001 - Contribute
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

Usage:  armbian-config main=[arguments] selection=[options]

	armbian-config main=System selection=Headers          -  Install headers:
	armbian-config main=System selection=Headers_remove   -  Remove headers:
~~~

***

## Development

Development is divided into three sections:

Click for more info:

<details>
<summary><b>Jobs / JSON Object</b></summary>

A list of the jobs defined in the Jobs file.
~~~
### SY001

Enable Armbian firmware upgrades

Jobs:

~~~
armbian_fw_manipulate unhold
~~~

### SY002

Disable Armbian kernel upgrades

Jobs:

~~~
armbian_fw_manipulate hold
~~~

### SY003

Edit the boot environment

Jobs:

~~~
nano /boot/armbianEnv.txt
~~~

### SY004

Install Linux headers

Jobs:

~~~
Headers_install
~~~

### SY005

Remove Linux headers

Jobs:

~~~
Headers_remove
~~~

### SY006

Install to internal storage

Jobs:

~~~
armbian-install
~~~

### SY007

Manage SSH login options

Jobs:

~~~
No commands available
~~~

### SY008

Change shell system wide to BASH

Jobs:

~~~
manage_zsh disable
~~~

### SY009

Change shell system wide to ZSH

Jobs:

~~~
manage_zsh enable
~~~

### SY010

Switch to rolling release

Jobs:

~~~
set_rolling
~~~

### SY011

Switch to stable release

Jobs:

~~~
set_stable
~~~

### SY012

Enable read only filesystem

Jobs:

~~~
manage_overlayfs enable
~~~

### SY013

Disable read only filesystem

Jobs:

~~~
manage_overlayfs disable
~~~

### SY014

Adjust welcome screen (motd)

Jobs:

~~~
adjust_motd
~~~

### SY015

Install alternative kernels

Jobs:

~~~
switch_kernels
~~~

### SY017

Manage device tree overlays

Jobs:

~~~
manage_dtoverlays
~~~

### NE001

Configure network interfaces

Jobs:

~~~
No commands available
~~~

### LO001

Change Global timezone

Jobs:

~~~
dpkg-reconfigure tzdata
~~~

### LO002

Change Locales reconfigure the language and character set

Jobs:

~~~
dpkg-reconfigure locales
source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale
export LANGUAGE=$LANG
~~~

### LO003

Change Keyboard layout

Jobs:

~~~
dpkg-reconfigure keyboard-configuration ; setupcon 
update-initramfs -u
~~~

### LO005

Change System Hostname

Jobs:

~~~
change_system_hostname
~~~

### Desktops

Desktop Environments

Jobs:

~~~
No commands available
~~~

### Netconfig

Network tools

Jobs:

~~~
No commands available
~~~

### DNS

DNS blockers

Jobs:

~~~
No commands available
~~~

### DevTools

Development

Jobs:

~~~
No commands available
~~~

### HomeAutomation

Home Automation

Jobs:

~~~
No commands available
~~~

### Benchy

System benchmaking and diagnostics

Jobs:

~~~
see_monitoring
~~~

### Containers

Containerlization and Virtual Machines

Jobs:

~~~
No commands available
~~~

### Media

Media Servers and Editors

Jobs:

~~~
No commands available
~~~

### Monitoring

Monitoring

Jobs:

~~~
No commands available
~~~

### Management

Remote Management tools

Jobs:

~~~
No commands available
~~~

### HE001

Contribute

Jobs:

~~~
show_message <<< $(about_armbian_configng)
~~~
~~~
</details>


<details>
<summary><b>Jobs API / Helper Functions</b></summary>

These helper functions facilitate various operations related to job management, such as creation, updating, deletion, and listing of jobs, acting as a practical API for developers.

| Description | Example | Credit |
|:----------- | ------- |:------:|
| Generate a Help message legacy cli commands. | see_cli_legacy | @Tearran 
| Run time variables Migrated procedures from Armbian config. | set_runtime_variables | @igorpecovnik 
| Check for (Whiptail, DIALOG, READ) tools and set the user interface. |  | Tearran 
| Toggle SSH lastlog | toggle_ssh_lastlog | @Tearran 
| Set Armbian to rolling release | set_rolling | @Tearran 
| Generate this markdown table of all module_options | see_function_table_md | @Tearran 
| Switching to alternative kernels | switch_kernels | @igorpecovnik 
| Webmin setup and service setting. | help install remove start stop enable disable status check | @Tearran 
| Set Armbian root filesystem to read only | manage_overlayfs enable/disable | @igorpecovnik 
| Display a menu from pipe | show_menu <<< armbianmonitor -h  ;  | @Tearran 
| Build the main menu from a object | generate_top_menu 'json_data' | @Tearran 
| Migrated procedures from Armbian config. | is_package_manager_running | @armbian 
| Migrated procedures from Armbian config. | check_desktop | @armbian 
| Generate Document files. | generate_readme | @Tearran 
| Storing netplan config to tmp | store_netplan_config | @igorpecovnik 
| Needed by generate_menu | execute_command 'id' | @Tearran 
| Display a Yes/No dialog box and process continue/exit | get_user_continue 'Do you wish to continue?' process_input | @Tearran 
| Migrated procedures from Armbian config. | connect_bt_interface | @armbian 
| Display a message box | show_message <<< 'hello world'  | @Tearran 
| Menu for armbianmonitor features | see_monitoring | @Tearran 
| Enable/disable device tree overlays | manage_dtoverlays | @viraniac 
| Show or generate QR code for Google OTP | qr_code generate | @igorpecovnik 
| Install/uninstall/check status of pi-hole container | help install uninstall status password | @armbian 
| Check if kernel headers are installed | are_headers_installed | @viraniac 
| Check when apt list was last updated and suggest updating or update | see_current_apt or see_current_apt update | @Tearran 
| Install/uninstall/check status of portainer container | help install uninstall status | @armbian 
| Migrated procedures from Armbian config. | check_if_installed nano | @armbian 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | @Tearran 
| Remove Linux headers | Headers_remove | @Tearran 
| Update submenu descriptions based on conditions | update_submenu_data | @Tearran 
| sanitize input cli | sanitize_input | @Tearran 
| Check if a domain is reachable via IPv4 and IPv6 | check_ip_version google.com | @Tearran 
| Install embyserver from repo using apt | install_embyserver | @schwar3kat 
| Migrated procedures from Armbian config. | set_header_remove | @igorpecovnik 
| Generate a submenu from a parent_id | generate_menu 'parent_id' | @Tearran 
| Install docker from a repo using apt | install_docker engine | @schwar3kat 
| Generate a markdown list json objects using jq. | see_jq_menu_list | @Tearran 
| Generate jobs from JSON file. | generate_jobs_from_json | @Tearran 
| Install kernel headers | is_package_manager_running | @Tearran 
| Toggle IPv6 on or off | toggle_ipv6 | @Tearran 
| Adjust welcome screen (motd) | adjust_motd clear, header, sysinfo, tips, commands | @igorpecovnik 
| Generate JSON-like object file. | generate_json | @Tearran 
| Install wrapper | apt_install_wrapper apt-get -y purge armbian-zsh | @igorpecovnik 
| Uses Avalible (Whiptail, DIALOG, READ) for the menu interface | <function_name> | Tearran 
| Netplan wrapper | network_config | @igorpecovnik 
| Change the background color of the terminal or dialog box | set_colors 0-7 | @Tearran 
| Show general information about this tool | about_armbian_configng | @igorpecovnik 
| Serve the edit and debug server. | serve_doc | @Tearran 
| Update JSON data with system information | update_json_data | @Tearran 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | @Tearran 
| Install/uninstall/check status of uptime kuma container | install uninstall status | @armbian 
| Stop hostapd, clean config | default_wireless_network_config | @igorpecovnik 
| Update sub-submenu descriptions based on conditions | update_sub_submenu_data "MenuID" "SubID" "SubSubID" "CMD" | @Tearran 
| Parse json to get list of desired menu or submenu items | parse_menu_items 'menu_options_array' | @viraniac 
| Show the usage of the functions. | see_use | @Tearran 
| Install Desktop environment | manage_desktops xfce install | @igorpecovnik 
| Set system shell to BASH | manage_zsh enable|disable | @igorpecovnik 
| Generate a Help message for cli commands. | see_cmd_list [category] | @Tearran 
| Revert network config back to Armbian defaults | default_network_config | @igorpecovnik 
| freeze, unhold, reinstall armbian related packages. | armbian_fw_manipulate unhold/freeze/reinstall | @igorpecovnik 
| Check the internet connection with fallback DNS | see_ping | @Tearran 
| Upgrade to next stable or rolling release | release_upgrade stable verify | @igorpecovnik 
| Install openhab from a repo using apt | install uinstall | @igorpecovnik 
| Update the /etc/skel files in users directories | update_skel | @igorpecovnik 
| change_system_hostname | change_system_hostname | @igorpecovnik 
| Set Armbian to stable release | set_stable | @Tearran 
| Secure version of get_user_continue | get_user_continue_secure 'Do you wish to continue?' process_input | @Tearran 
| Install plexmediaserver from repo using apt | install_plexmediaserver | @schwar3kat 


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
./armbian-config --help
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

