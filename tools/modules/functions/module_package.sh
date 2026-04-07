# package.sh

# internal function
_pkg_have_stdin() { [[ -t 0 ]]; }

declare -A module_options
module_options+=(
	["apt_operation_progress,author"]="@igorpecovnik"
	["apt_operation_progress,desc"]="Internal wrapper for APT operations with progress display"
	["apt_operation_progress,status"]="Internal"
)

# Wrapper for apt operations with progress display
# Replaces debconf-apt-progress with dialog_gauge UI
# Usage: apt_operation_progress <operation> [apt_args...]
# Operations: update, upgrade, full-upgrade, install, remove, fix-broken
apt_operation_progress() {
	local operation="$1"
	shift
	local args=("$@")
	local title="APT Operation"
	local error_file=$(mktemp)
	local exit_code

	case "$operation" in
		update)
			title="Package Update"
			;;
		upgrade)
			title="Package Upgrade"
			;;
		full-upgrade)
			title="Full Package Upgrade"
			;;
		install)
			title="Install Package"
			;;
		remove|autopurge)
			title="Remove Package"
			;;
		fix-broken)
			title="Fix Broken Packages"
			;;
		*)
			title="APT Operation"
			;;
	esac

	if [[ "$DIALOG" == "read" ]]; then
		# For read mode, just run without progress
		if [[ "$operation" == "fix-broken" ]]; then
			apt-get -y --fix-broken install "$@" 2>&1 | tee "$error_file"
		elif [[ "$operation" == "autopurge" ]]; then
			apt-get -y autopurge "$@" 2>&1 | tee "$error_file"
		else
			apt-get -y "$operation" "$@" 2>&1 | tee "$error_file"
		fi
		exit_code=${PIPESTATUS[0]}
	else
		# With dialog/whiptail, show progress
		(
			echo "XXX"
			echo "0"
			echo "Starting $operation..."
			echo "XXX"

			# Build apt command
			local apt_cmd
			if [[ "$operation" == "fix-broken" ]]; then
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y --fix-broken install ${args[*]}"
			elif [[ "$operation" == "autopurge" ]]; then
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y autopurge ${args[*]}"
			else
				apt_cmd="DEBIAN_FRONTEND=noninteractive apt-get -y $operation ${args[*]}"
			fi

			# Run apt command and capture output
			eval "$apt_cmd" 2>&1 | while IFS= read -r line; do
				# Parse apt output for progress indicators
				if [[ "$line" =~ ^(Hit|Get|Reading|Download|Fetch|Hit|Preparing|Unpacking|Setting|Selecting|Processing) ]]; then
					echo "XXX"
					echo "0"
					echo "$line"
					echo "XXX"
				elif [[ "$line" =~ (Err|Error|FAILED|could not|unable to) ]]; then
					echo "XXX"
					echo "0"
					echo "Error: $line"
					echo "XXX"
				fi
			done

			echo "XXX"
			echo "100"
			echo "$operation complete!"
			echo "XXX"
		) | dialog_gauge "$title" "Processing $operation..." 8 80

		exit_code=$?
	fi

	# Show any errors
	if [[ -s "$error_file" ]]; then
		if [[ $exit_code -ne 0 ]]; then
			dialog_msgbox "$title Failed" "$operation failed.\n\n$(cat "$error_file" | tail -20)" 12 60
		fi
	fi

	rm -f "$error_file"
	return $exit_code
}

declare -A module_options
module_options+=(
	["pkg_configure,author"]="@dimitry-ishenko"
	["pkg_configure,desc"]="Configure an unconfigured package"
	["pkg_configure,example"]="pkg_configure"
	["pkg_configure,feature"]="pkg_configure"
	["pkg_configure,status"]="Interface"
)

pkg_configure()
{
	_pkg_have_stdin && debconf-apt-progress -- dpkg --configure "$@" || dpkg --configure "$@"
}

module_options+=(
	["pkg_full_upgrade,author"]="@dimitry-ishenko"
	["pkg_full_upgrade,desc"]="Upgrade installed packages (potentially removing some)"
	["pkg_full_upgrade,example"]="pkg_full_upgrade"
	["pkg_full_upgrade,feature"]="pkg_full_upgrade"
	["pkg_full_upgrade,status"]="Interface"
)

pkg_full_upgrade()
{
	apt_operation_progress full-upgrade "$@"
}

