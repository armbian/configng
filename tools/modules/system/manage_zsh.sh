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

		sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
		sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

		pkg_update

		# install
		pkg_install armbian-zsh zsh-common zsh tmux

		update_skel

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
