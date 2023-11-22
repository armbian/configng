# Armbian ConfigNG 
Refactor of [armbian-config](https://github.com/armbian/config)       
## relaease 
2021-09-01
# User guide
## Quick start
Run the following commands:
~~~
sudo apt install git
cd ~/
git clone https://github.com/armbian/configng.git
bash ~/configng/bin/armbian-configng -h
~~~  
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
## legacy
System Custume configurations.

### config_legacy.sh

 - **Group Name:** legacy
 - **Action Name:** armbian_config
 - **Options:** none
 - **Description:** Armbian config Legacy

## network
Legacy applications for Armbian.

### set_wifi.sh

 - **Group Name:** network
 - **Action Name:** nmtui
 - **Options:** none.
 - **Description:** Set a local net test.

## other
Setup the Network settings.

### setup_desktop.sh

 - **Group Name:** desktop
 - **Action Name:** configure
 - **Options:** none.
 - **Description:** Hello World.

## software
Catch all for misc.

### setup_desktop.sh

 - **Group Name:** desktop
 - **Action Name:** configure
 - **Options:** none
 - **Description:** Configure armbian desktop.

## system
Setup Custume/Community software.

### see_monitor.sh

 - **Group Name:** monitor
 - **Action Name:** Bencharking
 - **Options:** 
 - **Description:** Armbian Monitor and Bencharking.


# Inclueded projects
[Bash Utility (https://labbots.github.io/bash-utility) 

 This allows for functional programming in Bash. Error handling and validation are also included.
The idea is to provide an API in Bash that can be called from a Command line interface, Text User interface and others.

 Why Bash? Well, because it's going to be in every distribution. Striped down distributions
may not include Python, C/C++, etc. build/runtime environments )

