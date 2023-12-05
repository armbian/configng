# Armbian ConfigNG 
Refactor of [armbian-config](https://github.com/armbian/config)       
## Updated
2023-12-05
# User guide
## Quick start
Run the following commands:

    sudo apt install git
    cd ~/
    git clone https://github.com/armbian/configng.git
    cd configng
    ./bin/armbian-configng --dev

If all goes well you should see the Text-Based User Inerface (TUI)

### To see a list of all functions and their descriptions, run the following command:
~~~
bash ~/configng/bin/armbian-configng -h
~~~
## Coding Style
follow the following coding style:
~~~
# @description A short description of the function.
#
# @exitcode 0  If successful.
#
# @options A description if there are options.
function group::string() {
    echo "hello world"
    return 0
}
~~~
## Codestyle can be used to auto generate
 - [Markdown](share/armbian-configng/readme.md)
 - [JSON](share/armbian-configng/data/armbian-configng.json)
 - [CSV](share/armbian-configng/data/armbian-configng.csv)
 - [HTML](share/armbian-configng/armbian-configng-table.html)
 - [github.io](//tearran/github.io/armbian-configng/index.html)
## Functions
 - Text User Interface
 - Command Line Interface
 - Help message
 - launch a feature

## Up to date list of functions 
## Network


### set_wifi.sh

 - **Group Name:** network
 - **Action Name:** NMTUI
 - **Options:** none.
 - **Description:** Network Manager.

## System
Network Wired wireless Bluetooth access point

### hello_world.sh

 - **Group Name:** system
 - **Action Name:** Hello
 - **Options:** none
 - **Description:** Hello System.

### see_monitor.sh

 - **Group Name:** monitor
 - **Action Name:** Bencharking
 - **Options:** 
 - **Description:** Armbian Monitor and Bencharking.


# Inclueded projects
- [Bash Utility](https://labbots.github.io/bash-utility) 
- [Armbian config](https://github.com/armbian/config.git)

