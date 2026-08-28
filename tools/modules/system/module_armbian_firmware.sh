# ==============================================================================
# Armbian Firmware Module
# ==============================================================================
#
# This module manages Armbian kernel and firmware packages, providing critical
# system functionality for switching between different kernel versions and branches.
#
# WARNING: This is a critical system module. Kernel management can render a
# system unbootable if misused. Always test on non-production systems first.
#
# Architecture Support:
#   x86-64     - Intel/AMD 64-bit systems
#   arm64      - ARM 64-bit systems (most SBCs)
#   armhf      - ARM 32-bit systems (hard float)
#   riscv64    - RISC-V 64-bit systems
#
# Commands:
#   select     - Interactive TUI for selecting and installing kernels
#   install    - Direct installation of specific kernel version
#   show       - Display available packages without installing
#   hold       - Prevent kernel packages from automatic upgrades
#   unhold     - Release held packages, allowing upgrades
#   repository - Switch between stable and rolling beta repositories
#   help       - Display usage information
#
# Kernel Branches:
#   legacy     - Older stable kernels (LTS 4.x/5.x)
#   vendor     - Vendor-specific kernels (board-specific)
#   current    - Latest stable kernels (LTS 6.x)
#   edge       - Bleeding edge kernels (testing/latest)
#
# Typical Usage:
#   module_armbian_firmware select              # Interactive kernel selection
#   module_armbian_firmware install current "" "" "" "" # Install latest current kernel
#   module_armbian_firmware hold status         # Check if kernels are held
#
# ==============================================================================

module_options+=(
	["module_armbian_firmware,author"]="@igorpecovnik"
	["module_armbian_firmware,maintainer"]="@igorpecovnik"
	["module_armbian_firmware,feature"]="module_armbian_firmware"
	["module_armbian_firmware,example"]="select install show hold unhold repository help"
	["module_armbian_firmware,desc"]="Module for Armbian firmware manipulating"
	["module_armbian_firmware,status"]="Active"
	["module_armbian_firmware,doc_link"]="https://docs.armbian.com/"
	["module_armbian_firmware,group"]="System"
	["module_armbian_firmware,arch"]="x86-64 arm64 armhf riscv64"
	["module_armbian_firmware,max_versions"]="4"
)

