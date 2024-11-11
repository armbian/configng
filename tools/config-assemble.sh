#!/bin/bash


SCRIPT_DIR="$(dirname "$0")"
LIB_DIR="$SCRIPT_DIR/../lib/armbian-config"

DEFAULT_FILE="$LIB_DIR/config.jobs.json"
DEFAULT_DIR="$SCRIPT_DIR/json"


# Define the module source and destination directories
SRC_DIR="$SCRIPT_DIR/modules"
DEST_DIR="$SCRIPT_DIR/../lib/armbian-config"
# change to the script directory
cd "$SCRIPT_DIR"/..


declare -A module_options
declare -A base_module_options
declare -A software_module_options

# Function to display the help message
for file in "$SRC_DIR"/*/module_*.sh; do
  [ -e "$file" ] && source "$file"
done

merge_software_info
merge_base_info


print_help() {
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo "  -h Display this help message"
	echo "  -p Assemble module and jobs for production"
	echo "  -t Assemble module and jobs  for testing"

}

function merge_modules(){

	[[ -d "$DEST_DIR" ]] && rm -rf "$DEST_DIR" && echo "remove $DEST_DIR"

	# Create the destination directory if it doesn't exist
	mkdir -p "$DEST_DIR"

	# Find all .sh files in the source directory and its subdirectories
	find "$SRC_DIR" -type f -name "*.sh" | while read -r file; do
		# Extract the parent directory name
		parent_dir=$(basename "$(dirname "$file")")

		# Define the output file name based on the parent directory
		output_file="$DEST_DIR/config.$parent_dir.sh"

		# Append the content of the current file to the output file
		cat "$file" >> "$output_file"

		# Add a newline for separation
		echo "" >> "$output_file"
	done

	echo "All scripts have been combined and placed into $DEST_DIR"


}

# Function to split JSON into smaller files
function split_json() {
	input_file="$1"
	output_dir="$DEFAULT_DIR"

	# Check if input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "Error: Input file '$input_file' does not exist."
		return 1
	fi

	# Create output directory if it doesn't exist
	if [[ ! -d "$output_dir" ]]; then
		mkdir -p "$output_dir"
	fi

	# Extract the total number of menu items
	count=$(jq '.menu | length' "$input_file")

	# Iterate over each menu item and save it as a separate JSON file
	for ((i=0; i<count; i++)); do
		item=$(jq ".menu[$i]" "$input_file")
		menu_id=$(jq -r ".menu[$i].id" "$input_file") # Extract the 'id' of the current item
		filename=$(echo "$menu_id" | tr '[:upper:]' '[:lower:]') # Convert filename to lowercase

		# Save backup file with proper indentation
		echo "{\"menu\": [$item]}" | jq --indent 4 '.' > "$output_dir/config.${filename}.json"

		# Extract 'sub' and replace it with 'menu' if it exists
		# jq ".menu[$i] | if has(\"sub\") then .sub | {menu: .} else {menu: [.] } end" "$input_file" > "$output_dir/config.${filename}.json"
	done

	echo "Splitting and transformation completed. Files are saved in '$output_dir'."

}

# Function to join JSON files into a single file with enforced ordering
function join_json_testing() {
	input_dir="$DEFAULT_DIR"
	output_file="$1"

	# Check if input directory exists
	if [[ ! -d "$input_dir" ]]; then
		echo "Error: Input directory '$input_dir' does not exist."
		return 1
	fi

	# Initialize an empty array for holding the merged JSON data
	merged_json="[]"

	# Define desired order for menu items (IDs)
	declare -a ordered_ids=(
		"System"
		"Network"
		"Localisation"
		"Software"
		"Help"
	)

	# Loop through ordered IDs to extract menu items in the correct order
	for id in "${ordered_ids[@]}"; do
		for file in "$input_dir"/*.json; do
			if [[ -f "$file" ]]; then
			# Find item matching the current ID
			item=$(jq --arg id "$id" '.menu[] | select(.id == $id)' "$file" 2>/dev/null)
				if [[ -n "$item" ]]; then
					merged_json=$(jq --argjson new_item "$item" '. + [$new_item]' <<< "$merged_json")
				fi
			fi
		done
	done

	# Construct the final JSON structure
	final_json=$(jq -n --argjson menu "$merged_json" '{"menu": $menu}')

	# Write the final JSON structure to a file
	echo "$final_json" | jq --indent 4 '.' > "$output_file"

	echo "JSON files rejoined into '$output_file'."
}


# Function to join JSON files into a single file with enforced ordering
function join_json_production() {

	input_dir="$DEFAULT_DIR"
	output_file="$1"

	# Check if input directory exists
	if [[ ! -d "$input_dir" ]]; then
		echo "Error: Input directory '$input_dir' does not exist."
		return 1
	fi

	# Initialize an empty array for holding the merged JSON data
	merged_json="[]"

	# Define desired order for menu items (IDs)
	declare -a ordered_ids=(
		"System"
		"Network"
		"Localisation"
		"Software"
		"Help"
	)

		# Function to recursively filter out disabled items
		filter_disabled() {
		jq 'walk(
			if type == "object" and has("status") and .status == "Disabled" then
			empty
			else
			.
			end
		)'
		}

	# Loop through ordered IDs to extract menu items in the correct order
	for id in "${ordered_ids[@]}"; do
		for file in "$input_dir"/*.json; do
			if [[ -f "$file" ]]; then
				# Find item matching the current ID, filter out disabled items
				item=$(jq --arg id "$id" '.menu[] | select(.id == $id)' "$file" 2>/dev/null | filter_disabled)
				if [[ -n "$item" ]]; then
					merged_json=$(jq --argjson new_item "$item" '. + [$new_item]' <<< "$merged_json")
				fi
			fi
		done
	done

	# Construct the final JSON structure
	final_json=$(jq -n --argjson menu "$merged_json" '{"menu": $menu}')

	# Write the final JSON structure to a file
	echo "$final_json" | jq --indent 4 '.' > "$output_file"

	echo "JSON files rejoined into '$output_file'."
}

function source_module_options() {

	declare -A module_options
	declare -A base_module_options
	declare -A software_module_options

	for file in "$SRC_DIR"/*/module_*.sh; do
		[ -e "$file" ] && source "$file"
	done

	merge_software_info
	merge_base_info

}

