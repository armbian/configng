
# @description Enable or Disable wireless IO devices. (wifi, bluetooth, ... lora?)
#
# @example
#   io::set_toggle enable
#   io::set_toggle disable
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
iowireless::set_toggle(){

[[ "$1" == "" ]] && echo "enable\ndisable";
[[ "$1" == "enable" ]] && echo "ToDo; enable place holder" ;
[[ "$1" == "disabe" ]] && echo "ToDo; disable place holder" ;

}