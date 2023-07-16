
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  System boards led monitoring. See
# 	TBD

# @description set the Sys board led to montor cpu activity.
#
# @example
#   boardLED::set_sysled_cpu
#   #Output
#   Led blinks to set cpu
#
# @exitcode 0  If successful.
#
# @stdout cpu.
boardled::set_sysled_cpu(){
    
	echo cpu | sudo tee /sys/class/leds/*/trigger

	}

# @description set the Sys board led to montor none.
#
# @example
#   boardLED::set_sysled_none
#   #Output
#   Led blinks to set no
#
# @exitcode 0  If successful.
#
# @stdout none.
boardled::set_sysled_none(){

	echo none | sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger
	}

# @description See a list of board led options.
#
# @example
#   boardLED::set_sysled_none
#   #Output
#   Led blinks to set no
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

