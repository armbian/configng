
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


  - ### Distribution upgrades
    - ### Upgrade to latest stable / LTS
    - ### Upgrade to rolling unstable


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
    - ### XFCE desktop
    - ### Gnome desktop
    - ### Cinnamon desktop
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


  - ### Development
    - ### Install tools for cloning and managing repositories (git)
    - ### Remove tools for cloning and managing repositories (git)


  - ### System benchmaking and diagnostics


  - ### Containerlization and Virtual Machines
    - ### Install Docker Minimal
    - ### Install Docker Engine
    - ### Remove Docker
    - ### Purge all Docker images, containers, and volumes


  - ### Media Servers and Editors
    - ### Install Plex Media server
    - ### Remove Plex Media server
    - ### Install Emby server
    - ### Remove Emby server


  - ### Remote Management tools
    - ### Install Cockpit web-based management tool
    - ### Purge Cockpit web-based management tool
    - ### Start Cockpit Service
    - ### Stop Cockpit Service




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
    SY016 - Distribution upgrades
	--cmd SY101 - Upgrade to latest stable / LTS
	--cmd SY102 - Upgrade to rolling unstable
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
      XFCE - XFCE desktop
	--cmd XFCE01 - XFCE desktop Install
	--cmd XFCE02 - Uninstall
	--cmd XFCE03 - Enable autologin
	--cmd XFCE04 - Disable autologin
      Gnome - Gnome desktop
	--cmd GNOME01 - Gnome desktop Install
	--cmd GNOME02 - Uninstall
	--cmd GNOME03 - Enable autologin
	--cmd GNOME04 - Disable autologin
      Cinnamon - Cinnamon desktop
	--cmd CINNAMON01 - Cinnamon desktop Install
	--cmd CINNAMON02 - Cinnamon desktop uninstall
	--cmd CINNAMON03 - Enable autologin
	--cmd CINNAMON04 - Disable autologin
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
    DevTools - Development
	--cmd DEV001 - Install tools for cloning and managing repositories (git)
	--cmd DEV001 - Remove tools for cloning and managing repositories (git)
    --cmd Benchy - System benchmaking and diagnostics
    Containers - Containerlization and Virtual Machines
	--cmd CON001 - Install Docker Minimal
	--cmd CON002 - Install Docker Engine
	--cmd CON003 - Remove Docker
	--cmd CON004 - Purge all Docker images, containers, and volumes
    Media - Media Servers and Editors
	--cmd MED001 - Install Plex Media server
	--cmd MED002 - Remove Plex Media server
	--cmd MED003 - Install Emby server
	--cmd MED004 - Remove Emby server
    Management - Remote Management tools
	--cmd MAN001 - Install Cockpit web-based management tool
	--cmd MAN002 - Purge Cockpit web-based management tool
	--cmd MAN003 - Start Cockpit Service
	--cmd MAN004 - Stop Cockpit Service

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
export BASHLOCATION=$(grep /bash$ /etc/shells | tail -1)
sed -i "s|^SHELL=.*|SHELL=${BASHLOCATION}|" /etc/default/useradd
sed -i "s|^DSHELL=.*|DSHELL=${BASHLOCATION}|" /etc/adduser.conf
apt_install_wrapper apt-get -y purge armbian-zsh zsh-common zsh tmux
update_skel
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /bash$ /etc/shells | tail -1)
~~~

### SY009

Change shell system wide to ZSH

Jobs:

~~~
export ZSHLOCATION=$(grep /zsh$ /etc/shells | tail -1)
sed -i "s|^SHELL=.*|SHELL=${ZSHLOCATION}|" /etc/default/useradd
sed -i "s|^DSHELL=.*|DSHELL=${ZSHLOCATION}|" /etc/adduser.conf
apt_install_wrapper apt-get -y install armbian-zsh zsh-common zsh tmux
update_skel
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /zsh$ /etc/shells | tail -1)
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

### SY016

Distribution upgrades

Jobs:

~~~
No commands available
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

### DevTools

