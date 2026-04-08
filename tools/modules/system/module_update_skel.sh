module_options+=(
	["module_update_skel,author"]="@igorpecovnik"
	["module_update_skel,feature"]="module_update_skel"
	["module_update_skel,desc"]="Copy /etc/skel files into existing user home directories"
	["module_update_skel,example"]="install help"
	["module_update_skel,status"]="Active"
	["module_update_skel,arch"]=""
)
#
# Module to update skel files in user home directories
#
function module_update_skel() {

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_update_skel,example"]}"

	case "$1" in
		"${commands[0]}")
			# install - copy skel to all regular users
			getent passwd |
				while IFS=: read -r username x uid gid gecos home shell; do
					if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
						continue
					fi
					cp -rn /etc/skel/. "$home/"
					chown -R "$uid:$gid" "$home/"
				done
		;;
		"${commands[1]}")
			show_module_help "module_update_skel" "Update Skel" "" "native"
		;;
		*)
			show_module_help "module_update_skel" "Update Skel" "" "native"
		;;
	esac
}
