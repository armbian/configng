---
title: CONFIG
section: 1
header: User Manual
footer: config 1.0.0
date: September 04, 2023
version: 1.0.0
---
# NAME
config - Configuration management script

# SYNOPSIS
config [OPTIONS] [GROUP] [OPTION]

# DESCRIPTION
This script is a configuration management tool.
It provides various functions grouped by categories to manage configurations.

# OPTIONS
Usage: config [options]
  Options:
    -h,    Print this help.

    -l,    List available function groups.

    -r,    Run a function group.

    -m,    View the Manual page.

# LIBRARIES
## wirerless


**set_wifi_nmtui**

    Enable or Disable wifi text user interface


**set_wpa_connect**

    Enable or Disable wifi command line. 

## cpucore


**see_policy**

    Return policy as int based on original armbian-config logic.


**see_freqs**

    Return CPU frequencies as string delimited by space.


**see_min_freq**

    Return CPU minimum frequency as string.


**see_max_freq**

    Return CPU maximum frequency as string.


**see_governor**

    Return CPU governor as string.


**see_governors**

    Return CPU governors as string delimited by space.


**set_freq**

    Set min, max and CPU governor.

## server


**set_lighthttpd**

    Sets up the lighttpd web server to serve CGI scripts. 

## install


**see_desktops**

    Display a list of avalible desktops to install.

## iolocal


**set_lirc**

    Enable or Disable Infrared Remote Control support.


**see_sysled**

    See a list of board led options.

## benchymark


**see_monitor**

    armbian monitor help message and tools.


**see_boot_times**

    system boot-up performance statistics.

## blockdevice


**set_vflash**

    Set up a simulated MTD spi flash for testing.


**rem_vflash**

    Remove tsting simulated MTD spi flash.

