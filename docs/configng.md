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
Usage: configng [options]
  Options:
    -h,    Print this help.

    -l,    List available function groups.

    -r,    Run a function group.

    -m,    View the Manual page.

# LIBRARIES
## cpu


**get_policy**

    Return policy as int based on original armbian-config logic.


**get_freqs**

    Return CPU frequencies as string delimited by space.


**get_min_freq**

    Return CPU minimum frequency as string.


**get_max_freq**

    Return CPU maximum frequency as string.


**get_governor**

    Return CPU governor as string.


**get_governors**

    Return CPU governors as string delimited by space.


**set_freq**

    Set min, max and CPU governor.

## storage


**set_spi_vflash**

    SetUp Virtula spi MTD FLash, Remove spi MTD FLash.

