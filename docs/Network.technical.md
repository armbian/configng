- [Network](#network): Fixed and wireless network settings
  - [N01](#n01): Configure network interfaces
    - [N02](#n02): Add / change interface
    - [N03](#n03): Revert to Armbian defaults
    - [N04](#n04): Show configuration
    - [N06](#n06): Show active status
  - [N15](#n15): Install Bluetooth support
  - [N16](#n16): Remove Bluetooth support
  - [N17](#n17): Bluetooth Discover
  - [N18](#n18): Toggle system IPv6/IPv4 internet protocol

# Network

**Description:** Fixed and wireless network settings


## N01

**Description:** Configure network interfaces


### N02

**Description:** Add / change interface

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

**Description:** Revert to Armbian defaults

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

**Description:** Show configuration

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

**Description:** Show active status

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

**Description:** Install Bluetooth support

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

**Description:** Remove Bluetooth support

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

**Description:** Bluetooth Discover

**Prompt:** 
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

**Description:** Toggle system IPv6/IPv4 internet protocol

**Prompt:** 
This will toggle your internet protocol
Would you like to continue?

**Command:** 
~~~
toggle_ipv6 | show_infobox
~~~

**Author:** 

**Status:** Preview


