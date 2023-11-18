
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#   utility_testing_benchmark related functions. See
#	https://systemd.io/  https://www.7-zip.org/ for more info.

# @description armbian monitor help message and tools.
#
# @example
#   see_systemd $1 (-h)
#
# @exitcode 0 If successful.
# @exitcode 1 If file not found.
# @exitcode 2 Function missing arguments.
#
benchymark::see_monitor(){
	[[ $1 == "" ]] && clear && monitor -h ; return 0
	[[ $1 == $1 ]] && monitor "$1" ; return 0
	

	}

#  Benchmark related functions. See
#	https://systemd.io/ for more info.
#   https://www.7-zip.org/

# @description system boot-up performance statistics.
#
# @example
#   see_systemd option: [ blame | time ]
#   #Output
#   -h (systemd help list, not not all are avalible.)
#   time (quick check of boot time)
#   balme (Lists modual boot load times)
#
# @exitcode 0  If successful.
#
# @stdout tobd.
benchymark::see_boot_times(){
	
	[[ $1 == "" ]] && sys_blame="options: blame, time" ;
	[[ $1 == "blame" ]] && sys_blame=$( systemd-analyze blame ) ; 
	[[ $1 == "time"  ]] && sys_blame=$( systemd-analyze time ) ; 
	printf '%s\n' "${sys_blame[@]}"
	return 0

	}
