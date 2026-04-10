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
			# install - copy skel into every regular user's home, then make
			# sure the entire home is owned by them.
			#
			# History: a previous refactor (#815) replaced the simple
			#   cp -r --update=none /etc/skel/. "$home/"
			#   chown -R "$uid:$gid" "$home/"
			# with a per-file find/cp/chown loop. That loop is internally
			# correct, but the old recursive chown was also serving as a
			# safety net: any root-owned file that other package postinst
			# scripts leaked into the user's home (caja, nemo, gnome-keyring
			# etc. all do this on first install) used to be reclaimed here.
			# Without it, caja and nemo refuse to start on first login with
			# "the directory containing settings needs read and write
			# permissions" because their ~/.config/{caja,nemo} ends up
			# root-owned.
			# Restore the original pattern.
			getent passwd |
				while IFS=: read -r username x uid gid gecos home shell; do
					if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
						continue
					fi
					cp -r --update=none /etc/skel/. "$home/"
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
