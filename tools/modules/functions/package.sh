# package.sh

# internal function
_pkg_have_stdin() { [[ -t 0 ]]; }

declare -A module_options
module_options+=(
	["pkg_configure,author"]="@dimitry-ishenko"
	["pkg_configure,desc"]="Configure an unconfigured package"
	["pkg_configure,example"]="pkg_configure"
	["pkg_configure,feature"]="pkg_configure"
	["pkg_configure,status"]="Interface"
)

pkg_configure()
{
	_pkg_have_stdin && debconf-apt-progress -- dpkg --configure "$@" || dpkg --configure "$@"
}

module_options+=(
	["pkg_full_upgrade,author"]="@dimitry-ishenko"
	["pkg_full_upgrade,desc"]="Upgrade installed packages (potentially removing some)"
	["pkg_full_upgrade,example"]="pkg_full_upgrade"
	["pkg_full_upgrade,feature"]="pkg_full_upgrade"
	["pkg_full_upgrade,status"]="Interface"
)

pkg_full_upgrade()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y full-upgrade "$@" || apt-get -y full-upgrade "$@"
}

module_options+=(
	["pkg_install,author"]="@dimitry-ishenko"
	["pkg_install,desc"]="Install package"
	["pkg_install,example"]="pkg_install neovim"
	["pkg_install,feature"]="pkg_install"
	["pkg_install,status"]="Interface"
)

pkg_install()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y install "$@" || apt-get -y install "$@"
	if [[ $? == 100 ]]; then
		_pkg_have_stdin && dpkg --configure -a
		_pkg_have_stdin && debconf-apt-progress -- apt-get -y install "$@" || apt-get -y install "$@"
	fi
}

module_options+=(
	["pkg_installed,author"]="@dimitry-ishenko"
	["pkg_installed,desc"]="Check if package is installed"
	["pkg_installed,example"]="pkg_installed mc"
	["pkg_installed,feature"]="pkg_installed"
	["pkg_installed,status"]="Interface"
)

pkg_installed()
{
	local status=$(dpkg -s "$1" 2>/dev/null | sed -n "s/Status: //p")
	! [[ -z "$status" || "$status" = *deinstall* || "$status" = *not-installed* ]]
}

module_options+=(
	["pkg_remove,author"]="@dimitry-ishenko"
	["pkg_remove,desc"]="Remove package"
	["pkg_remove,example"]="pkg_remove nmap"
	["pkg_remove,feature"]="pkg_remove"
	["pkg_remove,status"]="Interface"
)

pkg_remove()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y autopurge "$@" || apt-get -y autopurge "$@"
	if [[ $? == 100 ]]; then
		_pkg_have_stdin && dpkg --configure -a
		_pkg_have_stdin && debconf-apt-progress -- apt-get -y autopurge "$@" || apt-get -y autopurge "$@"
	fi
}

module_options+=(
	["pkg_update,author"]="@dimitry-ishenko"
	["pkg_update,desc"]="Update package repository"
	["pkg_update,example"]="pkg_update"
	["pkg_update,feature"]="pkg_update"
	["pkg_update,status"]="Interface"
)

pkg_update()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y update || apt-get -y update
}

module_options+=(
	["pkg_upgrade,author"]="@dimitry-ishenko"
	["pkg_upgrade,desc"]="Upgrade installed packages"
	["pkg_upgrade,example"]="pkg_upgrade"
	["pkg_upgrade,feature"]="pkg_upgrade"
	["pkg_upgrade,status"]="Interface"
)

pkg_upgrade()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y upgrade "$@" || apt-get -y upgrade "$@"
}

module_options+=(
	["pkg_fix,author"]="@igorpecovnik"
	["pkg_fix,desc"]="Fix dependency issues"
	["pkg_fix,example"]="pkg_fix"
	["pkg_fix,feature"]="pkg_fix"
	["pkg_fix,status"]="Interface"
)

pkg_fix()
{
	_pkg_have_stdin && debconf-apt-progress -- apt-get -y --fix-broken install "$@" || apt-get -y --fix-broken install "$@"
}
