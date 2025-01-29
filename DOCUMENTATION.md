
# Armbian Configuration Utility

<img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg">

Utility for configuring your board, adjusting services, and installing applications. It comes with Armbian by default.

To start the Armbian configuration utility, use the following command:
~~~
sudo armbian-config
~~~

- ## **System** 

  - ### Alternative kernels, headers, rolling updates, overlays
    - ### Install alternative kernels
    - ### Install Linux headers
    - ### Remove Linux headers
    - ### Manage device tree overlays
    - ### Select Odroid board configuration
    - ### Edit the boot environment


  - ### Install to internal media, ZFS, NFS, read-only rootfs
    - ### Install to internal storage
    - ### ZFS filesystem - enable support
    - ### ZFS filesystem - remove support
    - ### Enable read only filesystem
    - ### Disable read only filesystem
    - ### Enable Network filesystem (NFS) support
    - ### Disable Network filesystem (NFS) support
    - ### Manage NFS Server
    - ### Manage NFS Client


  - ### Manage SSH daemon options, enable 2FA
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
    - ### Sandboxed & containerised SSH server
    - ### Remove sandboxed SSH server
    - ### Purge sandboxed SSH server with data folder


  - ### Change shell, adjust MOTD
    - ### Change shell system wide to BASH
    - ### Change shell system wide to ZSH
    - ### Adjust welcome screen (motd)


  - ### OS updates and distribution upgrades
    - ### Enable Armbian firmware upgrades
    - ### Disable Armbian kernel upgrades
    - ### Switch system to rolling packages repository
    - ### Switch system to stable packages repository
    - ### Enable automating Docker container base images updating
    - ### Disable automating Docker container base images updating




- ## **Network** 

  - ### Basic Network Setup


  - ### Remove Fallback DHCP Configuration


  - ### View Network Settings


  - ### Advanced bridged network configuration
    - ### Add / change interface
    - ### Revert to Armbian defaults
    - ### Show configuration
    - ### Show active status


  - ### WireGuard VPN client / server


  - ### WireGuard remove


  - ### WireGuard clients QR codes


  - ### WireGuard purge with data folder




- ## **Localisation** 

  - ### Change Global timezone


  - ### Change Locales reconfigure the language and character set


  - ### Change Keyboard layout


  - ### Change System Hostname




