---
title: "armbian-config(1)"
author: "Armbian Team"
date: "Thu May  1 02:31:23 AM UTC 2025"
---

<img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg">

# NAME
**Armbian Config** - The Next Generation

# SYNOPSIS
`armbian-config[option] [arguments] [@]`

# DESCRIPTION
`armbian-config` provides configuration and installation routines for customizing and automating tasks within the Armbian Linux environment. These utilities help streamline setup processes for various use cases, such as managing software, network settings, localization, and system optimizations.

# COMMAND-LINE OPTIONS
`armbian-config` can also be used directly from the command line with the following options:

## General Options
- Display help for specific categories or overall usage.

```bash
armbian-config --help [cmd|System|Software|Network|Localisation]
```

- Navigate directly to a specific menu location or ID.

```bash
armbian-config --cmd help
```

- Programmatically interact with an application module or its helper functions.
(applications parsing interface)
```bash
armbian-config --api help
```


# Directly open run menu item
```bash

  System - System wide and admin settings (aarch64)
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
	--cmd ZFS001 - ZFS filesystem - enable support (v2.3.1)
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
	--cmd SSH002 - Remove sandboxed SSH server (ssh://192.168.43.68:2222)
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

  Network - Fixed and wireless network settings (wlan0)
    --cmd BNS001 - Basic network setup
    --cmd BNS002 - Remove Fallback DHCP Configuration
    --cmd VNS001 - View Network Configuration
    NEA001 - Advanced bridged network configuration
	--cmd NEA002 - Add / change interface
	--cmd NEA003 - Revert to Armbian defaults
	--cmd NEA004 - Show configuration
	--cmd NEA005 - Show active status
    --cmd WRG001 - WireGuard VPN client / server
    --cmd WRG002 - WireGuard remove
    --cmd WRG003 - WireGuard clients QR codes
    --cmd WRG004 - WireGuard purge with data folder

  Localisation - Localisation (en_US.UTF-8)
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
	--cmd HAB002 - openHAB remove (http://192.168.43.68:8080)
	--cmd HAB003 - openHAB purge with data folder
	--cmd HAS001 - Home Assistant open source home automation
	--cmd HAS002 - Home Assistant remove (http://192.168.43.68:8123)
	--cmd HAS003 - Home Assistant purge with data folder
	--cmd DOM001 - Domoticz open source home automation
	--cmd DOM002 - Domoticz remove (http://192.168.43.68:8080)
	--cmd DOM003 - Domoticz purge with data folder
	--cmd EVCC01 - EVCC - solar charging automation
	--cmd EVCC02 - EVCC - solar charging automation remove (http://192.168.43.68:7070)
	--cmd EVCC03 - EVCC purge with data folder
    DNS - Network-wide ad blockers servers
	--cmd PIH001 - Pi-hole DNS ad blocker
	--cmd PIH003 - Pi-hole remove (http://192.168.43.68:80)
	--cmd PIH002 - Pi-hole change web admin password
	--cmd PIH004 - Pi-hole purge with data folder
	--cmd UNB001 - Unbound caching DNS resolver
	--cmd UNB002 - Unbound remove
	--cmd UNB003 - Unbound purge with data folder
	--cmd ADG001 - AdGuardHome DNS sinkhole
	--cmd ADG002 - AdGuardHome remove (http://192.168.43.68:3000)
	--cmd ADG003 - AdGuardHome purge with data folder
    Music - Music servers and streamers
	--cmd NAV001 - Navidrome music server and streamer compatible with Subsonic/Airsonic
	--cmd NAV002 - Navidrome remove
	--cmd NAV003 - Navidrome purge with data folder
    Finance - Manage your finances
	--cmd ABU001 - Do your finances with Actual Budget
	--cmd ABU002 - Actual Budget remove (http://192.168.43.68:5006)
	--cmd ABU003 - Actual Budget purge with data folder
    Backup - Backup solutions for your data
	--cmd DPL001 - Duplicati install
	--cmd DPL002 - Duplicati remove (http://192.168.43.68:8200)
	--cmd DPL003 - Duplicati purge with data folder
    Downloaders - Download apps for movies, TV shows, music and subtitles
	--cmd DOW001 - qBittorrent BitTorrent client 
	--cmd DOW002 - qBittorrent remove (http://192.168.43.68:8090)
	--cmd DOW003 - qBittorrent purge with data folder
	--cmd DEL001 - Deluge BitTorrent client
	--cmd DEL002 - Deluge remove (http://192.168.43.68:8112)
	--cmd DEL003 - Deluge purge with data folder
	--cmd TRA001 - Transmission BitTorrent client
	--cmd TRA002 - Transmission remove (http://192.168.43.68:9091)
	--cmd TRA003 - Transmission purge with data folder
	--cmd SABN01 - SABnzbd newsgroup downloader
	--cmd SABN02 - SABnzbd remove (http://192.168.43.68:8080)
	--cmd SABN03 - SABnzbd purge with data folder
	--cmd MDS001 - Medusa automatic downloader for TV shows
	--cmd MDS002 - Medusa TV shows downloader remove (http://192.168.43.68:8081)
	--cmd MDS003 - Medusa TV shows downloader purge
	--cmd SON001 - Sonarr automatic downloader for TV shows
	--cmd SON002 - Sonarr remove (http://192.168.43.68:8989)
	--cmd SON003 - Sonarr purge with data folder
	--cmd RAD001 - Radarr automatic downloader for movies
	--cmd RAD002 - Radarr remove (http://192.168.43.68:7878)
	--cmd RAD003 - Radarr purge with data folder
	--cmd BAZ001 - Bazarr automatic subtitles downloader for Sonarr and Radarr
	--cmd BAZ002 - Bazarr remove (http://192.168.43.68:6767)
	--cmd BAZ003 - Bazarr purge with data folder
	--cmd LID001 - Lidarr automatic music downloader
	--cmd LID002 - Lidarr remove (http://192.168.43.68:8686)
	--cmd LID003 - Lidarr purge with data folder
	--cmd RDR001 - Readarr automatic downloader for Ebooks
	--cmd RDR002 - Readarr remove (http://192.168.43.68:8787)
	--cmd RDR003 - Readarr purge with data folder
	--cmd DOW025 - Prowlarr index manager and proxy for PVR
	--cmd DOW026 - Prowlarr remove (http://192.168.43.68:9696)
	--cmd DOW027 - Prowlarr purge with data folder
	--cmd JEL001 - Jellyseerr Jellyfin/Emby/Plex integration install
	--cmd JEL002 - Jellyseerr remove (http://192.168.43.68:5055)
	--cmd JEL003 - Jellyseerr purge with data folder
    Database - SQL database servers and web interface managers
	--cmd PGSQL1 - PostgreSQL install
	--cmd PGSQL2 - PostgreSQL remove
	--cmd PGSQL3 - PostgreSQL purge with data folder
	--cmd DAT001 - Mariadb SQL database server
	--cmd DAT002 - Mariadb remove (Server: 192.168.43.68)
	--cmd DAT003 - Mariadb purge with data folder
	--cmd REDIS1 - Redis install
	--cmd REDIS2 - Redis remove
	--cmd REDIS3 - Redis purge with data folder
	--cmd MYA001 - phpMyAdmin web interface manager
	--cmd MYA002 - phpMyAdmin remove (http://192.168.43.68:8071)
	--cmd MYA003 - phpMyAdmin purge with data folder
    DevTools - Applications and tools for development
	--cmd GIT001 - Install tools for cloning and managing repositories (git)
	--cmd GIT002 - Remove tools for cloning and managing repositories (git)
	--cmd ART001 - Armbian router for repository mirror automation
	--cmd ART002 - Remove Armbian router
	--cmd RSD001 - Armbian rsyncd server
	--cmd RSD002 - Remove Armbian rsyncd server
    Containers - Docker containerization and KVM virtual machines
	--cmd CON001 - Docker minimal
	--cmd CON002 - Docker engine
	--cmd CON003 - Docker remove
	--cmd CON004 - Docker purge with all images, containers, and volumes
	--cmd POR001 - Portainer container management platform
	--cmd POR002 - Portainer remove (http://192.168.43.68:9000)
	--cmd POR003 - Portainer purge with with data folder
    Media - Media servers, organizers and editors
	--cmd EMB001 - Emby organizes video, music, live TV, and photos
	--cmd EMB002 - Emby server remove (http://192.168.43.68:8096)
	--cmd EMB003 - Emby server purge with data folder
	--cmd STR001 - Stirling PDF tools for viewing and editing PDF files
	--cmd STR002 - Stirling PDF remove (http://192.168.43.68:8077)
	--cmd STR003 - Stirling PDF purge with data folder
	--cmd STC001 - Syncthing continuous file synchronization
	--cmd STC002 - Syncthing remove (http://192.168.43.68:8884)
	--cmd STC003 - Syncthing purge with data folder
	--cmd NCT001 - Nextcloud content collaboration platform
	--cmd NCT002 - Nextcloud remove (https://192.168.43.68:443)
	--cmd NCT003 - Nextcloud purge with data folder
	--cmd OWC001 - Owncloud share files and folders, easy and secure
	--cmd OWC002 - Owncloud remove (http://192.168.43.68:7787)
	--cmd OWC003 - Owncloud purge with data folder
	--cmd JMS001 - Jellyfin Media System
	--cmd JMS002 - Jellyfin remove (http://192.168.43.68:8096)
	--cmd JMS003 - Jellyfin purge with data folder
	--cmd HPS001 - Hastebin Paste Server
	--cmd HPS002 - Hastebin remove
	--cmd HPS003 - Hastebin purge with data folder
	--cmd IMM001 - Immich - high-performance self-hosted photo and video backup solution
	--cmd IMM002 - Immich remove (http://192.168.43.68:8077)
	--cmd IMM003 - Immich purge with data folder
    Monitoring - Real-time monitoring, collecting metrics, up-time status
	--cmd UPK001 - Uptime Kuma self-hosted monitoring tool
	--cmd UPK002 - Uptime Kuma remove (http://192.168.43.68:3001)
	--cmd UPK003 - Uptime Kuma purge with data folder
	--cmd NTD001 - Netdata - monitoring real-time metrics
	--cmd NTD002 - Netdata remove (http://192.168.43.68:19999)
	--cmd NTD003 - Netdata purge with data folder
	--cmd GRA001 - Grafana data analytics
	--cmd GRA002 - Grafana remove (http://192.168.43.68:3000)
	--cmd GRA003 - Grafana purge with data folder
	--cmd PRO001 - Prometheus docker image
	--cmd PRO002 - Prometheus remove
	--cmd PRO003 - Prometheus purge with data folder
	--cmd NAX001 - NetAlertX network scanner & notification framework
	--cmd NAX002 - NetAlertX network scanner remove (http://192.168.43.68:20211)
	--cmd NAX003 - NetAlertX network scanner purge with data folder
    Management - Remote File & Management tools
	--cmd CPT001 - Cockpit web-based management tool (http://192.168.43.68:9090)
	--cmd SMB001 - SAMBA Remote File share
	--cmd WBM001 - Webmin web-based management tool
	--cmd HPG001 - Install Homepage startpage / application dashboard
	--cmd HPG002 - Remove Homepage (http://192.168.43.68:3000)
	--cmd HPG003 - Purge Homepage with data folder
	--cmd NBOX01 - NetBox infrastructure resource modeling install
	--cmd NBOX02 - NetBox remove (http://192.168.43.68:8222)
	--cmd NBOX03 - NetBox purge with data folder
    Printing - Tools for printing and 3D printing
	--cmd OCT001 - OctoPrint web-based 3D printers management tool
	--cmd OCT002 - OctoPrint remove (http://192.168.43.68:7981)
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
    VPN - VPN tools
	--cmd VPN001 - ZeroTier connect devices over your own private network in the world.

  Help - About this tool
    --cmd HLP001 - Contribute
```

