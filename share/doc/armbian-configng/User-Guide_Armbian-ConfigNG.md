
# Armbian configuration utility
Utility for configuring your board, divided into four main sections:

- System - system and security settings,
- Network - wired, wireless, Bluetooth, access point,
- Personal - timezone, language, hostname,
- Software - system and 3rd party software install.


- ## **System** 
  - **S01** - Description: Enable Armbina kernal upgrades
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#s01)
  - **S02** - Description: Disable Armbina kernal upgrades
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#s02)
  - **S03** - Description: Edit the boot enviroment (WIP)
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#s03)
  - **S04** - Description: Install Linux headers
    - Status: [Pending Review](https://github.com/armbian/config/wiki#System)
  - **S05** - Description: Remove Linux headers
    - Status: [Pending Review](https://github.com/armbian/config/wiki#System)


- ## **Network** 
  - **BT0** - Description: Install Bluetooth support
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#bt0)
  - **BT1** - Description: Remove Bluetooth support
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#bt1)
  - **BT3** - Description: Bluetooth Discover
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#bt3)
  - **IR0** - Description: Install Infrared support
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#ir0)
  - **IR1** - Description: Uninstall Infrared support
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#ir1)
  - **N00** - Description: Manage wifi network connections
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#n00)
  - **N01** - Description: Advanced Edit /etc/network/interface
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#n01)
  - **N02** - Description: Disconect and forget all wifi connections (Advanced)
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#n02)
  - **N03** - Description: Toggle system IPv6/IPv4 internet protical
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#n03)
  - **N04** - Description: (WIP) Setup Hotspot/Access point
    - Status: [WIP](https://github.com/armbian/configng/wiki/Menu#n04)


- ## **Localisation** 
  - **L00** - Description: Change Globla timezone (WIP)
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#l00)
  - **L01** - Description: Change Locales reconfigure the language and charitorset
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#l01)
  - **L02** - Description: Change Keyboard layout
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#l02)
  - **L03** - Description: Change APT mirrors
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#l03)


- ## **Software** 
  - **I00** - Description: Update Application Repository
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#i00)
  - **I01** - Description: CLI System Monitor
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#i01)


- ## **Help** 
  - **H00** - Description: About This systme. (WIP)
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#h00)
  - **H02** - Description: List of Config function(WIP)
    - Status: [Active](https://github.com/armbian/configng/wiki/Menu#h02)


***

## Development

To clone this development branch, run the following commands:

~~~
    git clone https://github.com/armbian/configng
    cd configng
    ./armbian-configng --help
~~~

## Install latest release
dowload .deb package: 

~~~
{
    latest_release=$(curl -s https://api.github.com/repos/armbian/configng/releases/latest)
    deb_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
    curl -LO "$deb_url"
    deb_file=$(echo "$deb_url" | awk -F"/" '{print $NF}')
    sudo dpkg -i "$deb_file"
    sudo dpkg --configure -a
    sudo apt --fix-broken install
}
~~~

***

## CLI options
Command ine options.

Use:
~~~
    armbian-config --help
~~~

Outputs:
~~~
Usage:  armbian-configng [option] [arguments]

    --help      -  Display this help message.
    main=Help   -  Display Legacy Options (Backward Compatible)

    --cli S01  -  Enable Armbina kernal upgrades
    --cli S02  -  Disable Armbina kernal upgrades
    --cli S03  -  Edit the boot enviroment (WIP)
    --cli S04  -  Install Linux headers
    --cli S05  -  Remove Linux headers
    --cli BT0  -  Install Bluetooth support
    --cli BT1  -  Remove Bluetooth support
    --cli BT3  -  Bluetooth Discover
    --cli IR0  -  Install Infrared support
    --cli IR1  -  Uninstall Infrared support
    --cli N00  -  Manage wifi network connections
    --cli N01  -  Advanced Edit /etc/network/interface
    --cli N02  -  Disconect and forget all wifi connections (Advanced)
    --cli N03  -  Toggle system IPv6/IPv4 internet protical
    --cli N04  -  (WIP) Setup Hotspot/Access point
    --cli L00  -  Change Globla timezone (WIP)
    --cli L01  -  Change Locales reconfigure the language and charitorset
    --cli L02  -  Change Keyboard layout
    --cli L03  -  Change APT mirrors
    --cli I00  -  Update Application Repository
    --cli I01  -  CLI System Monitor
~~~

## Legacy options
Backward Compatible options.

Use:

    armbian-config main=Help

Outputs:
~~~
Legacy Options (Backward Compatible)
Please use 'armbian-config --help' for more information.

Usage:  armbian-configng main=[arguments] selection=[options]

    armbian-configng main=System selection=Headers          -  Install headers:                                        
    armbian-configng main=System selection=Headers_remove   -  Remove headers:                                 
~~~



## Note:
>
> The Bash procedures embedded within the JSON structure are meticulously designed with a focus on clear naming conventions and the simplicity of key pairs. These procedures serve multiple purposes, including facilitating the generation of content in various formats, such as Whiptail, Markdown, json out and others. Moreover, they are utilized for evaluation and execution of commands outlined in the JSON structure.
>
