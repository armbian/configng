#!/bin/bash

# @description Help message.
# @requirments none
# @exitcode 0  If successful.
# @default none
# @options none

generate_help(){

#Usage: ${filename%.*} [flag][option]

    cat << EOF
    
Usage: ${0##*/} [OPTION]...
    options:
        -h, --help    Show this help message and exit
        -d, --doc     Generate documentation
        --server      Serve and open HTML
        --web         Generate web
        -t            Generate TUI
        --json        Generate JSON
        --csv         Generate CSV
        help          Advanced no-interface options help message

    `generate_list_cli`

    This will parse the command to the Group function, and the function will be run.

    example ${0##*/} [group]=[function]

EOF
}

function testing::Help(){
    clear
    generate_help ; exit 0
}