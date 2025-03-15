
module_options+=(
	["module_api_files,id"]="DOC0740"
	["module_api_files,maintainer"]="@Tearran"
	["module_api_files,feature"]="module_api_files"
	["module_api_files,desc"]="Example module unattended interface."
	["module_api_files,example"]="help array json dbt test all"
	["module_api_files,status"]="Active"
	["module_api_files,about"]=""
	["module_api_files,doc_link"]="Missing"
	["module_api_files,author"]="@Tearran"
	["module_api_files,parent"]="docs"
	["module_api_files,group"]="Docs"
	["module_api_files,port"]="Unset"
	["module_api_files,arch"]="Missing"
)
#
# Function to handle the module commands for 'module_api_files'
function module_api_files() {

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_api_files,example"]}"

	# Handle the command passed to the function
	case "$1" in
		"${commands[0]}")
		echo -e "\nUsage: ${module_options["module_api_files,feature"]} <command>"
		echo -e "Commands:  ${module_options["module_api_files,example"]}"
		echo "Available commands:"
		echo -e "\tarray\t- Generate module_options files from production module_options array."
		echo -e "\tjson\t- Generate JSON object from module_options"
		echo -e "\tdbt\t- Generate DBT from module_options"
		echo -e "\ttest\t- Generate unit-test CONF from module_options."
		echo -e "\tall\t- Generate All above."
		echo
		;;
		"${commands[1]}")
		geneate_files_api "gen_api_array"
		;;
		"${commands[2]}")
		geneate_files_api "gen_api_json"
		;;
		"${commands[3]}")
		geneate_files_api "gen_api_dbt"
		;;
		"${commands[4]}")
		geneate_files_api "unit_test_files"
		;;
		"all")
		geneate_files_api "gen_api_array"
		geneate_files_api "gen_api_json"
		geneate_files_api "gen_api_dbt"
		geneate_files_api "unit_test_files"
		;;
		*)
		echo "${module_options["module_api_files,example"]}"
		;;
	esac
}


module_helper+=(
	["geneate_files_api,maintainer"]="@Tearran"
	["geneate_files_api,feature"]="geneate_files_api"
	["geneate_files_api,example"]=""
	["geneate_files_api,desc"]="Helper to sort module_option array"
	["geneate_files_api,status"]="Active"
	["geneate_files_api,condition"]=""
	["geneate_files_api,doc_link"]=""
	["geneate_files_api,author"]="@Tearran"
	["geneate_files_api,parent"]="docs"
	["geneate_files_api,group"]="Docs"
	["geneate_files_api,port"]=""
	["geneate_files_api,arch"]=""
)
# Use production array to verify a parent/group and subgroup/subsubgroup keys are valid
# may be used to verify other keys if needed
function geneate_files_api() {
	local generator=$1
	local i=0

	features=()
	for key in "${!module_options[@]}"; do
		if [[ $key == *",feature" ]]; then
			features+=("${module_options[$key]}")
		fi
	done

	for feature in "${features[@]}"; do

		i=$((i + 1))

		# Get keys pairs
		about_key="${feature},about"
		desc_key="${feature},desc"
		example_key="${feature},example"
		author_key="${feature},author"
		ref_key="${feature},ref_link"
		status_key="${feature},status"
		doc_key="${feature},doc_link"
		group_key="${feature},group"
		commands_key="${feature},commands"
		port_key="${feature},port"
		arch_key="${feature},arch"
		maintainer_key="${feature},maintainer"
		header_key="${feature},header"
		footer_key="${feature},footer"
		# Get array info
		about="${module_options[$about_key]}"
		author="${module_options[$author_key]}"
		ref_link="${module_options[$ref_key]}"
		status="${module_options[$status_key]}"
		doc_link="${module_options[$doc_key]}"
		desc="${module_options[$desc_key]}"
		example="${module_options[$example_key]}"
		group="${module_options[$group_key]}"
		commands="${module_options[$commands_key]}"
		port="${module_options[$port_key]}"
		arch="${module_options[$arch_key]}"
		maintainer="${module_options[$maintainer_key]}"
		header="${module_options[$header_key]}"
		footer="${module_options[$footer_key]}"
		if [[ -n group ]]; then
			g=$((g + 10)) ;
			group_prefix=$(echo "${group:0:3}" | tr '[:lower:]' '[:upper:]') # Extract first 3 letters and convert to uppercase
			id=$(printf "%s%04d" "$group_prefix" "$g") # Combine prefix with padded number
		else
			id="$feature"
		fi

		# Set default values for missing fields
		doc_link="${doc_link:-Missing}"
		port="${port:-Unset}"
		arch="${arch:-Missing}"
		example="${example:-}"
		author="${author:-Unknown}"
		maintainer="${maintainer:-Needed}"
		footer="${footer:-None}"
		header="${header:-None}"
		# Use group_prefix for id
		# Check if group belongs to the software category
		case "$group" in
			WebHosting|HomeAutomation|DNS|Downloaders|Database|Upkeep|DevTools|Containers|Media|Monitoring|Management|Printing|Netconfig)
			parent="software"
			;;
			Kernel|Storage|Access|User|Updates)
			parent="system"
			;;
			Network|Wifi)
			parent="network"
			;;
			Localisation|Locals)
			parent="localisation"
			;;
			Messages|Readme|Docs)
			parent="docs"
			;;
			Core|TUI|Interface|Helper)
			parent="functions"
			;;
			*)
			parent="unknown"
			group="unknown"
			;;
		esac

		# Call the specified generator function
		if [[ $(type -t "$generator") == "function" ]]; then
			"$generator"
		else
			echo "Error: Invalid generator function '$generator'."
			return 1
		fi

	done

	chown -R "${SUDO_USER:-$USER}":"${SUDO_USER:-$USER}" "$tools_dir"
}


