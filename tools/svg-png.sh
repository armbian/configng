#!/bin/bash

# Note: Pull requests for improvements to this script are welcome.
# Please do not create issues as they will be closed without review.
# Your understanding is appreciated.


# Function to display help message
show_help() {

    clear

    cat << EOF
Usage: $(basename "$0") [SVG_FILENAME]

This script converts an SVG file into PNG files
 sizes: 16x16, 32x32, 64x64, 128x128, and 256x256 pixels

The PNG files are placed in the appropriate size-specific folders to be used with a desktop environment.

Arguments:
  "[SVG_FILENAME]"   The name of the SVG file (without extension) to convert. Default is 'configng'.

Example:
  $(basename "$0") configng-cpu


EOF

}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi


cd "$(dirname "$0")"

svg_in=${1:-"configng"}

# Path to the SVG file
SVG_FILE="./icons/$svg_in.svg"

cp -r ./applications/ "../share"

# Output directory
OUTPUT_DIR="../share/icons/hicolor/"

mkdir -p "../share/icons/hicolor/scalable/"

cp -r ./icons/* "../share/icons/hicolor/scalable/"
# Sizes
SIZES=(16 32 64 128 256)


# Check if the SVG file exists
if [[ ! -f "$SVG_FILE" ]]; then
    echo "Error: SVG file '$SVG_FILE' does not exist."
    exit 1
fi

# Export the SVG to each size
for SIZE in "${SIZES[@]}"; do

    # Create the directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR/${SIZE}x${SIZE}/"

if [[ -n "$(command -v inkscape)" ]]; then
    inkscape "$SVG_FILE" --export-filename="$OUTPUT_DIR/${SIZE}x${SIZE}/$svg_in.png" --export-width=$SIZE --export-height=$SIZE
else
    echo "Not available. Please install inkscape."
fi


done

