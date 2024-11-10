module_options+=(
    ["set_software_json,author"]="@Tearran"
    ["set_software_json,ref_link"]=""
    ["set_software_json,feature"]="set_software_json"
    ["set_software_json,desc"]="Generate JSON-like object file."
    ["set_software_json,example"]="help install uninstall check"
    ["set_software_json,status"]="review"
)

set_software_json() {
    # Start building the JSON structure
    {
        echo "{"
        echo "  \"menu\": ["
        echo "    {"
        echo "      \"id\": \"Software\","
        echo "      \"description\": \"Description ...\","
        echo "      \"sub\": ["

        # Initialize arrays for handling parent-child relationships and direct features
        declare -A parent_map
        declare -A parent_counters
        features=()

        # Collect all features to organize them by parent_id
        for key in "${!software_module_options[@]}"; do
            if [[ $key == *",feature"* ]]; then
                features+=("$key")
            fi
        done

        # First pass to organize features into parent_map by parent_id
        for feature in "${features[@]}"; do
            feature_name="${software_module_options[${feature}]}"
            parent_id="${software_module_options[${feature_name},parent_id]}"
            desc="${software_module_options[${feature_name},desc]}"
            status="${software_module_options[${feature_name},status]}"
            author="${software_module_options[${feature_name},author]}"
            ref_link="${software_module_options[${feature_name},ref_link]}"

            # Format the counter based on the parent_id
            parent_prefix="${parent_id:0:3}"
            parent_prefix="${parent_prefix^^}"  # Convert to uppercase

            # Increment the counter for the parent_id
            if [[ -z "${parent_counters[$parent_id]}" ]]; then
                parent_counters[$parent_id]=0
            else
                parent_counters[$parent_id]=$((parent_counters[$parent_id] + 1))
            fi

            # Generate the unique ID based on parent_prefix and formatted counter
            printf -v formatted_counter "%02d" "${parent_counters[$parent_id]}"
            unique_id="${parent_prefix}${formatted_counter}"

            # Build the feature JSON structure
            feature_json="{"
            feature_json+="\"id\": \"$unique_id\", "
            feature_json+="\"description\": \"$desc\", "
            feature_json+="\"command\": [\"see_menu $feature_name\"], "
            feature_json+="\"status\": \"$status\", "
            feature_json+="\"author\": \"$author\", "
            feature_json+="\"src_reference\": \"$ref_link\""

            # Add condition if available
            if [[ -n "$feature_name" ]]; then
                feature_json+=", \"condition\": \"\""
            fi
            feature_json+="}"

            # Append the feature to the appropriate parent in the parent_map
            if [[ -n "$parent_id" ]]; then
                parent_map["$parent_id"]+="$feature_json,"
            fi
        done

        # Output JSON for each parent, handling commas correctly
        parent_index=0
        parent_count=${#parent_map[@]}
        for parent_id in "${!parent_map[@]}"; do
            # Trim the trailing comma from the parent's features list
            parent_features="${parent_map[$parent_id]}"
            parent_features="${parent_features%,}"

            # Check if parent_id is "Software" or a nested parent
            if [[ "$parent_id" == "Software" ]]; then
                echo "$parent_features"
            else
                # Start the parent block
                echo "        {"
                echo "          \"id\": \"$parent_id\","
                echo "          \"description\": \"Parent menu for $parent_id\","
                echo "          \"sub\": ["
                echo "            $parent_features"
                echo "          ]"
                echo "        }"
            fi

            # Print a comma after the parent block if it's not the last parent
            if [[ $parent_index -lt $((parent_count - 1)) ]]; then
                echo ","
            fi
            parent_index=$((parent_index + 1))
        done

        # Close the root structure
        echo "      ]"
        echo "    }"
        echo "  ]"
        echo "}"
    } | jq .  # Pipe the output to jq for pretty-printing
}

# Run the function to generate and pretty-print the JSON
#set_software_json
