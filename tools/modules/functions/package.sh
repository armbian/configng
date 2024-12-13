# package.sh

# internal function
_pkg_have_stdin() { [[ -t 0 ]] }

declare -A module_options
module_options+=(
	["package,author"]="@dimitry-ishenko"
	["package,desc"]="Install package"
	["package,example"]="pkg_install neovim"
	["package,feature"]="pkg_install"
	["package,status"]="Interface"
)

pkg_install()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y install "$@" || apt-get -y install "$@"
}

module_options+=(
	["package,author"]="@dimitry-ishenko"
	["package,desc"]="Check if package is installed"
	["package,example"]="pkg_installed mc"
	["package,feature"]="pkg_installed"
	["package,status"]="Interface"
)

pkg_installed()
{
	local status=$(dpkg -s "$1" 2>/dev/null | sed -n "s/Status: //p")
	! [[ -z "$status" || "$status" = *deinstall* || "$status" = *not-installed* ]]
}

module_options+=(
	["package,author"]="@dimitry-ishenko"
	["package,desc"]="Remove package"
	["package,example"]="pkg_remove nmap"
	["package,feature"]="pkg_remove"
	["package,status"]="Interface"
)

pkg_remove()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y autopurge "$@" || apt-get -y autopurge "$@"
}
