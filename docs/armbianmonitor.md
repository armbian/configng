---
    title: ARMBIANMONITOR
    section: 1
    header: User Manual
    footer: armbianmonitor
    author:
    date: August 31, 2023
---

# NAME
armbianmonitor - A script for monitoring and configuring Armbian behavior

# SYNOPSIS
`#!/bin/bash`

# DESCRIPTION
This script serves different purposes based on how it is called:

- Toggle boot verbosity (works)
- Monitoring mode: continually print monitoring info (WiP)
- Uploading /var/log/armbian-hardware-monitor.log to online pastebin service

Without arguments called it should present a simple user interface that guides through:

- Installation of RPi-Monitor if not already installed by user
- Active basic or more verbose monitoring mode
- Provides monitoring parameters for connected disks

The second part is WiP and all the user interaction part still completely missing.

# CONFIGURATION
This script is used to configure armbianmonitor behaviour. It will ask the user whether to activate monitoring or not, whether to enable debug monitoring and also how to deal with connected disks. In fact it walks through the list of available disks, checks them, tries to patch hddtemp.db if necessary and provides a proposal for /etc/armbianmonitor/disks.conf when a new disk is found.

In case monitoring should be activated the following file will be created: /etc/armbianmonitor/start-monitoring. If debug output has been chosen, then DEBUG will be written to the file.

The script will install smartmontools/gdisk if not already installed and patches smartmontools' update-smart-drivedb script if necessary. For disks the 'device model' will be shown but internally we rely always on the GUID. This is the key for entry in /etc/armbianmonitor/disks.conf

When the script exits and the user activated monitoring it recommends doing a restart since on the next reboot the setup-armbian-monitoring-environment script will configure monitoring sources and decides based on the existence and contents of /etc/armbianmonitor/start-monitoring whether rpimonitord should be started or not.

# DISK CONFIGURATION FORMAT
The format of /etc/armbianmonitor/disks.conf is as follows:

${GUID}:${Name}:${smartctl prefix}:${temp call}:${CRC}:${LCC}

Two examples:

A57BF307-7D82-4783-BD1D-B346CA8C195B:WD Green::199:193 # WD HDD on SATA
F8D372DC-63DB-494B-B802-87DC47FAD4E1:Samsung EVO:sat::199: # SSD in USB enclosure

# OPTIONS
The script accepts several options:
```
  -c \$path   Performs disk health/performance tests
  -d          Monitors writes to \$device
  -D          Tries to upload debug disk info to improve armbianmonitor
  -m          Provides simple CLI monitoring - scrolling output
  -M          Provides simple CLI monitoring - fixed-line output
  -n          Provides simple CLI network monitoring - scrolling output
  -N          Provides simple CLI network monitoring - fixed-line output
  -p          Tries to install cpuminer for performance measurements
  -r          Tries to install RPi-Monitor
  -u          Tries to upload armbian-hardware-monitor.log for support purposes
  -v          Tries to verify installed package integrity
  -z          Runs a quick 7-zip benchmark to estimate CPU performance
```
# TODO
Develop main functionality ;) asking the user regarding monitoring, deal with 'SMART overall-health self-assessment test result:', write documentation.

