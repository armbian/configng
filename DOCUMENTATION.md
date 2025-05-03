
# Armbian Configuration Utility

<img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg">

Utility for configuring your board, adjusting services, and installing applications. It comes with Armbian by default.

To start the Armbian configuration utility, use the following command:
~~~
sudo armbian-config
~~~

- ## **System** 

  - ### Alternative kernels, headers, overlays, bootenv
    - ### Use alternative kernels
    - ### Install Linux headers
    - ### Remove Linux headers
    - ### Manage device tree overlays
    - ### Select Odroid board configuration
    - ### Edit the boot environment


  - ### Install to internal media, ZFS, NFS, read-only rootfs
    - ### Install
    - ### Enable read only filesystem
    - ### Disable read only filesystem
    - ### Enable Network filesystem (NFS) support
    - ### Disable Network filesystem (NFS) support
    - ### Manage NFS Server
    - ### Manage NFS Client
    - ### ZFS filesystem - enable support
    - ### ZFS filesystem - remove support


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
    - ### Change shell system wide to ZSH
    - ### Change shell system wide to BASH
    - ### Adjust welcome screen (motd)


  - ### OS updates and distribution upgrades
    - ### Enable Armbian firmware upgrades
    - ### Disable Armbian firmware upgrades
    - ### Switch system to rolling packages repository
    - ### Switch system to stable packages repository
    - ### Enable automating Docker container base images updating
    - ### Disable automating Docker container base images updating
    - ### Enable automatic package updates.
    - ### Configure automatic package updates
    - ### Disable automatic package updates




