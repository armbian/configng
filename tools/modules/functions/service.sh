# service.sh

declare -A module_options
module_options+=(
	["service,author"]="@dimitry-ishenko"
	["service,desc"]="Wrapper for service manipulation"
	["service,example"]="service install some.service"
	["service,feature"]="service"
	["service,status"]="active"
)

function service()
{
	# ignore these commands, if running inside container
	[[ "$1" =~ ^(reload|restart|start|status|stop)$ ]] && systemd-detect-virt -qc && return 0
	systemctl "$@"
}
