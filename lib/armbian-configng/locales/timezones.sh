# @description Time zone configuration
# @requirments timedatectl
# @exitcode 0  If successful.
# @default none
# @options none
function locales::Timezone(){
    echo "Please select a country:"
    countries=$(timedatectl list-timezones | cut -d'/' -f1 | uniq)
    select country in $countries; do
        if [[ -n "$country" ]]; then
            echo "You have selected the country: $country"
            echo "Please select a time zone:"
            zones=$(timedatectl list-timezones | grep "^$country/")
            select zone in $zones; do
                if [[ -n "$zone" ]]; then
                    echo "You have selected the time zone: $zone"
                    sudo timedatectl set-timezone "$zone"
                    break 2
                else
                    echo "Invalid selection"
                fi
            done
        else
            echo "Invalid selection"
        fi
    done
}
