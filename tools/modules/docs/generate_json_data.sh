
module_options+=(
	["generate_json_data,feature"]="generate_json_data"   # The name of the function, master KEY for the module parsing
	["generate_json_data,helpers"]="set_json_data" # Helper dependancy
	["generate_json_data,author"]="@Tearran"    # The module contributors git id
	["generate_json_data,ref_link"]="@armbian"  # The maintainer's git id or link for additional information
	["generate_json_data,desc"]="Example unattended interface module." # A short description of what the module does
	["generate_json_data,example"]="check install remove help"   # A list of $1 options the module accepts
	["generate_json_data,commands"]="install remove"   # A list of $1 options the module accepts
	["generate_json_data,status"]="Development" # Options (Disabled, Development, Software, System, Network, Loca...)
	["generate_json_data,group"]="Temp" # Long list see menu for sub groups
	["generate_json_data,port"]=""      # Ports used
	["generate_json_data,arch"]=""      # Options for Architecture information (?)
)
#
# Function to generate a JSON-like object file
#
function set_json_data() {
	local i=0

	features=()
	for key in "${!module_options[@]}"; do
		if [[ $key == *",feature" ]]; then
			features+=("${module_options[$key]}")
		fi
	done

{
	echo -e "["

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
		helpers_key="${feature},helpers"
		group_key="${feature},group"
		commands_key="${feature},commands"
		port_key="${feature},port"
		arch_key="${feature},arch"

		# Get array info
		author="${module_options[$author_key]}"
		ref_link="${module_options[$ref_key]}"
		status="${module_options[$status_key]}"
		doc_link="${module_options[$doc_key]}"
		desc="${module_options[$desc_key]}"
		example="${module_options[$example_key]}"
		helpers="${module_options[$helpers_key]}"
		group="${module_options[$group_key]}"
		commands="${module_options[$commands_key]}"
		port="${module_options[$port_key]}"
		arch="${module_options[$arch_key]}"

		echo "  {"
		echo "    \"id\": \"$id\","
		echo "    \"feature\": \"$feature\","
		echo "    \"helpers\": \"$helpers\","
		echo "    \"description\": \"$desc ($feature)\","
		echo "    \"command\": \"$feature\","
		echo "    \"options\": \"$example\","
		echo "    \"status\": \"$status\","
		echo "    \"condition\": \"$feature check\","
		echo "    \"reference\": \"$ref_link\","
		echo "    \"author\": \"$author\","
		echo "    \"group\": \"$group\","
		echo "    \"commands\": \"$commands\","
		echo "    \"port\": \"$port\","
		echo "    \"arch\": \"$arch\""

		if [ $i -ne ${#features[@]} ]; then
			echo "  },"
		else
			echo "  }"
		fi
	done
	echo "]"

} | jq .

}

generate_json_data(){
set_json_data | jq '[
	.[] |
	if (.feature | type == "string") and (.feature | startswith("module_")) then
	{
		"id": .id,
		"description": .description,
		"command": ("see_menu " + .feature),
		"options": ("help " + .options + " status"),
		"status": .status,
		"helpers": .helpers,
		"condition": .condition,
		"author": .author
	}
	else empty
	end
	]'
}




interface_json_data() {
# Test Function
# uncomment to set the data to a file
#set_json_data > tools/json/config.temp.json
#json_file="$tools_dir/json/config.temp.json

	json_data=$(generate_json_data)
	generate_top_menu "$json_data"

#generate_menu "Modules" "$json_data"
}
