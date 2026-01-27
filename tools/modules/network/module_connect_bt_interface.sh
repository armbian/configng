module_options+=(
	["module_connect_bt_interface,author"]="@armbian"
	["module_connect_bt_interface,ref_link"]=""
	["module_connect_bt_interface,feature"]="connect_bt_interface"
	["module_connect_bt_interface,desc"]="Migrated procedures from Armbian config."
	["module_connect_bt_interface,example"]="module_connect_bt_interface"
	["module_connect_bt_interface,status"]="Active"
)
#
# connect to bluetooth device
#
function module_connect_bt_interface() {

	IFS=$'
'
	GLOBIGNORE='*'
	show_infobox <<< "
Discovering Bluetooth devices ... "
	BT_INTERFACES=($(hcitool scan | sed '1d'))

	local LIST=()
	for i in "${BT_INTERFACES[@]}"; do
		local a=$(echo ${i[0]//[[:blank:]]/} | sed -e 's/^\(.\{17\}\).*/\1/')
		local b=${i[0]//$a/}
		local b=$(echo $b | sed -e 's/^[ 	]*//')
		LIST+=("$a" "$b")
	done

	LIST_LENGTH=$((${#LIST[@]} / 2))
	if [ "$LIST_LENGTH" -eq 0 ]; then
		BT_ADAPTER=${WLAN_INTERFACES[0]}
		show_message <<< "
No nearby Bluetooth devices were found!"
	else
		exec 3>&1
		BT_ADAPTER=$(whiptail --title "Select interface" \
			--clear --menu "" $((6 + ${LIST_LENGTH})) 50 $LIST_LENGTH "${LIST[@]}" 2>&1 1>&3)
		exec 3>&-
		if [[ $BT_ADAPTER != "" ]]; then
			show_infobox <<< "
Connecting to $BT_ADAPTER "
			BT_EXEC=$(
				expect -c 'set prompt "#";set address '$BT_ADAPTER';spawn bluetoothctl;expect -re $prompt;send "disconnect $address
";
			sleep 1;send "remove $address
";sleep 1;expect -re $prompt;send "scan on
";sleep 8;send "scan off
";
			expect "Controller";send "trust $address
";sleep 2;send "pair $address
";sleep 2;send "connect $address
";
			send_user "
Should be paired now.
";sleep 2;send "quit
";expect eof'
			)
			echo "$BT_EXEC" > /tmp/bt-connect-debug.log
			if [[ $(echo "$BT_EXEC" | grep "Connection successful") != "" ]]; then
				show_message <<< "
Your device is ready to use!"
			else
				show_message <<< "
Error connecting. Try again!"
			fi
		fi
	fi

}
