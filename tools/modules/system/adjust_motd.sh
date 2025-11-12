
module_options+=(

["adjust_motd,author"]="@igorpecovnik"
["adjust_motd,ref_link"]=""
["adjust_motd,feature"]="about_armbian_configng"
["adjust_motd,desc"]="Adjust welcome screen (motd)"
["adjust_motd,example"]="adjust_motd clear, header, sysinfo, tips, commands"
["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear|00-clear)
				echo "Clear screen on login"
				;;
			header|10-armbian-header)
				echo "Show header with logo and version info"
				;;
			ap-info|15-ap-info)
				echo "Display active Wi-Fi access point (SSID, channel)"
				;;
			ip-info|20-ip-info)
				echo "Show LAN/WAN IPv4 and IPv6 addresses"
				;;
			containers-info|25-containers-info)
				echo "List running Docker containers"
				;;
			sysinfo|30-armbian-sysinfo)
				echo "Display performance and system information"
				;;
			tips|35-armbian-tips)
				echo "Show helpful tips and Armbian resources"
				;;
			commands|41-commands)
				echo "Show recommended commands"
				;;
			autoreboot-warn|98-armbian-autoreboot-warn)
				echo "Warn about pending automatic reboot after update"
				;;
			*)
				echo "No description available"
				;;
		esac
	}

	# read status
	function motd_status() {
		source /etc/default/armbian-motd
		if [[ $MOTD_DISABLE == *$1* ]]; then
			echo "OFF"
		else
			echo "ON"
		fi
	}

	LIST=()
	for v in $(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"); do
		LIST+=("$v" "$(motd_desc $v)" "$(motd_status $v)")
	done

	INLIST=($(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"))
	CHOICES=$($DIALOG --separate-output --nocancel --title "Adjust welcome screen" --checklist "" 14 76 8 "${LIST[@]}" 3>&1 1>&2 2>&3)
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
}
