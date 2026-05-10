module_options+=(
	["module_zsh,author"]="@igorpecovnik"
	["module_zsh,maintainer"]="@igorpecovnik"
	["module_zsh,feature"]="module_zsh"
	["module_zsh,example"]="install remove status help"
	["module_zsh,desc"]="Switch system-wide login shell to ZSH"
	["module_zsh,doc_link"]=""
	["module_zsh,group"]="User"
	["module_zsh,status"]="Active"
	["module_zsh,arch"]="x86-64 arm64 armhf riscv64"
)

#
# Module zsh
# Switches the system-wide default login shell between bash and zsh.
# Companion package armbian-zsh ships the dotfiles dropped into
# /etc/skel by module_update_skel.
#
function module_zsh() {
	local title="zsh"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zsh,example"]}"

	case "$1" in
		"${commands[0]}") # install
			pkg_update

			# Install before changing any shell pointer. If the
			# install fails and we've already pointed root + users
			# at /bin/zsh, pam_shells will lock everyone out.
			if ! pkg_install armbian-zsh zsh-common zsh; then
				echo "Failed to install zsh packages; shell not changed"
				return 1
			fi

			# Default shell for new accounts (useradd / adduser).
			sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

			# Refresh /etc/skel from armbian-zsh so newly created
			# users get the matching dotfiles. Abort on failure
			# rather than silently leaving /etc/skel in an
			# inconsistent state — useradd / adduser.conf already
			# point at /bin/zsh, so a quiet skel failure would
			# produce new accounts with bash dotfiles in a zsh
			# shell.
			if ! module_update_skel install; then
				echo "Error: module_update_skel install failed; shell not changed" >&2
				return 1
			fi

			# Move root first as a canary: if usermod rejects /bin/zsh
			# (e.g. it isn't listed in /etc/shells, pam_shells would
			# block logins anyway), abort BEFORE the blanket sed
			# flips every other user — otherwise we'd lock the whole
			# system out instead of just leaving root unchanged.
			if ! usermod --shell /bin/zsh root; then
				echo "Error: usermod --shell /bin/zsh root failed; /etc/passwd left unchanged" >&2
				return 1
			fi
			# Anchor to the 7th colon-delimited field (login shell)
			# rather than just `/bash$` so we can't accidentally
			# rewrite anything else that happens to end with the
			# string. [^:]* keeps the match inside field 7. Handles
			# any path ending in /bash (/bin/bash, /usr/local/bin/bash,
			# etc.).
			sed -i -E 's|^(([^:]*:){6}[^:]*)/bash$|\1/zsh|' /etc/passwd
		;;

		"${commands[1]}") # remove
			sed -i "s|^SHELL=.*|SHELL=/bin/bash|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/bash|" /etc/adduser.conf

			# Same canary pattern as install: gate the blanket sed
			# on root flipping cleanly. /bin/bash should always be
			# present and listed, but if for any reason usermod
			# refuses we'd otherwise leave root on zsh while every
			# other account moved to bash — inconsistent state.
			if ! usermod --shell /bin/bash root; then
				echo "Error: usermod --shell /bin/bash root failed; /etc/passwd left unchanged" >&2
				return 1
			fi
			sed -i -E 's|^(([^:]*:){6}[^:]*)/zsh$|\1/bash|' /etc/passwd

			# Remove packages last — flipping the shell pointer
			# first means the post-removal hook can't disturb a
			# logged-in user's active zsh process.
			pkg_remove armbian-zsh zsh-common zsh
		;;

		"${commands[2]}") # status
			# Active iff root's login shell is zsh. Matches the
			# JSON menu's visibility condition exactly.
			[[ "$(getent passwd root | awk -F: '{print $7}')" == */zsh ]]
		;;

		"${commands[3]}") # help
			echo -e "\nUsage: ${module_options["module_zsh,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zsh,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Switch system-wide login shell to zsh."
			echo -e "\tremove\t- Switch system-wide login shell back to bash."
			echo -e "\tstatus\t- Return 0 if zsh is the current system shell."
			echo
		;;

		*)
			${module_options["module_zsh,feature"]} ${commands[3]}
		;;
	esac
}
