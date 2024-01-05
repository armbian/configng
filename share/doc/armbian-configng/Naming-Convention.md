# Naming Convention

## deb packages
```bash 
armbian-release-category-name - A simple description with tag such as (metapackage) (dev) (contrib)
A very long and detailed description in this line a really long description can go here really really long. 
```

## User Levels

- Basic: For basic users, who are non-admins and only have access to userland
   - The conventions should be simple and straightforward. 
   - These users may not have a deep understanding of the system, so 
   - Defaults options should established and be easy to understand and use.
- Intermediate: For intermediate users, who are system admins or sudo users, 
   - The conventions can be more complex. 
   - These users have a deeper understanding or willingness to learn the system and may need more advanced options. 
   - Using the limitations of whiptail vs dialog can help define the conventions for this level and remaining compatible with dialog
- Advanced: For advanced users, who have access to all options and configurations, 
    - These users are expected to have a deep understanding of the system and its tools, 
    - Basic knowledge of help messages and documentation should be assumed for these users.
    - Help conventions will offer more complex options and configurations. 

## Categories
- System: 
    - configuring system-wide settings such as hostname, password, and time zone

- Network: 
    - Managing network connections and settings

- Display: 
    - Configuring display settings such as resolution and overscan

- Interfaces: 
   - Enabling or disabling hardware interfaces such as camera, SSH, and SPI

- Performance: 
   - Configuring performance-related settings such as overclocking and memory split

- Localization: for 
   - Configuring language, keyboard, and regional settings


## File Naming
### category_does_menuname.
* advance_install_desktops.sh
* advance_install_system.sh
* systems_config_boardled.sh
* network_config_wirerless.sh
* utiilty_config_storage.sh
* utility_test_benchmark.sh


## Function Naming

### Admin sudo user
**System administration, configuration, and security**
- `see_`: used for retrieving or viewing values  `apt-cashe grep something` `ls -h`  `cat file.txt`  `lsblk`
- `set_`: used for setting or updating values  `echo "somevalue" > somefile.txt`
- `get_`: used for getting downloads or updates `apt-get install something` 
- `rem_`: used for removing or uninstalling something `apt-get purge something`
### Non Admin non sudo
**user space, end-user Customization**
- `run_`: used for running apps in the user space `/usr/bin/chromium --kiosk https://forum.armbian.com/ https://github.com/armbian/configng &`
- `mod_`: used for modifying or getting something in user space `git clone` `wget` 

## Help message format
### Existing Example
- `ls --help`  Shows advanced flag options
- `p7zip -h`   Shows simple flag options
- `git --help` Shows advanced non flag options

```bash 

Usage: armbina-monitor [options] [ path | device ]

Options:
  -c [path]          Performs disk health/performance tests
  -d [device]        Monitors writes to $device
  -D                 Tries to upload debug disk info to improve armbianmonitor
  -m                 Provides simple CLI monitoring - scrolling output
  -M                 Provides simple CLI monitoring - fixed-line output
  -n                 Provides simple CLI network monitoring - scrolling output
  -N                 Provides simple CLI network monitoring - fixed-line output
  -p                 Tries to install cpuminer for performance measurements
  -r                 Tries to install RPi-Monitor
  -u                 Tries to upload armbian-hardware-monitor.log for support purposes
  -v                 Tries to verify installed package integrity
  -z                 Runs a quick 7-zip benchmark to estimate CPU performance
```



