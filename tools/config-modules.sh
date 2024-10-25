#!/bin/bash

# Define the source and destination directories
SCRIPT_DIR="$(dirname "$0")"
SRC_DIR="$SCRIPT_DIR/modules"
DEST_DIR="$SCRIPT_DIR/../lib/armbian-config"

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
bash ./tools/config-jobs.sh -p