# adds missing keys to module_option array
gen_api_array(){

	module_options_file="$tools_dir/dev/array/${parent}/${feature}_array.sh"

	# Create the parent directory if it doesn't exist
	mkdir -p "$(dirname "$module_options_file")"

cat << EOF > "$module_options_file"
module_options+=(
	["$feature,id"]="$id"
	["$feature,maintainer"]="$maintainer"
	["$feature,feature"]="$feature"
	["$feature,desc"]="$desc"
	["$feature,example"]="$example"
	["$feature,status"]="$status"
	["$feature,about"]=""
	["$feature,doc_link"]="$doc_link"
	["$feature,author"]="$author"
	["$feature,parent"]="$parent"
	["$feature,group"]="$group"
	["$feature,port"]="$port"
	["$feature,arch"]="$arch"
)

EOF

}

#
# output json objects for each module_option
#
gen_api_json(){

	if [ "$group" != "unknown" ]; then
		[ "$parent" != "docs" ] && json_objects="$tools_dir/dev/json/${parent}/${group}/${feature}.json"
	else
		json_objects="$tools_dir/dev/json/fix-${parent}/${feature}.json"
	fi

	# Create the parent directory if it doesn't exist
	mkdir -p "$(dirname "$json_objects")"

	# Generate the JSON content and format it with jq before writing to the file
	jq --indent 4 -n --arg id "$id" \
		--arg desc "$desc" \
		--arg feature "$feature" \
		--arg author "$author" \
		--arg condition "$feature status | grep install" \
		'{
			"id": $id,
			"description": $desc,
			"command": ["see_menu \($feature)"],
			"status": "",
			"author": $author,
			"condition": $condition
		}' > "$json_objects"
}

module_helper+=(
	["gen_api_dbt,maintainer"]="@Tearran"
	["gen_api_dbt,feature"]="gen_api_dbt"
	["gen_api_dbt,example"]=""
	["gen_api_dbt,desc"]="Helper for module_api"
	["gen_api_dbt,status"]="Active"
	["gen_api_dbt,condition"]=""
	["gen_api_dbt,doc_link"]=""
	["gen_api_dbt,author"]="@Tearran"
	["gen_api_dbt,parent"]="docs"
	["gen_api_dbt,group"]="Docs"
	["gen_api_dbt,port"]=""
	["gen_api_dbt,arch"]=""
)
#
# can output a Configuration file
#
gen_api_dbt(){
	if [ "$group" != "unknown" ]; then
		dbt_file="$tools_dir/modules/${parent}/${feature}_database.dbt"
	else
		dbt_file="$tools_dir/dev/dbt/${parent}/${feature}_database.dbt"
	fi

	# Create the parent directory if it doesn't exist
	mkdir -p "$(dirname "$dbt_file")"

	# Create the .conf file with the defined variables
	{
		echo "[${feature}]"
		echo "id         = ${id}"
		echo "maintainer = ${maintainer}"
		echo "feature    = ${feature}"
		echo "desc       = ${desc}"
		echo "example    = ${example}"
		echo "status     = ${status}"
		echo "about      = ${about}"
		echo "doc_link   = ${doc_link}"
		echo "author     = ${author}"
		echo "parent     = ${parent}"
		echo "group      = ${group}"
		echo "port       = ${port}"
		echo "arch       = ${arch}"
	} > "$dbt_file"

}

