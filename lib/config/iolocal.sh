
# @description Enable or Disable Infrared Remote Control support.
#
# @example
#   io::set_ir_toggle enable
#   io::set_ir_toggle disable
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
iolocal::set_ir_toggle(){

[[ "$1" == "enable" ]] && sudo apt -y --no-install-recommends install lirc ; exit 0 ;
[[ "$1" == "disabe" ]] && sudo apt -y remove lirc ; sudo apt -y -qq autoremove ; exit 0 ;

}

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
boardled::see_sysled_opt(){

	# the avalible options
	readarray triggers_led < <( cat /sys/class/leds/*/trigger )
    # see pass not argument the avalible options
    [[ -z $1 ]] && printf "%s\n" "${triggers_led[@]} ";
    exit 0 
}

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
boardled::set_sysled(){

	# the avalible options
	readarray triggers_led < <( cat /sys/class/leds/*/trigger )
    # see pass not argument the avalible options
    [[ -z $1 ]] && printf "%s\n" "${triggers_led[@]} ";
	# Set the systme Led blink to $1 valus
    [[ " ${triggers_led[@]} " =~ " ${1} " ]] &&  echo "${1}"| sudo tee /sys/class/leds/bananapi-m2-zero:red:pwr/trigger ;

}
