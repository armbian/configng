
module_options+=(
	["apt_install_wrapper,author"]="@igorpecovnik"
	["apt_install_wrapper,ref_link"]=""
	["apt_install_wrapper,feature"]="Install wrapper"
	["apt_install_wrapper,desc"]="Install wrapper"
	["apt_install_wrapper,example"]="apt_install_wrapper apt-get -y purge armbian-zsh"
	["apt_install_wrapper,status"]="Active"
)
#
# @description Use TUI / GUI for apt install if exists
#
function apt_install_wrapper() {

	if [ -t 0 ]; then
		debconf-apt-progress -- "$@"
	else
		# Terminal not defined - proceed without TUI
		"$@"
	fi
}