#
# Testing consept to convert config file to module_option array
#
convert_dbt_array(){
	# Ensure input file is provided
	if [[ $# -ne 1 ]]; then
		echo "Usage: $0 <input_file>"
		exit 1
	fi

	input_file="$1"
	output_file="${input_file%.dbt}_array.sh"  # Generate output based on input file name

	# Extract the module name from the first line (assumes it's in [brackets])
	module_name=$(awk -F'[][]' '/^\[/{print $2; exit}' "$input_file")

	# Ensure module_name is set
	if [[ -z "$module_name" ]]; then
		echo "Error: No module name found in $input_file"
		exit 1
	fi

	# Start writing the output file
	echo "module_options+=(" > "$output_file"

	# Process key-value pairs
	awk -v module="$module_name" -F ' *= *' '
	NF == 2 {
		key=$1; value=$2;
		gsub(/"/, "\\\"", value); # Escape double quotes
		print "\t[\"" module "," key "\"]=\"" value "\"";
	}
	' "$input_file" >> "$output_file"

	# End the array
	echo ")" #>> "$output_file"

	echo "Conversion complete: $output_file"

}
#
# same testing as above
#
function dbt_to_array() {
	local ini_file=$1
	declare -gA ini_options

	while IFS='=' read -r key value; do
		key="${key%%[[:space:]]*}"   # Trim spaces around the key
		value="${value##*[[:space:]]}" # Trim spaces around the value

		if [[ -n "$key" && "${key:0:1}" != "#" && "${key:0:1}" != ";" ]]; then
			ini_options["$key"]="$value"
		fi
	done < "$ini_file"
}

module_helper+=(
	["unit_test_files,maintainer"]="@Tearran"
	["unit_test_files,feature"]="unit_test_files"
	["unit_test_files,example"]=""
	["unit_test_files,desc"]="Helper for module_api"
	["unit_test_files,status"]="Active"
	["unit_test_files,condition"]=""
	["unit_test_files,doc_link"]=""
	["unit_test_files,author"]="@Tearran"
	["unit_test_files,parent"]="docs"
	["unit_test_files,group"]="Docs"
	["unit_test_files,port"]=""
	["unit_test_files,arch"]=""
)

	# Unrefined unit-test config file for  ./test/*.conf
function unit_test_files(){
	if [ "$group" != "unknown" ] && [ -n "$id" ]; then
		conf_file="$tools_dir/dev/tests/${id}.conf"
	fi

	# Create the parent directory if it doesn't exist
	mkdir -p "$(dirname "$conf_file")"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["$feature,example"]}"

	if [[ $parent == "software" ]]; then
		if [[ " ${commands[@]} " =~ " help " && " ${commands[@]} " =~ " status " ]]; then
		{
		echo "ENABLED=true"
		echo "RELEASE=\"$arch\""
		echo "MENUID=\"$id\""
		echo ""
		echo "function testcase(){"

		for i in "${!commands[@]}"; do

			if [[ "${commands[$i]}" == "install" || "${commands[$i]}" == "setup"  ]]; then
				echo "		armbian-config --api $feature ${commands[$i]}"
				echo "		[[ -n \"\$condition\" ]]"
			elif [[ "${commands[$i]}" == "uninstall" || "${commands[$i]}" == "remove"  ]]; then
				echo "		armbian-config --api $feature ${commands[$i]}"
				echo "		[[ -z \"\$condition\" ]]"
			else
				continue
			fi
		done

		echo "}"

		} > "$conf_file"
		fi
	fi
}


