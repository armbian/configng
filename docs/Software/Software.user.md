# Run/Install 3rd party applications


***

## Desktop Environments


***

### XFCE desktop


***

#### XFCE desktop Install
Install XFCE:
Xfce is a lightweight desktop environment for UNIX-like operating systems. It aims to be fast and low on system resources, while still being visually appealing and user friendly.

**Command:** 
~~~
armbian-config --cmd XFCE01
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Uninstall
**Command:** 
~~~
armbian-config --cmd XFCE02
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Enable autologin
**Command:** 
~~~
armbian-config --cmd XFCE03
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Disable autologin
**Command:** 
~~~
armbian-config --cmd XFCE04
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

### Gnome desktop


***

#### Gnome desktop Install
**Command:** 
~~~
armbian-config --cmd GNOME01
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Uninstall
**Command:** 
~~~
armbian-config --cmd GNOME02
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Enable autologin
**Command:** 
~~~
armbian-config --cmd GNOME03
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Disable autologin
**Command:** 
~~~
armbian-config --cmd GNOME04
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

### Cinnamon desktop


***

#### Cinnamon desktop Install

<!--- section image START from tools/include/images/CINNAMON01.png --->
[![Cinnamon desktop Install](/images/CINNAMON01.png)](#)
<!--- section image STOP from tools/include/images/CINNAMON01.png --->

**Command:** 
~~~
armbian-config --cmd CINNAMON01
~~~

**Author:** @igorpecovnik

**Status:** Stable


<!--- footer START from tools/include/markdown/CINNAMON01-footer.md --->
Cinnamon is a Linux desktop that provides advanced innovative features and a traditional user experience.The desktop layout is similar to Gnome 2 with underlying technology forked from Gnome Shell. Cinnamon makes users feel at home with an easy-to-use and comfortable desktop experience.
<!--- footer STOP from tools/include/markdown/CINNAMON01-header.md --->



***

#### Cinnamon desktop uninstall
**Command:** 
~~~
armbian-config --cmd CINNAMON02
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Enable autologin
**Command:** 
~~~
armbian-config --cmd CINNAMON03
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

#### Disable autologin
**Command:** 
~~~
armbian-config --cmd CINNAMON04
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

### Improve application search speed
**Command:** 
~~~
armbian-config --cmd Xapian
~~~

**Author:** @igorpecovnik

**Status:** Stable



***

## Network tools


***

### Install realtime console network usage monitor (nload)
**Command:** 
~~~
armbian-config --cmd NET001
~~~

**Author:** @armbian

**Status:** Stable



***

### Remove realtime console network usage monitor (nload)
**Command:** 
~~~
armbian-config --cmd NET002
~~~

**Author:** @armbian

**Status:** Stable



***

### Install bandwidth measuring tool (iperf3)
**Command:** 
~~~
armbian-config --cmd NET003
~~~

**Author:** @armbian

**Status:** Stable



***

### Remove bandwidth measuring tool (iperf3)
**Command:** 
~~~
armbian-config --cmd NET004
~~~

**Author:** @armbian

**Status:** Stable



***

### Install IP LAN monitor (iptraf-ng)
**Command:** 
~~~
armbian-config --cmd NET005
~~~

**Author:** @armbian

**Status:** Stable



***

### Remove IP LAN monitor (iptraf-ng)
**Command:** 
~~~
armbian-config --cmd NET006
~~~

**Author:** @armbian

**Status:** Stable



***

### Install hostname broadcast via mDNS (avahi-daemon)
**Command:** 
~~~
armbian-config --cmd NET007
~~~

**Author:** @armbian

**Status:** Stable



***

### Remove hostname broadcast via mDNS (avahi-daemon)
**Command:** 
~~~
armbian-config --cmd NET008
~~~

**Author:** @armbian

**Status:** Stable



***

## Development


***

### Install tools for cloning and managing repositories (git)
**Command:** 
~~~
armbian-config --cmd DEV001
~~~

**Author:** @armbian

**Status:** Stable



***

### Remove tools for cloning and managing repositories (git)
**Command:** 
~~~
armbian-config --cmd DEV001
~~~

**Author:** @armbian

**Status:** Stable



***

## System benchmaking and diagnostics
**Command:** 
~~~
armbian-config --cmd Benchy
~~~

**Author:** @armbian

**Status:** Stable



***

## Containerlization and Virtual Machines


***

### Install Docker Minimal

<!--- section image START from tools/include/images/CON001.webp --->
[![Install Docker Minimal](/images/CON001.webp)](#)
<!--- section image STOP from tools/include/images/CON001.webp --->

This operation will install Docker Minimal.

**Command:** 
~~~
armbian-config --cmd CON001
~~~

**Author:** @schwar3kat

**Status:** Stable


<!--- footer START from tools/include/markdown/CON001-footer.md --->
What is Docker?Accelerate how you build, share, and run applicationsDocker helps developers build, share, run, and verify applications anywhere — without tedious environment configuration or management.
<!--- footer STOP from tools/include/markdown/CON001-header.md --->



***

### Install Docker Engine
This operation will install Docker Engine.

**Command:** 
~~~
armbian-config --cmd CON002
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Remove Docker
This operation will purge Docker.

**Command:** 
~~~
armbian-config --cmd CON003
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Purge all Docker images, containers, and volumes
This operation will delete all Docker images, containers, and volumes.

**Command:** 
~~~
armbian-config --cmd CON004
~~~

**Author:** @schwar3kat

**Status:** Stable



***

## Media Servers and Editors


***

### Install Plex Media server
This operation will install Plex Media server.

**Command:** 
~~~
armbian-config --cmd MED001
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Remove Plex Media server
This operation will purge Plex Media server.

**Command:** 
~~~
armbian-config --cmd MED002
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Install Emby server
This operation will install Emby server.

**Command:** 
~~~
armbian-config --cmd MED003
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Remove Emby server
This operation will purge Emby server.

**Command:** 
~~~
armbian-config --cmd MED004
~~~

**Author:** @schwar3kat

**Status:** Stable



***

## Remote Management tools


***

### Install Cockpit web-based management tool

<!--- section image START from tools/include/images/MAN001.png --->
[![Install Cockpit web-based management tool](/images/MAN001.png)](#)
<!--- section image STOP from tools/include/images/MAN001.png --->

This operation will install Cockpit.
cockpit cockpit-ws cockpit-system cockpit-storaged

**Command:** 
~~~
armbian-config --cmd MAN001
~~~

**Author:** @schwar3kat

**Status:** Stable


<!--- footer START from tools/include/markdown/MAN001-footer.md --->
Introducing CockpitCockpit is a web-based graphical interface for servers, intended for everyone, especially those who are:- new to Linux(including Windows admins)- familiar with Linuxand want an easy, graphical way to administer servers- expert adminswho mainly use other tools but want an overview on individual systemsThanks to Cockpit intentionally using system APIs and commands, a whole team of admins can manage a system in the way they prefer, including the command line and utilities right alongside Cockpit.
<!--- footer STOP from tools/include/markdown/MAN001-header.md --->



***

### Purge Cockpit web-based management tool
This operation will purge Cockpit.

**Command:** 
~~~
armbian-config --cmd MAN002
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Start Cockpit Service
**Command:** 
~~~
armbian-config --cmd MAN003
~~~

**Author:** @schwar3kat

**Status:** Stable



***

### Stop Cockpit Service
**Command:** 
~~~
armbian-config --cmd MAN004
~~~

**Author:** @schwar3kat

**Status:** Stable



***

