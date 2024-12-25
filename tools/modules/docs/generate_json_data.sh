

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
		echo "    \"condition\": \" \","
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


function generate_json_data() {
	set_json_data | jq '
	# Define an array of allowed software groups
	def softwareGroups: ["WebHosting", "Netconfig", "Downloaders", "Database", "DNS", "DevTools", "HomeAutomation", "Benchy", "Containers", "Media", "Monitoring", "Management"];

	{
	"menu": [
	{
		"id": "Software",
		"description": "Run/Install 3rd party applications",
		"sub": (
		group_by(.group)
		# Skip grouped arrays where the group is null, empty, or not in softwareGroups
		| map(select(.[0].group != null and .[0].group != "" and (.[0].group | IN(softwareGroups[]))))
		| map({
		"id": .[0].group,
		"description": .[0].group,
		"sub": (
			map({
			"id": .id,
			"description": .description,
			"command": [("see_menu " + .feature)],
			"options": ("help " + .options + " status"),
			"status": .status,
			"condition": "",
			"author": .author
			})
		)
		})
		)
	}
	]
	}
	'
	}

# Test Function
interface_json_data() {
	# Convert the example string to an array
	local commands=("raw" "mnu" "top" "sub" "help")
	json_data=$(generate_software_json)
	case "$1" in

	"${commands[0]}")
		echo "Setting JSON data to file..."
		set_json_data | jq --tab --indent 4 '.' > tools/json/config.temp.json
	;;
	"${commands[1]}")
		echo "Generating JSON data..."
		generate_software_json | jq --tab --indent 4 '.' > tools/json/config.temp.json
	;;
	"${commands[2]}")
		generate_top_menu "$json_data"
	;;
	"${commands[3]}")
		generate_menu "Software" "$json_data"
	;;
	"${commands[-1]}")
		echo "Usage: interface_json_data <command>"
		echo "Available commands:"
		echo -e "\traw\t- Set flat JSON data to a file for inspection not used"
		echo -e "\tmnu\t- Generate the Menu JSON data to file for inspection not used"
		echo -e "\ttop\t- Show the top menu using the JSON data."
		echo -e "\tsub\t- Show the Software menu using the JSON data."
	;;
	esac
}
