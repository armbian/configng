
# @description Enable or Disable Infrared Remote Control.
#
# @example
#   io::set_ir_toggle enable
#   io::set_ir_toggle disable
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
io::set_ir_toggle(){

[[ "$1" == "enable" ]] && sudo apt -y --no-install-recommends install lirc ;
[[ "$1" == "disabe" ]] && sudo apt -y remove lirc ; sudo apt -y -qq autoremove ;

}