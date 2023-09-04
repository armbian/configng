---
title: CONFIGNG
section: 1
header: User Manual
footer: configng 1.0.0
date: September 04, 2023

version: 1.0.0
---

## NAME

config - A command line tool for system configuration

## DESCRIPTION

The `config` command is a command line tool for system configuration. It provides a range of options for configuring various aspects of the system, including wireless, IO, installation, benchmarking, CPU core, and block device settings.

# SYNOPSIS

`configng [options]`

## OPTIONS
- `-h` Show the help message.

- `-l` Show a list of avalible group options.

- `-r` Run a function group.

- `Group` The name of the function group to run.

- `option` The option to run within the specified function group.

  - `wireless [options]`
    - `set_wifi_nmtui` Enable or Disable wifi text user interface.
    - `set_wpa_connect` Enable or Disable wifi command line.

  - `iolocal [options]`
    - `set_lirc` Enable or Disable Infrared Remote Control support.
    - `see_sysled_opt` See a list of board led options.
    - `set_sysled` See a list of board led options.

  - `install [options]`
    - `see_desktops` Display a list of avalible desktops to install.

  - `benchymark [options]`
    - `see_boot_times` armbian monitor help message and tools.
    - `perform_task` system boot-up performance statistics.

  - `cpucore [options]`
    - `see_policy` Return policy as int based on original armbian-config logic.
    - `see_freqs` Return CPU frequencies as string delimited by space.
    - `see_min_freq` Return CPU minimum frequency as string.
    - `see_max_freq` Return CPU maximum frequency as string.
    - `see_governor` Return CPU governor as string.
    - `see_governors` Return CPU governors as string delimited by space.
    - `set_freq` Set min, max and CPU governor.

  - `blockdevice [options]`
    - `set_vflash` Set up a simulated MTD spi flash for testing.
    - `rem_vflash` Remove tsting simulated MTD spi flash.

## EXAMPLES

To see a list of available desktops to install:

```
config install see_desktops
```

To enable Infrared Remote Control support:

```
config iolocal set_lirc
```

To see a list of board led options:

```
config iolocal see_sysled_opt
```

To set the minimum and maximum CPU frequencies and governor:

```
config cpucore set_freq
```

# OPTIONS

`-h` ,Displays help message

`-v` ,Display version info



# EXAMPLES

Here are some examples of how to use the configng command:

`configng -h`

`configng -v`

# ENVIRONMENT

Lists any environment variables that affect the behavior of the command.

# SEE ALSO

Other relevant commands and resources.

# BUGS

Report bugs to <"https://github.com/Tearran/configng/issues">.

# AUTHOR

 Tearran tearran@*hidden*

 Someone noreplay@*hidden*
