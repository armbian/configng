#!/bin/bash
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  CPU related functions. See https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt for more info.
#

# @description Return policy as int based on original armbian-config logic.
#
# @example
#   cpu::get_policy
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout Policy as integer.
cpu::get_policy(){
	declare -i policy=0
	[[ $(grep -c '^processor' /proc/cpuinfo) -gt 4 ]] && policy=4
	[[ ! -d /sys/devices/system/cpu/cpufreq/policy4 ]] && policy=0
	[[ -d /sys/devices/system/cpu/cpufreq/policy0 && -d /sys/devices/system/cpu/cpufreq/policy2 ]] && policy=2
	printf '%d\n' "$policy"
}

# @description Return CPU frequencies as string delimited by space.
#
# @example
#   cpu::get_freqs 0
#   echo $?
#   #Output
#   648000 816000 912000 960000 1008000 1056000 1104000 1152000
#
# @arg $1 int policy.
#
# @exitcode 0  If successful.
# @exitcode 1  If file not found.
# @exitcode 2 Function missing arguments.
#
# @stdout Space delimited string of CPU frequencies.
cpu::get_freqs(){
	# Check number of arguments
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/sys/devices/system/cpu/cpufreq/policy$1/scaling_available_frequencies"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	# Return value
	printf '%s\n' "$(cat $file)"
}

# @description Return CPU minimum frequency as string.
#
# @example
#   cpu::get_min_freq 0
#   echo $?
#   #Output
#   648000
#
# @arg $1 int policy.
#
# @exitcode 0  If successful.
# @exitcode 1  If file not found.
# @exitcode 2 Function missing arguments.
#
# @stdout CPU minimum frequency as string.
cpu::get_min_freq(){
	# Check number of arguments
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/sys/devices/system/cpu/cpufreq/policy$1/scaling_min_freq"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	# Return value
	printf '%s\n' "$(cat $file)"
}

# @description Return CPU maximum frequency as string.
#
# @example
#   cpu::get_max_freq 0
#   echo $?
#   #Output
#   1152000
#
# @arg $1 int policy.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
#
# @stdout CPU maximum frequency as string.
cpu::get_max_freq(){
	# Check number of arguments
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/sys/devices/system/cpu/cpufreq/policy$1/scaling_max_freq"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	# Return value
	printf '%s\n' "$(cat $file)"
}

# @description Return CPU governor as string.
#
# @example
#   cpu::get_governor 0
#   echo $?
#   #Output
#   performance
#
# @arg $1 int policy.
cpu::get_governor(){
	# Check number of arguments
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/sys/devices/system/cpu/cpufreq/policy$1/scaling_governor"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	# Return value
	printf '%s\n' "$(cat $file)"
}

# @description Return CPU governors as string delimited by space.
#
# @example
#   cpu::get_governors 0
#   echo $?
#   #Output
#   performance
#
# @arg $1 int policy.
cpu::get_governors(){
	# Check number of arguments
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/sys/devices/system/cpu/cpufreq/policy$1/scaling_available_governors"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	# Return value
	printf '%s\n' "$(cat $file)"
}

# @description Set min, max and CPU governor.
#
# @example
#   cpu::set_freq 0 648000 1152000 performance
#   echo $?
#   #Output
#   performance
#
# @arg $1 int Policy.
# @arg $2 int Minimum frequency.
# @arg $3 int Maximum frequency.
# @arg $4 string Governor.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
# @exitcode 3 Invalid minimum frequency.
# @exitcode 4 Invalid maximum frequency.
# @exitcode 5 Minimum frequency must be <= maximum frequency.
# @exitcode 6 Invalid governor.
cpu::set_freq(){
	# Check number of arguments
    [[ $# -lt 4 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
	# Build file based on policy value
	local file="/etc/default/cpufrequtils"
	# Check if file exists
	[ ! -f "$file" ] && printf '%s\n' "$file not found" && return 1
	declare -i  policy=$1
	declare -i  min_freq=$2
	declare -i  max_freq=$3
	local  governor=$4
	# Return frequencies as array
	declare -a freqs=( $(string::split "$(cpu::get_freqs $policy)" " ") )
	# Validate minimum frequency
	array::contains "$min_freq" ${freqs[@]}
	 [[ $? != 0 ]] && printf "%s: Invalid minimum frequency\n" "${FUNCNAME[0]}" && return 3
	 # Validate maximum frequency
	array::contains "$max_freq" ${freqs[@]}
	 [[ $? != 0 ]] && printf "%s: Invalid maximum frequency\n" "${FUNCNAME[0]}" && return 4
	 # Validate minimum frequency is <= maximum frequency
	 [ "$min_freq" -gt "$max_freq" ] && printf "%s: Minimum frequency must be <= maximum frequency\n" "${FUNCNAME[0]}" && return 5
	 # Return governors
	declare -a governors=( $(string::split "$(cpu::get_governors $policy)" " ") )
	 # Validate maximum governor
	array::contains "$governor" ${governor[@]}
	 [[ $? != 0 ]] && printf "%s: Invalid minimum frequency\n" "${FUNCNAME[0]}" && return 6
	 # Update file
	sed -i "s/MIN_SPEED=.*/MIN_SPEED=$min_freq/" "$file"
	sed -i "s/MAX_SPEED=.*/MAX_SPEED=$max_freq/" "$file"
	sed -i "s/GOVERNOR=.*/GOVERNOR=$governor/" "$file"
	# Return value
	return 0
}


# @description SetUp Virtula spi MTD FLash, Remove spi MTD FLash.
#
# @example
#   storage::set_spi_vflash s
#   echo $?
#   #Output
#   
#
# @arg $1 int UnSet.
# @arg $1 int SetUp.
#
# @exitcode 0  If successful.
storage::set_spi_vflash(){
    # TODO handeling 
    [[ "$1" == "setup" ]] && create_virt_spi
    [[ "$1" == "remove" ]] && remove_virt_spi

}

create_virt_spi()
{
	# Load the nandsim and mtdblock modules to create a virtual MTD device

	sudo modprobe mtdblock
    #sudo modprobe nandsim
	# Find the newly created MTD device
	if [[ ! -e /dev/mtdblock0 ]]; then
  		sudo modprobe nandsim
		irtual_mtd=$(grep -l "NAND simulator" /sys/class/mtd/mtd*/name | sed -r 's/.*mtd([0-9]+).*/mtd\1/')
	else
		echo "$( sudo ls /dev/mtdblock0 )"
	fi

	# Create a symlink to the virtual MTD device with the name "spi0.0"
	# This is necessary because the erase_spi_bootloader function looks for an MTD device with this name
	if [[ ! -e /dev/mtdblock0 ]]; then
		ln -s /dev/$virtual_mtd /dev/mtdblock0
	fi

    # Create the mount point if it doesn't exist
    mkdir -p /tmp/boot

    # Mount the virtual MTD device to the mount point
    mount -t jffs2 /dev/mtdblock0 /tmp/boot

	# write a file to remove
	touch /tmp/boot/Mounted_MTD.txt

	echo "$( sudo ls /dev/mtd* )"

}

remove_virt_spi()
{
    # Unmount the virtual MTD device from the mount point
    umount $(mount | grep /dev/mtdblock0 | awk '{print $3}')

    # Remove the symlink to the virtual MTD device
    rm /dev/mtdblock0

    # Unload the nandsim and mtdblock modules to remove the virtual MTD device
    sudo modprobe -r mtdblock
    sudo modprobe -r nandsim

	echo "0"
}