module_options+=(
	["pkg_install,author"]="@dimitry-ishenko"
	["pkg_install,desc"]="Install package"
	["pkg_install,example"]="pkg_install neovim"
	["pkg_install,feature"]="pkg_install"
	["pkg_install,status"]="Interface"
)

pkg_install()
{
	# Extract only package names from args (skip apt options)
	local pkg_names=()
	local skip_next=false
	for arg in "$@"; do
		if $skip_next; then skip_next=false; continue; fi
		case "$arg" in
			-o) skip_next=true; continue ;;
			-*) continue ;;
		esac
		pkg_names+=("$arg")
	done

	# Dry-run to capture the list of new packages apt will install
	local dry_run_output
	dry_run_output=$(apt-get -s -y install "${pkg_names[@]}" 2>&1)
	echo "DEBUG pkg_install: dry-run for ${#pkg_names[@]} packages" >&2
	local new_packages=()
	local capture=false
	while IFS= read -r line; do
		if [[ "$line" == "The following NEW packages will be installed:" ]]; then
			capture=true
			echo "DEBUG pkg_install: found: $line" >&2
			continue
		fi
		# Stop capturing when we hit any other section header
		if [[ "$line" == "The following additional packages will be installed:" ]] || \
		[[ "$line" == "The following packages will be upgraded:" ]] || \
		[[ "$line" == "The following packages will be REMOVED:" ]]; then
			capture=false
			continue
		fi
		if $capture; then
			if [[ "$line" =~ ^[[:space:]] ]]; then
				new_packages+=($line)
			else
				capture=false
			fi
		fi
	done <<< "$dry_run_output"
	echo "DEBUG pkg_install: apt dry-run reports ${#new_packages[@]} new packages" >&2

	local exit_code
	apt_operation_progress install "$@"
	exit_code=$?

	if [[ $exit_code == 100 ]]; then
		dpkg --configure -a
		apt_operation_progress install "$@"
		exit_code=$?
	fi

	# Track newly installed packages
	if [[ $exit_code -eq 0 ]]; then
		ACTUALLY_INSTALLED+=("${new_packages[@]}")
		echo "DEBUG pkg_install: ACTUALLY_INSTALLED now has ${#ACTUALLY_INSTALLED[@]} entries" >&2
	fi

	return $exit_code
}

module_options+=(
	["pkg_installed,author"]="@dimitry-ishenko"
	["pkg_installed,desc"]="Check if package is installed"
	["pkg_installed,example"]="pkg_installed mc"
	["pkg_installed,feature"]="pkg_installed"
	["pkg_installed,status"]="Interface"
)

pkg_installed()
{
	local status=$(dpkg -s "$1" 2>/dev/null | sed -n "s/Status: //p")
	! [[ -z "$status" || "$status" = *deinstall* || "$status" = *not-installed* ]]
}

module_options+=(
	["pkg_remove,author"]="@dimitry-ishenko"
	["pkg_remove,desc"]="Remove package"
	["pkg_remove,example"]="pkg_remove nmap"
	["pkg_remove,feature"]="pkg_remove"
	["pkg_remove,status"]="Interface"
)

pkg_remove()
{
	local exit_code
	apt_operation_progress autopurge "$@"
	exit_code=$?

	if [[ $exit_code == 100 ]]; then
		dpkg --configure -a
		apt_operation_progress autopurge "$@"
		exit_code=$?
	fi

	return $exit_code
}

module_options+=(
	["pkg_update,author"]="@dimitry-ishenko"
	["pkg_update,desc"]="Update package repository"
	["pkg_update,example"]="pkg_update"
	["pkg_update,feature"]="pkg_update"
	["pkg_update,status"]="Interface"
)

pkg_update()
{
	apt_operation_progress update
}

module_options+=(
	["pkg_upgrade,author"]="@dimitry-ishenko"
	["pkg_upgrade,desc"]="Upgrade installed packages"
	["pkg_upgrade,example"]="pkg_upgrade"
	["pkg_upgrade,feature"]="pkg_upgrade"
	["pkg_upgrade,status"]="Interface"
)

pkg_upgrade()
{
	apt_operation_progress upgrade "$@"
}

module_options+=(
	["pkg_fix,author"]="@igorpecovnik"
	["pkg_fix,desc"]="Fix dependency issues"
	["pkg_fix,example"]="pkg_fix"
	["pkg_fix,feature"]="pkg_fix"
	["pkg_fix,status"]="Interface"
)

pkg_fix()
{
	apt_operation_progress fix-broken "$@"
}
