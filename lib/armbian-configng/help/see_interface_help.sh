#!/bin/bash


# @description armbian-intrface Help message.
# @requirments none
# @exitcode 0  If successful.
# @default none
# @options none



function help::interface(){
    clear
    [[ -f /usr/bin/armbian-interface ]] && /usr/bin/armbian-interface -h  || exit 2    
    ./armbian-interface --help | ./armbian-interface -o ; exit 0
}