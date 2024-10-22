- [Network tools](#netconfig)
  - [Install realtime console network usage monitor (nload)](#sw08)
  - [Remove realtime console network usage monitor (nload)](#sw09)
  - [Install bandwidth measuring tool (iperf3)](#sw10)
  - [Remove bandwidth measuring tool (iperf3)](#sw11)
  - [Install IP LAN monitor (iptraf-ng)](#sw12)
  - [Remove IP LAN monitor (iptraf-ng)](#sw13)
  - [Install hostname broadcast via mDNS (avahi-daemon)](#sw14)
  - [Remove hostname broadcast via mDNS (avahi-daemon)](#sw15)

# Netconfig

**description:** Network tools


## SW08

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

## SW09

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

## SW10

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

## SW11

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

## SW12

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

## SW13

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

## SW14

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

## SW15

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

