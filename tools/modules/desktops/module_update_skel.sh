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
			# install - copy skel into every regular user's home, then
			# fix ownership of the entire home tree.
			#
			# Implementation note: we used to do
			#   cp -r --update=none /etc/skel/. "$home/"
			# but '--update=none' was only added in GNU coreutils 9.3
			# (Debian bookworm ships 9.1 and rejects it). The
			# alternative '-n' / '--no-clobber' is available on both,
			# but on coreutils 9.2+ '-n' prints a diagnostic and
			# exits nonzero whenever it skips a file — which on a
			# normal repeat invocation is every file. Neither flag is
			# portable across bookworm and noble simultaneously.
			#
			# Use a per-file find loop instead: walk /etc/skel and
			# copy each entry only if it doesn't already exist at
			# the destination. find walks parents before children, so
			# directories are created before any of their
			# contents arrive.
			#
			# Give the home to its owner first. Other package postinst
			# scripts leak root-owned files into it (caja, nemo,
			# gnome-keyring and others do this on first install):
			# without this, caja and nemo refuse to start on first login,
			# and the copy below cannot write into those folders.
			#
			# Then copy as the owner, not as root. A link that the user
			# made can only lead where the user may write anyway, so it
			# cannot redirect a root write outside the home.
			getent passwd |
				while IFS=: read -r username x uid gid gecos home shell; do
					if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
						continue
					fi
					chown -R "$uid:$gid" "$home/"
					runuser -u "$username" -- sh -c '
						cd /etc/skel || exit 0
						find . -mindepth 1 | while read -r src; do
							dst="$1/${src#./}"
							if [ -d "$src" ] && [ ! -L "$src" ]; then
								[ -d "$dst" ] || mkdir "$dst" 2>/dev/null || :
							elif [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
								cp -P "$src" "$dst" 2>/dev/null || :
							fi
						done' sh "$home"
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
