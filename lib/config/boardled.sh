
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  System boards led monitoring. See
# 	TBD

# @description See a list of board led options.
#
# @example
#   boardled::set_sysled
#   #Output
#   Led blinks to set $1
#
# @exitcode 0  If successful.
#
# @stdout tbd.
boardled::see_sysled(){

	# the avalible options
	readarray triggers_led < <( cat /sys/class/leds/*/trigger )
    # see pass not argument the avalible options
    [[ -z $1 ]] && printf "%s\n" "${triggers_led[@]} ";
	# Set the systme Led blink to $1 valus
    [[ " ${triggers_led[@]} " =~ " ${1} " ]] &&  echo "${1}"| sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger ;

}

# @description Set board led options to none (off).
#
# @exitcode 0  If successful.
#
# @stdout tbd.
boardled::see_sysled_none(){

  echo "none"| sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger ;

}

# @description Set board led options to monitor CPU.
#
# @exitcode 0  If successful.
#
# @stdout tbd.
boardled::see_sysled_cpu(){

  echo "cpu"| sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger ;

}

# @description Set board led options to heartbeat pulse.
#
# @exitcode 0  If successful.
#
# @stdout tbd.
boardled::see_sysled_beat(){

  echo "heartbeat"| sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger ;

}