- ## **Network** 

  - ### Basic network setup


  - ### Remove Fallback DHCP Configuration


  - ### View Network Configuration


  - ### Advanced bridged network configuration
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
    - ### EVCC - solar charging automation
    - ### EVCC - solar charging automation remove
    - ### EVCC purge with data folder


  - ### Network-wide ad blockers servers
    - ### Pi-hole DNS ad blocker
    - ### Pi-hole remove
    - ### Pi-hole change web admin password
    - ### Pi-hole purge with data folder
    - ### Unbound caching DNS resolver
    - ### Unbound remove
    - ### Unbound purge with data folder
    - ### AdGuardHome DNS sinkhole
    - ### AdGuardHome remove
    - ### AdGuardHome purge with data folder


  - ### Music servers and streamers
    - ### Navidrome music server and streamer compatible with Subsonic/Airsonic
    - ### Navidrome remove
    - ### Navidrome purge with data folder


  - ### Manage your finances
    - ### Do your finances with Actual Budget
    - ### Actual Budget remove
    - ### Actual Budget purge with data folder


  - ### Backup solutions for your data
    - ### Duplicati install
    - ### Duplicati remove
    - ### Duplicati purge with data folder


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
    - ### PostgreSQL install
    - ### PostgreSQL remove
    - ### PostgreSQL purge with data folder
    - ### Mariadb SQL database server
    - ### Mariadb remove
    - ### Mariadb purge with data folder
    - ### Redis install
    - ### Redis remove
    - ### Redis purge with data folder
    - ### phpMyAdmin web interface manager
    - ### phpMyAdmin remove
    - ### phpMyAdmin purge with data folder


  - ### Armbian infrastructure services
    - ### Router for repository mirror automation
    - ### Remove CDN router
    - ### GitHub runners for Armbian automation
    - ### Remove GitHub runners for Armbian automation
    - ### Rsyncd server
    - ### Remove Armbian rsyncd server


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
    - ### Jellyfin Media System
    - ### Jellyfin remove
    - ### Jellyfin purge with data folder
    - ### Hastebin Paste Server
    - ### Hastebin remove
    - ### Hastebin purge with data folder
    - ### Immich - high-performance self-hosted photo and video backup solution
    - ### Immich remove
    - ### Immich purge with data folder


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
    - ### Prometheus docker image
    - ### Prometheus remove
    - ### Prometheus purge with data folder
    - ### NetAlertX network scanner & notification framework
    - ### NetAlertX network scanner remove
    - ### NetAlertX network scanner purge with data folder


  - ### Remote File & Management tools
    - ### Cockpit web-based management tool
    - ### SAMBA Remote File share
    - ### Webmin web-based management tool
    - ### Install Homepage startpage / application dashboard
    - ### Remove Homepage
    - ### Purge Homepage with data folder
    - ### NetBox infrastructure resource modeling install
    - ### NetBox remove
    - ### NetBox purge with data folder


  - ### Tools for printing and 3D printing
    - ### OctoPrint web-based 3D printers management tool
    - ### OctoPrint remove
    - ### OctoPrint purge with data folder


  - ### Console network tools for measuring load and bandwidth
    - ### nload - realtime console network usage monitor
    - ### nload - remove
    - ### iperf3 bandwidth measuring tool
    - ### iperf3 remove
    - ### iptraf-ng IP LAN monitor
    - ### iptraf-ng remove
    - ### avahi-daemon hostname broadcast via mDNS
    - ### avahi-daemon remove


  - ### Virtual Private Network tools
    - ### WireGuard VPN client / server
    - ### WireGuard remove
    - ### WireGuard clients QR codes
    - ### WireGuard purge with data folder
    - ### ZeroTier connect devices over your own private network in the world.




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
	echo << EOF | sudo tee /etc/apt/sources.list.d/armbian.sources
	Types: deb
	URIs: https://apt.armbian.com
	Suites: noble
	Components: main noble-utils noble-desktop
	Architectures: amd64
	Signed-By: /usr/share/keyrings/armbian.gpg
	EOF
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
    Kernel - Alternative kernels, headers, overlays, bootenv
	--cmd KER001 - Use alternative kernels
	--cmd HEAD01 - Install Linux headers
	--cmd HEAD02 - Remove Linux headers
	--cmd DTO001 - Manage device tree overlays
	--cmd ODR001 - Select Odroid board configuration
	--cmd BOOT01 - Edit the boot environment
    Storage - Install to internal media, ZFS, NFS, read-only rootfs
	--cmd STO001 - Install
	--cmd ROO001 - Enable read only filesystem
	--cmd ROO002 - Disable read only filesystem
	--cmd NETF01 - Enable Network filesystem (NFS) support
	--cmd NETF02 - Disable Network filesystem (NFS) support
      NETF03 - Manage NFS Server
	--cmd NETF04 - Enable network filesystem (NFS) daemon
	--cmd NETF05 - Configure network filesystem (NFS) daemon
	--cmd NETF06 - Remove network filesystem (NFS) daemon
	--cmd NETF07 - Show network filesystem (NFS) daemon clients
      NETF08 - Manage NFS Client
	--cmd NETF09 - Find NFS servers in subnet and mount shares
	--cmd NETF10 - Show and manage NFS mounts
	--cmd ZFS001 - ZFS filesystem - enable support (v2.2.2)
	--cmd ZFS002 - ZFS filesystem - remove support ()
    Access - Manage SSH daemon options, enable 2FA
	--cmd ACC001 - Disable root login
	--cmd ACC002 - Enable root login
	--cmd ACC003 - Disable password login
	--cmd ACC004 - Enable password login
	--cmd ACC005 - Disable Public key authentication login
	--cmd ACC006 - Enable Public key authentication login
	--cmd ACC007 - Disable OTP authentication
	--cmd ACC008 - Enable OTP authentication
	--cmd ACC009 - Generate new OTP authentication QR code
	--cmd ACC010 - Show OTP authentication QR code
	--cmd ACC011 - Disable last login banner
	--cmd ACC012 - Enable last login banner
	--cmd SSH001 - Sandboxed & containerised SSH server
	--cmd SSH002 - Remove sandboxed SSH server (ssh://10.1.0.57:2222)
	--cmd SSH003 - Purge sandboxed SSH server with data folder
    User - Change shell, adjust MOTD
	--cmd SHELL1 - Change shell system wide to ZSH
	--cmd SHELL2 - Change shell system wide to BASH
	--cmd MOTD01 - Adjust welcome screen (motd)
    Updates - OS updates and distribution upgrades
	--cmd UPD001 - Enable Armbian firmware upgrades
	--cmd UPD002 - Disable Armbian firmware upgrades
	--cmd ROLLIN - Switch system to rolling packages repository
	--cmd STABLE - Switch system to stable packages repository
	--cmd WTC001 - Enable automating Docker container base images updating
	--cmd WTC002 - Disable automating Docker container base images updating
	--cmd UNAT01 - Enable automatic package updates.
	--cmd UNAT02 - Configure automatic package updates
	--cmd UNAT03 - Disable automatic package updates

  Network - Fixed and wireless network settings (eth0)
    --cmd BNS001 - Basic network setup
    --cmd BNS002 - Remove Fallback DHCP Configuration
    --cmd VNS001 - View Network Configuration
    NEA001 - Advanced bridged network configuration
	--cmd NEA002 - Add / change interface
	--cmd NEA003 - Revert to Armbian defaults
	--cmd NEA004 - Show configuration
	--cmd NEA005 - Show active status

  Localisation - Localisation (C.UTF-8)
    --cmd LOC001 - Change Global timezone
    --cmd LOC002 - Change Locales reconfigure the language and character set
    --cmd LOC003 - Change Keyboard layout
    --cmd LOC005 - Change System Hostname

  Software - Run/Install 3rd party applications (Update the package lists.)
    WebHosting - Web server, LEMP, reverse proxy, Let's Encrypt SSL
	--cmd SWAG01 - SWAG reverse proxy
	--cmd SWAG02 - SWAG reverse proxy .htpasswd set
	--cmd SWAG03 - SWAG remove
	--cmd SWAG04 - SWAG purge with data folder
    HomeAutomation - Home Automation for control home appliances
	--cmd HAB001 - openHAB empowering the smart home
	--cmd HAB002 - openHAB remove (http://10.1.0.57:8080)
	--cmd HAB003 - openHAB purge with data folder
	--cmd HAS001 - Home Assistant open source home automation
	--cmd HAS002 - Home Assistant remove (http://10.1.0.57:8123)
	--cmd HAS003 - Home Assistant purge with data folder
	--cmd DOM001 - Domoticz open source home automation
	--cmd DOM002 - Domoticz remove (http://10.1.0.57:8080)
	--cmd DOM003 - Domoticz purge with data folder
	--cmd EVCC01 - EVCC - solar charging automation
	--cmd EVCC02 - EVCC - solar charging automation remove (http://10.1.0.57:7070)
	--cmd EVCC03 - EVCC purge with data folder
    DNS - Network-wide ad blockers servers
	--cmd PIH001 - Pi-hole DNS ad blocker
	--cmd PIH003 - Pi-hole remove (http://10.1.0.57:80)
	--cmd PIH002 - Pi-hole change web admin password
	--cmd PIH004 - Pi-hole purge with data folder
	--cmd UNB001 - Unbound caching DNS resolver
	--cmd UNB002 - Unbound remove
	--cmd UNB003 - Unbound purge with data folder
	--cmd ADG001 - AdGuardHome DNS sinkhole
	--cmd ADG002 - AdGuardHome remove (http://10.1.0.57:3000)
	--cmd ADG003 - AdGuardHome purge with data folder
    Music - Music servers and streamers
	--cmd NAV001 - Navidrome music server and streamer compatible with Subsonic/Airsonic
	--cmd NAV002 - Navidrome remove
	--cmd NAV003 - Navidrome purge with data folder
    Finance - Manage your finances
	--cmd ABU001 - Do your finances with Actual Budget
	--cmd ABU002 - Actual Budget remove (http://10.1.0.57:5006)
	--cmd ABU003 - Actual Budget purge with data folder
    Backup - Backup solutions for your data
	--cmd DPL001 - Duplicati install
	--cmd DPL002 - Duplicati remove (http://10.1.0.57:8200)
	--cmd DPL003 - Duplicati purge with data folder
    Downloaders - Download apps for movies, TV shows, music and subtitles
	--cmd DOW001 - qBittorrent BitTorrent client 
	--cmd DOW002 - qBittorrent remove (http://10.1.0.57:8090)
	--cmd DOW003 - qBittorrent purge with data folder
	--cmd DEL001 - Deluge BitTorrent client
	--cmd DEL002 - Deluge remove (http://10.1.0.57:8112)
	--cmd DEL003 - Deluge purge with data folder
	--cmd TRA001 - Transmission BitTorrent client
	--cmd TRA002 - Transmission remove (http://10.1.0.57:9091)
	--cmd TRA003 - Transmission purge with data folder
	--cmd SABN01 - SABnzbd newsgroup downloader
	--cmd SABN02 - SABnzbd remove (http://10.1.0.57:8080)
	--cmd SABN03 - SABnzbd purge with data folder
	--cmd MDS001 - Medusa automatic downloader for TV shows
	--cmd MDS002 - Medusa TV shows downloader remove (http://10.1.0.57:8081)
	--cmd MDS003 - Medusa TV shows downloader purge
	--cmd SON001 - Sonarr automatic downloader for TV shows
	--cmd SON002 - Sonarr remove (http://10.1.0.57:8989)
	--cmd SON003 - Sonarr purge with data folder
	--cmd RAD001 - Radarr automatic downloader for movies
	--cmd RAD002 - Radarr remove (http://10.1.0.57:7878)
	--cmd RAD003 - Radarr purge with data folder
	--cmd BAZ001 - Bazarr automatic subtitles downloader for Sonarr and Radarr
	--cmd BAZ002 - Bazarr remove (http://10.1.0.57:6767)
	--cmd BAZ003 - Bazarr purge with data folder
	--cmd LID001 - Lidarr automatic music downloader
	--cmd LID002 - Lidarr remove (http://10.1.0.57:8686)
	--cmd LID003 - Lidarr purge with data folder
	--cmd RDR001 - Readarr automatic downloader for Ebooks
	--cmd RDR002 - Readarr remove (http://10.1.0.57:8787)
	--cmd RDR003 - Readarr purge with data folder
	--cmd DOW025 - Prowlarr index manager and proxy for PVR
	--cmd DOW026 - Prowlarr remove (http://10.1.0.57:9696)
	--cmd DOW027 - Prowlarr purge with data folder
	--cmd JEL001 - Jellyseerr Jellyfin/Emby/Plex integration install
	--cmd JEL002 - Jellyseerr remove (http://10.1.0.57:5055)
	--cmd JEL003 - Jellyseerr purge with data folder
    Database - SQL database servers and web interface managers
	--cmd PGSQL1 - PostgreSQL install
	--cmd PGSQL2 - PostgreSQL remove
	--cmd PGSQL3 - PostgreSQL purge with data folder
	--cmd DAT001 - Mariadb SQL database server
	--cmd DAT002 - Mariadb remove (Server: 10.1.0.57)
	--cmd DAT003 - Mariadb purge with data folder
	--cmd REDIS1 - Redis install
	--cmd REDIS2 - Redis remove
	--cmd REDIS3 - Redis purge with data folder
	--cmd MYA001 - phpMyAdmin web interface manager
	--cmd MYA002 - phpMyAdmin remove (http://10.1.0.57:8071)
	--cmd MYA003 - phpMyAdmin purge with data folder
    Armbian - Armbian infrastructure services
	--cmd ART001 - Router for repository mirror automation
	--cmd ART002 - Remove CDN router
	--cmd GHR001 - GitHub runners for Armbian automation
	--cmd GHR002 - Remove GitHub runners for Armbian automation
	--cmd RSD001 - Rsyncd server
	--cmd RSD002 - Remove Armbian rsyncd server
    DevTools - Applications and tools for development
	--cmd GIT001 - Install tools for cloning and managing repositories (git)
	--cmd GIT002 - Remove tools for cloning and managing repositories (git)
    Containers - Docker containerization and KVM virtual machines
	--cmd CON001 - Docker minimal
	--cmd CON002 - Docker engine
	--cmd CON003 - Docker remove
	--cmd CON004 - Docker purge with all images, containers, and volumes
	--cmd POR001 - Portainer container management platform
	--cmd POR002 - Portainer remove (http://10.1.0.57:9000)
	--cmd POR003 - Portainer purge with with data folder
    Media - Media servers, organizers and editors
	--cmd EMB001 - Emby organizes video, music, live TV, and photos
	--cmd EMB002 - Emby server remove (http://10.1.0.57:8096)
	--cmd EMB003 - Emby server purge with data folder
	--cmd STR001 - Stirling PDF tools for viewing and editing PDF files
	--cmd STR002 - Stirling PDF remove (http://10.1.0.57:8077)
	--cmd STR003 - Stirling PDF purge with data folder
	--cmd STC001 - Syncthing continuous file synchronization
	--cmd STC002 - Syncthing remove (http://10.1.0.57:8884)
	--cmd STC003 - Syncthing purge with data folder
	--cmd NCT001 - Nextcloud content collaboration platform
	--cmd NCT002 - Nextcloud remove (https://10.1.0.57:443)
	--cmd NCT003 - Nextcloud purge with data folder
	--cmd OWC001 - Owncloud share files and folders, easy and secure
	--cmd OWC002 - Owncloud remove (http://10.1.0.57:7787)
	--cmd OWC003 - Owncloud purge with data folder
	--cmd JMS001 - Jellyfin Media System
	--cmd JMS002 - Jellyfin remove (http://10.1.0.57:8096)
	--cmd JMS003 - Jellyfin purge with data folder
	--cmd HPS001 - Hastebin Paste Server
	--cmd HPS002 - Hastebin remove
	--cmd HPS003 - Hastebin purge with data folder
	--cmd IMM001 - Immich - high-performance self-hosted photo and video backup solution
	--cmd IMM002 - Immich remove (http://10.1.0.57:8077)
	--cmd IMM003 - Immich purge with data folder
    Monitoring - Real-time monitoring, collecting metrics, up-time status
	--cmd UPK001 - Uptime Kuma self-hosted monitoring tool
	--cmd UPK002 - Uptime Kuma remove (http://10.1.0.57:3001)
	--cmd UPK003 - Uptime Kuma purge with data folder
	--cmd NTD001 - Netdata - monitoring real-time metrics
	--cmd NTD002 - Netdata remove (http://10.1.0.57:19999)
	--cmd NTD003 - Netdata purge with data folder
	--cmd GRA001 - Grafana data analytics
	--cmd GRA002 - Grafana remove (http://10.1.0.57:3000)
	--cmd GRA003 - Grafana purge with data folder
	--cmd PRO001 - Prometheus docker image
	--cmd PRO002 - Prometheus remove
	--cmd PRO003 - Prometheus purge with data folder
	--cmd NAX001 - NetAlertX network scanner & notification framework
	--cmd NAX002 - NetAlertX network scanner remove (http://10.1.0.57:20211)
	--cmd NAX003 - NetAlertX network scanner purge with data folder
    Management - Remote File & Management tools
	--cmd CPT001 - Cockpit web-based management tool (http://10.1.0.57:9090)
	--cmd SMB001 - SAMBA Remote File share
	--cmd WBM001 - Webmin web-based management tool
	--cmd HPG001 - Install Homepage startpage / application dashboard
	--cmd HPG002 - Remove Homepage (http://10.1.0.57:3000)
	--cmd HPG003 - Purge Homepage with data folder
	--cmd NBOX01 - NetBox infrastructure resource modeling install
	--cmd NBOX02 - NetBox remove (http://10.1.0.57:8222)
	--cmd NBOX03 - NetBox purge with data folder
    Printing - Tools for printing and 3D printing
	--cmd OCT001 - OctoPrint web-based 3D printers management tool
	--cmd OCT002 - OctoPrint remove (http://10.1.0.57:7981)
	--cmd OCT003 - OctoPrint purge with data folder
    Netconfig - Console network tools for measuring load and bandwidth
	--cmd NLD001 - nload - realtime console network usage monitor
	--cmd NLD002 - nload - remove
	--cmd IPR001 - iperf3 bandwidth measuring tool
	--cmd IPR002 - iperf3 remove
	--cmd IPT001 - iptraf-ng IP LAN monitor
	--cmd IPT002 - iptraf-ng remove
	--cmd AVH001 - avahi-daemon hostname broadcast via mDNS
	--cmd AVH002 - avahi-daemon remove
    VPN - Virtual Private Network tools
	--cmd WRG001 - WireGuard VPN client / server
	--cmd WRG002 - WireGuard remove
	--cmd WRG003 - WireGuard clients QR codes
	--cmd WRG004 - WireGuard purge with data folder
	--cmd ZTR001 - ZeroTier connect devices over your own private network in the world.

  Help - About this tool
    --cmd HLP001 - Contribute
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

Alternative kernels, headers, overlays, bootenv

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

Basic network setup

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

View Network Configuration

Jobs:

~~~
show_message <<< "$(netplan get all)"
~~~

### NEA001

Advanced bridged network configuration

Jobs:

~~~
No commands available
~~~

### LOC001

Change Global timezone

Jobs:

~~~
dpkg-reconfigure tzdata
~~~

### LOC002

Change Locales reconfigure the language and character set

Jobs:

~~~
dpkg-reconfigure locales
source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale
export LANGUAGE=$LANG
~~~

### LOC003

Change Keyboard layout

Jobs:

~~~
dpkg-reconfigure keyboard-configuration ; setupcon 
update-initramfs -u
~~~

### LOC005

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

### Finance

Manage your finances

Jobs:

~~~
No commands available
~~~

### Backup

Backup solutions for your data

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

### Armbian

Armbian infrastructure services

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

Remote File & Management tools

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

### VPN

Virtual Private Network tools

Jobs:

~~~
No commands available
~~~

### HLP001

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
| Manage checkpoints | debug help mark reset total | @dimitry-ishenko 
| Generate this markdown table of all module_options | see_function_table_md | @Tearran 
| Netplan wrapper | simple advanced type stations select store restore dhcp static help | @igorpecovnik 
| Exit with error code 1, optionally printing a message to stderr | run_critical_function || die 'The world is about to end' | @dimitry-ishenko 
| Reload service | srv_reload ssh.service | @dimitry-ishenko 
| Webmin setup and service setting. | help install remove start stop enable disable status check | @Tearran 
| Install HA supervised container | install remove purge status help | @igorpecovnik 
| Display a menu from pipe | show_menu <<< armbianmonitor -h  ;  | @Tearran 
| Start service | srv_start ssh.service | @dimitry-ishenko 
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
| Install PostgreSQL container (advanced relational database) | install remove purge status help |  
| Install jellyfin container | install remove purge status help | @armbian 
| Install jellyseerr container | install remove purge status help | @armbian 
| Needed by generate_menu | execute_command 'id' | @Tearran 
| Display a Yes/No dialog box and process continue/exit | get_user_continue 'Do you wish to continue?' process_input | @Tearran 
| Module for Armbian firmware manipulating. | select install show hold unhold repository headers help | @igorpecovnik 
| Deploy Armbian KVM instances | install remove save drop restore list help | @igorpecovnik 
| Unmask service | srv_unmask ssh.service | @dimitry-ishenko 
| Migrated procedures from Armbian config. | connect_bt_interface | @armbian 
| Display a message box | show_message <<< 'hello world'  | @Tearran 
| Manage self hosted runners | install remove remove_online purge status help | @igorpecovnik 
| Install domoticz container | install remove purge status help | @armbian 
| Install and configure automatic updates | install remove configure status defaults help | @igorpecovnik 
| Menu for armbianmonitor features | see_monitoring | @Tearran 
| Enable/disable device tree overlays |  | @viraniac 
| XFCE desktop packages | install remove disable enable status auto manual login help | @igorpecovnik 
| Show or generate QR code for Google OTP | qr_code generate | @igorpecovnik 
| Remove package | pkg_remove nmap | @dimitry-ishenko 
| Install Immich (photo and video backup solution) | install remove purge status help |  
| Samba setup and service setting. | help install remove start stop enable disable configure default status | @Tearran 
| Check when apt list was last updated and suggest updating or update | see_current_apt or see_current_apt update | @Tearran 
| Install/uninstall/check status of portainer container | install remove purge status help | @armbian 
| Install plexmediaserver from repo using apt | install remove status | @schwar3kat 
| Generate 'Armbian CPU logo' SVG for document file. | generate_svg | @Tearran 
| Upgrade installed packages (potentially removing some) | pkg_full_upgrade | @dimitry-ishenko 
| Install zfs filesystem support | install remove status kernel_max zfs_version zfs_installed_version help | @igorpecovnik 
| Check if package is installed | pkg_installed mc | @dimitry-ishenko 
| Update submenu descriptions based on conditions | update_submenu_data | @Tearran 
| Install evcc container | install remove purge status help | @naltatis 
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
| Enable service | srv_enable ssh.service | @dimitry-ishenko 
| Generate jobs from JSON file. | generate_jobs_from_json | @Tearran 
| Display a warning with a gauge for 10 seconds then continue |  | @igorpecovnik 
| Install armbian router container | install remove purge status help | @armbian 
| Install hastebin container | install remove purge status help | @armbian 
| Install radarr container | install remove purge status help | @armbian 
| Toggle IPv6 on or off | toggle_ipv6 | @Tearran 
| Adjust welcome screen (motd) | adjust_motd clear, header, sysinfo, tips, commands | @igorpecovnik 
| Install embyserver container | install remove purge status help | @schwar3kat 
| Install duplicati container | install remove purge status help |  
| Install qbittorrent container | install remove purge status help | @qbittorrent 
| Reload systemd configuration | srv_daemon_reload | @dimitry-ishenko 
| Generate JSON-like object file. | generate_json | @Tearran 
| Install actualbudget container | install remove purge status help |  
| Install transmission container | install remove purge status help | @armbian 
| Install nextcloud container | install remove purge status help | @igorpecovnik 
| Install navidrome container | install remove purge status help | @armbian 
| Install Openhab | install remove purge status help | @igorpecovnik 
| Uses Avalible (Whiptail, DIALOG, READ) for the menu interface | <function_name> | Tearran 
| Netplan wrapper | network_config | @igorpecovnik 
| Install medusa container | install remove purge status help | @armbian 
| Install prometheus container | install remove purge status help | @armbian 
| Install syncthing container | install remove purge status help | @igorpecovnik 
| Install Zerotier | help install remove start stop enable disable status check | @jnovos 
| Install grafana container | install remove purge status help | @armbian 
| Select optimised Odroid board configuration | select | @GeoffClements 
| Install owncloud container | install remove purge status help | @armbian 
| Install netdata container | install remove purge status help | @armbian 
| Change the background color of the terminal or dialog box | set_colors 0-7 | @Tearran 
| Show general information about this tool | about_armbian_configng | @igorpecovnik 
| Install unbound container | install remove purge status help | @igorpecovnik 
| Serve the edit and debug server. | serve_doc | @Tearran 
| Update JSON data with system information | update_json_data | @Tearran 
| Check if service is active | srv_active ssh.service | @dimitry-ishenko 
| Install nfs client | install remove servers mounts help | @igorpecovnik 
| pipeline strings to an infobox  | show_infobox <<< 'hello world' ;  | @Tearran 
| Install readarr container | install remove purge status help | @armbian 
| Install uptimekuma container | install remove purge status help | @armbian 
| Stop hostapd, clean config | default_wireless_network_config | @igorpecovnik 
| Install homepage container | install remove purge status help | @armbian 
| Generate desktop packages list |  | @igorpecovnik 
| Update sub-submenu descriptions based on conditions | update_sub_submenu_data MenuID SubID SubSubID CMD | @Tearran 
| Parse json to get list of desired menu or submenu items | parse_menu_items 'menu_options_array' | @viraniac 
| Show the usage of the functions. | see_use | @Tearran 
| Check if service is enabled | srv_enabled ssh.service | @dimitry-ishenko 
| Install adguardhome container | install remove purge status help | @igorpecovnik 
| Set system shell to BASH | manage_zsh enable|disable | @igorpecovnik 
| Install NetBox container (IPAM/DCIM tool) | install remove purge status help |  
| Install sabnzbd container | install remove purge status help | @armbian 
| Mask service | srv_mask ssh.service | @dimitry-ishenko 
| Show service status information | srv_status ssh.service | @dimitry-ishenko 
| Install Redis in a container (In-Memory Data Store) | install remove purge status help |  
| Stop service | srv_stop ssh.service | @dimitry-ishenko 
| Configure an unconfigured package | pkg_configure | @dimitry-ishenko 
| Install Pi-hole container | install remove purge password status help | @armbian 
| Generate a Help message for cli commands. | see_cmd_list [category] | @Tearran 
| Install mariadb container | install remove purge status help | @igorpecovnik 
| Disable service | srv_disable ssh.service | @dimitry-ishenko 
| Revert network config back to Armbian defaults | default_network_config | @igorpecovnik 
| Check if the current OS is supported based on /etc/armbian-distribution-status | help | @Tearran 
| Install prowlarr container | install remove purge status help | @Prowlarr 
| Install nfsd server | install remove manage add status clients servers help | @igorpecovnik 
| Install and configure Armbian rsyncd. | install remove status help | @igorpecovnik 
| Check the internet connection with fallback DNS | see_ping | @Tearran 
| Make sure param contains only valid chars | sanitize 'foo_bar_42' | @Tearran 
| Install docker from a repo using apt | install remove purge status help | @schwar3kat 
| Upgrade to next stable or rolling release | release_upgrade stable verify | @igorpecovnik 
| Update the /etc/skel files in users directories | update_skel | @igorpecovnik 
| Default module implementation | disable enable help install remove status | @dimitry-ishenko 
| change_system_hostname | change_system_hostname | @igorpecovnik 
| Install netalertx container | install remove purge status help | @jokob-sk 
| Restart service | srv_restart ssh.service | @dimitry-ishenko 
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

