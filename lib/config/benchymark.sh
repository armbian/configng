
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  Benchmark related functions. See
#	https://systemd.io/ for more info.
#   https://www.7-zip.org/

# @description system boot-up performance statistics.
#
# @example
#   benchymark::see_systemd $1 (blame time chain)
#   #Output
#   time (quick check of boot time)
#   balme (List modual  load times)
#   chain ()
#
# @exitcode 0  If successful.
#
# @stdout tobd.
benchymark::see_monitor(){
	[[ $1 == "" ]] && clear && armbianmonitor -h ;
	[[ $1 == $1 ]] && armbianmonitor "$1" ;
	exit 0
	}
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  Benchmark related functions. See
#	https://systemd.io/ for more info.
#   https://www.7-zip.org/

# @description system boot-up performance statistics.
#
# @example
#   benchymark::see_systemd $1 (blame time chain)
#   #Output
#   time (quick check of boot time)
#   balme (List modual  load times)
#   chain ()
#
# @exitcode 0  If successful.
#
# @stdout tobd.
benchymark::see_boot_times(){
	
	[[ $1 == "" ]] && sys_blame=$( systemd-analyze -h ) ;
	[[ $1 == "blame" ]] && sys_blame=$( systemd-analyze blame ) ;
	[[ $1 == "time"  ]] && sys_blame=$( systemd-analyze time ) ;
	[[ $1 == "chain" ]] && sys_blame=$( systemd-analyze critical-chain ) ;
	printf '%s\n' "${sys_blame[@]}"
	exit 0
	}
