# configng
[![CodeFactor](https://www.codefactor.io/repository/github/tearran/configng/badge)](https://www.codefactor.io/repository/github/tearran/configng)
![Shields.io](https://img.shields.io/github/issues/Tearran/configng)
![Shields.io](https://img.shields.io/github/forks/Tearran/configng)
![Shields.io](https://img.shields.io/github/license/Tearran/configng)

---
See [[Wiki]](https://github.com/Tearran/configng/wiki) for more info.

## Quick start
### install prebuild
```bash
{
wget wget https://github.com/Tearran/configng/releases/download/v0.1-alpha/armbian-bookworm-utils-config.0.1.deb ;
sudo dpkg -i armbian-bookworm-utils-config.0.1.deb
}
```
### Build source.
```bash
{
  # install Git if needed
  [[ -z $(which git) ]] && sudo apt update && sudo apt install git ;
  # Clone repo to ~/.loclal/src/
  git clone https://github.com/Tearran/configng.git ~/.local/src/armbian-utilties ;
  # build a deb package
  cd ~/.local/src/armbian-utilties
  ~/.local/src/armbian-utilties/build.contrib.sh
  ls "/home/beta/.local/src/armbian-utilties/debs"  
}
```

---
## Quick use 
 see list of avalible desptops that can be install via apt
```bash
config -r install see_desktops
```
see help list

$`config -h` 
```bash
Usage: config [options]
  Options:
    -h,    Print this help.

    -l,    List available function groups.

    -r,    Run a function group.
```

see list of avalible options

$`config -l`
```bash
Usage: config [ -r  [group] [option] ]

wirerless [options]
        set_wifi_nmtui  Enable or Disable wifi text user interface
        set_wpa_connect Enable or Disable wifi command line.

iolocal [options]
        set_lirc        Enable or Disable Infrared Remote Control support.
        see_sysled      See a list of board led options.

install [options]
        see_desktops    Display a list of avalible desktops to install.

benchymark [options]
        see_monitor     armbian monitor help message and tools.
        see_boot_times  system boot-up performance statistics.

cpucore [options]
        see_policy      Return policy as int based on original armbian-config logic.
        see_freqs       Return CPU frequencies as string delimited by space.
        see_min_freq    Return CPU minimum frequency as string.
        see_max_freq    Return CPU maximum frequency as string.
        see_governor    Return CPU governor as string.
        see_governors   Return CPU governors as string delimited by space.
        set_freq        Set min, max and CPU governor.

blockdevice [options]
        set_vflash      Set up a simulated MTD spi flash for testing.
        rem_vflash      Remove tsting simulated MTD spi flash.
```

---
<!--
This is a refactoring of [armbian-config](https://github.com/armbian/config) using [Bash Utility](https://labbots.github.io/bash-utility) 
embedded in this project. This allows for functional programming in Bash. Error handling and validation are also included. 
The idea is to provide an API in Bash that can be called from a Command line interface, Text User interface and others.
Why Bash? Well, because it's going to be in every distribution. Striped down distributions 
may not include Python, C/C++, etc. build/runtime environments 



## Coding standards
[Shell Style Guide](https://google.github.io/styleguide/shellguide.html) has some good ideas, 
but fundementally look at the code in lib:
```
# @description Strip characters from the beginning of a string.
#
# @example
#   echo "$(string::lstrip "Hello World!" "He")"
#   #Output
#   llo World!
#
# @arg $1 string The input string.
# @arg $2 string The characters you want to strip.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
#
# @stdout Returns the modified string.
string::lstrip() {
[[ $# -lt 2 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
printf '%s\n' "${1##$2}"
}
```

Functions should follow ~~filename~~::func_name style. Then you can tell just from the name which 
file the function is located in. Return codes should also follow a similar pattern:
* 0 Successful
* 1 Not found
* 2 Function missing arguments
* 3-255 all other errors

Validate values:
```
# Validate minimum frequency is <= maximum frequency
[ "$min_freq" -gt "$max_freq" ] && printf "%s: Minimum frequency must be <= maximum frequency\n" "${FUNCNAME[0]}" && return 5
```

Return values should use stdout:

```
# Return value
printf '%s\n' "$(cat $file)"
```

Only use sudo when needed and never run as root!

-->
