
# Armbian Configuration Utility
Utility for configuring your board, adjusting services, and installing applications. 

## Sections
Armbian-configng is divided into four main sections:
- System - system and security settings,
- Network - wired, wireless, Bluetooth, access point,
- Localisation - timezone, language, hostname,
- Software - system and 3rd party software install.

## Install latest release
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

Armbian_config requires root privilege. To start the Armbian configuration utility, use the following sudo "super user do" command:
~~~
sudo armbian-configng
~~~

## list of features
Updated: Thu Aug  8 11:47:36 PM EDT 2024

- ### **System** 
  - **S01** - Enable Armbian kernel upgrades
  - **S02** - Disable Armbian kernel upgrades
  - **S03** - Edit the boot environment
  - **S04** - Install Linux headers
  - **S05** - Remove Linux headers


- ### **Network** 
  - **N00** - Install Bluetooth support
  - **N01** - Remove Bluetooth support
  - **N02** - Bluetooth Discover
  - **N03** - Install Infrared support
  - **N04** - Uninstall Infrared support
  - **N05** - Manage wifi network connections
  - **N06** - Advanced Edit /etc/network/interface
  - **N07** - Disconnect and forget all wifi connections (Advanced)
  - **N08** - Toggle system IPv6/IPv4 internet protocol
  - **N09** - (WIP) Setup Hotspot/Access point
  - **N10** - Announce system in the network (Avahi) 
  - **N11** - Disable system announce in the network (Avahi) 


- ### **Localisation** 
  - **L00** - Change Global timezone (WIP)
  - **L01** - Change Locales reconfigure the language and character set
  - **L02** - Change Keyboard layout
  - **L03** - Change APT mirrors


- ### **Software** 
  - **I00** - Update Application Repository
  - **I01** - CLI System Monitor


- ### **Help** 
  - **H00** - About This system. (WIP)
  - **H02** - List of Config function(WIP)


***

## CLI options
Command line options.

Use:
~~~
armbian-configng --help
~~~

Outputs:
~~~
Usage:  armbian-configng [option] [arguments]

    --help      -  Display this help message.
    main=Help   -  Display Legacy Options (Backward Compatible)

    --cli S01  -  Enable Armbian kernel upgrades
    --cli S02  -  Disable Armbian kernel upgrades
    --cli S03  -  Edit the boot environment
    --cli S04  -  Install Linux headers
    --cli S05  -  Remove Linux headers
    --cli N00  -  Install Bluetooth support
    --cli N01  -  Remove Bluetooth support
    --cli N02  -  Bluetooth Discover
    --cli N03  -  Install Infrared support
    --cli N04  -  Uninstall Infrared support
    --cli N05  -  Manage wifi network connections
    --cli N06  -  Advanced Edit /etc/network/interface
    --cli N07  -  Disconnect and forget all wifi connections (Advanced)
    --cli N08  -  Toggle system IPv6/IPv4 internet protocol
    --cli N09  -  (WIP) Setup Hotspot/Access point
    --cli N10  -  Announce system in the network (Avahi) 
    --cli N11  -  Disable system announce in the network (Avahi) 
    --cli L00  -  Change Global timezone (WIP)
    --cli L01  -  Change Locales reconfigure the language and character set
    --cli L02  -  Change Keyboard layout
    --cli L03  -  Change APT mirrors
    --cli I00  -  Update Application Repository
    --cli I01  -  CLI System Monitor
~~~

## Legacy options
Backward Compatible options.

Use:
~~~
armbian-configng main=Help
~~~

Outputs:
~~~
Legacy Options (Backward Compatible)
Please use 'armbian-configng --help' for more information.

Usage:  armbian-configng main=[arguments] selection=[options]

    armbian-configng main=System selection=Headers          -  Install headers:                                        
    armbian-configng main=System selection=Headers_remove   -  Remove headers:                                 
~~~

***

Sources

https://github.com/armbian/configng

