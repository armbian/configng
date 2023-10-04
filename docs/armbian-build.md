---
title: ARMBIAN-BUILD
section: 1
header: User Manual
footer: armbian-build 0.0.0
date: October 04, 2023
version: 0.0.0
---

# NAME

ARMBIAN-BUILD - A command-line tool

# DESCRIPTION

The `armbian-build` command is a command-line tool for A command-line tool. It provides a range of options for configuring various aspects of the system.

# SYNOPSIS

`armbian-build [OPTIONS] [CATEGORY] [FUNCTION]`

`armbian-build` is the script name.

[OPTIONS] are the available options.

[CATEGORY] is the group/category.

[FUNCTION] is the function within the specified group.

# OPTIONS
  -h, --help
    Display a help message and exit.
  -l, --list
    Expose all groups and functions.
  -r [CATEGORY] [FUNCTION]
    Run the specified function within the specified group.

## Groups
  wireless [options]
    set_wifi_nmtui  Enable or Disable the WiFi text user interface.
    set_wpa_connect Enable or Disable WiFi command line.

  benchmark [options]
    see_monitor     Armbian monitor help message and tools.
    see_boot_times  System boot-up performance statistics.

# EXAMPLES
1. Display the help message:
   `armbian-build -h`

2. Expose all groups and functions:
   `armbian-build -l`

3. Run the 'set_wifi_nmtui' function within the 'wireless' group:
   `armbian-build -r wireless set_wifi_nmtui`

4. Display system boot-up performance statistics:
   `armbian-build -r benchmark see_boot_times`

# ENVIRONMENT

Lists any environment variables that affect the behavior of the command.

# SEE ALSO

Other relevant commands and resources.

# BUGS

Report bugs to <https://github.com/Tearran/configng/issues>.

# AUTHORS

  Tearran tearran@*hidden*
  Someone noreply@*hidden*

