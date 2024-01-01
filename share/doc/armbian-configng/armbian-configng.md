
<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
    <br>
    Armbian ConfigNG
    <br>
    <a href="https://www.codefactor.io/repository/github/tearran/configng"><img src="https://www.codefactor.io/repository/github/tearran/configng/badge" alt="CodeFactor" /></a>
</p>

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
function group::string() {s
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
## Functions list as of 2024-01-01
## locales


### set_timezones.sh

 - **Group Name:** locales
 - **Action Name:** Timezone
 - **Options:** user selection
 - **Description:** Time zone configuration

## system
Locale Language Region Time Keyboard

### get_system_clone.sh

 - **Group Name:** testing
 - **Action Name:** Install
 - **Options:** [sdcard] [emmc] [usb]
 - **Description:** Armbian installer

### see_monitor.sh

 - **Group Name:** monitor
 - **Action Name:** Bencharking
 - **Options:** help message
 - **Description:** Monitor and Bencharking.

### set_freeze.sh

 - **Group Name:** testing
 - **Action Name:** Kernel_hold
 - **Options:** [frozen] [unfrozen]
 - **Description:** Kernal U-boot update Hold/Unhold.

### set_wifi.sh

 - **Group Name:** network
 - **Action Name:** NMTUI
 - **Options:** connect
 - **Description:** Network Manager.


# Inclueded projects
- [Bash Utility](https://labbots.github.io/bash-utility)
- [Armbian config](https://github.com/armbian/config.git)

