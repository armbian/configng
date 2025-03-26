# checkpoint.sh

my_module="checkpoint"

module_options+=(
	["$my_module,author"]="@dimitry-ishenko"
	["$my_module,feature"]="checkpoint"
	["$my_module,example"]="debug help info reset total"
	["$my_module,desc"]="Manage checkpoints"
	["$my_module,status"]="Active"
	["$my_module,group"]="Development"
)

_checkpoint_add()
{
	local time=$(date +%s)

	if [[ -n "$DEBUG" ]]; then
		printf "%-30s %4d sec\n" "$1" $((time - _checkpoint_time))
	else
		echo "$1"
	fi

	_checkpoint_time="$time"
}

_checkpoint_help()
{
	echo "
Usage: ${module_options[$my_module,feature]} <action> <message>
Where <action> is one of:
	debug      Show message in debug mode (DEBUG non-zero).
	help       Show this help screen.
	info       Show message in UI or debug mode.
	reset      (Re)set starting point.
	total      Show total elapsed time (and reset).
"
}

_checkpoint_reset()
{
	_checkpoint_start=$(date +%s)
	_checkpoint_time=$_checkpoint_start
}
_checkpoint_reset

_checkpoint_total()
{
	_checkpoint_time=$_checkpoint_start
	_checkpoint_add "TOTAL time elapsed"
	_checkpoint_reset
}

checkpoint()
{
	local exit_code=$?

	case "$1" in
		debug) [[ -n "$DEBUG" ]] && _checkpoint_add "$2";;
		help)  _checkpoint_help;;
		info)  [[ -n "${UXMODE}${DEBUG}" ]] && _checkpoint_add "$2";;
		reset) _checkpoint_reset;;
		total) [[ -n "$DEBUG" ]] && _checkpoint_total;;
	esac

	return $exit_code
}
