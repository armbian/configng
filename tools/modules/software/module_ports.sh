
module_options+=(
	["module_cockpit,author"]="@armbian"
	["module_cockpit,maintainer"]="@Tearran"
	["module_list_ports,feature"]="module_list_ports"
	["module_list_ports,example"]=""
	["module_list_ports,desc"]="Lists ports info and conflicts"
	["module_list_ports,ports"]="80 443 22 21 587 124"
	["module_list_ports,status"]="review"
)

	# Function to iterate over all module_options ports and detect conflicts
function module_list_ports() {
	declare -A port_usage

	for key in "${!module_options[@]}"; do
	if [[ $key == *,ports ]]; then
		IFS=' ' read -r -a ports <<< "${module_options[$key]}"
		for port in "${ports[@]}"; do
		((port_usage[$port]++))
		done
	fi
	done

	for key in "${!module_options[@]}"; do
	if [[ $key == *,ports ]]; then
		echo "${key%*,ports}:"
		IFS=' ' read -r -a ports <<< "${module_options[$key]}"
		for port in "${ports[@]}"; do
			echo "$port"
			if [[ ${port_usage[$port]} -gt 1 ]]; then
				echo "Conflict: Port $port is used by multiple modules"
			fi
		done
	fi
	done
}