Development

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
| Generate a Help message legacy cli commands. | see_cli_legacy | Joey Turner 
| Run time variables Migrated procedures from Armbian config. | set_runtime_variables | Igor Pecovnik 
| Toggle SSH lastlog | toggle_ssh_lastlog | tearran 
| Set Armbian to rolling release | set_rolling | Tearran 
| Generate this markdown table of all module_options | see_function_table_md | Joey Turner 
| Switching to alternative kernels |  | Igor 
| Set Armbian root filesystem to read only | manage_overlayfs enable|disable | igorpecovnik 
| Display a menu from pipe | show_menu <<< armbianmonitor -h  ;  | Joey Turner 
| Build the main menu from a object | generate_top_menu 'json_data' | Joey Turner 
| Migrated procedures from Armbian config. | is_package_manager_running | Igor Pecovnik 
| Migrated procedures from Armbian config. | check_desktop | Igor Pecovnik 
| Generate Document files. | generate_readme | Joey Turner 
|  |  | Igor Pecovnik 
| Needed by generate_menu |  | Joey Turner 
| Display a Yes/No dialog box and process continue/exit | get_user_continue 'Do you wish to continue?' process_input | Joey Turner 
| Display a message box | show_message <<< 'hello world'  | Joey Turner 
| Migrated procedures from Armbian config. | connect_bt_interface | Igor Pecovnik 
| Menu for armbianmonitor features | see_monitoring | Joey Turner 
| Enable/disable device tree overlays | manage_dtoverlays | Gunjan Gupta 
| Show or generate QR code for Google OTP | qr_code generate | Igor Pecovnik 
| Check if kernel headers are installed | are_headers_installed | Gunjan Gupta 
| Check when apt list was last updated and suggest updating or update | see_current_apt || see_current_apt update | Joey Turner 
| Migrated procedures from Armbian config. | check_if_installed nano | Igor Pecovnik 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | Joey Turner 
| Remove Linux headers | Headers_remove | Joey Turner 
| Update submenu descriptions based on conditions | update_submenu_data | Joey Turner 
| sanitize input cli | sanitize_input |  
| Check if a domain is reachable via IPv4 and IPv6 | check_ip_version google.com | Joey Turner 
| Migrated procedures from Armbian config. | set_header_remove | Igor Pecovnik 
| Generate a submenu from a parent_id | generate_menu 'parent_id' | Tearran 
| Generate a markdown list json objects using jq. | see_jq_menu_list | Joey Turner 
| Generate jobs from JSON file. | generate_jobs_from_json | Joey Turner 
| Install kernel headers | is_package_manager_running | Joey Turner 
| Toggle IPv6 on or off | toggle_ipv6 | Joey Turner 
| Adjust welcome screen (motd) |  | igorpecovnik 
| Generate JSON-like object file. | generate_json | Joey Turner 
| Install wrapper | apt_install_wrapper apt-get -y purge armbian-zsh | igorpecovnik 
| Netplan wrapper | network_config | Igor Pecovnik 
| Change the background color of the terminal or dialog box | set_colors 0-7 | Joey Turner 
|  |  | Igor Pecovnik 
| Serve the edit and debug server. | serve_doc | Joey Turner 
| Update JSON data with system information | update_json_data | Joey Turner 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | Joey Turner 
| Stop hostapd, clean config | default_wireless_network_config | Igor Pecovnik 
| Update sub-submenu descriptions based on conditions | update_sub_submenu_data "MenuID" "SubID" "SubSubID" "CMD" | @Tearran 
| Parse json to get list of desired menu or submenu items | parse_menu_items 'menu_options_array' | Gunjan Gupta 
| Show the usage of the functions. | see_use | Joey Turner 
| Install Desktop environment | manage_desktops xfce install | @igorpecovnik 
| Generate a Help message for cli commands. | see_cmd_list [catagory] | Joey Turner 
| Revert network config back to Armbian defaults | default_network_config | Igor Pecovnik 
| freeze/unhold/reinstall armbian related packages. | armbian_fw_manipulate unhold|freeze|reinstall | Igor Pecovnik 
| Check the internet connection with fallback DNS | see_ping | Joey Turner 
| Upgrade to next stable or rolling release | release_upgrade stable verify | Igor Pecovnik 
| Install docker from a repo using apt | install_docker engine | Kat Schwarz 
| change_system_hostname | change_system_hostname | igorpecovnik 
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

