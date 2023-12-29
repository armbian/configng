# @description Time zone configuration
# @requirments timedatectl
# @exitcode 0  If successful.
# @default none
# @options none
function locales::select_zone(){
    echo "Please select a time zone:"
    select zone in $(timedatectl list-timezones); do
        if [[ -n "$zone" ]]; then
            echo "You have selected the time zone: $zone"
            timedatectl set-timezone "$zone"
            break
        else
            echo "Invalid selection"
        fi
    done

}