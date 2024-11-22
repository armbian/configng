
#declare -A module_options

module_options+=(
	["module_atuin,author"]="@atuinsh"
	["module_atuin,maintainer"]="@armbian @Tearran"
	["module_atuin,testers"]="@Tearran"
	["module_atuin,feature"]="module_atuin"
	["module_atuin,example"]="help install remove reset"
	["module_atuin,desc"]="Module to install logout and uninstall Atuin."
	["module_atuin,remote"]="https://services.armbian.de/atuin"
	["module_atuin,port"]=""
	["module_atuin,status"]="review"
)

function module_atuin() {

	local user_name user_home
	if [[ $EUID -eq 0 ]]; then
		user_name=${SUDO_USER:-$USER} # Use SUDO_USER or fallback to $user
		user_home=$(eval echo ~"$user_name")
	else
		user_name=$USER
		user_home=$HOME
	fi

	local title="atuin"
	local condition
	condition=$(command -v atuin)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_atuin,example"]}"

	case "$1" in
		help)
			# Help Command
			echo -e "\nUsage: ${module_options["module_atuin,feature"]} <command>"
			echo -e "Commands: ${module_options["module_atuin,example"]}\n"
			echo "Available commands:"
			echo -e "  reset \t- reset config to atuin default"
			echo -e "  logout\t- Log out from $title"
			echo -e "  remove\t- Uninstall $title"
		;;
		install)
			# Install Command
			echo "Installing $title..."
			# Installation logic for Atuin
			# Uncomment the next line for actual installation
			set_atuin
			generate_atuin_config
			echo "Warning: Please exit and restart your shell to reload the changes."
		;;
		remove)
			# Remove Command
			echo "Under constrution Removing $title..."
			remove_atuin
		;;
		reset)
			echo "config reset $title to armbian defaults"
			generate_atuin_config
		;;
		*) # Unknown Command
			echo -e "Unknown command: $1\n"
			echo -e "Available commands: ${module_options["module_atuin,example"]}"
		;;
	esac
}

function set_atuin() {
	# Define variables
	atuin_url="https://github.com/atuinsh/atuin/releases/download/v18.4.0-beta.3/atuin-x86_64-unknown-linux-gnu.tar.gz"
	atuin_dir="$user_home/.atuin/bin"
	atuin_binary="atuin"
	bash_preexec_file="$user_home/.bash-preexec.sh"
	atuin_bashrc_file="$user_home/.bashrc"
	local user_name user_home
	if [[ $EUID -eq 0 ]]; then
		# Check if SUDO_USER is set
		if [ -z "$SUDO_USER" ]; then
		echo "Error: Unknown user. SUDO_USER is not set." >&2
		exit 1
		fi
		user_name=$SUDO_USER
		user_home=$(eval echo ~"$user_name")
	else
		user_name=$USER
		user_home=$HOME
	fi

	# Create target directory as the user (not as root)
	mkdir -p "$atuin_dir"
	# Ensure correct ownership (user should own these files)
	chown "$user_name:$user_name" "$atuin_dir"

	# Download and install as the correct user
	if [[ ! -f "$user_home/atuin.tar.gz" ]]; then
		echo "Downloading Atuin installer..."
		wget -q --show-progress "$atuin_url" -O "$user_home/atuin.tar.gz" || { echo "Error: Failed to download the file." >&2; exit 1; }
	else
		echo "File already exists. Skipping download."
	fi

	# Extract the tar.gz file as the user
	echo "Extracting Atuin binary..."
	tar -xvzf "$user_home/atuin.tar.gz" -C "$user_home"

	# Move the binary to the desired location as the user
	echo "Moving Atuin binary to $atuin_dir..."
	mv "$user_home/atuin-aarch64-unknown-linux-gnu/$atuin_binary" "$atuin_dir/$atuin_binary"

	# Clean up the extracted folder (leave the tar file for testing)
	echo "Cleaning up extracted folder..."
	rm -rf "$user_home/atuin-aarch64-unknown-linux-gnu"

	# Change ownership of the Atuin binary to the user
	chown "$user_name:$user_name" "$atuin_dir/$atuin_binary"

	generate_atuin_config

	# Create env file for shell (sh compatible) as the user
	echo "Creating env file to set PATH..."
	cat <<EOL > "$atuin_dir/env"
#!/bin/sh
# Add binaries to PATH if they aren't added yet
# Affix colons on either side of \$PATH to simplify matching
case ":${PATH}:" in
	*:"\$HOME/.atuin/bin":*)
	;;
	*)
		# Prepending path in case a system-installed binary needs to be overridden
		export PATH="\$HOME/.atuin/bin:\$PATH"
	;;
