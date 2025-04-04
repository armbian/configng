# module_samba.sh

module_options+=(
	["module_samba,author"]="@dimitry-ishenko"
	["module_samba,feature"]="module_samba"
	["module_samba,desc"]="Manage SAMBA Server"
	["module_samba,example"]="help install remove status"
	["module_samba,status"]="Active"
)

_module_samba_help()
{
	local err="$1"
	[[ -n "$err" ]] && echo "module_samba: $err"

	echo "
Usage: module_samba <command>
Where <command> is one of:
	help       Show this help screen.
	install    Install SAMBA Server.
	remove     Remove SAMBA Server.
	status     Get install status of SAMBA.
"
	return $((${#err} > 0))
}

module_samba()
{
	case "$1" in
		help) _module_samba_help;;
		install) pkg_install samba;;
		remove)  pkg_remove samba;;
		status)  pkg_installed samba;;
		*) _module_samba_help "Invalid command '$1'";;
	esac
}
