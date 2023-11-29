# Armbian ConfigNG 
Refactor of [armbian-config](https://github.com/armbian/config)       
## relaease 
2021-09-01
# User guide
## Quick start
Run the following commands:

    sudo apt install git
    cd ~/
    git clone https://github.com/armbian/configng.git
    bash ~/configng/bin/armbian-configng -h

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
 - Markdown
 - JSON
 - Text User Interface
 - Command Line Interface
 - Help message
 - launch a feature

## Up to date list of functions 
## Locale


### hello_world.sh

 - **Group Name:** locale
 - **Action Name:** Hello
 - **Options:** none.
 - **Description:** Hello World.

## Misc
Personal, Timezone, language, hostname"

### setup_dev_chroot.sh

 - **Group Name:** chroot
 - **Action Name:** setup
 - **Options:** none.
 - **Description:** WIP: Setup a non destructive Test enviroment.

### setup_softinks.sh

 - **Group Name:** setup
 - **Action Name:** Branding
 - **Options:** none
 - **Description:** Banding With Softlinks .

## Network
Catch all for miscellaneous scripts

### set_wifi.sh

 - **Group Name:** network
 - **Action Name:** nmtui
 - **Options:** none
 - **Description:** Set a local net test.

## Software
Network Wired wireless Bluetooth access point

### see_monitor.sh

 - **Group Name:** monitor
 - **Action Name:** Bencharking
 - **Options:** none.
 - **Description:** Armbian Monitor and Bencharking.

## System
Software  System and 3rd party software install

### hello_world.sh

 - **Group Name:** system
 - **Action Name:** Hello
 - **Options:** 
 - **Description:** Hello System.


# Inclueded projects
[Bash Utility (https://labbots.github.io/bash-utility) 

 This allows for functional programming in Bash. Error handling and validation are also included.
The idea is to provide an API in Bash that can be called from a Command line interface, Text User interface and others.

 Why Bash? Well, because it's going to be in every distribution. Striped down distributions
may not include Python, C/C++, etc. build/runtime environments )

