# debug_log.sh - script-wide debug logging

module_options+=(
	["debug_log,author"]="@igorpecovnik"
	["debug_log,feature"]="debug_log"
	["debug_log,example"]="debug_log \"pkg_install: \${#pkg_names[@]} packages\""
	["debug_log,desc"]="Write a debug message to the debug log sink"
	["debug_log,status"]="Active"
	["debug_log,group"]="Development"
)

#
# Debug logging
# -------------
# Activation:
#   DEBUG=1   -> debug_log lines are captured
#   DEBUG=2   -> same + xtrace (set -x) captured via BASH_XTRACEFD
#
# Destination:
#   DEBUG_LOG=<path>  ->  append to this file (created if missing)
#   If DEBUG is set but DEBUG_LOG is unset, default to
#     /var/log/armbian-config.log when running as root, else
#     /tmp/armbian-config.log
#   If the log file cannot be opened, fall back to stderr.
#
# Callers should use `debug_log "message"`. It is always safe to call
# (it is a no-op when DEBUG is empty), so modules can instrument freely.
#

_debug_log_fd=""

_debug_log_init() {
	[[ -n "$_debug_log_fd" ]] && return 0      # already initialised
	[[ -z "$DEBUG" ]] && return 0              # not enabled

	if [[ -z "$DEBUG_LOG" ]]; then
		if [[ $EUID -eq 0 ]]; then
			DEBUG_LOG="/var/log/armbian-config.log"
		else
			DEBUG_LOG="/tmp/armbian-config.log"
		fi
	fi

	# Try to open the log file on fd 9; fall back to stderr (fd 2) on failure.
	if { exec 9>>"$DEBUG_LOG"; } 2>/dev/null; then
		_debug_log_fd=9
		export DEBUG_LOG
	else
		_debug_log_fd=2
		unset DEBUG_LOG
	fi

	# Write a session header so concatenated runs stay readable.
	printf '\n===== armbian-config debug session: %s pid=%d user=%s =====\n' \
		"$(date '+%Y-%m-%d %H:%M:%S')" "$$" "${USER:-$(id -un 2>/dev/null)}" >&${_debug_log_fd}

	# DEBUG=2 -> capture shell xtrace to the same sink.
	if [[ "$DEBUG" == 2 ]]; then
		export BASH_XTRACEFD=${_debug_log_fd}
		export PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
		set -x
	fi
}

debug_log() {
	[[ -z "$DEBUG" ]] && return 0
	_debug_log_init
	local src="${BASH_SOURCE[1]##*/}"
	local line="${BASH_LINENO[0]}"
	local fn="${FUNCNAME[1]:-main}"
	printf '%s [%s:%s %s] %s\n' \
		"$(date '+%H:%M:%S')" "$src" "$line" "$fn" "$*" >&${_debug_log_fd}
}

_debug_log_path() {
	# Used by `armbian-config --debug-log-path` and checkpoint to know where to tee.
	echo "${DEBUG_LOG:-}"
}
