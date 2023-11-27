#!/bin/bash

# Get the directory of the script
script_dir=$(dirname "$(readlink -f "$0")")

# Define the target file
target_file="/usr/sbin/armbian-config"

# Create the symbolic link in the script's directory

# Creat a renamed symbolic link to armbian-config to adress legacy
[[ ! -f "$script_dir/armbian-configlg" ]] && ln -s "$target_file" "$script_dir/armbian-configlg" || echo "symbolic link already exists"
# Creat a Branding symbolic link to armbian-configng-dev

# Use case loading banded libraies
[[ ! -f "$script_dir/jampi-config" ]] && ln -s "$script_dir/armbian-configng-dev" "$script_dir/jampi-config" || echo "symbolic link already exists"
[[ ! -f "$script_dir/armbian-configng" ]] && ln -s "$script_dir/armbian-configng-dev" "$script_dir/armbian-configng" || echo "symbolic link already exists"