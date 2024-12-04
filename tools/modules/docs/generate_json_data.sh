
module_options+=(
	["generate_json_options,author"]="@Tearran"
	["generate_json_options,ref_link"]=""
	["generate_json_options,feature"]="generate_json_options"
	["generate_json_options,desc"]="Generate JSON-like object file."
	["generate_json_options,example"]=""
	["generate_json_options,status"]="review"
	["generate_json_options,doc_link"]=""
)
#
# Function to generate a JSON-like object file
#
function get_json_data() {
	local i=0

	features=()
	for key in "${!module_options[@]}"; do
		if [[ $key == *",feature" ]]; then
		features+=("${module_options[$key]}")
		fi
	done

	{
		#echo -e "["

		for feature in "${features[@]}"; do
		feature_prefix=$(echo "${feature:0:3}" | tr '[:lower:]' '[:upper:]') # Extract first 3 letters and convert to uppercase

		i=$((i + 1))
		id=$(printf "%s%03d" "$feature_prefix" "$i") # Combine prefix with padded number

		# Get keys pairs
		desc_key="${feature},desc"
		example_key="${feature},example"
		author_key="${feature},author"
		ref_key="${feature},ref_link"
		status_key="${feature},status"
		doc_key="${feature},doc_link"
		# Get array info
		author="${module_options[$author_key]}"
		ref_link="${module_options[$ref_key]}"
		status="${module_options[$status_key]}"
		doc_link="${module_options[$doc_key]}"
		desc="${module_options[$desc_key]}"
		example="${module_options[$example_key]}"


		echo "  {"
		echo "    \"id\": \"$id\","
		echo "    \"id\": \"$feature\","
		echo "    \"description\": \"$desc ($feature) \","
		echo "    \"command\": [ \"see_menu $feature\" ],"
		echo "    \"status\": \"test\","
		echo "    \"condition\": \"[ -n see_ping ]\","
		echo "    \"author\": \"$author\""
		if [ $i -ne ${#features[@]} ]; then
			echo "  },"
		else
			echo "  }"
		fi
		done
		#echo "]"

	} #| jq .
}


set_json_head() {
	echo -e "{\n\"menu\" : ["

}

set_json_foot() {
	echo "]"
	echo "}"
}

generate_json_data(){
	{
		set_json_head
		echo -e "{\n\"id\" : \"Module\","
		echo -e "\"description\": \"Development and testing\","
		echo -e "\"sub\": ["
		get_json_data
		echo "]"
		echo "}"
		set_json_foot

	} | jq .
}


interface_json_data() {
# Test Function

	#set_json_data > tools/json/config.temp.json
	#json_file="$tools_dir/json/config.temp.json"
	json_data=$(generate_json_data)
	generate_top_menu "$json_data"
	#generate_menu "Modules" "$json_data"


}
