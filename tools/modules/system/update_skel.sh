
module_options+=(
	["update_skel,author"]="@igorpecovnik"
	["update_skel,ref_link"]=""
	["update_skel,feature"]="update_skel"
	["update_skel,desc"]="Update the /etc/skel files in users directories"
	["update_skel,example"]="update_skel"
	["update_skel,status"]="Active"
)
#
# Copy /etc/skel files into existing user home directories (skip existing files)
#
function update_skel() {

	getent passwd |
		while IFS=: read -r username x uid gid gecos home shell; do
			if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
				continue
			fi
			cp -rn /etc/skel/. "$home/"
			chown -R "$uid:$gid" "$home/"
		done

}

