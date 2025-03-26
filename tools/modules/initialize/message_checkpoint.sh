module_options+=(
	["set_checkpoint,author"]="@armbian"
	["set_checkpoint,maintainer"]="@igorpecovnik"
	["set_checkpoint,feature"]="set_checkpoint"
	["set_checkpoint,example"]="help start mark stop show"
	["set_checkpoint,desc"]="Helper module for timing code execution"
	["set_checkpoint,status"]=""
	["set_checkpoint,doc_link"]=""
	["set_checkpoint,group"]="Development"
	["set_checkpoint,port"]=""
	["set_checkpoint,arch"]="x86-64 arm64"
)

module_options+=(
	["debug_checkpoint,author"]="@armbian"
	["debug_checkpoint,maintainer"]="@igorpecovnik"
	["debug_checkpoint,feature"]="debug_checkpoint"
	["debug_checkpoint,example"]="help start mark stop show"
	["debug_checkpoint,desc"]="Helper module for debug info"
	["debug_checkpoint,status"]=""
	["debug_checkpoint,doc_link"]=""
	["debug_checkpoint,group"]="Development"
	["debug_checkpoint,port"]=""
	["debug_checkpoint,arch"]="x86-64 arm64"
)
#
# Function to manage timer with multiple checkpoints
function set_checkpoint() {
	case "$1" in
		help)
			echo "Usage: set_checkpoint <start|stop|mark|show> [description] [show]"
			echo "Commands:"
			echo "  start              Start the timer."
			echo "  stop               Stop the timer."
			echo "  mark [description] [time] Mark a checkpoint with an optional description and an optional flag to show the output."
			echo "  show               Show the total elapsed time and checkpoints."
		;;
		start)
			set_checkpoint_START=$(date +%s)
			set_checkpoint_CHECKPOINTS=()
			set_checkpoint_DESCRIPTIONS=()
			set_checkpoint_PREV=$set_checkpoint_START
		;;
		stop)
			set_checkpoint_STOP=$(date +%s)
		;;
		mark)
			if [[ "$UXMODE" == "true" || -n "$DEBUG" ]]; then
				local checkpoint_time=$(date +%s)
				local checkpoint_duration=$((checkpoint_time - set_checkpoint_PREV))
				set_checkpoint_PREV=$checkpoint_time
				set_checkpoint_CHECKPOINTS+=($checkpoint_time)
				set_checkpoint_DESCRIPTIONS+=("$2")
				local count=${#set_checkpoint_DESCRIPTIONS[@]}
				# No debug UX mode debug level 1 defaulted here
				[[ -z "$DEBUG" ]] && printf "%-30s %10d seconds\n" "$2 " "${checkpoint_duration}"

				# debug level 2 shows all message
				[[ "$DEBUG" -eq 2 ]] && printf "%-30s %10d seconds\n" "$2 " "${checkpoint_duration}"
			fi
		;;
		show)
			[[ -z "$set_checkpoint_STOP" ]]	&& set_checkpoint stop
			if [[ -n "$set_checkpoint_START" && -n "$set_checkpoint_STOP" ]]; then
				set_checkpoint_DURATION=$((set_checkpoint_STOP - set_checkpoint_START))
				printf "%-30s: %d seconds\n" "Total elapsed time" "${set_checkpoint_DURATION}"

				local previous_time=$set_checkpoint_START
				for i in "${!set_checkpoint_CHECKPOINTS[@]}"; do
				local checkpoint_time=${set_checkpoint_CHECKPOINTS[$i]}
				local checkpoint_duration=$((checkpoint_time - previous_time))
				local description=${set_checkpoint_DESCRIPTIONS[$i]}
				printf "%-30s: %d seconds\n" "${description:-Checkpoint $((i+1))}" "${checkpoint_duration}"
				previous_time=$checkpoint_time
				done
			else
				echo "Timer has not been started and stopped properly."
			fi
		;;
		*)
			echo "Usage: set_checkpoint <start|stop|mark|show> [description]"
		;;
	esac
}

# Example usage
# set_checkpoint aluse with debugging
#checkpoint() {
#	case "$1" in
#		start|stop|mark|show)
#			set_checkpoint "$1" "$2"
#		;;
#		debug)
#			[[ -n "$DEBUG" && -n $tools_dir ]] && set_checkpoint mark "$2"
#		;;
#		help)
#			set_checkpoint help
#			echo "  debug              DEBUG checkpoint message"
#		;;
#		*)
#			echo "Invalid command. Use: help, start, stop, mark, debug, show"
#		;;
#	esac
#}