function module_armbian_firmware() {
	local title="Armbian FW"

	# Convert the example string to an array of available commands
	# Commands: select, install, show, hold, unhold, repository, help
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_firmware,example"]}"

	# Update kernel environment variables
	# BRANCH, KERNELPKG_VERSION, KERNELPKG_LINUXFAMILY may require being updated after kernel switch
	update_kernel_env

	case "$1" in

		# ========================================================================
		# SELECT COMMAND: Interactive TUI for selecting and installing kernels
		# ========================================================================
		"${commands[0]}")

			# Update package lists to ensure we have latest kernel information
			# Beta repositories are updated frequently, so we always refresh before showing available kernels
			pkg_update

			# Default to showing all kernel branches if not explicitly defined
			# This handles old builds where KERNEL_TEST_TARGET might not be set
			[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,vendor,current,edge"

			# Check if firmware packages are currently on hold (prevented from upgrading)
			# If so, warn user and offer to release the hold before proceeding
			if ${module_options["module_armbian_firmware,feature"]} ${commands[3]} "status"; then
				if dialog_yesno "Warning!" "Firmware upgrade is disabled. Release hold and proceed?" "Yes" "No" 7 60; then
					${module_options["module_armbian_firmware,feature"]} ${commands[4]}
				else
					return 0
				fi
			fi

			# Ask user if they want to see all available kernels or just mainstream ones
			# Default (no) shows all branches including edge and vendor-specific kernels
			if ! dialog_yesno "Advanced options" "Show only mainstream kernels on the list?" "Yes" "No" 7 60 --defaultno; then
				KERNEL_TEST_TARGET="legacy,vendor,current,edge"
			fi

			# Build list of kernel package names to search for in repository
			# Special handling for Rockchip RK3588 boards which use different naming scheme
			local kernel_test_target=$(\
				for kernel_test_target in ${KERNEL_TEST_TARGET//,/ }
				do
					# Rockchip RK3588 exception: vendor kernel uses rk35xx suffix
					# current/edge kernels use rockchip64 suffix
					if [[ "${BOARDFAMILY}" == "rockchip-rk3588" ]]; then
						if [[ "${kernel_test_target}" == "vendor" ]]; then
							echo "linux-image-${kernel_test_target}-rk35xx"
						elif [[ "${kernel_test_target}" =~ ^(current|edge)$ ]]; then
							echo "linux-image-${kernel_test_target}-rockchip64"
						fi
					else
						# Standard naming for all other board families
						echo "linux-image-${kernel_test_target}-${LINUXFAMILY}"
					fi
				done
				)

			# Get currently installed kernel version to hide it from the selection list
			# This prevents users from "reinstalling" the same kernel they already have
			local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}' | head -1)

			# Build grep command to filter out currently installed kernel from the list
			[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"

			# Construct apt-cache search command to find available kernel versions
			# This complex pipeline extracts package names and versions from repository metadata
			local search_exec="apt-cache show ${kernel_test_target} \
			| grep -E \"Package:|Version:|version:|family\" \
			| grep -v \"Config-Version\" \
			| sed -n -e 's/^.*: //p' \
			| sed 's/\.$//g' \
			| xargs -n3 -d'\n' \
			| sed \"s/ /=/\" $grep_current_kernel"

			# Collect all kernels grouped by branch, then take last N of each branch
			# This prevents overwhelming the user with too many old kernel versions
			declare -A branch_kernels
			IFS=$'\n'
			for line in $(eval ${search_exec}); do
				# Extract package and version (package=version format), and kernel version
				local pkg=$(echo "$line" | awk -F '=| ' '{print $1}')
				local kernel_ver=$(echo "$line" | awk -F '=| ' '{print $2}')
				# Extract branch (3rd field in package name: linux-image-<branch>-<linuxfamily>)
				local branch=$(echo "$pkg" | cut -d'-' -f3 | cut -d'=' -f1)
				# Add to branch group
				branch_kernels["$branch"]+="$line"$'\n'
			done
			unset IFS

			# Build menu list for dialog: package name and kernel version
			# Only show last N kernels per branch (most recent versions)
			# N is configurable via module_armbian_firmware,max_versions option
			IFS=$'\n'
			local LIST=()
			local max_versions="${module_options["module_armbian_firmware,max_versions"]:-3}"
			for branch in "${!branch_kernels[@]}"; do
				# Sort by kernel version (field 2) and take last N (newest)
				for line in $(echo "${branch_kernels[$branch]}" | sort -k2 -V -r | head -n "$max_versions"); do
					# First field: package=version (e.g., linux-image-current-meson64=23.02.2-trunk)
					# Second field: kernel version (e.g., 6.6.44)
					LIST+=("$(echo $line | awk '{print $1}')      ")
					LIST+=("v$(echo $line | awk '{print $2}')")
				done
			done
			unset IFS

			# Calculate menu dimensions and display selection dialog
			local list_length=$((${#LIST[@]} / 2))
			if [ "$list_length" -eq 0 ]; then
				# No alternative kernels available for this board
				dialog_msgbox "Warning" "No other kernels available!" 7 31
			else
				# Calculate menu dimensions
				local menu_height=$((${list_length} + 7))
				local menu_width=80
				local menu_list_height=${list_length}

				# Show kernel selection menu and capture user's choice
				if target_version=$(dialog_menu "Select kernel" "" ${menu_height} ${menu_width} ${menu_list_height} -- "${LIST[@]}")
				then
					# Extract branch and linuxfamily from selected package name
					# Package name format: linux-image-<branch>-<linuxfamily>=<version>
					local branch=$(echo "${target_version}" | cut -d'-' -f3)
					local linuxfamily=$(echo "${target_version}" | cut -d'-' -f4 | cut -d'=' -f1)
					# Call install command to perform the actual kernel installation
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "${target_version/*=/}" "" "${linuxfamily}"
				fi
			fi

		;;

		# ========================================================================
		# INSTALL COMMAND: Purge old kernel packages and install new ones
		# Parameters: $2=branch, $3=version, $4=hide, $5=linuxfamily
		# ========================================================================
		"${commands[1]}")

			# Parse input parameters
			local branch=$2                              # Kernel branch: legacy, vendor, current, edge
			local version="$( echo $3 | tr -d '\011\012\013\014\015\040')" # Specific version (cleaned of tabs/spaces)
			local hide=$4                                # If "hide", suppress output
			local linuxfamily=$5                         # Board family (e.g., rockchip64, meson64)

			# Idempotency check: don't reinstall if exact version is already present
			# This prevents unnecessary reboots and saves time
			if [[ -n "${version}" ]]; then
				local current_version=$(dpkg -l | grep "^ii" | grep "linux-image-${branch}-${linuxfamily}" | awk '{print $3}')
				if [[ "${current_version}" == "${version}" ]]; then
					echo "Kernel ${branch}-${linuxfamily} version ${version} is already installed."
					return 0
				fi
			fi

			# Update package lists to ensure we have latest repository information
			# This is critical for beta repositories which are updated frequently
			pkg_update

			# Create temporary APT pinning policy to force packages from current release
			# Priority 1001 ensures these packages won't be upgraded to different versions
			# The trap ensures cleanup even if the script is interrupted
			cat > "/etc/apt/preferences.d/armbian-upgrade-policy" <<- EOT
			Package: armbian-bsp* armbian-firmware* linux-*
			Pin: release a=${DISTROID}
			Pin-Priority: 1001
			EOT
			trap '{ rm -f -- "/etc/apt/preferences.d/armbian-upgrade-policy"; }' EXIT

			# Generate the list of packages to install based on branch and version
			# The "hide" parameter suppresses output since we're using the list programmatically
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${branch}" "${version}" "hide" "" "$linuxfamily"

			# CRITICAL ORDERING: never remove the running kernel before its
			# replacement is safely on disk. A generated image can carry a kernel
			# that is not present in any repository; removing it first and only then
			# discovering the new one can't be fetched leaves the board with NO
			# kernel (unbootable). So: validate -> download EVERYTHING -> only then
			# remove the old and install the new from the local cache.

			# Nothing resolved to install (e.g. the running kernel's branch/family
			# has no package in the selected repo) — abort, current kernel untouched.
			if [[ ${#packages[@]} -eq 0 || -z "${packages[*]// }" ]]; then
				echo "Error: no ${branch}-${linuxfamily} kernel packages found in the selected repository — current kernel left untouched."
				return 1
			fi

			# Actually download every target package (NOT --simulate) into apt's
			# cache. If any can't be located or fetched, apt returns non-zero and we
			# bail out here, BEFORE anything is removed.
			if ! apt-get install --download-only --allow-downgrades -y ${packages[@]} > /dev/null 2>&1; then
				echo "Error: could not download kernel packages (${packages[*]}) — network / repository problem. Current kernel left untouched; try again later and report to Armbian forums."
				return 1
			fi

			# Downloads succeeded and are cached. Install the NEW kernel FIRST, as a
			# single apt transaction served from that cache. Two reasons this order
			# matters — reversing it (the old "purge linux-image* then install")
			# strands the board with NO kernel:
			#   * apt replaces the same-named packages in place, so a bootable kernel
			#     is present at every step; if the install fails, the current kernel
			#     is left untouched instead of already-purged.
			#   * direct apt-get (like the download above) gives a trustworthy exit
			#     code — pkg_install's dialog-gauge path masks apt failures, so a
			#     failed install used to look like success right after the purge.
			if ! DEBIAN_FRONTEND=noninteractive apt-get install --allow-downgrades -y ${packages[@]} > /dev/null 2>&1; then
				rm -f /etc/apt/preferences.d/armbian-upgrade-policy
				echo "Error: kernel install failed — current kernel left in place. Try again later and report to the Armbian forums."
				return 1
			fi

			# Confirm the replacement image is actually installed BEFORE pruning
			# the others. A broken/incomplete repo could install linux-dtb /
			# linux-headers but omit the linux-image, leaving `keep` with no image
			# package — the prune below would then remove every kernel. Bail here
			# (current kernel untouched) rather than strand the board.
			local target_image="linux-image-${branch}-${linuxfamily}"
			if ! dpkg-query -W -f='${db:Status-Status}\n' "$target_image" 2>/dev/null | grep -qx 'installed'; then
				rm -f /etc/apt/preferences.d/armbian-upgrade-policy
				echo "Error: replacement kernel image ${target_image} is not installed — current kernel left in place."
				return 1
			fi

			# New kernel is on disk. Now prune only the OTHER kernel packages a
			# branch/family switch leaves behind (e.g. current -> edge), by EXACT
			# name and explicitly excluding what we just installed. NEVER a
			# 'linux-image*' wildcard — that also matches the kernel we just put on
			# and is exactly what used to delete the running kernel. Use `purge`
			# (not `autopurge`): autopurge would also cascade into these packages'
			# now-unused dependencies, which is risky in a scripted -y run.
			local keep=" "
			for pkg in ${packages[@]}; do keep+="${pkg%%=*} "; done
			local stale=()
			while IFS= read -r ipkg; do
				[[ -n "$ipkg" && "$keep" != *" $ipkg "* ]] && stale+=("$ipkg")
			done < <(dpkg-query -W -f='${Package}\n' 'linux-image-*' 'linux-dtb-*' 'linux-headers-*' 2>/dev/null)
			if [[ ${#stale[@]} -gt 0 ]]; then
				DEBIAN_FRONTEND=noninteractive apt-get purge -y "${stale[@]}" > /dev/null 2>&1 || true
			fi

			# Clean up the temporary APT policy file
			rm -f /etc/apt/preferences.d/armbian-upgrade-policy

			# Final safety net: a bootable kernel MUST remain — an installed
			# linux-image package AND an actual image in /boot. If neither, something
			# removed it out from under us; say so loudly and fail rather than let the
			# caller reboot into an unbootable system.
			# NB: match the /boot image by listing the directory and grepping — a
			# bare `ls /boot/vmlinuz-* /boot/Image*` returns non-zero when ANY single
			# glob has no match (e.g. no zImage on arm64), which would false-positive
			# even with a valid kernel present.
			if ! dpkg-query -W -f='${db:Status-Status}\n' 'linux-image-*' 2>/dev/null | grep -q '^installed' \
				|| ! ls -1 /boot 2>/dev/null | grep -qE '^(vmlinuz-|Image|zImage)'; then
				echo "CRITICAL: no bootable kernel present after switch — do NOT reboot; reinstall a kernel via armbian-config (System > Firmware) first."
				return 1
			fi

			# Prompt for reboot if running interactively
			# Kernel changes require reboot to take effect
			if test -t 0; then
				if dialog_yesno " Reboot required " "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
					reboot
				fi
			fi
		;;

		# ========================================================================
		# SHOW COMMAND: Generate list of packages to install (without installing)
		# Parameters: $2=branch, $3=version, $4=hide, $5=repository, $6=linuxfamily
		# Output: Space-separated list of package names (unless $4=="hide")
		# ========================================================================
		"${commands[2]}")

			# Parse input parameters with defaults
			local branch="${2:-$BRANCH}"                 # Default to current branch
			local version="$( echo "$3" | tr -d '\011\012\013\014\015\040')" # Clean version string
			local hide="$4"                              # If "hide", don't output the list
			local repository="$5"                        # Repository to use (currently unused)
			local linuxfamily="${6:-$KERNELPKG_LINUXFAMILY}" # Default to kernel environment

			# Default to stable repository if not specified
			[[ -z $repository ]] && local repository="apt.armbian.com"

			# Build base package list for kernel installation
			# Always includes kernel image and device tree binaries
			armbian_packages=(
				"linux-image-${branch}-${linuxfamily}"
				"linux-dtb-${branch}-${linuxfamily}"
			)

			# Add headers to package list if they were previously installed
			# This maintains user's previous choice to have headers installed
			if dpkg -l | grep -E "linux-headers" >/dev/null; then
				armbian_packages+=("linux-headers-${branch}-${linuxfamily}")
			fi

			# Resolve specific package versions from repository cache
			# When a specific version is requested, we check if it exists
			# If the requested version doesn't exist, we skip that package rather than failing
			# This prevents breaking installations when specific versions are removed from repos
			packages=""
			for pkg in ${armbian_packages[@]}; do

				# Query APT cache for package information
				# Returns package name and version if available in repository
				local cache_show=$(apt-cache show "$pkg" 2> /dev/null | grep -E "Package:|^Version:|family" \
					| sed -n -e 's/^.*: //p' \
					| sed 's/\.$//g' \
					| xargs -n2 -d'\n' \
					| grep "${pkg}")

				# Add package to installation list
				# If version specified, use "package=version" format
				# If version not specified or not found, use bare package name (latest)
				if [[ -n "${version}" && -n "${cache_show}" ]]; then
					# Check if exact version exists in cache
					if [[ -n $(echo "$cache_show" | grep "$version""$" ) ]]; then
						packages+="${pkg}=${version} "
					fi
					# If version doesn't exist, package is silently skipped (fallback behavior)
				elif [[ -n "${cache_show}" ]]; then
					# No version specified, use package name (will install latest)
					packages+="${pkg} "
				fi
			done

			# Output the package list unless "hide" parameter is set
			# The "hide" mode is used when we need the list programmatically but don't want to display it
			[[ "$4" != "hide" ]] && echo ${packages[@]}

		;;

		# ========================================================================
		# HOLD COMMAND: Prevent kernel packages from being upgraded
		# Parameters: $2=status (if "status", check if packages are held; otherwise, hold them)
		# Returns: 0 if packages are held (when status=="status"), 1 otherwise
		# ========================================================================
		"${commands[3]}")

			# Parse input parameter
			local status="$2"    # "status" to check, empty to actually hold packages

			# Generate list of kernel packages that would be affected
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# Two modes: check status or actually hold packages
			if [[ "$status" == "status" ]]; then
				# STATUS MODE: Check if Armbian kernel packages are currently on hold
				# Get list of all packages on hold in the system
				local get_hold=($(apt-mark showhold))

				# Check which of our packages are in the held packages list
				# This nested loop matches our packages against the global hold list
				local test_hold=($(for all_packages in "${packages[@]}"; do
					for hold_packages in "${get_hold[@]}"; do
						echo "$all_packages" | grep -q "$hold_packages" && echo "$all_packages"
					done
				done))

				# Return 0 (true) if any packages are held, 1 (false) otherwise
				[[ -z ${test_hold[@]} ]] && return 1 || return 0
			else
				# HOLD MODE: Place Armbian kernel packages on hold
				# This prevents automatic upgrades via apt upgrade
				# Note: packages array must not be quoted to allow word splitting
				apt-mark hold ${packages[@]} # without quotes
			fi

		;;

		# ========================================================================
		# UNHOLD COMMAND: Release held kernel packages, allowing upgrades
		# Parameters: None
		# ========================================================================
		"${commands[4]}")

			# Generate list of kernel packages to unhold
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# Remove hold mark from all Armbian kernel packages
			# This allows them to be upgraded again via apt upgrade
			# Note: packages array must not be quoted to allow word splitting
			apt-mark unhold ${packages[@]} # without quotes

		;;

		# ========================================================================
		# REPOSITORY COMMAND: Switch between stable and rolling repositories
		# Parameters: $2=repository (stable/rolling), $3=status (if "status", just check)
		# Side effect: When not just checking status, reinstalls firmware from new repo
		# ========================================================================
		"${commands[5]}")

			# Parse input parameters
			local repository=$2     # Target repository: "stable" or "rolling"
			local status=$3          # If "status", only check current repo without switching

			# Get current kernel branch and family for potential reinstallation
			local branch=${BRANCH}
			local linuxfamily=${LINUXFAMILY:-$KERNELPKG_LINUXFAMILY}

			# Find which Armbian sources file exists (old .list or new .sources format)
			local sources_file=""
			[[ -f "/etc/apt/sources.list.d/armbian.list" ]] && sources_file="/etc/apt/sources.list.d/armbian.list"
			[[ -f "/etc/apt/sources.list.d/armbian.sources" ]] && sources_file="/etc/apt/sources.list.d/armbian.sources"

			# Validate we found a sources file
			if [[ -z "$sources_file" ]]; then
				echo "Error: Armbian APT sources file not found." >&2
				return 1
			fi

			# Current Armbian mirror host — what we revert to if the switch turns
			# out to have no kernel to offer.
			local prev_host
			prev_host="$(grep -oE '[a-zA-Z0-9.-]*\.armbian\.com' "$sources_file" | head -1)"
			# No *.armbian.com entry means a custom/third-party mirror we must not
			# pretend to switch: report not-on-requested for a status query, and
			# refuse an actual switch rather than silently reinstalling from — and
			# reporting success on — a repo the source list was never changed to.
			if [[ -z "$prev_host" ]]; then
				[[ "$status" == "status" ]] && return 1
				echo "Error: ${sources_file} has no *.armbian.com entry — refusing to switch the repository on a custom mirror."
				return 1
			fi
			local on_repo=rolling
			[[ "$prev_host" == "apt.armbian.com" ]] && on_repo=stable

			# Map the requested repo to its mirror host.
			local target_host="$prev_host"
			case "$repository" in
				rolling) target_host="beta.armbian.com" ;;
				stable)  target_host="apt.armbian.com"  ;;
			esac

			# Status query: report whether we're already on the requested repo.
			if [[ "$status" == "status" ]]; then
				[[ "$on_repo" == "$repository" ]] && return 0 || return 1
			fi

			# Point the sources at the requested repo (no-op if already there).
			if [[ "$prev_host" != "$target_host" ]]; then
				sed -i "s|[a-zA-Z0-9.-]*\.armbian\.com|${target_host}|g" "$sources_file"
				pkg_update
			fi

			# Predict the empty-repo case: verify the TARGET repo actually publishes
			# a kernel for this board BEFORE committing to it. apt-cache show can't
			# tell us — it also reports the currently-INSTALLED package, so an empty
			# rolling would look populated — so use madison, which lists only versions
			# available from a repository. If the target has none (e.g. rolling with
			# no kernel published yet), revert the source change and keep the board on
			# its working repo + kernel rather than stranding it on a repo it can be
			# neither reinstalled from nor upgraded against.
			local kpkg="linux-image-${branch}-${linuxfamily}"
			if ! apt-cache madison "$kpkg" 2>/dev/null | grep -q "$kpkg"; then
				echo "Error: the '${repository}' repository (${target_host}) publishes no ${kpkg} — refusing the switch and reverting to ${prev_host}; current kernel left in place."
				if [[ "$prev_host" != "$target_host" ]]; then
					sed -i "s|[a-zA-Z0-9.-]*\.armbian\.com|${prev_host}|g" "$sources_file"
					pkg_update
				fi
				return 1
			fi

			# If we're not just checking status, reinstall the kernel from the
			# newly-switched repository. The install command is brick-safe (downloads
			# first, installs the new kernel before pruning the old, and verifies a
			# bootable kernel remains). Surface its result: on failure the source list
			# was switched but the kernel could NOT be reinstalled from the new repo —
			# the current kernel is left intact, so warn and return non-zero rather
			# than reporting a clean switch the caller would then reboot into.
			if [[ "$status" != "status" ]]; then
				if ! ${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "" "" "${linuxfamily}"; then
					echo "Warning: repository switched to '${repository}', but the kernel could not be reinstalled from it — current kernel left in place. Resolve the repository/kernel availability before rebooting."
					return 1
				fi
			fi
		;;


		# ========================================================================
		# HELP COMMAND: Display usage information
		# ========================================================================
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_firmware,feature"]} <command> <switches>"
			echo -e "Commands:  ${module_options["module_armbian_firmware,example"]}"
			echo "Available commands:"
			echo -e "  select     - TUI to select $title.                    switches: [ stable | rolling ]"
			echo -e "  install    - Install $title.                          switches: [ \$branch | \$version ]"
			echo -e "  show       - Show $title packages.                    switches: [ \$branch | \$version | hide ]"
			echo -e "  hold       - Mark $title packages as held back.       switches: [status] returns true or false"
			echo -e "  unhold     - Unset $title packages set as held back."
			echo -e "  repository - Selects repository and performs update.   switches: [ stable | rolling ]"
			echo
		;;
		*)
			# Default to help if invalid command is provided
			${module_options["module_armbian_firmware,feature"]} ${commands[6]}
		;;
	esac
}
