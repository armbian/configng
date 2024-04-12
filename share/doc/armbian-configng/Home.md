
# Armbian configuration utility
Utility for configuring your board, divided into four main sections:

- System - system and security settings,
- Network - wired, wireless, Bluetooth, access point,
- Personal - timezone, language, hostname,
- Software - system and 3rd party software install.



To Configure and change global sytem settings, run the following command: `./armbian-configng`

***
## Screenshots
![edit-boot-env-2024-04-03 10-06-58](https://github.com/armbian/configng/assets/2831630/448f0515-0854-4a8a-8421-53c8b72bb5c5)
![BT-connect-2024-04-03 10-06-58](https://github.com/armbian/configng/assets/2831630/fef037ce-346d-4d70-9025-90f69fbdf5d3)
Following was updated on:
Fri Apr 12 01:33:08 AM MST 2024.

***
- ## **System** 
  - **S01** - Description: Enable Armbina kernal upgrades
    - Status: [WIP](https://github.com/armbian/configng/wiki/Menu#s01)
  - **S02** - Description: Disable Armbina kernal upgrades
    - Status: [WIP](https://github.com/armbian/configng/wiki/Menu#s02)
  - **S03** - Description: Edit the boot enviroment (WIP)
    - Status: [WIP](https://github.com/armbian/configng/wiki/Menu#s03)


- ## **Network** 
  - **BT0** - Description: Install Bluetooth support
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#bt0)
  - **BT1** - Description: Remove Bluetooth support
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#bt1)
  - **BT3** - Description: Bluetooth Discover
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#bt3)
  - **IR0** - Description: Install Infrared support
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#ir0)
  - **IR1** - Description: Uninstall Infrared support
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#ir1)
  - **N00** - Description: Manage wifi network connections
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#n00)
  - **N01** - Description: Advanced Edit /etc/network/interface
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#n01)
  - **N02** - Description: Disconect and forget all wifi connections (Advanced)
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#n02)
  - **N03** - Description: Toggle system IPv6/IPv4 internet protical
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#n03)


- ## **Localisation** 
  - **L00** - Description: Change Globla timezone (WIP)
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#l00)
  - **L01** - Description: Change Locales reconfigure the language and charitorset
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#l01)
  - **L02** - Description: Change Keyboard layout
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#l02)
  - **L03** - Description: Change APT mirrors
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#l03)


- ## **Software** 
  - **I00** - Description: Update Application Repository
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#i00)
  - **I01** - Description: CLI System Monitor
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#i01)


- ## **Help** 
  - **H00** - Description: About This systme. (WIP)
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#h00)
  - **H02** - Description: List of Config function(WIP)
    - Status: [review](https://github.com/armbian/configng/wiki/Menu#h02)


***
## Quick start
Run the following commands:

    echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://armbian.github.io/configng stable main"     | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
    
    armbian-configng --dev

If all goes well you should see the Text-Based User Inerface (TUI)

## Development
Development test brances are available for testing. To clone the development branch, run the following commands:

~~~
git clone https://github.com/armbian/configng.git
cd configng
~~~



## Note:
>
> The Bash procedures embedded within the JSON structure are meticulously designed with a focus on clear naming conventions and the simplicity of key pairs. These procedures serve multiple purposes, including facilitating the generation of content in various formats, such as Whiptail, Markdown, json out and others. Moreover, they are utilized for evaluation and execution of commands outlined in the JSON structure.
>
