

base_module_options+=(
	["merge_software_info,author"]="@Tearran"
	["merge_software_info,feature"]="merge_software_info"
	["merge_software_info,desc"]="Merge software_module_options with module_options for combatibility."
	["merge_software_info,example"]=""
	["merge_software_info,status"]="review"
)

merge_software_info() {

	for key in "${!software_module_options[@]}"; do
	# Update only if key does not exist or differs in value
		if [[ -z "${module_options[$key]}" || "${module_options[$key]}" != "${software_module_options[$key]}" ]]; then
			module_options["$key"]="${software_module_options[$key]}"
			#echo "Merging $key: ${software_module_options[$key]}"
		fi
	done
}

base_module_options+=(
	["merge_base_info,author"]="@Tearran"
	["merge_base_info,feature"]="merge_base_info"
	["merge_base_info,desc"]="Merge base_module_options with module_options for combatibility."
	["merge_base_info,example"]=""
	["merge_base_info,status"]="review"
)

merge_base_info() {

	for key in "${!base_module_options[@]}"; do
	# Update only if key does not exist or differs in value
		if [[ -z "${module_options[$key]}" || "${module_options[$key]}" != "${base_module_options[$key]}" ]]; then
			module_options["$key"]="${base_module_options[$key]}"
			#echo "Merging $key: ${base_module_options[$key]}"
		fi
	done
}
