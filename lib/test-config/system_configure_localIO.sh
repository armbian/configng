
# @description Enable or Disable Infrared Remote Control support.
#
# @example
#   set_ir_toggle enable
#   set_ir_toggle disable
#
# @exitcode 0  If successful.
iolocal::set_lirc(){

[[ "$1" == "enable" ]] && apt -y --no-install-recommends install lirc ; 
[[ "$1" == "disabe" ]] && apt -y remove lirc ; apt -y -qq autoremove ;

}

# @description See a list of board led options.
#
# @example
#   set_sysled
#
# @exitcode 0  If successful.
#
# @stdout tbd.
iolocal::see_sysled(){

	# the avalible options
	readarray -d " " triggers_led <  /sys/class/leds/*:red*/trigger 
    # see pass not argument the avalible options
    [[ -z $1 ]] && printf "%s\n" "${triggers_led[@]} ";

}
