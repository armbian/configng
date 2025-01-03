declare -A module_options
module_options+=(
    ["module_dnsmasq,author"]="@Tearran"
    ["module_dnsmasq,feature"]="module_dnsmasq"
    ["module_dnsmasq,example"]="help install remove purge status"
    ["module_dnsmasq,desc"]="Setup and service management for dnsmasq."
    ["module_dnsmasq,status"]="Stable"
    ["module_dnsmasq,doc_link"]="https://thekelleys.org.uk/dnsmasq/doc.html"
    ["module_dnsmasq,group"]="DNS"
    ["module_dnsmasq,arch"]="x86-64 arm64"
)

function module_dnsmasq() {
    local title="dnsmasq"
    local condition=$(dpkg -s "dnsmasq" 2>/dev/null | sed -n "s/Status: //p")
    # Convert the example string to an array
    local commands
    IFS=' ' read -r -a commands <<< "${module_options["module_dnsmasq,example"]}"

    case "$1" in
        "${commands[0]}")
        ## help/menu options for the module
        echo -e "\nUsage: ${module_options["module_dnsmasq,feature"]} <command>"
        echo -e "Commands: ${module_options["module_dnsmasq,example"]}"
        echo "Available commands:"
        if [[ -z "$condition" ]]; then
            echo -e "  install\t- Install $title."
        else
            echo -e "\tremove\t- Remove $title."
            echo -e "\tpurge\t- Purge $title and its configuration files."
            echo -e "\tstatus\t- Show the status of the $title service."
        fi
        echo
        ;;
        "${commands[1]}")
        ## install dnsmasq

        echo "Disabling systemd-resolved service..."
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        rm /etc/resolv.conf
        echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 127.0.0.1" | tee /etc/resolv.conf

        echo "Updating package list..."
        apt update

        echo "Installing dnsmasq..."
        apt install -y dnsmasq

        echo "Configuring dnsmasq..."
        {
            echo "interface=lo"
            echo "listen-address=127.0.0.1"
            echo "bind-interfaces"
            echo "server=8.8.8.8"
            echo "server=8.8.4.4"
            echo "domain-needed"
            echo "bogus-priv"
            echo "cache-size=1000"
            echo "resolv-file=/etc/resolv.conf"
        } | tee /etc/dnsmasq.conf

        echo "Checking for services using port 53..."
        local service_using_port_53=$(lsof -i :53 | grep LISTEN | awk '{print $1}' | uniq)

        for service in $service_using_port_53; do
            echo "Stopping service using port 53: $service"
            systemctl stop "$service"
            systemctl disable "$service"
        done

        echo "Restarting dnsmasq service to apply configuration..."
        systemctl restart dnsmasq

        echo "Enabling dnsmasq to start on boot..."
        systemctl enable dnsmasq

        echo "dnsmasq installation and configuration complete."
        ;;
        "${commands[2]}")
        ## remove dnsmasq
        echo "Stopping dnsmasq service..."
        systemctl stop dnsmasq

        echo "Removing dnsmasq..."
        apt remove -y dnsmasq

        echo "dnsmasq removed successfully."
        ;;
        "${commands[3]}")
        ## purge dnsmasq
        echo "Stopping dnsmasq service..."
        systemctl stop dnsmasq

        echo "Purging dnsmasq and cleaning up configuration files..."
        apt purge -y dnsmasq
        rm -rf /etc/dnsmasq.conf

        echo "Cleaning up orphaned libraries and configuration files..."
        apt autoremove -y
        apt clean

        echo "dnsmasq purged successfully."
        ;;
        "${commands[4]}")
        ## status of dnsmasq
        systemctl status dnsmasq
        ;;
        *)
        echo "Invalid command. Try: '${module_options["module_dnsmasq,example"]}'"
        ;;
    esac
}

# Uncomment to test the module
# module_dnsmasq "$1"
