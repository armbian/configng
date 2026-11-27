# service.sh

# internal function
_srv_system_running() { [[ $(systemctl is-system-running) =~ ^(running|degraded)$ ]]; }

declare -A module_options
module_options+=(
	["srv_active,author"]="@dimitry-ishenko"
	["srv_active,desc"]="Check if service is active"
	["srv_active,example"]="srv_active ssh.service"
	["srv_active,feature"]="srv_active"
	["srv_active,status"]="Interface"
)

srv_active()
{
	# fail inside container
	_srv_system_running && systemctl is-active --quiet "$@"
}

declare -A module_options
module_options+=(
	["srv_daemon_reload,author"]="@dimitry-ishenko"
	["srv_daemon_reload,desc"]="Reload systemd configuration"
	["srv_daemon_reload,example"]="srv_daemon_reload"
	["srv_daemon_reload,feature"]="srv_daemon_reload"
	["srv_daemon_reload,status"]="Interface"
)

srv_daemon_reload()
{
	# ignore inside container
	_srv_system_running && systemctl daemon-reload || true
}

module_options+=(
	["srv_disable,author"]="@dimitry-ishenko"
	["srv_disable,desc"]="Disable service"
	["srv_disable,example"]="srv_disable ssh.service"
	["srv_disable,feature"]="srv_disable"
	["srv_disable,status"]="Interface"
)

srv_disable() { systemctl disable "$@"; }

module_options+=(
	["srv_enable,author"]="@dimitry-ishenko"
	["srv_enable,desc"]="Enable service"
	["srv_enable,example"]="srv_enable ssh.service"
	["srv_enable,feature"]="srv_enable"
	["srv_enable,status"]="Interface"
)

srv_enable() { systemctl enable "$@"; }

module_options+=(
	["srv_enabled,author"]="@dimitry-ishenko"
	["srv_enabled,desc"]="Check if service is enabled"
	["srv_enabled,example"]="srv_enabled ssh.service"
	["srv_enabled,feature"]="srv_enabled"
	["srv_enabled,status"]="Interface"
)

srv_enabled() { systemctl is-enabled "$@"; }

module_options+=(
	["srv_mask,author"]="@dimitry-ishenko"
	["srv_mask,desc"]="Mask service"
	["srv_mask,example"]="srv_mask ssh.service"
	["srv_mask,feature"]="srv_mask"
	["srv_mask,status"]="Interface"
)

srv_mask() { systemctl mask "$@"; }

module_options+=(
	["srv_reload,author"]="@dimitry-ishenko"
	["srv_reload,desc"]="Reload service"
	["srv_reload,example"]="srv_reload ssh.service"
	["srv_reload,feature"]="srv_reload"
	["srv_reload,status"]="Interface"
)

srv_reload()
{
	# ignore inside container
	_srv_system_running && systemctl reload "$@" || true
}

module_options+=(
	["srv_restart,author"]="@dimitry-ishenko"
	["srv_restart,desc"]="Restart service"
	["srv_restart,example"]="srv_restart ssh.service"
	["srv_restart,feature"]="srv_restart"
	["srv_restart,status"]="Interface"
)

srv_restart()
{
	# ignore inside container
	_srv_system_running && systemctl restart "$@" || true
}

module_options+=(
	["srv_start,author"]="@dimitry-ishenko"
	["srv_start,desc"]="Start service"
	["srv_start,example"]="srv_start ssh.service"
	["srv_start,feature"]="srv_start"
	["srv_start,status"]="Interface"
)

srv_start()
{
	# ignore inside container
	_srv_system_running && systemctl start "$@" || true
}

module_options+=(
	["srv_status,author"]="@dimitry-ishenko"
	["srv_status,desc"]="Show service status information"
	["srv_status,example"]="srv_status ssh.service"
	["srv_status,feature"]="srv_status"
	["srv_status,status"]="Interface"
)

srv_status() { systemctl status "$@"; }

