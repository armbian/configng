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
			# directories are created and chowned before any of their
			# contents arrive.
			#
			# After the per-file copy, chown -R the entire home
			# anyway. This is a safety net for root-owned files that
			# other package postinst scripts leak into the user's
			# home (caja, nemo, gnome-keyring and others all do this
			# on first install) — without the recursive chown, caja
			# and nemo refuse to start on first login complaining
			# that ~/.config/{caja,nemo} are not writable.
			getent passwd |
				while IFS=: read -r username x uid gid gecos home shell; do
					if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
						continue
					fi
					find /etc/skel -mindepth 1 | while read -r src; do
						local dst="$home/${src#/etc/skel/}"
						if [ -d "$src" ]; then
							[ -d "$dst" ] || mkdir "$dst"
						elif [ ! -e "$dst" ]; then
							cp "$src" "$dst"
						fi
					done
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
