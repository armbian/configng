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
bash ~/configng/bin/armbian-configng
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
## Network
System Custume configurations.

### set_wifi.sh

 - **Group Name:** network
 - **Action Name:** nmtui
 - **Options:** none.
 - **Description:** Set a local net test.

## Others
Setup the Network settings.

### hello_world.sh

 - **Group Name:** world
 - **Action Name:** Hello
 - **Options:** none.
 - **Description:** Hello World.

## Software
Catch all for misc.

### setup_desktop.sh

 - **Group Name:** desktop
 - **Action Name:** configure
 - **Options:** none
 - **Description:** Configure armbian desktop.

## System
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

