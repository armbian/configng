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
			#
			# The owner cannot read some files, such as the 0400
			# .google_authenticator from module_qr_code. The owner's copy
			# lists them. Root reads them and the owner writes them.
			local username x uid gid gecos home shell unreadable src rc=0
			while IFS=: read -r username x uid gid gecos home shell; do
				if [ ! -d "$home" ] || [ "$username" == 'root' ] || [ "$uid" -lt 1000 ] || [ "$uid" -ge 65534 ]; then
					continue
				fi
				chown -R "$uid:$gid" "$home/"
				unreadable=$(runuser -u "$username" -- bash -c '
					cd /etc/skel || exit 0
					rc=0
					while IFS= read -r src; do
						dst="$1/${src#./}"
						if [ -d "$src" ] && [ ! -L "$src" ]; then
							[ -d "$dst" ] || mkdir "$dst" || rc=1
						elif [ -e "$dst" ] || [ -L "$dst" ]; then
							:
						elif [ -f "$src" ] && [ ! -L "$src" ] && [ ! -r "$src" ]; then
							printf "%s\n" "$src"
						else
							cp -P "$src" "$dst" || rc=1
						fi
					done < <(find . -mindepth 1)
					exit "$rc"' bash "$home") || rc=1
				while IFS= read -r src; do
					[ -n "$src" ] || continue
					runuser -u "$username" -- sh -c '
						umask 077
						[ -e "$1" ] || [ -L "$1" ] || { cat > "$1" && chmod "$2" "$1"; }' \
						sh "$home/${src#./}" "$(stat -c %a "/etc/skel/${src#./}")" \
						< "/etc/skel/${src#./}" || rc=1
				done <<< "$unreadable"
			done < <(getent passwd)
			[ "$rc" -eq 0 ] || echo "Warning: some /etc/skel files were not copied" >&2
			return "$rc"
		;;
		"${commands[1]}")
			show_module_help "module_update_skel" "Update Skel" "" "native"
		;;
		*)
			show_module_help "module_update_skel" "Update Skel" "" "native"
		;;
	esac
}
