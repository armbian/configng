module_options+=(
	["module_zsh,author"]="@igorpecovnik"
	["module_zsh,maintainer"]="@igorpecovnik"
	["module_zsh,feature"]="module_zsh"
	["module_zsh,example"]="install remove status help"
	["module_zsh,desc"]="Switch system-wide login shell to ZSH"
	["module_zsh,doc_link"]=""
	["module_zsh,group"]="User"
	["module_zsh,status"]="Active"
	["module_zsh,arch"]=""
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
			if ! pkg_install armbian-zsh zsh-common zsh tmux; then
				echo "Failed to install zsh packages; shell not changed"
				return 1
			fi

			# Default shell for new accounts (useradd / adduser).
			sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

			# Refresh /etc/skel from armbian-zsh so newly created
			# users get the matching dotfiles.
			module_update_skel install

			# Move root + every existing user still on bash.
			usermod --shell /bin/zsh root
			sed -i 's|/bash$|/zsh|' /etc/passwd
		;;

		"${commands[1]}") # remove
			sed -i "s|^SHELL=.*|SHELL=/bin/bash|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/bash|" /etc/adduser.conf

			usermod --shell /bin/bash root
			sed -i 's|/zsh$|/bash|' /etc/passwd

			# Remove packages last — flipping the shell pointer
			# first means the post-removal hook can't disturb a
			# logged-in user's active zsh process.
			pkg_remove armbian-zsh zsh-common zsh tmux
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
