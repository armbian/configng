# Naming Convention

## Categories
1. Network  - Ethernet Wireless Bluetooth Access Point    
2. Locales  - Locale Language Region Time Keyboard      
3. System   - System and Security                        
4. SoftWare - Third-party applications                 

# Function Naming Convention

This project uses the following naming convention for functions:
## Admin sudo user
### main function groups system and security
- `see_`: used for retrieving or viewing values  `apt-cashe grep something` `ls -h`  `cat file.txt`  `lsblk`
- `set_`: used for setting or updating values  `echo "somevalue" > somefile.txt`
- `get_`: used for getting downloads or updates `apt-get install something` 
- `rem_`: used for removing or uninstalling something `apt-get purge something`
## Non Admin non sudo
### user space, end-user Customization
- `run_`: used for running apps in the user space `/usr/bin/chromium --kiosk https://forum.armbian.com/ https://github.com/armbian/configng &`
- `mod_`: used for modifying or getting something in user space `git clone` `wget` 

Please use these prefixes consistently when naming functions in this project.

# Help message format
## Existing Example
- `ls --help`  Shows advanced flag options
- `p7zip -h`   Shows simple flag options
- `git --help` Shows advanced non flag options

## Base Example.
potentially build to any of the with previous
```bash

```


