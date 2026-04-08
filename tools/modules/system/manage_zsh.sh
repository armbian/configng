module_options+=(
	["manage_zsh,author"]="@igorpecovnik"
	["manage_zsh,ref_link"]=""
	["manage_zsh,feature"]="manage_zsh"
	["manage_zsh,desc"]="Set system shell to BASH"
	["manage_zsh,example"]="manage_zsh enable|disable"
	["manage_zsh,status"]="Active"
)
#
# @description Set system shell to ZSH
#
function manage_zsh() {

	local bash_location=$(grep /bash$ /etc/shells | tail -1)
	local zsh_location=$(grep /zsh$ /etc/shells | tail -1)

	if [[ "$1" == "enable" ]]; then

		pkg_update

		# install zsh before changing any shells — if install fails, abort
		# to avoid setting an invalid shell that locks all users out via pam_shells
		if ! pkg_install armbian-zsh zsh-common zsh tmux; then
			echo "Failed to install zsh packages; shell not changed"
			return 1
		fi

		sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
		sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

		module_update_skel install

		# change shell for root
		usermod --shell "/bin/zsh" root
		# change shell for others
		sed -i 's/bash$/zsh/g' /etc/passwd

	else

		sed -i "s|^SHELL=.*|SHELL=/bin/bash|" /etc/default/useradd
		sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/bash|" /etc/adduser.conf

		# remove
		pkg_remove armbian-zsh zsh-common zsh tmux

		# change shell for root
		usermod --shell "/bin/bash" root
		# change shell for others
		sed -i 's/zsh$/bash/g' /etc/passwd

	fi

}
