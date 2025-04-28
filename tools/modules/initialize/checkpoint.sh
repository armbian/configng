# checkpoint.sh

module_options+=(
	["checkpoint,author"]="@dimitry-ishenko"
	["checkpoint,feature"]="checkpoint"
	["checkpoint,example"]="debug help mark reset total"
	["checkpoint,desc"]="Manage checkpoints"
	["checkpoint,status"]="Active"
	["checkpoint,group"]="Development"
)

_checkpoint_add()
{
	local type="$1" msg="$2"

	if [[ -n "$DEBUG" ]]; then
		local time=$(date +%s)
		printf "%-30s %4d sec\n" "$msg" $((time - _checkpoint_time))
		_checkpoint_time=$time

	elif [[ -n "$UXMODE" && "$type" == mark ]]; then
		_checkpoint_time=$(date +%s)
		echo "$msg"
	fi
}

_checkpoint_help()
{
	echo "
Usage: ${module_options[checkpoint,feature]} <action> <message>
Where <action> is one of:
	debug      Show message in debug mode (DEBUG non-zero).
	help       Show this help screen.
	mark       Show message in UI or debug mode.
	reset      (Re)set starting point.
	total      Show total time and reset (in debug mode).

The 'debug' command will show time elapsed since the previous checkpoint after
the <message>. The 'mark' command will also show the elapsed time if the debug
mode is active (the DEBUG env var is non-zero).
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
	_checkpoint_add "debug" "TOTAL time elapsed"
	_checkpoint_reset
}

checkpoint()
{
	local exit_code=$?

	case "$1" in
		debug) _checkpoint_add "$1" "$2";;
		help)  _checkpoint_help;;
		mark)  _checkpoint_add "$1" "$2";;
		reset) _checkpoint_reset;;
		total) _checkpoint_total;;
	esac

	return $exit_code
}
