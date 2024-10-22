- [Fixed and wireless network settings](#network)
  - [Configure network interfaces](#n01)
    - [Add / change interface](#n02)
    - [Revert to Armbian defaults](#n03)
    - [Show configuration](#n04)
    - [Show active status](#n06)
  - [Install Bluetooth support](#n15)
  - [Remove Bluetooth support](#n16)
  - [Bluetooth Discover](#n17)
  - [Toggle system IPv6/IPv4 internet protocol](#n18)

# Network

**description:** Fixed and wireless network settings


## N01

**description:** Configure network interfaces


### N02

**description:** Add / change interface

**Command:** 
~~~
network_config armbian
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~

~~~

### N03

**description:** Revert to Armbian defaults

**Command:** 
~~~
default_network_config
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~

~~~

### N04

**description:** Show configuration

**Command:** 
~~~
show_message <<< "$(netplan get all)"
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
[[ -f /etc/netplan/armbian.yaml ]]
~~~

### N06

**description:** Show active status

**Command:** 
~~~
show_message <<< "$(netplan status --all)"
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
[ -f /etc/netplan/armbian.yaml ] && [ netplan status 2>/dev/null ]
~~~

## N15

**description:** Install Bluetooth support

**Command:** 
~~~
see_current_apt , debconf-apt-progress -- apt-get -y install bluetooth bluez bluez-tools, check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y --no-install-recommends install pulseaudio-module-bluetooth blueman
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed bluetooth && ! check_if_installed bluez && ! check_if_installed bluez-tools
~~~

## N16

**description:** Remove Bluetooth support

**Command:** 
~~~
see_current_apt , debconf-apt-progress -- apt-get -y remove bluetooth bluez bluez-tools, check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y remove pulseaudio-module-bluetooth blueman, debconf-apt-progress -- apt -y -qq autoremove
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed bluetooth || check_if_installed bluez || check_if_installed bluez-tools
~~~

## N17

**description:** Bluetooth Discover

**prompt:** 
This will enable bluetooth and discover devices

Would you like to continue?

**Command:** 
~~~
connect_bt_interface
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed bluetooth || check_if_installed bluez || check_if_installed bluez-tools
~~~

## N18

**description:** Toggle system IPv6/IPv4 internet protocol

**prompt:** 
This will toggle your internet protocol
Would you like to continue?

**Command:** 
~~~
toggle_ipv6 | show_infobox
~~~

**Author:** 

**Status:** Preview


