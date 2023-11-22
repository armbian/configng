#!/bin/bash

# Get the directory of the script
script_dir=$(dirname "$(realpath "$0")")

# Navigate to the parent Git repository
cd "$script_dir" || exit 1
git_root=$(git rev-parse --show-toplevel) || exit 1

# Get the Git commit hash
commit_hash=$(git rev-parse HEAD)

# Create a tar archive with the Git commit number in the filename
tar -czf "${git_root}/repo_archive_${commit_hash}.tar.gz" -C "$git_root" .

# Display a message
echo "Tar archive created: ${git_root}/repo_archive_${commit_hash}.tar.gz"