# Directly access modules and helpers

```bash
Usage: ./bin/armbian-config --api [module] [options]

--api see_cli_legacy - Generate a Help message legacy cli commands.
	[options] - None

--api set_runtime_variables - Run time variables Migrated procedures from Armbian config.
	[options] - None

--api set_interface - Check for (Whiptail, DIALOG, READ) tools and set the user interface.
	[options] - None

--api toggle_ssh_lastlog - Toggle SSH lastlog
	[options] - None

--api checkpoint - Manage checkpoints
	[options] - debug help mark reset total

--api see_function_table_md - Generate this markdown table of all module_options
	[options] - None

--api module_simple_network - Netplan wrapper
	[options] - simple advanced type stations select store restore dhcp static help

--api die - Exit with error code 1, optionally printing a message to stderr
	[options] - run_critical_function || die 'The world is about to end'

--api srv_reload - Reload service
	[options] - srv_reload ssh.service

--api module_webmin - Webmin setup and service setting.
	[options] - help install remove start stop enable disable status check

--api module_haos - Install HA supervised container
	[options] - install remove purge status help

--api show_menu - Display a menu from pipe
	[options] - show_menu <<< armbianmonitor -h  ; 

--api srv_start - Start service
	[options] - srv_start ssh.service

--api module_watchtower - Install watchtower container
	[options] - install remove status help

--api generate_top_menu - Build the main menu from a object
	[options] - generate_top_menu 'json_data'

--api module_bazarr - Install bazarr container
	[options] - install remove purge status help

--api module_headers - Install headers container
	[options] - install remove status help

--api is_package_manager_running - Migrated procedures from Armbian config.
	[options] - None

--api check_desktop - Migrated procedures from Armbian config.
	[options] - None

--api module_phpmyadmin - Install phpmyadmin container
	[options] - install remove purge status help

--api module_stirling - Install stirling container
	[options] - install remove purge status help

--api module_sonarr - Install sonarr container
	[options] - install remove purge status help

--api generate_readme - Generate Document files.
	[options] - None

--api store_netplan_config - Storing netplan config to tmp
	[options] - None

--api module_postgres - Install PostgreSQL container (advanced relational database)
	[options] - install remove purge status help

--api module_jellyfin - Install jellyfin container
	[options] - install remove purge status help

--api module_jellyseerr - Install jellyseerr container
	[options] - install remove purge status help

--api execute_command - Needed by generate_menu
	[options] - execute_command 'id'

--api get_user_continue - Display a Yes/No dialog box and process continue/exit
	[options] - get_user_continue 'Do you wish to continue?' process_input

--api module_armbian_firmware - Module for Armbian firmware manipulating.
	[options] - select install show hold unhold repository headers help

--api module_armbian_kvmtest - Deploy Armbian KVM instances
	[options] - install remove save drop restore list help

--api srv_unmask - Unmask service
	[options] - srv_unmask ssh.service

--api connect_bt_interface - Migrated procedures from Armbian config.
	[options] - None

--api show_message - Display a message box
	[options] - show_message <<< 'hello world' 

--api module_armbian_runners - Manage self hosted runners
	[options] - install remove remove_online purge help

--api module_domoticz - Install domoticz container
	[options] - install remove purge status help

--api module_armbian_upgrades - Install and configure automatic updates
	[options] - install remove configure status defaults help

--api see_monitoring - Menu for armbianmonitor features
	[options] - None

--api manage_dtoverlays - Enable/disable device tree overlays
	[options] - None

--api module_desktop - XFCE desktop packages
	[options] - install remove disable enable status auto manual login help

--api qr_code - Show or generate QR code for Google OTP
	[options] - qr_code generate

--api pkg_remove - Remove package
	[options] - pkg_remove nmap

--api module_immich - Install Immich (photo and video backup solution)
	[options] - install remove purge status help

--api module_samba - Samba setup and service setting.
	[options] - help install remove start stop enable disable configure default status

--api see_current_apt - Check when apt list was last updated and suggest updating or update
	[options] - see_current_apt or see_current_apt update

--api module_portainer - Install/uninstall/check status of portainer container
	[options] - install remove purge status help

--api Install plexmediaserver - Install plexmediaserver from repo using apt
	[options] - install remove status

--api generate_svg - Generate 'Armbian CPU logo' SVG for document file.
	[options] - None

--api pkg_full_upgrade - Upgrade installed packages (potentially removing some)
	[options] - None

--api module_zfs - Install zfs filesystem support
	[options] - install remove status kernel_max zfs_version zfs_installed_version help

--api pkg_installed - Check if package is installed
	[options] - pkg_installed mc

--api update_submenu_data - Update submenu descriptions based on conditions
	[options] - None

--api module_evcc - Install evcc container
	[options] - install remove purge status help

--api module_openssh-server - Install openssh-server container
	[options] - install remove purge status help

--api pkg_upgrade - Upgrade installed packages
	[options] - None

--api module_lidarr - Install lidarr container
	[options] - install remove purge status help

--api check_ip_version - Check if a domain is reachable via IPv4 and IPv6
	[options] - check_ip_version google.com

--api pkg_install - Install package
	[options] - pkg_install neovim

--api module_wireguard - Install wireguard container
	[options] - install remove purge qrcode status help

--api module_swag - Secure Web Application Gateway 
	[options] - install remove purge status password help

--api module_deluge - Install deluge container
	[options] - install remove purge status help

--api module_overlayfs - Set Armbian root filesystem to read only
	[options] - install remove status help

--api module_cockpit - Cockpit setup and service setting.
	[options] - help install remove start stop enable disable status check

--api generate_menu - Generate a submenu from a parent_id
	[options] - generate_menu 'parent_id'

--api see_jq_menu_list - Generate a markdown list json objects using jq.
	[options] - None

--api module_octoprint - Install octoprint container
	[options] - install remove purge status help

--api srv_enable - Enable service
	[options] - srv_enable ssh.service

--api generate_jobs_from_json - Generate jobs from JSON file.
	[options] - None

--api info_wait_autocontinue - Display a warning with a gauge for 10 seconds then continue
	[options] - None

--api module_armbianrouter - Install armbian router container
	[options] - install remove purge status help

--api module_hastebin - Install hastebin container
	[options] - install remove purge status help

--api module_radarr - Install radarr container
	[options] - install remove purge status help

--api toggle_ipv6 - Toggle IPv6 on or off
	[options] - None

--api about_armbian_configng - Adjust welcome screen (motd)
	[options] - adjust_motd clear, header, sysinfo, tips, commands

--api module_embyserver - Install embyserver container
	[options] - install remove purge status help

--api module_duplicati - Install duplicati container
	[options] - install remove purge status help

--api module_qbittorrent - Install qbittorrent container
	[options] - install remove purge status help

--api srv_daemon_reload - Reload systemd configuration
	[options] - None

--api generate_json - Generate JSON-like object file.
	[options] - None

--api module_actualbudget - Install actualbudget container
	[options] - install remove purge status help

--api module_transmission - Install transmission container
	[options] - install remove purge status help

--api module_nextcloud - Install nextcloud container
	[options] - install remove purge status help

--api module_navidrome - Install navidrome container
	[options] - install remove purge status help

--api module_openhab - Install Openhab
	[options] - install remove purge status help

--api see_menu - Uses Avalible (Whiptail, DIALOG, READ) for the menu interface
	[options] - <function_name>

--api network_config - Netplan wrapper
	[options] - None

--api module_medusa - Install medusa container
	[options] - install remove purge status help

--api module_prometheus - Install prometheus container
	[options] - install remove purge status help

--api module_syncthing - Install syncthing container
	[options] - install remove purge status help

--api module_zerotier - Install Zerotier
	[options] - help install remove start stop enable disable status check

--api module_grafana - Install grafana container
	[options] - install remove purge status help

--api Odroid board - Select optimised Odroid board configuration
	[options] - select

--api module_owncloud - Install owncloud container
	[options] - install remove purge status help

--api module_netdata - Install netdata container
	[options] - install remove purge status help

--api set_colors - Change the background color of the terminal or dialog box
	[options] - set_colors 0-7

--api about_armbian_configng - Show general information about this tool
	[options] - None

--api module_unbound - Install unbound container
	[options] - install remove purge status help

--api serve_doc - Serve the edit and debug server.
	[options] - None

--api update_json_data - Update JSON data with system information
	[options] - None

--api srv_active - Check if service is active
	[options] - srv_active ssh.service

--api module_nfs - Install nfs client
	[options] - install remove servers mounts help

--api show_infobox - pipeline strings to an infobox 
	[options] - show_infobox <<< 'hello world' ; 

--api module_readarr - Install readarr container
	[options] - install remove purge status help

--api module_uptimekuma - Install uptimekuma container
	[options] - install remove purge status help

--api default_wireless_network_config - Stop hostapd, clean config
	[options] - None

--api module_homepage - Install homepage container
	[options] - install remove purge status help

--api module_desktop - Generate desktop packages list
	[options] - None

--api update_sub_submenu_data - Update sub-submenu descriptions based on conditions
	[options] - update_sub_submenu_data MenuID SubID SubSubID CMD

--api parse_menu_items - Parse json to get list of desired menu or submenu items
	[options] - parse_menu_items 'menu_options_array'

--api see_use - Show the usage of the functions.
	[options] - None

--api srv_enabled - Check if service is enabled
	[options] - srv_enabled ssh.service

--api module_adguardhome - Install adguardhome container
	[options] - install remove purge status help

--api manage_zsh - Set system shell to BASH
	[options] - manage_zsh enable|disable

--api module_netbox - Install NetBox container (IPAM/DCIM tool)
	[options] - install remove purge status help

--api module_sabnzbd - Install sabnzbd container
	[options] - install remove purge status help

--api srv_mask - Mask service
	[options] - srv_mask ssh.service

--api srv_status - Show service status information
	[options] - srv_status ssh.service

--api module_redis - Install Redis in a container (In-Memory Data Store)
	[options] - install remove purge status help

--api srv_stop - Stop service
	[options] - srv_stop ssh.service

--api pkg_configure - Configure an unconfigured package
	[options] - None

--api module_pi_hole - Install Pi-hole container
	[options] - install remove purge password status help

--api see_cmd_list - Generate a Help message for cli commands.
	[options] - see_cmd_list [category]

--api module_mariadb - Install mariadb container
	[options] - install remove purge status help

--api srv_disable - Disable service
	[options] - srv_disable ssh.service

--api default_network_config - Revert network config back to Armbian defaults
	[options] - None

--api check_os_status - Check if the current OS is supported based on /etc/armbian-distribution-status
	[options] - help

--api module_prowlarr - Install prowlarr container
	[options] - install remove purge status help

--api module_nfsd - Install nfsd server
	[options] - install remove manage add status clients servers help

--api module_armbian_rsyncd - Install and configure Armbian rsyncd.
	[options] - install remove status help

--api see_ping - Check the internet connection with fallback DNS
	[options] - None

--api sanitize - Make sure param contains only valid chars
	[options] - sanitize 'foo_bar_42'

--api module_docker - Install docker from a repo using apt
	[options] - install remove purge status help

--api Upgrade upstream distribution release - Upgrade to next stable or rolling release
	[options] - release_upgrade stable verify

--api update_skel - Update the /etc/skel files in users directories
	[options] - None

--api module_default - Default module implementation
	[options] - disable enable help install remove status

--api Change hostname - change_system_hostname
	[options] - change_system_hostname

--api module_netalertx - Install netalertx container
	[options] - install remove purge status help

--api srv_restart - Restart service
	[options] - srv_restart ssh.service

--api pkg_update - Update package repository
	[options] - None

--api get_user_continue_secure - Secure version of get_user_continue
	[options] - get_user_continue_secure 'Do you wish to continue?' process_input
```


---

# SEE ALSO
For more information, visit:
- [Armbian Documentation](https://docs.armbian.com/User-Guide_Armbian-Config/)
- [GitHub Repository](https://github.com/armbian/configng)

---

# COPYRIGHT
© 2025 Armbian Team. Distributed under the GPL 3.0 license.