module_options+=(
	["srv_stop,author"]="@dimitry-ishenko"
	["srv_stop,desc"]="Stop service"
	["srv_stop,example"]="srv_stop ssh.service"
	["srv_stop,feature"]="srv_stop"
	["srv_stop,status"]="Interface"
)

srv_stop()
{
	# ignore inside container
	_srv_system_running && systemctl stop "$@" || true
}

module_options+=(
	["srv_unmask,author"]="@dimitry-ishenko"
	["srv_unmask,desc"]="Unmask service"
	["srv_unmask,example"]="srv_unmask ssh.service"
	["srv_unmask,feature"]="srv_unmask"
	["srv_unmask,status"]="Interface"
)

srv_unmask() { systemctl unmask "$@"; }

module_options+=(
	["srv_power,author"]="@igorpecovnik"
	["srv_power,desc"]="Reboot or power off; ask before overriding shutdown block inhibitors"
	["srv_power,example"]="srv_power reboot|poweroff"
	["srv_power,feature"]="srv_power"
	["srv_power,status"]="Interface"
)

# Print "WHO (USER): WHY" for each shutdown block inhibitor. WHO and WHY can contain spaces.
_srv_power_blockers()
{
	systemd-inhibit --list --no-pager 2> /dev/null | awk '
		NR == 1 { w = index($0, "WHY"); m = index($0, "MODE"); next }
		$NF == "block" && substr($0, 1, w - 1) ~ /shutdown/ && match($0, / +[0-9]+ +[^ ]+ +/) {
			who = substr($0, 1, RSTART - 1); split(substr($0, RSTART, RLENGTH), f, " ")
			why = substr($0, w, m - w); sub(/ +$/, "", why)
			printf "%s (%s): %s\n", who, f[2], why
		}'
}

# Ask before overriding shutdown block inhibitors.
# Without blockers, show why logind refused (${3}), for example other logged-in users.
_srv_power_confirm()
{
	local text="These programs block ${1}:\n\n${2}\n\nInterrupt them and ${1} anyway?"
	[[ -n "$2" ]] || text="The ${1} request was refused:\n\n${3:-no reason given}\n\n${1^} anyway?"
	dialog_yesno "Shutdown blocked" "$text" "Yes" "No" 0 110
}

# Call logind only: systemctl starts the target through PID 1 after some logind errors,
# and that skips the delay inhibitors. Flags of RebootWithFlags and PowerOffWithFlags
# (systemd 248+): 1 = root obeys block inhibitors, 16 = skip block inhibitors (256+).
_srv_power_logind()
{
	busctl call --allow-interactive-authorization=no --timeout=30 \
		org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager \
		"${1}WithFlags" t "$2" 2>&1 > /dev/null
}

# Ask before overriding block inhibitors: systemd < 257 lets root override them silently.
# Delay inhibitors get PrepareForShutdown: logind waits until they end or time out.
# On systemd 257+, logind needs polkit to let root override block inhibitors:
# share/polkit-1/rules.d. If logind refuses, show why and keep the system running.
srv_power()
{
	local action="$1" method blockers err skip=0
	case "$action" in
		reboot) method=Reboot ;;
		poweroff) method=PowerOff ;;
		*) return 1 ;;
	esac
	# systemd < 257: root ignores block inhibitors without flag 1, and has no flag 16.
	(( $(systemctl --version | awk 'NR == 1 { print $2 + 0 }') >= 257 )) && skip=16
	blockers=$(_srv_power_blockers)
	if [[ -n "$blockers" ]]; then
		_srv_power_confirm "$action" "$blockers" || return 1
	else
		# flag 1: refuse a block inhibitor that starts after the scan
		err=$(_srv_power_logind "$method" 1) && return 0
		_srv_power_confirm "$action" "$(_srv_power_blockers)" "$err" || return 1
	fi
	err=$(_srv_power_logind "$method" "$skip") && return 0
	dialog_msgbox "Shutdown refused" "The ${action} request was refused:\n\n${err:-no reason given}\n\nThe system did not ${action}." 0 110
	return 1
}
