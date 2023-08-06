
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
see_monitor(){
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



# Function to perform some task and return an exit code
benchymark::perform_task() {
    # Do some task here
    # For this example, we'll just return different exit codes based on some conditions
    if [ -z "$1" == "success" ]; then
        return 2        # Exit code 0 for success
    elif [ -n "$1" ]; then
        return 1        # Exit code 1 for file not found
    else
        return 0        # Exit code 2 for missing arguments
    fi
	}

## test for returns

## Call the function with different arguments
#perform_task "$@"
#exit_status=$?
#
## Based on the exit status, decide where to pipe the results
#if [ $exit_status -eq 0 ]; then
#    echo "Function executed successfully."    # Print to stdout
#elif [ $exit_status -eq 1 ]; then
#    echo "File not found."                   # Print to stdout
#else
#    echo "Function missing arguments."       # Print to stdout
#fi
#
#



