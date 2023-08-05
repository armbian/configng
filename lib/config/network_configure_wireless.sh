
# @description Enable or Disable wifi text user interface
#
# @example
#   set_wifi
#
# @exitcode 0  If successful.
wirerless::set_wifi_nmtui(){

     nmtui-connect ;

}

# @description Enable or Disable wifi command line. 
#
# @example SSID PASS
#   set_wpa_connect 
#
# @exitcode 0  If successful.
wirerless::set_wpa_connect(){

  ##   wpa_passphrase $SSID $PASS >> /etc/wpa_supplicant/wpa_supplicant.conf
  sudo wpa_passphrase $1 $2 >> "$HOME/.local/etc/wpa_supplicant/wpa_supplicant.conf"

}

# To run independenly
[[ "$0" = "$BASH_SOURCE" ]] && "$@" ;
