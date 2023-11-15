
# @description Enable or Disable wifi text user interface
#

# @exitcode 0  If successful.
#
# @options none
wirerless::set_wifi_nmtui(){

     nmtui-connect ;

}

# @description Enable or Disable wifi command line. 
#
# @exitcode 0  If successful.
#
# @options none
wirerless::set_wpa_connect(){

[[ -z "$@" ]] && echo "Useage: wpa_passphrase [ SSID ] [ PASS ]"
[[ -n "$@" ]] && wpa_passphrase $1 $2 >> "$HOME/.local/etc/wpa_supplicant/wpa_supplicant.conf"

}

[[ "$0" = "$BASH_SOURCE" ]] && "$@" ;
