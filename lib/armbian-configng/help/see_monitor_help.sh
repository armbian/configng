#!/bin/bash


# @description armbianmonitor Help message.
# @requirments none
# @exitcode 0  If successful.
# @default none
# @options none



function help::monitor(){
    clear
[[ -f /usr/bin/armbianmonitor ]] && /usr/bin/armbianmonitor -h  || exit 2    
     exit 0
}