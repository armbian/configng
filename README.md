
# Armbian Configuration Utility
Utility for configuring your board, adjusting services, and installing applications. 

## Armbian-configng is divided into four main sections:
1. System - system and security settings,
2. Network - wired, wireless, Bluetooth, access point,
3. Localisation - timezone, language, hostname,
4. Software - system and 3rd party software install.

## Development

Development is divided into three sections:
1. Jobs - JSON object
    - lib/armbian-configng/config.ng.jobs.json
2. API - Helper functions
    - lib/armbian-configng/config.ng.functions.sh
    - lib/armbian-configng/config.ng.docs.sh
    - lib/armbian-configng/config.ng.network.sh
3. Runtime - Board statuses.
    - lib/armbian-configng/config.ng.jobs.json

***

### Jobs / JSON Object

A list of BASH prosedures, jobs defined in the Jobs file.

 ### S01

Enable Armbian kernel upgrades

Jobs:

~~~
set_safe_boot unhold
~~~

### S02

Disable Armbian kernel upgrades

Jobs:

~~~
set_safe_boot freeze
~~~

### S03

Edit the boot environment

Jobs:

~~~
get_user_continue "This will open /boot/armbianEnv.txt file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?" process_input
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

### N00

Install Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y install bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y --no-install-recommends install pulseaudio-module-bluetooth blueman
~~~

### N01

Remove Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y remove bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y remove pulseaudio-module-bluetooth blueman
debconf-apt-progress -- apt -y -qq autoremove
~~~

### N02

Bluetooth Discover

Jobs:

~~~
get_user_continue "Verify that your Bluetooth device is discoverable!" process_input ; connect_bt_interface
~~~

### N03

Install Infrared support

Jobs:

~~~
see_current_apt; debconf-apt-progress -- apt-get -y --no-install-recommends install lirc
~~~

### N04

Uninstall Infrared support

Jobs:

~~~
see_current_apt; debconf-apt-progress -- apt-get -y --no-install-recommends install lirc
~~~

### N05

Manage wifi network connections

Jobs:

~~~
nmtui connect
~~~

### N06

Advanced Edit /etc/network/interface

Jobs:

~~~
get_user_continue "This will open interface file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?" process_input
nano /etc/network/interfaces
~~~

### N07

Disconnect and forget all wifi connections (Advanced)

Jobs:

~~~
get_user_continue "Disconnect and forget all wifi connections
Would you like to continue?" process_input
LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL,TYPE con show | grep wifi |  awk '{print $1}' | while read line; \ 
do nmcli con delete uuid  $line; done > /dev/null
~~~

### N08

Toggle system IPv6/IPv4 internet protocol

Jobs:

~~~
get_user_continue "This will toggle your internet protocol
Would you like to continue?" process_input
toggle_ipv6 | show_infobox
~~~

### N09

(WIP) Setup Hotspot/Access point

Jobs:

~~~
get_user_continue "This operation will install necessary software and add configuration files.
Do you wish to continue?" process_input
hotspot_setup
~~~

### N10

Announce system in the network (Avahi) 

Jobs:

~~~
get_user_continue "This operation will install avahi-daemon and add configuration files.
Do you wish to continue?" process_input
check_if_installed avahi-daemon
debconf-apt-progress -- apt-get -y install avahi-daemon libnss-mdns
cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/
cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/
service avahi-daemon restart
~~~

### N11

Disable system announce in the network (Avahi) 

Jobs:

~~~
get_user_continue "This operation will purge avahi-daemon 
Do you wish to continue?" process_input
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
get_user_continue "This will update apt" process_input
debconf-apt-progress -- apt update
~~~

### I01

CLI System Monitor

Jobs:

~~~
armbianmonitor -m | show_infobox
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


### API / Helper Functions

These helper functions facilitate various operations related to job management, such as creation, updating, deletion, and listing of jobs, acting as a practical API for developers.

| Description | Example | Credit |
|:----------- | ------- |:------:|
| Generate a Help message legacy cli commands. | see_cli_legacy | Joey Turner 
| Run time variables Migrated procedures from Armbian config. | set_runtime_variables | Igor Pecovnik 
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
| Freeze/unhold Migrated procedures from Armbian config. | set_safe_boot unhold or set_safe_boot freeze | Igor Pecovnik 
| Check when apt list was last updated | see_current_apt | Joey Turner 
| Migrated procedures from Armbian config. | check_if_installed nano | Igor Pecovnik 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | Joey Turner 
| Remove Linux headers | Headers_remove | Joey Turner 
| Show or hide menu items based on conditions | toggle_menu_item | Joey Turner 
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
| Generate a Help message for cli commands. | see_cli_list | Joey Turner 
| Generate JSON-like object file. | generate_json | Joey Turner 
| Change the background color of the terminal or dialog box | set_colors 0-7 | Joey Turner 
| Serve the edit and debug server. | serve_doc | Joey Turner 
| Update JSON data with system information | update_json_data | Joey Turner 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | Joey Turner 
| Show the usage of the functions. | see_use | Joey Turner 
| Check the internet connection with fallback DNS | see_ping | Joey Turner 
| Secure version of get_user_continue | get_user_continue_secure 'Do you wish to continue?' process_input | Joey Turner 


### Runtime / Board Statuses

(WIP)

This section outlines the runtime environment to check configurations and statuses for dynamically managing jobs based on JSON data.

(WIP)



## Testing and contributing

***Development***



Git Development and contribute:
~~~
{
    git clone https://github.com/armbian/configng
    cd configng
    ./armbian-configng --help
}
~~~

Install the dependencies:
~~~
sudo apt install git jq whiptail
~~~

Make changes, test and update documents:
Note: `sudo` is not used for development.
~~~
armbian-configng --doc
~~~

