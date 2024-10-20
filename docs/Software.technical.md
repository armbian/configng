- [Software](#software): Run/Install 3rd party applications
  - [Desktops](#desktops): Desktop Environments
    - [XFCE](#xfce): XFCE desktop
      - [DE01](#de01): XFCE desktop Install
      - [DE02](#de02): Uninstall
      - [DE03](#de03): Enable autologin
      - [DE04](#de04): Disable autologin
    - [Gnome](#gnome): Gnome desktop
      - [DE11](#de11): Gnome desktop Install
      - [DE12](#de12): Uninstall
      - [DE13](#de13): Enable autologin
      - [DE14](#de14): Disable autologin
    - [DE20](#de20): i3-wm desktop
      - [DE21](#de21): i3 desktop Install
      - [DE22](#de22): i3 desktop uninstall
      - [DE23](#de23): Enable autologin
      - [DE24](#de24): Disable autologin
    - [Cinnamon](#cinnamon): Cinnamon desktop
      - [DE31](#de31): Cinnamon desktop Install
      - [DE32](#de32): Cinnamon desktop uninstall
      - [DE33](#de33): Enable autologin
      - [DE34](#de34): Disable autologin
    - [DE40](#de40): Kde-neon desktop
      - [DE41](#de41): Kde-neon desktop Install
      - [DE42](#de42): Uninstall
      - [DE43](#de43): Enable autologin
      - [DE44](#de44): Disable autologin
    - [DE99](#de99): Improve application search speed
  - [Netconfig](#netconfig): Network tools
    - [SW08](#sw08): Install realtime console network usage monitor (nload)
    - [SW09](#sw09): Remove realtime console network usage monitor (nload)
    - [SW10](#sw10): Install bandwidth measuring tool (iperf3)
    - [SW11](#sw11): Remove bandwidth measuring tool (iperf3)
    - [SW12](#sw12): Install IP LAN monitor (iptraf-ng)
    - [SW13](#sw13): Remove IP LAN monitor (iptraf-ng)
    - [SW14](#sw14): Install hostname broadcast via mDNS (avahi-daemon)
    - [SW15](#sw15): Remove hostname broadcast via mDNS (avahi-daemon)
  - [DevTools](#devtools): Development
    - [SW17](#sw17): Install tools for cloning and managing repositories (git)
    - [SW18](#sw18): Remove tools for cloning and managing repositories (git)
  - [Benchy](#benchy): System benchmaking and diagnostics
  - [Containers](#containers): Containerlization and Virtual Machines
    - [SW25](#sw25): Install Docker Minimal
    - [SW26](#sw26): Install Docker Engine
    - [SW27](#sw27): Remove Docker
    - [SW28](#sw28): Purge all Docker images, containers, and volumes
  - [Media](#media): Media Servers and Editors
    - [SW21](#sw21): Install Plex Media server
    - [SW22](#sw22): Remove Plex Media server
    - [SW23](#sw23): Install Emby server
    - [SW24](#sw24): Remove Emby server
  - [Management](#management): Remote Management tools
    - [M00](#m00): Install Cockpit web-based management tool
    - [M01](#m01): Purge Cockpit web-based management tool
    - [M02](#m02): Start Cockpit Service
    - [M03](#m03): Stop Cockpit Service

# Software

**Description:** Run/Install 3rd party applications


## Desktops

**Description:** Desktop Environments


### XFCE

**Description:** XFCE desktop


#### DE01

**Description:** XFCE desktop Install

**Prompt:** 
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

**Description:** Uninstall

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

**Description:** Enable autologin

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

**Description:** Disable autologin

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

**Description:** Gnome desktop


#### DE11

**Description:** Gnome desktop Install

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

**Description:** Uninstall

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

**Description:** Enable autologin

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

**Description:** Disable autologin

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

**Description:** i3-wm desktop

**Status:** Disabled


#### DE21

**Description:** i3 desktop Install

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

**Description:** i3 desktop uninstall

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

**Description:** Enable autologin

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

**Description:** Disable autologin

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

**Description:** Cinnamon desktop


#### DE31

**Description:** Cinnamon desktop Install

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

**Description:** Cinnamon desktop uninstall

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

**Description:** Enable autologin

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

**Description:** Disable autologin

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

**Description:** Kde-neon desktop

**Status:** Disabled


#### DE41

**Description:** Kde-neon desktop Install

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

**Description:** Uninstall

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

**Description:** Enable autologin

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

**Description:** Disable autologin

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

**Description:** Improve application search speed

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

**Description:** Network tools


### SW08

**Description:** Install realtime console network usage monitor (nload)

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

**Description:** Remove realtime console network usage monitor (nload)

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

**Description:** Install bandwidth measuring tool (iperf3)

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

**Description:** Remove bandwidth measuring tool (iperf3)

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

**Description:** Install IP LAN monitor (iptraf-ng)

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

**Description:** Remove IP LAN monitor (iptraf-ng)

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

**Description:** Install hostname broadcast via mDNS (avahi-daemon)

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

**Description:** Remove hostname broadcast via mDNS (avahi-daemon)

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

**Description:** Development


### SW17

**Description:** Install tools for cloning and managing repositories (git)

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

**Description:** Remove tools for cloning and managing repositories (git)

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

**Description:** System benchmaking and diagnostics

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

**Description:** Containerlization and Virtual Machines


### SW25

**Description:** Install Docker Minimal

**Prompt:** 
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

**Description:** Install Docker Engine

**Prompt:** 
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

**Description:** Remove Docker

**Prompt:** 
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

**Description:** Purge all Docker images, containers, and volumes

**Prompt:** 
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

**Description:** Media Servers and Editors


### SW21

**Description:** Install Plex Media server

**Prompt:** 
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

**Description:** Remove Plex Media server

**Prompt:** 
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

**Description:** Install Emby server

**Prompt:** 
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

**Description:** Remove Emby server

**Prompt:** 
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

**Description:** Remote Management tools


### M00

**Description:** Install Cockpit web-based management tool

**Prompt:** 
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

**Description:** Purge Cockpit web-based management tool

**Prompt:** 
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

**Description:** Start Cockpit Service

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

**Description:** Stop Cockpit Service

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