- ## **Software** 

  - ### Web server, LEMP, reverse proxy, Let's Encrypt SSL
    - ### SWAG reverse proxy
    - ### SWAG reverse proxy .htpasswd set
    - ### SWAG remove
    - ### SWAG purge with data folder


  - ### Home Automation for control home appliances
    - ### openHAB empowering the smart home
    - ### openHAB remove
    - ### openHAB purge with data folder
    - ### Home Assistant open source home automation
    - ### Home Assistant remove
    - ### Home Assistant purge with data folder
    - ### Domoticz open source home automation
    - ### Domoticz remove
    - ### Domoticz purge with data folder


  - ### Network-wide ad blockers servers
    - ### Pi-hole DNS ad blocker
    - ### Pi-hole remove
    - ### Pi-hole change web admin password
    - ### Pi-hole purge with data folder


  - ### Music servers and streamers
    - ### Navidrome music server and streamer compatible with Subsonic/Airsonic
    - ### Navidrome remove
    - ### Navidrome purge with data folder


  - ### Download apps for movies, TV shows, music and subtitles
    - ### qBittorrent BitTorrent client 
    - ### qBittorrent remove
    - ### qBittorrent purge with data folder
    - ### Deluge BitTorrent client
    - ### Deluge remove
    - ### Deluge purge with data folder
    - ### Transmission BitTorrent client
    - ### Transmission remove
    - ### Transmission purge with data folder
    - ### SABnzbd newsgroup downloader
    - ### SABnzbd remove
    - ### SABnzbd purge with data folder
    - ### Medusa automatic downloader for TV shows
    - ### Medusa TV shows downloader remove
    - ### Medusa TV shows downloader purge
    - ### Sonarr automatic downloader for TV shows
    - ### Sonarr remove
    - ### Sonarr purge with data folder
    - ### Radarr automatic downloader for movies
    - ### Radarr remove
    - ### Radarr purge with data folder
    - ### Bazarr automatic subtitles downloader for Sonarr and Radarr
    - ### Bazarr remove
    - ### Bazarr purge with data folder
    - ### Lidarr automatic music downloader
    - ### Lidarr remove
    - ### Lidarr purge with data folder
    - ### Readarr automatic downloader for Ebooks
    - ### Readarr remove
    - ### Readarr purge with data folder
    - ### Prowlarr index manager and proxy for PVR
    - ### Prowlarr remove
    - ### Prowlarr purge with data folder
    - ### Jellyseerr Jellyfin/Emby/Plex integration install
    - ### Jellyseerr remove
    - ### Jellyseerr purge with data folder


  - ### SQL database servers and web interface managers
    - ### Mariadb SQL database server
    - ### Mariadb remove
    - ### Mariadb purge with data folder
    - ### phpMyAdmin web interface manager
    - ### phpMyAdmin remove
    - ### phpMyAdmin purge with data folder


  - ### Applications and tools for development
    - ### Install tools for cloning and managing repositories (git)
    - ### Remove tools for cloning and managing repositories (git)


  - ### Docker containerization and KVM virtual machines
    - ### Docker minimal
    - ### Docker engine
    - ### Docker remove
    - ### Docker purge with all images, containers, and volumes
    - ### Portainer container management platform
    - ### Portainer remove
    - ### Portainer purge with with data folder


  - ### Media servers, organizers and editors
    - ### Emby organizes video, music, live TV, and photos
    - ### Emby server remove
    - ### Emby server purge with data folder
    - ### Stirling PDF tools for viewing and editing PDF files
    - ### Stirling PDF remove
    - ### Stirling PDF purge with data folder
    - ### Syncthing continuous file synchronization
    - ### Syncthing remove
    - ### Syncthing purge with data folder
    - ### Nextcloud content collaboration platform
    - ### Nextcloud remove
    - ### Nextcloud purge with data folder
    - ### Owncloud share files and folders, easy and secure
    - ### Owncloud remove
    - ### Owncloud purge with data folder


  - ### Real-time monitoring, collecting metrics, up-time status
    - ### Uptime Kuma self-hosted monitoring tool
    - ### Uptime Kuma remove
    - ### Uptime Kuma purge with data folder
    - ### Netdata - monitoring real-time metrics
    - ### Netdata remove
    - ### Netdata purge with data folder
    - ### Grafana data analytics
    - ### Grafana remove
    - ### Grafana purge with data folder


  - ### Remote Management tools
    - ### Cockpit web-based management tool
    - ### Webmin web-based management tool


  - ### Tools for printing and 3D printing
    - ### OctoPrint web-based 3D printers management tool
    - ### OctoPrint remove
    - ### OctoPrint purge with data folder


  - ### Console network tools for measuring load and bandwidth
    - ### nload -realtime console network usage monitor
    - ### nload - remove
    - ### iperf3 bandwidth measuring tool
    - ### iperf3 remove
    - ### iptraf-ng IP LAN monitor
    - ### iptraf-ng remove
    - ### avahi-daemon hostname broadcast via mDNS
    - ### avahi-daemon remove




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
    Kernel - Alternative kernels, headers, rolling updates, overlays
	--cmd SY201 - Install alternative kernels
	--cmd SY204 - Install Linux headers
	--cmd SY205 - Remove Linux headers
	--cmd SY210 - Manage device tree overlays
	--cmd SY300 - Select Odroid board configuration
	--cmd SY010 - Edit the boot environment
    Storage - Install to internal media, ZFS, NFS, read-only rootfs
	--cmd SY001 - Install to internal storage
	--cmd SY220 - ZFS filesystem - enable support (v2.2.2)
	--cmd SY221 - ZFS filesystem - remove support ()
	--cmd SY007 - Enable read only filesystem
	--cmd SY008 - Disable read only filesystem
	--cmd NFS01 - Enable Network filesystem (NFS) support
	--cmd NFS02 - Disable Network filesystem (NFS) support
      NFS05 - Manage NFS Server
	--cmd NFS06 - Enable network filesystem (NFS) daemon
	--cmd NFS07 - Configure network filesystem (NFS) daemon
	--cmd NFS08 - Remove network filesystem (NFS) daemon
	--cmd NFS09 - Show network filesystem (NFS) daemon clients
      NFS20 - Manage NFS Client
	--cmd NFS21 - Find NFS servers in subnet and mount shares
    Access - Manage SSH daemon options, enable 2FA
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
	--cmd SSH200 - Sandboxed & containerised SSH server
	--cmd SSH201 - Remove sandboxed SSH server
	--cmd SSH202 - Purge sandboxed SSH server with data folder
    User - Change shell, adjust MOTD
	--cmd SY005 - Change shell system wide to BASH
	--cmd SY006 - Change shell system wide to ZSH
	--cmd SY009 - Adjust welcome screen (motd)
    Updates - OS updates and distribution upgrades
	--cmd SY202 - Enable Armbian firmware upgrades
	--cmd SY203 - Disable Armbian kernel upgrades
	--cmd SY206 - Switch system to rolling packages repository
	--cmd SY207 - Switch system to stable packages repository
	--cmd WTC001 - Enable automating Docker container base images updating
	--cmd WTC002 - Disable automating Docker container base images updating

  Network - Fixed and wireless network settings (eth0)
    --cmd BNS001 - Basic Network Setup
    --cmd BNS002 - Remove Fallback DHCP Configuration
    --cmd VNS001 - View Network Settings
    NEA002 - Advanced bridged network configuration
	--cmd NE002 - Add / change interface
	--cmd NE003 - Revert to Armbian defaults
	--cmd NE004 - Show configuration
	--cmd NE005 - Show active status
    --cmd WG001 - WireGuard VPN client / server
    --cmd WG002 - WireGuard remove
    --cmd WG003 - WireGuard clients QR codes
    --cmd WG004 - WireGuard purge with data folder

  Localisation - Localisation (C.UTF-8)
    --cmd LO001 - Change Global timezone
    --cmd LO002 - Change Locales reconfigure the language and character set
    --cmd LO003 - Change Keyboard layout
    --cmd LO005 - Change System Hostname

  Software - Run/Install 3rd party applications (Update the package lists.)
    WebHosting - Web server, LEMP, reverse proxy, Let's Encrypt SSL
	--cmd SWAG01 - SWAG reverse proxy
	--cmd SWAG02 - SWAG reverse proxy .htpasswd set
	--cmd SWAG03 - SWAG remove
	--cmd SWAG04 - SWAG purge with data folder
    HomeAutomation - Home Automation for control home appliances
	--cmd HAB001 - openHAB empowering the smart home
	--cmd HAB002 - openHAB remove (http://10.1.0.152:8080)
	--cmd HAB003 - openHAB purge with data folder
	--cmd HAS001 - Home Assistant open source home automation
	--cmd HAS002 - Home Assistant remove (http://10.1.0.152:8123)
	--cmd HAS003 - Home Assistant purge with data folder
	--cmd DOM001 - Domoticz open source home automation
	--cmd DOM002 - Domoticz remove (http://10.1.0.152:8080)
	--cmd DOM003 - Domoticz purge with data folder
    DNS - Network-wide ad blockers servers
	--cmd DNS001 - Pi-hole DNS ad blocker
	--cmd DNS003 - Pi-hole remove (http://10.1.0.152:80)
	--cmd DNS002 - Pi-hole change web admin password
	--cmd DNS004 - Pi-hole purge with data folder
    Music - Music servers and streamers
	--cmd NAV001 - Navidrome music server and streamer compatible with Subsonic/Airsonic
	--cmd NAV002 - Navidrome remove
	--cmd NAV003 - Navidrome purge with data folder
    Downloaders - Download apps for movies, TV shows, music and subtitles
	--cmd DOW001 - qBittorrent BitTorrent client 
	--cmd DOW002 - qBittorrent remove (http://10.1.0.152:8090)
	--cmd DOW003 - qBittorrent purge with data folder
	--cmd DEL001 - Deluge BitTorrent client
	--cmd DEL002 - Deluge remove (http://10.1.0.152:8112)
	--cmd DEL003 - Deluge purge with data folder
	--cmd TRA001 - Transmission BitTorrent client
	--cmd TRA002 - Transmission remove (http://10.1.0.152:9091)
	--cmd TRA003 - Transmission purge with data folder
	--cmd SABN01 - SABnzbd newsgroup downloader
	--cmd SABN02 - SABnzbd remove (http://10.1.0.152:8080)
	--cmd SABN03 - SABnzbd purge with data folder
	--cmd MDS001 - Medusa automatic downloader for TV shows
	--cmd MDS002 - Medusa TV shows downloader remove (http://10.1.0.152:8081)
	--cmd MDS003 - Medusa TV shows downloader purge
	--cmd SON001 - Sonarr automatic downloader for TV shows
	--cmd SON002 - Sonarr remove (http://10.1.0.152:8989)
	--cmd SON003 - Sonarr purge with data folder
	--cmd RAD001 - Radarr automatic downloader for movies
	--cmd RAD002 - Radarr remove (http://10.1.0.152:7878)
	--cmd RAD003 - Radarr purge with data folder
	--cmd BAZ001 - Bazarr automatic subtitles downloader for Sonarr and Radarr
	--cmd BAZ002 - Bazarr remove (http://10.1.0.152:6767)
	--cmd BAZ003 - Bazarr purge with data folder
	--cmd LID001 - Lidarr automatic music downloader
	--cmd LID002 - Lidarr remove (http://10.1.0.152:8686)
	--cmd LID003 - Lidarr purge with data folder
	--cmd RDR001 - Readarr automatic downloader for Ebooks
	--cmd RDR002 - Readarr remove (http://10.1.0.152:8787)
	--cmd RDR003 - Readarr purge with data folder
	--cmd DOW025 - Prowlarr index manager and proxy for PVR
	--cmd DOW026 - Prowlarr remove (http://10.1.0.152:9696)
	--cmd DOW027 - Prowlarr purge with data folder
	--cmd JEL001 - Jellyseerr Jellyfin/Emby/Plex integration install
	--cmd JEL002 - Jellyseerr remove (http://10.1.0.152:5055)
	--cmd JEL003 - Jellyseerr purge with data folder
    Database - SQL database servers and web interface managers
	--cmd DAT001 - Mariadb SQL database server
	--cmd DAT002 - Mariadb remove (Server: 10.1.0.152)
	--cmd DAT003 - Mariadb purge with data folder
	--cmd DAT005 - phpMyAdmin web interface manager
	--cmd DAT006 - phpMyAdmin remove (http://10.1.0.152:8071)
	--cmd DAT007 - phpMyAdmin purge with data folder
    DevTools - Applications and tools for development
	--cmd DEV001 - Install tools for cloning and managing repositories (git)
	--cmd DEV002 - Remove tools for cloning and managing repositories (git)
    Containers - Docker containerization and KVM virtual machines
	--cmd CON001 - Docker minimal
	--cmd CON002 - Docker engine
	--cmd CON003 - Docker remove
	--cmd CON004 - Docker purge with all images, containers, and volumes
	--cmd CON005 - Portainer container management platform
	--cmd CON006 - Portainer remove (http://10.1.0.152:9000)
	--cmd CON007 - Portainer purge with with data folder
    Media - Media servers, organizers and editors
	--cmd MED003 - Emby organizes video, music, live TV, and photos
	--cmd MED004 - Emby server remove (http://10.1.0.152:8096)
	--cmd MED005 - Emby server purge with data folder
	--cmd MED010 - Stirling PDF tools for viewing and editing PDF files
	--cmd MED011 - Stirling PDF remove (http://10.1.0.152:8077)
	--cmd MED012 - Stirling PDF purge with data folder
	--cmd MED015 - Syncthing continuous file synchronization
	--cmd MED016 - Syncthing remove (http://10.1.0.152:8884)
	--cmd MED017 - Syncthing purge with data folder
	--cmd MED020 - Nextcloud content collaboration platform
	--cmd MED021 - Nextcloud remove (https://10.1.0.152:443)
	--cmd MED022 - Nextcloud purge with data folder
	--cmd MED025 - Owncloud share files and folders, easy and secure
	--cmd MED026 - Owncloud remove (http://10.1.0.152:7787)
	--cmd MED027 - Owncloud purge with data folder
    Monitoring - Real-time monitoring, collecting metrics, up-time status
	--cmd MON001 - Uptime Kuma self-hosted monitoring tool
	--cmd MON002 - Uptime Kuma remove (http://10.1.0.152:3001)
	--cmd MON003 - Uptime Kuma purge with data folder
	--cmd MON005 - Netdata - monitoring real-time metrics
	--cmd MON006 - Netdata remove (http://10.1.0.152:19999)
	--cmd MON007 - Netdata purge with data folder
	--cmd GRA001 - Grafana data analytics
	--cmd GRA002 - Grafana remove (http://10.1.0.152:3000)
	--cmd GRA003 - Grafana purge with data folder
    Management - Remote Management tools
	--cmd MAN001 - Cockpit web-based management tool (http://10.1.0.152:9090)
	--cmd MAN005 - Webmin web-based management tool
    Printing - Tools for printing and 3D printing
	--cmd OCT001 - OctoPrint web-based 3D printers management tool
	--cmd OCT002 - OctoPrint remove (http://10.1.0.152:7981)
	--cmd OCT003 - OctoPrint purge with data folder
    Netconfig - Console network tools for measuring load and bandwidth
	--cmd NET001 - nload -realtime console network usage monitor
	--cmd NET002 - nload - remove
	--cmd NET003 - iperf3 bandwidth measuring tool
	--cmd NET004 - iperf3 remove
	--cmd NET005 - iptraf-ng IP LAN monitor
	--cmd NET006 - iptraf-ng remove
	--cmd NET007 - avahi-daemon hostname broadcast via mDNS
	--cmd NET008 - avahi-daemon remove

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
### Kernel

Alternative kernels, headers, rolling updates, overlays

Jobs:

~~~
No commands available
~~~

### Storage

Install to internal media, ZFS, NFS, read-only rootfs

Jobs:

~~~
No commands available
~~~

### Access

Manage SSH daemon options, enable 2FA

Jobs:

~~~
No commands available
~~~

### User

Change shell, adjust MOTD

Jobs:

~~~
No commands available
~~~

### Updates

OS updates and distribution upgrades

Jobs:

~~~
No commands available
~~~

### BNS001

Basic Network Setup

Jobs:

~~~
module_simple_network simple
~~~

### BNS002

Remove Fallback DHCP Configuration

Jobs:

~~~
rm -f /etc/netplan/10-dhcp-all-interfaces.yaml
netplan apply
~~~

### VNS001

View Network Settings

Jobs:

~~~
show_message <<< "$(netplan get all)"
~~~

### NEA002

Advanced bridged network configuration

Jobs:

~~~
No commands available
~~~

### WG001

WireGuard VPN client / server

Jobs:

~~~
module_wireguard install
~~~

### WG002

WireGuard remove

Jobs:

~~~
module_wireguard remove
~~~

### WG003

WireGuard clients QR codes

Jobs:

~~~
module_wireguard qrcode
~~~

### WG004

WireGuard purge with data folder

Jobs:

~~~
module_wireguard purge
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

### WebHosting

Web server, LEMP, reverse proxy, Let's Encrypt SSL

Jobs:

~~~
No commands available
~~~

### HomeAutomation

Home Automation for control home appliances

Jobs:

~~~
No commands available
~~~

### DNS

Network-wide ad blockers servers

Jobs:

~~~
No commands available
~~~

### Music

Music servers and streamers

Jobs:

~~~
No commands available
~~~

### Downloaders

Download apps for movies, TV shows, music and subtitles

Jobs:

~~~
No commands available
~~~

### Database

SQL database servers and web interface managers

Jobs:

~~~
No commands available
~~~

### DevTools

Applications and tools for development

Jobs:

~~~
No commands available
~~~

### Containers

Docker containerization and KVM virtual machines

Jobs:

~~~
No commands available
~~~

### Media

Media servers, organizers and editors

Jobs:

~~~
No commands available
~~~

### Monitoring

Real-time monitoring, collecting metrics, up-time status

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

### Printing

Tools for printing and 3D printing

Jobs:

~~~
No commands available
~~~

### Netconfig

Console network tools for measuring load and bandwidth

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
| Generate this markdown table of all module_options | see_function_table_md | @Tearran 
| Netplan wrapper | simple advanced type stations select store restore dhcp static help | @igorpecovnik 
| Webmin setup and service setting. | help install remove start stop enable disable status check | @Tearran 
| Install HA supervised container | install remove purge status help | @igorpecovnik 
| Display a menu from pipe | show_menu <<< armbianmonitor -h  ;  | @Tearran 
| Install watchtower container | install remove status help | @armbian 
| Build the main menu from a object | generate_top_menu 'json_data' | @Tearran 
| Install bazarr container | install remove purge status help | @igorpecovnik 
| Install headers container | install remove status help | @armbian 
| Migrated procedures from Armbian config. | is_package_manager_running | @armbian 
| Migrated procedures from Armbian config. | check_desktop | @armbian 
| Install phpmyadmin container | install remove purge status help | @igorpecovnik 
| Install stirling container | install remove purge status help | @Frooodle 
| Install sonarr container | install remove purge status help | @armbian 
| Generate Document files. | generate_readme | @Tearran 
| Storing netplan config to tmp | store_netplan_config | @igorpecovnik 
| Install jellyseerr container | install remove purge status help | @armbian 
| Needed by generate_menu | execute_command 'id' | @Tearran 
| Display a Yes/No dialog box and process continue/exit | get_user_continue 'Do you wish to continue?' process_input | @Tearran 
| Module for Armbian firmware manipulating. | select install show hold unhold repository headers help | @igorpecovnik 
| Deploy Armbian KVM instances | install remove save restore list help | @igorpecovnik 
| Migrated procedures from Armbian config. | connect_bt_interface | @armbian 
| Display a message box | show_message <<< 'hello world'  | @Tearran 
| Manage self hosted runners | install remove remove_online purge help | @igorpecovnik 
| Install domoticz container | install remove purge status help | @armbian 
| Menu for armbianmonitor features | see_monitoring | @Tearran 
| Enable/disable device tree overlays |  | @viraniac 
| Show or generate QR code for Google OTP | qr_code generate | @igorpecovnik 
| Remove package | pkg_remove nmap | @dimitry-ishenko 
| Check when apt list was last updated and suggest updating or update | see_current_apt or see_current_apt update | @Tearran 
| Install/uninstall/check status of portainer container | install remove purge status help | @armbian 
| Install plexmediaserver from repo using apt | install remove status | @schwar3kat 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | @Tearran 
| Upgrade installed packages (potentially removing some) | pkg_full_upgrade | @dimitry-ishenko 
| Install zfs filesystem support | install remove status kernel_max zfs_version zfs_installed_version help | @igorpecovnik 
| Check if package is installed | pkg_installed mc | @dimitry-ishenko 
| Update submenu descriptions based on conditions | update_submenu_data | @Tearran 
| sanitize input cli | sanitize_input | @Tearran 
| Install openssh-server container | install remove purge status help | @armbian 
| Upgrade installed packages | pkg_upgrade | @dimitry-ishenko 
| Install lidarr container | install remove purge status help | @armbian 
| Check if a domain is reachable via IPv4 and IPv6 | check_ip_version google.com | @Tearran 
| Install package | pkg_install neovim | @dimitry-ishenko 
| Install wireguard container | install remove purge qrcode status help | @armbian 
| Secure Web Application Gateway  | install remove purge status password help | @igorpecovnik 
| Install deluge container | install remove purge status help | @igorpecovnik 
| Set Armbian root filesystem to read only | install remove status help | @igorpecovnik 
| Cockpit setup and service setting. | help install remove start stop enable disable status check | @tearran 
| Generate a submenu from a parent_id | generate_menu 'parent_id' | @Tearran 
| Generate a markdown list json objects using jq. | see_jq_menu_list | @Tearran 
| Install octoprint container | install remove purge status help | @armbian 
| Generate jobs from JSON file. | generate_jobs_from_json | @Tearran 
| Display a warning with a gauge for 10 seconds then continue |  | @igorpecovnik 
| Install radarr container | install remove purge status help | @armbian 
| Toggle IPv6 on or off | toggle_ipv6 | @Tearran 
| Adjust welcome screen (motd) | adjust_motd clear, header, sysinfo, tips, commands | @igorpecovnik 
| Install embyserver container | install remove purge status help | @schwar3kat 
| Install qbittorrent container | install remove purge status help | @qbittorrent 
| Generate JSON-like object file. | generate_json | @Tearran 
| Install transmission container | install remove purge status help | @armbian 
| Install nextcloud container | install remove purge status help | @igorpecovnik 
| Install navidrome container | install remove purge status help | @armbian 
| Wrapper for service manipulation | service install some.service | @dimitry-ishenko 
| Install Openhab | install remove purge status help | @igorpecovnik 
| Uses Avalible (Whiptail, DIALOG, READ) for the menu interface | <function_name> | Tearran 
| Netplan wrapper | network_config | @igorpecovnik 
| Install medusa container | install remove purge status help | @armbian 
| Install syncthing container | install remove purge status help | @igorpecovnik 
| Install grafana container | install remove purge status help | @armbian 
| Select optimised Odroid board configuration | select | @GeoffClements 
| Install owncloud container | install remove purge status help | @armbian 
| Install netdata container | install remove purge status help | @armbian 
| Change the background color of the terminal or dialog box | set_colors 0-7 | @Tearran 
| Show general information about this tool | about_armbian_configng | @igorpecovnik 
| Serve the edit and debug server. | serve_doc | @Tearran 
| Update JSON data with system information | update_json_data | @Tearran 
| Install nfs client | install remove servers help | @igorpecovnik 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | @Tearran 
| Install readarr container | install remove purge status help | @armbian 
| Install uptimekuma container | install remove purge status help | @armbian 
| Stop hostapd, clean config | default_wireless_network_config | @igorpecovnik 
| Update sub-submenu descriptions based on conditions | update_sub_submenu_data MenuID SubID SubSubID CMD | @Tearran 
| Parse json to get list of desired menu or submenu items | parse_menu_items 'menu_options_array' | @viraniac 
| Show the usage of the functions. | see_use | @Tearran 
| Install Desktop environment | manage_desktops xfce install | @igorpecovnik 
| Set system shell to BASH | manage_zsh enable|disable | @igorpecovnik 
| Install sabnzbd container | install remove purge status help | @armbian 
| Configure an unconfigured package | pkg_configure | @dimitry-ishenko 
| Install Pi-hole container | install remove purge password status help | @armbian 
| Generate a Help message for cli commands. | see_cmd_list [category] | @Tearran 
| Install mariadb container | install remove purge status help | @igorpecovnik 
| Revert network config back to Armbian defaults | default_network_config | @igorpecovnik 
| Check if the current OS is supported based on /etc/armbian-distribution-status | help | @Tearran 
| Install prowlarr container | install remove purge status help | @Prowlarr 
| Install nfsd server | install remove manage add status clients servers help | @igorpecovnik 
| Check the internet connection with fallback DNS | see_ping | @Tearran 
| Install docker from a repo using apt | install remove purge status help | @schwar3kat 
| Upgrade to next stable or rolling release | release_upgrade stable verify | @igorpecovnik 
| Update the /etc/skel files in users directories | update_skel | @igorpecovnik 
| change_system_hostname | change_system_hostname | @igorpecovnik 
| Update package repository | pkg_update | @dimitry-ishenko 
| Secure version of get_user_continue | get_user_continue_secure 'Do you wish to continue?' process_input | @Tearran 


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

