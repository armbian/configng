#!/bin/bash

# Function to set the path
function Path::set_bashrc(){

    # Check if the path is already set
if grep -q "configng" ~/.bashrc; then
    echo "Path already set"
    exit 0
else
    echo "Setting path"
    # Add the path to the bashrc file
    echo "export PATH=$PATH:~/configng/bin" >> ~/.bashrc
    # Add the library path to the bashrc file
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/configng/lib" >> ~/.bashrc
fi

}


# Function to tar archive the repository
function Archive::tar(){
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

    # Return success
    return 0
}