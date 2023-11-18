#!/bin/bash

# @description Sets up the lighttpd web server to serve CGI scripts. 
#
# @OPTIONS
# $1 -d, do apt udate
# $1 -u, uninsall server and configruaitons.
#
# @example
#	config server set_lighthttpd -u
#
# @author tearran
#
server::set_lighthttpd() {
    # Parse command-line arguments
    while getopts ":du" opt; do
        case $opt in
            d)
                # If the -d option is passed, skip updating package lists
                skip_update=1
                ;;
            u)
                # If the -u option is passed, prompt the user to confirm uninstallation
                read -p "Are you sure you want to uninstall lighttpd and purge its configuration? [y/N] " confirm
                if [[ $confirm == [yY] ]]; then
                    # Uninstall lighttpd and purge its configuration
                    sudo apt-get purge -y lighttpd
                    exit 0
                else
                    # Abort the script
                    exit 1
                fi
                ;;
            \?)
                # If an invalid option is passed, show usage information and exit
                echo "Usage: $0 [-d] [-u]" >&2
                exit 1
                ;;
        esac
    done

    # Update package lists (unless the -d option was passed)
    if [[ -n $skip_update ]]; then
        sudo apt-get update
    fi

    # Install lighttpd
    sudo apt-get install -y lighttpd

    # Create public_html and cgi-bin directories
    mkdir -p ~/public_html/cgi-bin

    # Enable userdir module
    sudo lighty-enable-mod userdir

    # Configure lighttpd to serve CGI scripts
    sudo sh -c 'cat << EOF >> /etc/lighttpd/conf-available/10-cgi.conf
server.modules += ( "mod_cgi" )
cgi.assign = (
    ".cgi" => "/bin/bash",
    ".sh" => "/bin/bash",
    ".py" => "/usr/bin/python3"
)
alias.url += ( "/cgi-bin/" => "/home/'"$USER"'/public_html/cgi-bin/" )
EOF'

    # Enable CGI module
    sudo lighty-enable-mod cgi

    # Restart lighttpd
    sudo service lighttpd restart
}

# Call the main function with command-line arguments
set_lighthttpd "$@"