# Main script logic with case statement
case "$1" in
    -n|--noint)
        shift
        if [[ -z "$1" || "$1" == "help" ]]; then
            see_base_list
            see_software_list
            exit 0
        fi
        option="$1"
        shift
        # args=$(sanitize_input "$@")
	args=$("$@")
        # echo -e "\"$option\" \"$args\""
        "$option" "$args"
        exit 0
        ;;
    -s|--split)
        if [[ -z "$2" ]]; then
            echo "Error: Missing arguments for -s option."
            print_help
            exit 1
        fi
        split_json "$2"
        ;;
    -t|--test)
        if [[ -n "$2" ]]; then
            cd "$SCRIPT_DIR"/..
            # Merge all modules into a single file
            merge_modules
            # Source the module for module_info
            source_module_options
            # Output the software JSON file
            set_software_json > "$DEFAULT_DIR/config.software.json"
            echo "Processing JSON files, please wait..."
            join_json_production "$DEFAULT_FILE"
            # Generate the markdown user file
            "$SCRIPT_DIR"/config-markdown.py -u
            # start armbian-config to manually test modules
            $SCRIPT_DIR/../bin/armbian-config
        fi
        ;;
    -p|--production)
        if [[ -n "$2" ]]; then
            merge_modules
            echo "Processing JSON files, please wait..."
            join_json_production "$2"
            "$SCRIPT_DIR"/config-markdown.py -u
        else
            merge_modules
            echo "Processing JSON files, please wait..."
            join_json_production "$DEFAULT_FILE"
            "$SCRIPT_DIR"/config-markdown.py -u
        fi
        ;;
    -h|--help)
        print_help
        ;;
    *)
        echo "Error: Invalid option."
        print_help
        exit 1
        ;;
esac


exit 0
