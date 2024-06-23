
## CLI options
Command ine options.

Use:

    armbian-config --help

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
deprecated

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
