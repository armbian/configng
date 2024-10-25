module_options+=(
	["sanitize_input,author"]=""
	["sanitize_input,ref_link"]=""
	["sanitize_input,feature"]="sanitize_input"
	["sanitize_input,desc"]="sanitize input cli"
	["sanitize_input,example"]="sanitize_input"
	["sanitize_input,status"]="Pending Review"
	["sanitize_input,doc_link"]=""
)
#
# sanitize input cli
#
sanitize_input() {
	local sanitized_input=()
	for arg in "$@"; do
		if [[ $arg =~ ^[a-zA-Z0-9_=]+$ ]]; then
			sanitized_input+=("$arg")
		else
			echo "Invalid argument: $arg"
			exit 1
		fi
	done
	echo "${sanitized_input[@]}"
}

