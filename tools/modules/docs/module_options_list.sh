

base_module_options+=(
	["see_software_list,author"]="@Tearran"
	["see_software_list,ref_link"]=""
	["see_software_list,feature"]="see_software_list"
	["see_software_list,desc"]="Show the usage of the functions."
	["see_software_list,example"]=""
	["see_software_list,status"]="review"
	["see_software_list,doc_link"]=""
)
#
# Function to parse the key-pairs  (WIP)
see_software_list() {
	mod_message="\nSoftware modules:\n"
	# Iterate over the options
	for key in "${!software_module_options[@]}"; do
		# Split the key into function_name and type
		IFS=',' read -r function_name type <<< "$key"
		# If the type is 'long', append the option to the help message
		if [[ "$type" == "feature" ]]; then
			mod_message+="  ${software_module_options["$function_name,feature"]} - ${software_module_options["$function_name,desc"]}\n"

			if [[ -n "${software_module_options["$function_name,example"]}" ]];then
				mod_message+="    ${software_module_options["$function_name,example"]}\n"
			else
				mod_message+="    no options\n"
			fi
		fi
	done

	echo -e "$mod_message"
}


base_module_options+=(
	["see_base_list,author"]="@Tearran"
	["see_base_list,ref_link"]=""
	["see_base_list,feature"]="see_base_list"
	["see_base_list,desc"]="Show the usage of the functions."
	["see_base_list,example"]=""
	["see_base_list,status"]="review"
	["see_base_list,doc_link"]=""
)

see_base_list() {
	mod_message="\nBase modules:\n"
	# Iterate over the options
	for key in "${!base_module_options[@]}"; do
		# Split the key into function_name and type
		IFS=',' read -r function_name type <<< "$key"
		# If the type is 'long', append the option to the help message
		if [[ "$type" == "feature" ]]; then
			mod_message+="  ${base_module_options["$function_name,feature"]} - ${base_module_options["$function_name,desc"]}\n"

			if [[ -n "${base_module_options["$function_name,example"]}" ]];then
				mod_message+="    ${base_module_options["$function_name,example"]}\n"
			else
				mod_message+="    no options\n"
			fi
		fi
	done

	echo -e "$mod_message"
}
