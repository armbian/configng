# module_default.sh

module_options+=(
	["module_default,author"]="@dimitry-ishenko"
	["module_default,desc"]="Default module implementation"
	["module_default,example"]="disable enable help install remove status"
	["module_default,feature"]="module_default"
)

module_default()
{
	local action="$1" modules="$2" packages="$3" services="$4"
	shift 4

	case "$action" in
		enable)  _module_default_invoke "$action" "$modules" "$services" "$@";;
		disable) _module_default_invoke "$action" "$modules" "$services" "$@";;
		help)    _module_default_invoke "$action" "$modules" "$modules" "$packages" "$services" "$@";;
		install) _module_default_invoke "$action" "$modules" "$packages" "$@";;
		remove)  _module_default_invoke "$action" "$modules" "$packages" "$@";;
		status)  _module_default_invoke "$action" "$modules" "$packages" "$services" "$@";;
		*)       _module_default_invoke "$action" "$modules" "$packages" "$services" "$@";;
	esac
}

_module_default_invoke()
{
	local action="$1" modules="$2"
	shift 2

	for module in $modules default; do
		local fn="module_${module}_${action}"
		if [[ $(type -t "$fn") == "function" ]]; then
			"$fn" "$@"
			return 0
		fi
	done

	echo "Unknown action '$action'"
	return 1
}

module_default_disable()
{
	local services="$1"
	echo "Disabling $services..."
	srv_disable $services
}

module_default_enable()
{
	local services="$1"
	echo "Enabling $services..."
	srv_enable $services
}

module_default_help()
{
	local module=($1) packages="$2" services="$3" extra="$4"

	local text="
Usage: module_$module <action> [options...]

Where <action> is one of:
	disable     Disable service(s) for $module.
	enable      Enable service(s) for $module.
	help        Show this help screen.
	install     Install package(s) for $module.
	remove      Remove package(s) for $module.
	status      Check $module status (installed and/or enabled)."

	# remove "install" and "remove" lines, if the module doesn't install anything (eg, service-only module)
	[[ -n "$packages" ]] || text=`grep -Pve " (install|remove) " <<< "$text"`

	# remove "enable" and "disable" lines, if the module doesn't have any services (eg, software-only module)
	[[ -n "$services" ]] || text=`grep -Pve " (enable|disable) " <<< "$text"`

	# remove the "status" line, if the modules doesn't have status (eg, internal module
	# that doesn't install any packages and doesn't have any services)
	[[ -n "$packages$services" ]] || text=`grep -Pv " status " <<< "$text"`

	echo "$text"
	[[ -z "$extra" ]] || echo "$extra"
	echo
}

module_default_install()
{
	local packages="$1"
	echo "Installing $packages..."
	pkg_install $packages
}

module_default_remove()
{
	local packages="$1"
	echo "Removing $packages..."
	pkg_remove $packages
}

module_default_status()
{
	local packages="$1" services="$2"
	[[ -z "$services" ]] || srv_enabled $services || return 1
	[[ -z "$packages" ]] || pkg_installed $packages
}