esac
EOL
	echo "Env file created at $atuin_dir/env"

	echo "Updating .bashrc..."
	if ! grep -q ". ~/.atuin/bin/env" "$atuin_bashrc_file"; then
		echo ". ~/.atuin/bin/env" >> "$atuin_bashrc_file"
		echo "Added . ~/.atuin/bin/env to .bashrc"
	fi

	# Ensure the user can update .bash-preexec.sh
	if [[ ! -f "$bash_preexec_file" ]]; then
		echo "~/.bash-preexec.sh not found. Downloading..."
		wget -q https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -O "$bash_preexec_file" || { echo "Error: Failed to download .bash-preexec.sh" >&2; exit 1; }
	fi
	if ! grep -q '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' "$atuin_bashrc_file"; then
		echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> "$atuin_bashrc_file"
	fi

	# Ensure eval "$(atuin init bash)" is in .bashrc
	if ! grep -q 'eval "$(atuin init bash)"' "$atuin_bashrc_file"; then
		echo 'eval "$(atuin init bash)"' >> "$atuin_bashrc_file"
	fi

	# Make sure all directories and files are owned by the user
	chown -R "$user_name:$user_name" "$user_home/.atuin"

	echo "Atuin installation complete!"
}


remove_atuin() {
	# Ensure correct user environment if running as root
	local user_name user_home
	if [[ $EUID -eq 0 ]]; then
		# Check if SUDO_USER is set
		if [ -z "$SUDO_USER" ]; then
		echo "Error: Unknown user. SUDO_USER is not set." >&2
		exit 1
		fi
		user_name=$SUDO_USER
		user_home=$(eval echo ~"$user_name")
	else
		user_name=$USER
		user_home=$HOME
	fi

	# Check if Atuin is installed and proceed with removal
	echo "Removing Atuin..."

	# Define file paths to remove
	atuin_bin_path="$user_home/.atuin/bin/atuin"
	atuin_config_dir="$user_home/.config/atuin"
	atuin_local_share_dir="$user_home/.local/share/atuin"
	atuin_home_dir="$user_home/.atuin"
	bash_preexec_file="$user_home/.bash-preexec.sh"
	atuin_bashrc_file="$user_home/.bashrc"

	# Remove Atuin binary and related directories
	rm -f "$atuin_bin_path"
	rm -rf "$atuin_config_dir" "$atuin_local_share_dir" "$atuin_home_dir"

	# Remove lines related to Atuin from .bashrc
	echo "Removing Atuin references from .bashrc..."
	sed -i '/\[\[ -f ~\/.bash-preexec.sh \]\] && source ~\/.bash-preexec.sh/d' "$atuin_bashrc_file"
	sed -i '/eval "\$(atuin init bash)"/d' "$atuin_bashrc_file"

	echo "Atuin uninstallation complete. Please restart your shell."

}


function generate_atuin_config() {

	local user_name user_home
	if [[ $EUID -eq 0 ]]; then
		user_name=${SUDO_USER:-$USER} # Use SUDO_USER or fallback to $user
		user_home=$(eval echo ~"$user_name")
	else
		user_name=$USER
		user_home=$HOME
	fi
	# Use USER_HOME for file operations
	echo "Creating files in $user_home"
	local ouput_folder=".config/atuin"
	local output_file="config.toml"

	# Ensure the target directory exists
	mkdir -p "$user_home/$ouput_folder"
	chown $user_name:$user_name "$user_home/$ouput_folder"
	# Configuration template as a here-document
	cat <<'EOF' > "$user_home/$ouput_folder/$output_file"
sync_address = "https://services.armbian.de/atuin"
db_path = "~/.local/share/atuin/history.db"
key_path = "~/.local/share/atuin/key"
session_path = "~/.local/share/atuin/session"
# auto_sync = false
# update_check = true
# sync_frequency = "10m"

[sync]
records = true

EOF

	# Change ownership of the configuration file to the non-root user
	chown $user_name:$user_name "$user_home/$ouput_folder/$output_file"

	echo "Configuration file created at $user_home/$ouput_folder/$output_file"

}

#module_atuin "$1"
