- [Run/Install 3rd party applications](#software)
  - [Desktop Environments](#desktops)
    - [XFCE desktop](#xfce)
      - [XFCE desktop Install](#de01)
      - [Uninstall](#de02)
      - [Enable autologin](#de03)
      - [Disable autologin](#de04)
    - [Gnome desktop](#gnome)
      - [Gnome desktop Install](#de11)
      - [Uninstall](#de12)
      - [Enable autologin](#de13)
      - [Disable autologin](#de14)
    - [i3-wm desktop](#de20)
      - [i3 desktop Install](#de21)
      - [i3 desktop uninstall](#de22)
      - [Enable autologin](#de23)
      - [Disable autologin](#de24)
    - [Cinnamon desktop](#cinnamon)
      - [Cinnamon desktop Install](#de31)
      - [Cinnamon desktop uninstall](#de32)
      - [Enable autologin](#de33)
      - [Disable autologin](#de34)
    - [Kde-neon desktop](#de40)
      - [Kde-neon desktop Install](#de41)
      - [Uninstall](#de42)
      - [Enable autologin](#de43)
      - [Disable autologin](#de44)
    - [Improve application search speed](#de99)
  - [Network tools](#netconfig)
    - [Install realtime console network usage monitor (nload)](#sw08)
    - [Remove realtime console network usage monitor (nload)](#sw09)
    - [Install bandwidth measuring tool (iperf3)](#sw10)
    - [Remove bandwidth measuring tool (iperf3)](#sw11)
    - [Install IP LAN monitor (iptraf-ng)](#sw12)
    - [Remove IP LAN monitor (iptraf-ng)](#sw13)
    - [Install hostname broadcast via mDNS (avahi-daemon)](#sw14)
    - [Remove hostname broadcast via mDNS (avahi-daemon)](#sw15)
  - [Development](#devtools)
    - [Install tools for cloning and managing repositories (git)](#sw17)
    - [Remove tools for cloning and managing repositories (git)](#sw18)
  - [System benchmaking and diagnostics](#benchy)
  - [Containerlization and Virtual Machines](#containers)
    - [Install Docker Minimal](#sw25)
    - [Install Docker Engine](#sw26)
    - [Remove Docker](#sw27)
    - [Purge all Docker images, containers, and volumes](#sw28)
  - [Media Servers and Editors](#media)
    - [Install Plex Media server](#sw21)
    - [Remove Plex Media server](#sw22)
    - [Install Emby server](#sw23)
    - [Remove Emby server](#sw24)
  - [Remote Management tools](#management)
    - [Install Cockpit web-based management tool](#m00)
    - [Purge Cockpit web-based management tool](#m01)
    - [Start Cockpit Service](#m02)
    - [Stop Cockpit Service](#m03)

# Software

**description:** Run/Install 3rd party applications


## Desktops

**description:** Desktop Environments


### XFCE

**description:** XFCE desktop


#### DE01

**description:** XFCE desktop Install

**prompt:** 
Install XFCE:
Xfce is a lightweight desktop environment for UNIX-like operating systems. It aims to be fast and low on system resources, while still being visually appealing and user friendly.

**Command:** 
~~~
manage_desktops 'xfce' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/xfce.desktop ]
~~~

#### DE02

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'xfce' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ]
~~~

#### DE03

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'xfce' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

#### DE04

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'xfce' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### Gnome

**description:** Gnome desktop


#### DE11

**description:** Gnome desktop Install

**Command:** 
~~~
manage_desktops 'gnome' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/gnome.desktop ]
~~~

#### DE12

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'gnome' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ]
~~~

#### DE13

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'gnome' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && ! cat /etc/gdm3/custom.conf 2>/dev/null | grep AutomaticLoginEnable | grep true >/dev/null
~~~

#### DE14

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'gnome' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && cat /etc/gdm3/custom.conf 2>/dev/null | grep AutomaticLoginEnable | grep true >/dev/null
~~~

### DE20

**description:** i3-wm desktop

**Status:** Disabled


#### DE21

**description:** i3 desktop Install

**Command:** 
~~~
manage_desktops 'i3-wm' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/i3.desktop ]
~~~

#### DE22

**description:** i3 desktop uninstall

**Command:** 
~~~
manage_desktops 'i3-wm' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ]
~~~

#### DE23

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'i3-wm' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

#### DE24

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'i3-wm' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### Cinnamon

**description:** Cinnamon desktop


#### DE31

**description:** Cinnamon desktop Install

**Command:** 
~~~
manage_desktops 'cinnamon' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/cinnamon.desktop ] && [ ! -f /usr/share/xsessions/cinnamon2d.desktop ]
~~~

#### DE32

**description:** Cinnamon desktop uninstall

**Command:** 
~~~
manage_desktops 'cinnamon' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] || [ -f /usr/share/xsessions/cinnamon2d.desktop ]
~~~

#### DE33

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'cinnamon' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

#### DE34

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'cinnamon' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE40

**description:** Kde-neon desktop

**Status:** Disabled


#### DE41

**description:** Kde-neon desktop Install

**Command:** 
~~~
manage_desktops 'kde-neon' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/gnome.desktop ]
~~~

#### DE42

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'kde-neon' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ]
~~~

#### DE43

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'kde-neon' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

#### DE44

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'kde-neon' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE99

**description:** Improve application search speed

**Command:** 
~~~
update-apt-xapian-index -u; sleep 3
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
systemctl is-active --quiet service display-manager
~~~

## Netconfig

**description:** Network tools


### SW08

**description:** Install realtime console network usage monitor (nload)

**Command:** 
~~~
get_user_continue "This operation will install nload.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y install nload
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed nload
~~~

### SW09

**description:** Remove realtime console network usage monitor (nload)

**Command:** 
~~~
get_user_continue "This operation will purge nload.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y purge nload
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed nload
~~~

### SW10

**description:** Install bandwidth measuring tool (iperf3)

**Command:** 
~~~
get_user_continue "This operation will install iperf3.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y install iperf3
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed iperf3
~~~

### SW11

**description:** Remove bandwidth measuring tool (iperf3)

**Command:** 
~~~
get_user_continue "This operation will purge iperf3.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y purge iperf3
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed iperf3
~~~

### SW12

**description:** Install IP LAN monitor (iptraf-ng)

**Command:** 
~~~
get_user_continue "This operation will install iptraf-ng.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y install iptraf-ng
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed iptraf-ng
~~~

### SW13

**description:** Remove IP LAN monitor (iptraf-ng)

**Command:** 
~~~
get_user_continue "This operation will purge nload.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y purge iptraf-ng
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed iptraf-ng
~~~

### SW14

**description:** Install hostname broadcast via mDNS (avahi-daemon)

**Command:** 
~~~
get_user_continue "This operation will install avahi-daemon and add configuration files.
Do you wish to continue?" process_input, check_if_installed avahi-daemon, debconf-apt-progress -- apt-get -y install avahi-daemon libnss-mdns, cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/, cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/, service avahi-daemon restart
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed avahi-daemon
~~~

### SW15

**description:** Remove hostname broadcast via mDNS (avahi-daemon)

**Command:** 
~~~
get_user_continue "This operation will purge avahi-daemon 
Do you wish to continue?" process_input, check_if_installed avahi-daemon, systemctl stop avahi-daemon avahi-daemon.socket, debconf-apt-progress -- apt-get -y purge avahi-daemon
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed avahi-daemon
~~~

## DevTools

**description:** Development


### SW17

**description:** Install tools for cloning and managing repositories (git)

**Command:** 
~~~
get_user_continue "This operation will install git.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y install git
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed git
~~~

### SW18

**description:** Remove tools for cloning and managing repositories (git)

**Command:** 
~~~
get_user_continue "This operation will remove git.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y purge git
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed git
~~~

## Benchy

**description:** System benchmaking and diagnostics

**Command:** 
~~~
see_monitoring
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
[ -f /usr/bin/armbianmonitor ]
~~~

## Containers

**description:** Containerlization and Virtual Machines


### SW25

**description:** Install Docker Minimal

**prompt:** 
This operation will install Docker Minimal.
Would you like to continue?

**Command:** 
~~~
install_docker
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-ce
~~~

### SW26

**description:** Install Docker Engine

**prompt:** 
This operation will install Docker Engine.
Would you like to continue?

**Command:** 
~~~
install_docker engine
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-compose-plugin
~~~

### SW27

**description:** Remove Docker

**prompt:** 
This operation will purge Docker.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed docker-ce
~~~

### SW28

**description:** Purge all Docker images, containers, and volumes

**prompt:** 
This operation will delete all Docker images, containers, and volumes.
Would you like to continue?

**Command:** 
~~~
rm -rf /var/lib/docker, rm -rf /var/lib/containerd
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-ce && [ -d /var/lib/docker ]
~~~

## Media

**description:** Media Servers and Editors


### SW21

**description:** Install Plex Media server

**prompt:** 
This operation will install Plex Media server.
Would you like to continue?

**Command:** 
~~~
install_plexmediaserver
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed plexmediaserver
~~~

### SW22

**description:** Remove Plex Media server

**prompt:** 
This operation will purge Plex Media server.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt-get -y purge plexmediaserver, sed -i '/plexmediaserver.gpg/s/^/#/g' /etc/apt/sources.list.d/plexmediaserver.list
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed plexmediaserver
~~~

### SW23

**description:** Install Emby server

**prompt:** 
This operation will install Emby server.
Would you like to continue?

**Command:** 
~~~
install_embyserver
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed emby-server
~~~

### SW24

**description:** Remove Emby server

**prompt:** 
This operation will purge Emby server.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt -y purge emby-server
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed emby-server
~~~

## Management

**description:** Remote Management tools


### M00

**description:** Install Cockpit web-based management tool

**prompt:** 
This operation will install Cockpit.
cockpit cockpit-ws cockpit-system cockpit-storaged
Would you like to continue?

**Command:** 
~~~
see_current_apt update, apt_install_wrapper apt -y install cockpit cockpit-ws cockpit-system cockpit-storaged 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed cockpit
~~~

### M01

**description:** Purge Cockpit web-based management tool

**prompt:** 
This operation will purge Cockpit.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt -y purge cockpit
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit
~~~

### M02

**description:** Start Cockpit Service

**Command:** 
~~~
sudo systemctl enable --now cockpit.socket | show_infobox 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit && ! systemctl is-enabled cockpit.socket > /dev/null 2>&1
~~~

### M03

**description:** Stop Cockpit Service

**Command:** 
~~~
systemctl stop cockpit cockpit.socket, systemctl disable cockpit.socket | show_infobox 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit && systemctl is-enabled cockpit.socket > /dev/null 2>&1
~~~

