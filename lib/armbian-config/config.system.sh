
module_options+=(
["about_armbian_configng,author"]="@igorpecovnik"
["about_armbian_configng,ref_link"]=""
["about_armbian_configng,feature"]="about_armbian_configng"
["about_armbian_configng,desc"]="Show general information about this tool"
["about_armbian_configng,example"]="about_armbian_configng"
["about_armbian_configng,status"]="Active"
)
#
# @description Show general information about this tool
#
# Sized to fit an 80x24 terminal without scrolling: dialog msgbox is
# auto-sized, and it clips rather than scrolls, so keep this at or under
# 15 lines and 70 columns.
#
function about_armbian_configng() {

	echo "Armbian Config: The Next Generation"
	echo ""
	echo "Configures an installed Armbian system: kernel and firmware, storage,"
	echo "network, users and services, plus optional third-party software."
	echo ""
	echo "  System         kernel, firmware, storage, users, services"
	echo "  Network        wired, wireless, hotspot, DNS, addressing"
	echo "  Localisation   locale, timezone, keyboard, hostname"
	echo "  Software       install and remove curated applications"
	echo ""
	echo "Every entry is scriptable:  armbian-config --api <module> <command>"
	echo ""
	echo "Docs    https://docs.armbian.com/armbian-config/"
	echo "Issues  https://github.com/armbian/configng/issues"
	echo "Donate  https://github.com/sponsors/armbian"

}


module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
["store_netplan_config,ref_link"]=""
["store_netplan_config,feature"]="Storing netplan config to tmp"
["store_netplan_config,desc"]=""
["store_netplan_config,example"]=""
["store_netplan_config,status"]="Active"
)
#
# @description Restoring Netplan configuration from temp folder
#
function restore_netplan_config() {

	echo "Restoring NetPlan configs" | show_infobox
	# just in case
	if [[ -n ${restore_netplan_config_folder} ]]; then
		rm -f /etc/netplan/*
		rsync -ar ${restore_netplan_config_folder}/. /etc/netplan
	fi

}


module_options+=(
	["module_zsh,author"]="@igorpecovnik"
	["module_zsh,maintainer"]="@igorpecovnik"
	["module_zsh,feature"]="module_zsh"
	["module_zsh,example"]="install remove status help"
	["module_zsh,desc"]="Switch system-wide login shell to ZSH"
	["module_zsh,doc_link"]=""
	["module_zsh,group"]="User"
	["module_zsh,status"]="Active"
	["module_zsh,arch"]="x86-64 arm64 armhf riscv64"
)

#
# Module zsh
# Switches the system-wide default login shell between bash and zsh.
# Companion package armbian-zsh ships the dotfiles dropped into
# /etc/skel by module_update_skel.
#
function module_zsh() {
	local title="zsh"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zsh,example"]}"

	case "$1" in
		"${commands[0]}") # install
			pkg_update

			# Install before changing any shell pointer. If the
			# install fails and we've already pointed root + users
			# at /bin/zsh, pam_shells will lock everyone out.
			if ! pkg_install armbian-zsh zsh-common zsh; then
				echo "Failed to install zsh packages; shell not changed"
				return 1
			fi

			# Default shell for new accounts (useradd / adduser).
			sed -i "s|^SHELL=.*|SHELL=/bin/zsh|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/zsh|" /etc/adduser.conf

			# Refresh /etc/skel from armbian-zsh so newly created
			# users get the matching dotfiles. Abort on failure
			# rather than silently leaving /etc/skel in an
			# inconsistent state — useradd / adduser.conf already
			# point at /bin/zsh, so a quiet skel failure would
			# produce new accounts with bash dotfiles in a zsh
			# shell.
			if ! module_update_skel install; then
				echo "Error: module_update_skel install failed; shell not changed" >&2
				return 1
			fi

			# Move root first as a canary: if usermod rejects /bin/zsh
			# (e.g. it isn't listed in /etc/shells, pam_shells would
			# block logins anyway), abort BEFORE the blanket sed
			# flips every other user — otherwise we'd lock the whole
			# system out instead of just leaving root unchanged.
			if ! usermod --shell /bin/zsh root; then
				echo "Error: usermod --shell /bin/zsh root failed; /etc/passwd left unchanged" >&2
				return 1
			fi
			# Anchor to the 7th colon-delimited field (login shell)
			# rather than just `/bash$` so we can't accidentally
			# rewrite anything else that happens to end with the
			# string. [^:]* keeps the match inside field 7. Handles
			# any path ending in /bash (/bin/bash, /usr/local/bin/bash,
			# etc.).
			sed -i -E 's|^(([^:]*:){6}[^:]*)/bash$|\1/zsh|' /etc/passwd
		;;

		"${commands[1]}") # remove
			sed -i "s|^SHELL=.*|SHELL=/bin/bash|" /etc/default/useradd
			sed -i -E "s|(^\|#)DSHELL=.*|DSHELL=/bin/bash|" /etc/adduser.conf

			# Same canary pattern as install: gate the blanket sed
			# on root flipping cleanly. /bin/bash should always be
			# present and listed, but if for any reason usermod
			# refuses we'd otherwise leave root on zsh while every
			# other account moved to bash — inconsistent state.
			if ! usermod --shell /bin/bash root; then
				echo "Error: usermod --shell /bin/bash root failed; /etc/passwd left unchanged" >&2
				return 1
			fi
			sed -i -E 's|^(([^:]*:){6}[^:]*)/zsh$|\1/bash|' /etc/passwd

			# Remove packages last — flipping the shell pointer
			# first means the post-removal hook can't disturb a
			# logged-in user's active zsh process.
			pkg_remove armbian-zsh zsh-common zsh
		;;

		"${commands[2]}") # status
			# Active iff root's login shell is zsh. Matches the
			# JSON menu's visibility condition exactly.
			[[ "$(getent passwd root | awk -F: '{print $7}')" == */zsh ]]
		;;

		"${commands[3]}") # help
			echo -e "\nUsage: ${module_options["module_zsh,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_zsh,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Switch system-wide login shell to zsh."
			echo -e "\tremove\t- Switch system-wide login shell back to bash."
			echo -e "\tstatus\t- Return 0 if zsh is the current system shell."
			echo
		;;

		*)
			${module_options["module_zsh,feature"]} ${commands[3]}
		;;
	esac
}


module_options+=(
["store_netplan_config,author"]="@igorpecovnik"
["store_netplan_config,ref_link"]="store_netplan_config"
["store_netplan_config,feature"]="store_netplan_config"
["store_netplan_config,desc"]="Storing netplan config to tmp"
["store_netplan_config,example"]="store_netplan_config"
["store_netplan_config,status"]="Active"
)
#
# @description Storing Netplan configuration to temp folder
#
function store_netplan_config () {

	# store current configs to temporal folder
	restore_netplan_config_folder=$(mktemp -d /tmp/XXXXXXXXXX)
	rsync --quiet /etc/netplan/* ${restore_netplan_config_folder}/ 2>/dev/null
	trap restore_netplan_config 1 2 3 6

}



module_options+=(
["module_devicetree_overlays,author"]="@viraniac"
["module_devicetree_overlays,maintainer"]="@igorpecovnik,@The-going"
["module_devicetree_overlays,ref_link"]=""
["module_devicetree_overlays,feature"]="module_devicetree_overlays"
["module_devicetree_overlays,desc"]="Enable/disable device tree overlays"
["module_devicetree_overlays,example"]="install remove edit show help"
["module_devicetree_overlays,status"]="Active"
["module_devicetree_overlays,group"]="Kernel"
["module_devicetree_overlays,port"]=""
["module_devicetree_overlays,arch"]="aarch64 armhf riscv64"
["module_devicetree_overlays,help_install"]="Add overlays to the boot config (overlays=foo,bar — comma delimited)"
["module_devicetree_overlays,help_remove"]="Remove overlays from the boot config (overlays=foo,bar — comma delimited)"
["module_devicetree_overlays,help_edit"]="Interactive TUI for toggling overlays (default action)"
["module_devicetree_overlays,help_show"]="List currently-enabled overlays"
["module_devicetree_overlays,help_help"]="Print this help"
)
#
# @description Manage device tree overlays
#
# Usage: module_devicetree_overlays                              (defaults to `help`)
#        module_devicetree_overlays edit                         interactive TUI
#        module_devicetree_overlays install overlays=foo,bar     add overlays (idempotent)
#        module_devicetree_overlays remove  overlays=foo,bar     remove overlays (idempotent)
#        module_devicetree_overlays show                         list currently-enabled overlays
#        module_devicetree_overlays help                         this message
#
# Boot-config writes go through a temp + atomic mv, with the previous
# file preserved as <name>.bak — on an SBC a partial write is a brick.
#
function module_devicetree_overlays() {
	local cmd="${1:-help}"
	shift || true

	# Subcommand registry — order in module_options[*,example] defines
	# the dispatch indices below. Update both together.
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_devicetree_overlays,example"]}"

	case "$cmd" in
		"${commands[0]}")
			# install
			_dt_overlays_install "$@"
		;;
		"${commands[1]}")
			# remove
			_dt_overlays_remove "$@"
		;;
		"${commands[2]}")
			# edit
			_dt_overlays_edit
		;;
		"${commands[3]}")
			# show
			_dt_overlays_show
		;;
		"${commands[4]}")
			# help
			show_module_help "module_devicetree_overlays" "Device Tree Overlays" \
				"Examples:\n  module_devicetree_overlays show\n  module_devicetree_overlays install overlays=uart3,spi-spidev\n  module_devicetree_overlays remove overlays=uart3\n  module_devicetree_overlays edit\n\nNotes:\n- install validates every name against the available .dtbo set;\n  if any name is unknown the whole batch is rejected.\n- remove silently skips names that are not currently enabled.\n- On Raspberry Pi only the '# Armbian config' block of config.txt\n  is managed; overlays set above it are left alone.\n- The boot config (/boot/armbianEnv.txt or /boot/firmware/config.txt)\n  is rewritten atomically and the previous version kept as <name>.bak." \
				"native"
			return 0
		;;
		*)
			echo "Error: unknown subcommand '${cmd}'" >&2
			echo "Available: ${commands[*]}" >&2
			return 1
		;;
	esac
}

#
# Resolve $overlayconf, $overlaydir, $overlay_prefix, $overlay_prefixes
# and $is_pi based on the running board. Sets them in the caller's scope.
# overlay_prefix is a space-separated list; overlay_prefixes holds its
# items in order. Returns 1 with a user-facing message if the board is
# incompatible.
#
function _dt_overlays_resolve_paths() {
	local pi_config="/boot/firmware/config.txt"
	local armbian_env="/boot/armbianEnv.txt"

	is_pi="false"

	if [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		is_pi="true"
		overlayconf="$pi_config"
		overlaydir=$(find /boot/dtb/ -maxdepth 1 -type d \( -name "overlay" -o -name "overlays" \) 2>/dev/null | head -n1)
	else
		overlayconf="$armbian_env"
		overlaydir=$(find /boot/dtb/ -name overlay -and -type d 2>/dev/null)
	fi

	# Anchored regex — the unanchored form would also pick up keys like
	# `something_overlay_prefix_FOO=`.
	overlay_prefix=$(awk -F= '/^overlay_prefix=/ {print $2}' "$overlayconf" 2>/dev/null)
	# A prefix that matches no overlay is not an error: the SoC can have
	# no overlays yet. Discovery then returns nothing.
	read -r -a overlay_prefixes <<< "$overlay_prefix"

	if [[ ! -f "$overlayconf" || ! -d "$overlaydir" ]]; then
		echo "Error: incompatible OS configuration — Armbian device tree files not found" >&2
		return 1
	fi

	return 0
}

#
# Print the scenario bitmap of a boot script (see _dt_overlays_edit).
# Old scripts use ${overlay_prefix}; list-aware scripts loop over the
# prefixes with ${overlay_prefix_item}.
#
function _dt_overlays_scenario() {
	awk 'BEGIN{p=0;s=0}
		/load.*overlays?\/\${overlay_prefix(_item)?}-\${overlay_file}.dtbo/{p=1}
		/load.*overlays?\/\${overlay_file}.dtbo/{s=1}
		END{print p s}
	' "$1" 2>/dev/null
}

#
# Print 0 if token $1 (from overlays= or dtoverlay=) names overlay $2
# (as listed by _dt_overlays_discover): same name, or one of the
# prefixes plus name. Pi parameters after the first comma are ignored.
#
function _dt_overlays_token_matches() {
	local token="${1%%,*}" overlay="$2" p
	[[ "$token" == "$overlay" ]] && return 0
	for p in "${overlay_prefixes[@]}"; do
		[[ "$token" == "${p}-${overlay}" ]] && return 0
	done
	return 1
}

#
# Output every overlay name (without the platform prefix) that the
# board could load, one per line. With several prefixes, the first
# prefix that provides a name wins, as in the boot script, and each
# file is listed once. Honours the same scenario detection as the TUI
# so we don't offer overlays the boot script can't load.
#
function _dt_overlays_discover() {
	local f name p

	# The Pi firmware loads dtoverlay=<name> by file name; there is no
	# boot.scr and no prefix.
	if [[ "$is_pi" == "true" ]]; then
		for f in "$overlaydir"/*.dtbo; do
			[[ -e "$f" ]] || continue
			name="${f##*/}"
			echo "${name%.dtbo}"
		done | sort
		return 0
	fi

	local boot_scr="/boot/boot.scr"

	# scenario bitmap (see _dt_overlays_edit for the full table)
	local scenario
	scenario=$(_dt_overlays_scenario "$boot_scr")

	if [[ "$scenario" == "10" || "$scenario" == "11" ]]; then
		# Nested prefixes (rockchip-rk3568-hk, rockchip-rk3568) match the
		# same file twice; keep the name of the first prefix only.
		local -A seen_name=() seen_file=()
		for p in "${overlay_prefixes[@]}"; do
			for f in "$overlaydir"/"${p}"-*.dtbo; do
				[[ -e "$f" ]] || continue
				name="${f##*/}"
				name="${name%.dtbo}"
				name="${name#"${p}-"}"
				[[ -n "${seen_name[$name]}" || -n "${seen_file[$f]}" ]] && continue
				seen_name[$name]=1
				seen_file[$f]=1
				echo "$name"
			done
		done | sort
	fi

	if [[ "$scenario" == "01" || "$scenario" == "11" ]]; then
		update_kernel_env
		if [[ "$BOARDFAMILY" == "rockchip-rk3588" && "$BRANCH" == vendor* && "${#overlay_prefixes[@]}" -le 1 ]]; then
			# Installs with one prefix (images before prefix lists): vendor
			# RK3588 overlays carry many board names; offer the ones the
			# prefix does not cover by their full name. Images with a list
			# get board prefixes instead.
			for f in "$overlaydir"/*.dtbo; do
				[[ -e "$f" ]] || continue
				name="${f##*/}"
				name="${name%.dtbo}"
				local covered="false"
				for p in "${overlay_prefixes[@]}"; do
					[[ "$name" == "${p}-"* ]] && covered="true" && break
				done
				[[ "$covered" == "false" ]] && echo "$name"
			done | sort
		fi
	fi
}

#
# Output the overlays this module manages, one per line. On Armbian
# (armbianEnv.txt) the prefix is already stripped on disk; on Pi
# (config.txt) only the block below `# Armbian config` is ours, and we
# emit whatever is on its dtoverlay= lines, parameters included (they
# can contain '=').
#
function _dt_overlays_read_current() {
	if [[ "$is_pi" == "true" ]]; then
		awk '/^# Armbian config$/ {b=1; next}
			b && /^dtoverlay=/ {sub(/^dtoverlay=/, ""); print}' "$overlayconf"
	else
		awk -F= '/^overlays=/ {print $2}' "$overlayconf" | tr ' ' '\n' | awk 'NF'
	fi
}

#
# Output the Pi overlays set above `# Armbian config`, one per line.
# They are enabled, but _dt_overlays_write_config copies them through
# untouched, so they cannot be changed here. Lines under a filter
# such as [cm5] apply to some models only, so they are skipped; [all]
# ends a filter. Nothing on Armbian.
#
function _dt_overlays_read_fixed() {
	[[ "$is_pi" == "true" ]] || return 0
	awk '/^# Armbian config$/ {exit}
		/^\[/ {filtered = ($0 !~ /^\[all\]/); next}
		!filtered && /^dtoverlay=/ {sub(/^dtoverlay=/, ""); print}' "$overlayconf"
}

#
# Print 0 if overlay $1 is set above `# Armbian config`; see
# _dt_overlays_read_fixed. The caller provides the `fixed` array.
#
function _dt_overlays_is_fixed() {
	local t
	for t in "${fixed[@]}"; do
		_dt_overlays_token_matches "$t" "$1" && return 0
	done
	return 1
}

#
# Parse `overlays=foo,bar,baz` from the positional args and emit each
# name on its own line. Empty / missing arg is allowed; caller decides.
#
function _dt_overlays_parse_arg() {
	local arg overlays=""
	for arg in "$@"; do
		case "$arg" in
			overlays=*) overlays="${arg#overlays=}" ;;
		esac
	done
	[[ -z "$overlays" ]] && return 0
	echo "$overlays" | tr ',' '\n' | awk 'NF'
}

function _dt_overlays_show() {
	local overlayconf overlaydir overlay_prefix is_pi
	local -a overlay_prefixes
	_dt_overlays_resolve_paths || return 1

	local current fixed
	current=$(_dt_overlays_read_current)
	fixed=$(_dt_overlays_read_fixed)
	if [[ -z "$current" && -z "$fixed" ]]; then
		echo "(no overlays currently enabled)"
		return 0
	fi
	[[ -n "$current" ]] && echo "$current"
	local t
	while IFS= read -r t; do
		if [[ -n "$t" ]]; then
			echo "$t (set above \"# Armbian config\", edit by hand)"
		fi
	done <<< "$fixed"
}

function _dt_overlays_install() {
	local overlayconf overlaydir overlay_prefix is_pi
	local -a overlay_prefixes
	_dt_overlays_resolve_paths || return 1

	local -a requested
	mapfile -t requested < <(_dt_overlays_parse_arg "$@")
	if [[ "${#requested[@]}" -eq 0 ]]; then
		echo "Error: no overlays specified (use overlays=foo,bar)" >&2
		return 1
	fi

	# Validate every requested name exists in the discovered set. Abort
	# the whole batch on any unknown name — no partial commit.
	local -a available
	mapfile -t available < <(_dt_overlays_discover)
	if [[ "${#available[@]}" -eq 0 ]]; then
		if [[ "$is_pi" == "true" ]]; then
			echo "Error: no overlays found in ${overlaydir}" >&2
		else
			echo "Error: no overlays in ${overlaydir} match overlay_prefix='${overlay_prefix}'" >&2
		fi
		return 1
	fi

	local name found
	local -a unknown=()
	for name in "${requested[@]}"; do
		found="false"
		local a
		for a in "${available[@]}"; do
			if [[ "$a" == "$name" ]]; then
				found="true"
				break
			fi
		done
		[[ "$found" == "false" ]] && unknown+=("$name")
	done
	if [[ "${#unknown[@]}" -gt 0 ]]; then
		echo "Error: unknown overlay(s): ${unknown[*]}" >&2
		echo "Run 'module_devicetree_overlays edit' to see what's available." >&2
		return 1
	fi

	# Merge: current ∪ requested, dedup, preserve insertion order so
	# diffs against the previous file stay readable. Overlays set above
	# `# Armbian config` are already enabled; do not add them again.
	local -a current fixed
	mapfile -t current < <(_dt_overlays_read_current)
	mapfile -t fixed < <(_dt_overlays_read_fixed)

	local -a wanted=()
	for name in "${requested[@]}"; do
		_dt_overlays_is_fixed "$name" || wanted+=("$name")
	done

	local -a merged=()
	for name in "${current[@]}" "${wanted[@]}"; do
		[[ -z "$name" ]] && continue
		local already="false"
		local m
		for m in "${merged[@]}"; do
			if [[ "$m" == "$name" ]] || _dt_overlays_token_matches "$m" "$name"; then
				already="true"
				break
			fi
		done
		[[ "$already" == "false" ]] && merged+=("$name")
	done

	# Idempotent: nothing new to write, exit clean.
	if [[ "${#merged[@]}" -eq "${#current[@]}" ]]; then
		echo "All requested overlays are already enabled."
		return 0
	fi

	_dt_overlays_commit "$(printf '%s\n' "${merged[@]}")"
}

function _dt_overlays_remove() {
	local overlayconf overlaydir overlay_prefix is_pi
	local -a overlay_prefixes
	_dt_overlays_resolve_paths || return 1

	local -a requested
	mapfile -t requested < <(_dt_overlays_parse_arg "$@")
	if [[ "${#requested[@]}" -eq 0 ]]; then
		echo "Error: no overlays specified (use overlays=foo,bar)" >&2
		return 1
	fi

	# Overlays set above `# Armbian config` would survive the rewrite.
	# Refuse the whole batch rather than report a removal that did not
	# happen.
	local -a fixed
	mapfile -t fixed < <(_dt_overlays_read_fixed)
	local name
	local -a stuck=()
	for name in "${requested[@]}"; do
		_dt_overlays_is_fixed "$name" && stuck+=("$name")
	done
	if [[ "${#stuck[@]}" -gt 0 ]]; then
		echo "Error: ${stuck[*]} set above \"# Armbian config\" in ${overlayconf}; edit it there by hand." >&2
		return 1
	fi

	local -a current
	mapfile -t current < <(_dt_overlays_read_current)
	if [[ "${#current[@]}" -eq 0 ]]; then
		echo "No overlays currently enabled."
		return 0
	fi

	local -a kept=()
	local c drop
	for c in "${current[@]}"; do
		drop="false"
		for name in "${requested[@]}"; do
			if _dt_overlays_token_matches "$c" "$name"; then
				drop="true"
				break
			fi
		done
		[[ "$drop" == "false" ]] && kept+=("$c")
	done

	if [[ "${#kept[@]}" -eq "${#current[@]}" ]]; then
		echo "None of the requested overlays were enabled — nothing to do."
		return 0
	fi

	_dt_overlays_commit "$(printf '%s\n' "${kept[@]}")"
}

#
# Commit the new overlay set to the boot config. Input is a newline-
# separated list of names (no prefix). Atomic write + .bak is delegated
# to _dt_overlays_write_config.
#
function _dt_overlays_commit() {
	local newlines="$1"
	local newoverlays

	if [[ "$is_pi" == "true" ]]; then
		# Pi format keeps one overlay per `dtoverlay=` line; pass through
		# the newline-separated list as-is and let the writer emit lines.
		newoverlays="$newlines"
	else
		# Armbian format is a single space-separated `overlays=` line.
		newoverlays=$(echo "$newlines" | tr '\n' ' ')
		newoverlays="${newoverlays% }"
	fi

	_dt_overlays_write_config "$overlayconf" "$is_pi" "$newoverlays"
}

#
# Atomically rewrite the boot config with the new overlay selection.
# Writes to <conf>.tmp, copies the existing <conf> to <conf>.bak (so
# the user has one rollback hop), then mv's tmp into place. A failure
# anywhere in the pipeline leaves the original file untouched.
#
function _dt_overlays_write_config() {
	local conf="$1"
	local is_pi="$2"
	local newoverlays="$3"
	local conf_tmp="${conf}.tmp"
	local conf_bak="${conf}.bak"

	if [[ "$is_pi" == "true" ]]; then
		{
			# Preserve everything before our managed block, then re-emit
			# the block from scratch with the current selection.
			if grep -q '^# Armbian config$' "$conf"; then
				sed '/^# Armbian config$/,$d' "$conf"
			else
				cat "$conf"
			fi
			echo "# Armbian config"
			# End a filter such as [cm5] left open above the block.
			echo "[all]"
			local ov
			while IFS= read -r ov; do
				[[ -z "$ov" ]] && continue
				printf 'dtoverlay=%s\n' "$ov"
			done <<< "$newoverlays"
		} > "$conf_tmp"
	else
		if grep -q "^overlays=" "$conf"; then
			sed "s|^overlays=.*|overlays=${newoverlays}|" "$conf" > "$conf_tmp"
		else
			cat "$conf" > "$conf_tmp"
			echo "overlays=${newoverlays}" >> "$conf_tmp"
		fi
	fi

	if [[ ! -s "$conf_tmp" ]]; then
		echo "Error: would have written empty boot config to ${conf}" >&2
		rm -f "$conf_tmp"
		return 1
	fi

	cp -p "$conf" "$conf_bak" 2>/dev/null || true

	if ! mv "$conf_tmp" "$conf"; then
		echo "Error: failed to install ${conf}" >&2
		rm -f "$conf_tmp"
		return 1
	fi

	echo "Updated ${conf} (previous version saved as ${conf_bak})"
}

#
# Interactive TUI (the historic primary mode). Shares all discovery
# helpers with install/remove so behavior is consistent across modes.
#
function _dt_overlays_edit() {
	local overlayconf overlaydir overlay_prefix is_pi
	local -a overlay_prefixes
	_dt_overlays_resolve_paths || return 1

	# scenario bitmap:
	#   00 — overlays cannot be loaded by /boot/boot.scr
	#   01 — only full name (with prefix) loads
	#   10 — only short name (without prefix) loads
	#   11 — both spellings load
	local boot_scr="/boot/boot.scr"
	local scenario
	scenario=$(_dt_overlays_scenario "$boot_scr")

	if [[ "$is_pi" != "true" && "$scenario" == "00" ]]; then
		dialog_yesno "Manage devicetree overlays" "    The overlays provided by Armbian cannot be loaded\n    by /boot/boot.scr script.\n" "Exit" "Cancel" 11 44
		return 0
	fi

	local changes="false"
	while true; do
		local -a options=()
		local -a available
		mapfile -t available < <(_dt_overlays_discover)
		if [[ "${#available[@]}" -eq 0 ]]; then
			if [[ "$is_pi" == "true" ]]; then
				dialog_yesno "Manage devicetree overlays" "    No overlays found in\n    ${overlaydir}\n" "Exit" "Cancel" 11 44
			else
				dialog_yesno "Manage devicetree overlays" "    No overlay matches\n    overlay_prefix=${overlay_prefix}\n" "Exit" "Cancel" 11 44
			fi
			return 0
		fi

		local -a current fixed
		mapfile -t current < <(_dt_overlays_read_current)
		mapfile -t fixed < <(_dt_overlays_read_fixed)

		# Overlays set above `# Armbian config` are not listed: unticking
		# one could not disable it. Name them in the dialog text instead.
		local note=""
		[[ "${#fixed[@]}" -gt 0 ]] && note="\nSet above \"# Armbian config\" (edit by hand):\n    ${fixed[*]}\n"

		local overlay status token
		for overlay in "${available[@]}"; do
			[[ -z "$overlay" ]] && continue
			_dt_overlays_is_fixed "$overlay" && continue
			status="OFF"
			for token in "${current[@]}"; do
				_dt_overlays_token_matches "$token" "$overlay" && status="ON" && break
			done
			options+=( "$overlay" "" "$status" )
		done

		local selection
		selection=$(dialog_checklist "Manage devicetree overlays" "\nUse <space> to toggle functions and save them.\nExit when you are done.\n\n    overlay_prefix=$overlay_prefix\n${note} " 0 0 0 --cancel-button "Back" --ok-button "Save" -- "${options[@]}")
		local exit_status=$?

		case "$exit_status" in
			0)
				changes="true"
				local newoverlays
				newoverlays=$(echo "$selection" | sed 's/"//g')

				# Keep enabled overlays the dialog does not list (set by full
				# name, or by hand); the selection replaces the listed ones.
				local -a ovs
				IFS=' ' read -r -a ovs <<< "$newoverlays"
				newoverlays=""
				local ov listed
				for token in "${current[@]}"; do
					listed="false"
					for overlay in "${available[@]}"; do
						_dt_overlays_token_matches "$token" "$overlay" && listed="true" && break
					done
					[[ "$listed" == "false" ]] && newoverlays+="$token "
				done
				# A selected overlay that is already enabled keeps its stored
				# spelling, so Pi parameters (foo,param=1) survive a save.
				local kept
				for ov in "${ovs[@]}"; do
					kept="$ov"
					for token in "${current[@]}"; do
						_dt_overlays_token_matches "$token" "$ov" && kept="$token" && break
					done
					newoverlays+="$kept "
				done
				newoverlays="${newoverlays% }"

				if [[ "$is_pi" == "true" ]]; then
					# Pi writer expects one overlay per line.
					_dt_overlays_write_config "$overlayconf" "$is_pi" "$(echo "$newoverlays" | tr ' ' '\n')" || return 1
				else
					_dt_overlays_write_config "$overlayconf" "$is_pi" "$newoverlays" || return 1
				fi
				;;
			1)
				if [[ "$changes" == "true" ]]; then
					dialog_yesno "Reboot required" "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34
					[[ $? == 0 ]] && systemctl reboot
				fi
				break
				;;
			255)
				;;
		esac
	done
}

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
					# Rockchip RK3588/RK35xx exception: vendor kernel uses rk35xx
					# suffix, current/edge kernels use rockchip64. The vendor BSP
					# family is BOARDFAMILY=rockchip-rk3588 on some boards (Rock 5B)
					# and BOARDFAMILY=rk35xx on others (NanoPi M5), so match both.
					if [[ "${BOARDFAMILY}" == "rockchip-rk3588" || "${BOARDFAMILY}" == "rk35xx" ]]; then
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
					# NB: the family can itself contain '-' (e.g. spacemit-k3,
					# sun55iw3-syterkit), so take fields 4-onward -- 'cut -f4' alone
					# truncates 'spacemit-k3' to 'spacemit' and would then install the
					# wrong SoC's kernel (linux-image-legacy-spacemit) and purge the
					# correct one, leaving the board with no matching DTB (unbootable).
					local branch=$(echo "${target_version}" | cut -d'-' -f3)
					local linuxfamily=$(echo "${target_version}" | cut -d'-' -f4- | cut -d'=' -f1)
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

			# Resolve the kernel package family. When the caller does not pass one
			# ($5 empty -- e.g. an --api call or the autotests harness that wants us
			# to decide), default to the running kernel's family. Then apply the
			# per-board exceptions where the family DEPENDS ON THE BRANCH, so a
			# manual/API branch switch targets the right package. Rockchip RK3588
			# ships vendor/legacy as the BSP -rk35xx kernels but current/edge as
			# mainline -rockchip64; without this remap, switching vendor -> current
			# would look for the nonexistent linux-image-current-rk35xx. The vendor
			# BSP family is BOARDFAMILY=rockchip-rk3588 on some boards (Rock 5B) and
			# BOARDFAMILY=rk35xx on others (NanoPi M5), so match both. This mirrors
			# the naming logic already used by the interactive selector.
			[[ -z "${linuxfamily}" ]] && linuxfamily="${KERNELPKG_LINUXFAMILY}"
			if [[ "${BOARDFAMILY}" == "rockchip-rk3588" || "${BOARDFAMILY}" == "rk35xx" ]]; then
				case "${branch}" in
					vendor|legacy) linuxfamily="rk35xx" ;;
					current|edge)  linuxfamily="rockchip64" ;;
				esac
			fi

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

			# Downloads succeeded and are cached. Install the NEW kernel FIRST (before
			# pruning anything), served from that cache. Two reasons this order
			# matters — reversing it (the old "purge linux-image* then install")
			# strands the board with NO kernel:
			#   * apt replaces the same-named packages in place, so a bootable kernel
			#     is present at every step; if the install fails, the current kernel
			#     is left untouched instead of already-purged.
			#   * direct apt-get (like the download above) gives a trustworthy exit
			#     code — pkg_install's dialog-gauge path masks apt failures, so a
			#     failed install used to look like success right after the purge.
			#
			# Install linux-headers in its OWN transaction, BEFORE linux-image. In a
			# single combined transaction apt is free to configure linux-image before
			# linux-headers; the image postinst then runs its DKMS module builds with
			# no kernel headers present and fails on the first pass (needs an
			# 'apt-get -f install' retry to self-heal, and on older images aborts
			# before the boot-symlink relink, which can leave the board unbootable —
			# see armbian/build#10766). Two transactions guarantee the headers are
			# fully configured first, so DKMS builds succeed on the first pass. Both
			# are served from the cache the --download-only step populated above, so
			# there is no extra network I/O.
			# ${packages} is a space-delimited scalar, not an array -- it is built with
			# packages+="${pkg} " above, and every other user in this file expands it
			# unquoted on purpose. Split it once, here, so the classification below sees
			# one package per iteration instead of the whole list as a single word.
			local hdr_pkgs=() rest_pkgs=() split_pkgs=() _p
			read -r -a split_pkgs <<< "${packages}"
			for _p in "${split_pkgs[@]}"; do
				case "$_p" in
					linux-headers-*) hdr_pkgs+=("$_p") ;;
					*)               rest_pkgs+=("$_p") ;;
				esac
			done

			if [[ ${#hdr_pkgs[@]} -gt 0 ]] \
				&& ! DEBIAN_FRONTEND=noninteractive apt-get install --allow-downgrades -y "${hdr_pkgs[@]}" > /dev/null 2>&1; then
				rm -f /etc/apt/preferences.d/armbian-upgrade-policy
				echo "Error: kernel headers install failed — current kernel left in place. Try again later and report to the Armbian forums."
				return 1
			fi

			if ! DEBIAN_FRONTEND=noninteractive apt-get install --allow-downgrades -y "${rest_pkgs[@]}" > /dev/null 2>&1; then
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
				# Purge the old branch's kernel packages. Do NOT hide the result
				# behind '|| true': this often targets the *running* kernel (a
				# switch happens before the reboot), whose postrm hooks (initramfs /
				# bootloader update) can return non-zero -- which used to be
				# swallowed, silently leaving the old kernel installed next to the
				# new one. So: purge, then re-check what is still installed, retry
				# once after fixing any half-configured state, and report clearly
				# what could not be removed. The new kernel is already installed and
				# verified above, so a leftover old one is a warning, not fatal.
				DEBIAN_FRONTEND=noninteractive apt-get purge -y "${stale[@]}" > /dev/null 2>&1 || true
				# Any state other than 'not-installed' means the purge did not
				# finish. A postrm that fails leaves half-installed / unpacked /
				# half-configured, and a purge that degrades to a plain remove
				# leaves config-files -- matching only 'installed' would skip
				# precisely the states this code exists to catch. A dpkg-query
				# failure means dpkg has never heard of the package: nothing left.
				local leftover=() spkg spkg_state
				for spkg in "${stale[@]}"; do
					spkg_state="$(dpkg-query -W -f='${db:Status-Status}\n' "$spkg" 2>/dev/null)" || continue
					if [[ -n "$spkg_state" && "$spkg_state" != "not-installed" ]]; then
						leftover+=("$spkg")
					fi
				done
				if [[ ${#leftover[@]} -gt 0 ]]; then
					# a transient dpkg lock or a half-configured package can clear
					# on a second pass
					DEBIAN_FRONTEND=noninteractive dpkg --configure -a > /dev/null 2>&1 || true
					DEBIAN_FRONTEND=noninteractive apt-get purge -y "${leftover[@]}" > /dev/null 2>&1 || true
					local still=()
					for spkg in "${leftover[@]}"; do
						spkg_state="$(dpkg-query -W -f='${db:Status-Status}\n' "$spkg" 2>/dev/null)" || continue
						if [[ -n "$spkg_state" && "$spkg_state" != "not-installed" ]]; then
							still+=("$spkg")
						fi
					done
					if [[ ${#still[@]} -gt 0 ]]; then
						echo "Warning: could not remove the previous kernel package(s): ${still[*]}." >&2
						echo "         The new kernel is installed, but the old one is still present; remove it after rebooting onto the new kernel: apt-get purge ${still[*]}" >&2
					fi
				fi
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
			[[ "$prev_host" != "$target_host" ]] && \
				sed -i "s|[a-zA-Z0-9.-]*\.armbian\.com|${target_host}|g" "$sources_file"

			# Refresh the index so the madison check below reflects the TARGET repo's
			# current contents. Needed after an actual switch, but also on a no-op
			# switch (already on the requested repo) where the ambient index may be
			# stale or entirely absent — e.g. a freshly provisioned container with no
			# apt lists yet, which otherwise makes madison find nothing and the switch
			# wrongly report the repo as publishing no kernel.
			pkg_update

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

module_options+=(
	["module_openssh-server,author"]="@armbian"
	["module_openssh-server,maintainer"]="@igorpecovnik"
	["module_openssh-server,feature"]="module_openssh-server"
	["module_openssh-server,example"]="install remove purge status help"
	["module_openssh-server,desc"]="Install openssh-server container"
	["module_openssh-server,status"]="Active"
	["module_openssh-server,doc_link"]="https://docs.linuxserver.io/images/docker-openssh-server/#server-mode"
	["module_openssh-server,group"]="Network"
	["module_openssh-server,port"]="2222"
	["module_openssh-server,arch"]="x86-64 arm64"
)
#
# Module openssh-server
#
function module_openssh-server () {
	local title="openssh-server"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
		# Containers can't run when Docker's storage is on overlay (overlayroot);
		# remove and purge still work there
		if [[ "$1" == "install" ]]; then
			docker_check_overlay_root || return 1
		fi
	fi

	local container=$(docker container ls -a --filter "name=openssh-server" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep 'lscr.io/linuxserver/openssh-server:' | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openssh-server,example"]}"

	OPENSSHSERVER_BASE="${SOFTWARE_FOLDER}/openssh-server"

	case "$1" in
		"${commands[0]}")
			[[ -d "${OPENSSHSERVER_BASE}" ]] || mkdir -p "${OPENSSHSERVER_BASE}" || { echo "Couldn't create storage directory: ${OPENSSHSERVER_BASE}"; return 1; }
			USER_NAME=$(dialog_inputbox "Enter username" "\nHit enter for defaults" "upload")
			PUBLIC_KEY=$(dialog_inputbox "Enter public key" "" "" 9 50)
			MOUNT_POINT=$(dialog_inputbox "Enter shared folder path" "" "${SOFTWARE_FOLDER}/swag/config/www")
			docker run -d \
			--name=openssh-server \
			--net=lsio \
			--hostname=openssh-server `#optional` \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e PUBLIC_KEY="${PUBLIC_KEY}"  \
			-e SUDO_ACCESS=false \
			-e PASSWORD_ACCESS=false  \
			-e USER_PASSWORD=password \
			-e USER_NAME="${USER_NAME}" \
			-p 2222:2222 \
			-v "${OPENSSHSERVER_BASE}/config:/config" \
			-v "${MOUNT_POINT}:/config/storage" \
			--restart unless-stopped \
			lscr.io/linuxserver/openssh-server:latest
			wait_for_container_ready "openssh-server" 20 3 "running" || return 1
			# read container version
			container_version=$(docker exec openssh-server /bin/bash -c "grep ^PRETTY_NAME= /etc/os-release | sed -E 's/PRETTY_NAME=\"([^\"]*) v[0-9].*/\\1/'")
			# install rsync
			docker exec openssh-server /bin/bash -c "
			apk update; apk add rsync;
			echo '' > /etc/motd;
			echo \"Welcome to your sandboxed Armbian SSH environment running $container_version\" >> /etc/motd;
			echo '' >> /etc/motd;
			"
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_openssh-server,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${OPENSSHSERVER_BASE}" && "${OPENSSHSERVER_BASE}" != "/" ]]; then
				rm -rf "${OPENSSHSERVER_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_openssh-server,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openssh-server,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_openssh-server,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_headers,author"]="@armbian"
	["module_headers,maintainer"]="@igorpecovnik"
	["module_headers,feature"]="module_headers"
	["module_headers,desc"]="Install kernel headers for building kernel modules"
	["module_headers,example"]="install remove status help"
	["module_headers,port"]=""
	["module_headers,status"]="Active"
	["module_headers,arch"]=""
	["module_headers,doc_link"]="https://www.kernel.org/doc/html/latest/"
	["module_headers,group"]="System"
	["module_headers,help_remove"]="Remove kernel headers and build dependencies"
)
#
# Module Headers
#
function module_headers () {
	local title="Kernel Headers"
	local install_pkg=""

	# Determine the correct headers package to install
	if [[ -f /etc/armbian-release ]]; then
		source /etc/armbian-release
		# Branch information is stored in armbian-release at boot time.
		# When we change kernel branches, we need to re-read this and update it
		update_kernel_env
		if [[ -n "${BRANCH}" && -n "${LINUXFAMILY}" ]]; then
			install_pkg="linux-headers-${BRANCH}-${LINUXFAMILY}"
		fi
	fi
	if [[ -z "${install_pkg}" ]]; then
		local arch
		arch="$(dpkg --print-architecture)" || return 1
		local kernel_release
		kernel_release="$(uname -r)" || return 1
		# Remove architecture suffix from kernel release if present
		install_pkg="linux-headers-$(echo "${kernel_release}" | sed "s/-${arch}//")"
	fi

	# Validate we determined a package name
	if [[ -z "${install_pkg}" ]]; then
		echo "Error: Unable to determine kernel headers package name"
		return 1
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_headers,example"]}"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			if pkg_installed "${install_pkg}"; then
				echo "Kernel headers are already installed: ${install_pkg}"
				return 0
			fi

			echo "Installing kernel headers: ${install_pkg}"
			pkg_update
			pkg_install "${install_pkg}" build-essential git || return 1
			echo "Kernel headers installed successfully"
		;;
		"${commands[1]}")
			echo "Removing kernel headers: ${install_pkg}"
			pkg_remove "${install_pkg}" build-essential || return 1
			# Safely remove header directories
			if compgen -G "/usr/src/linux-headers*" > /dev/null; then
				rm -rf /usr/src/linux-headers*
				echo "Kernel headers removed successfully"
			fi
		;;
		"${commands[2]}")
			if pkg_installed "${install_pkg}"; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			show_module_help "module_headers" "$title" "" "native"
		;;
		*)
			${module_options["module_headers,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_overlayfs,author"]="@igorpecovnik"
	["module_overlayfs,maintainer"]="@igorpecovnik"
	["module_overlayfs,feature"]="module_overlayfs"
	["module_overlayfs,example"]="install remove status help"
	["module_overlayfs,desc"]="Set Armbian root filesystem to read only"
	["module_overlayfs,status"]="Active"
	["module_overlayfs,doc_link"]="https://docs.kernel.org/filesystems/overlayfs.html"
	["module_overlayfs,group"]="System"
	["module_overlayfs,port"]=""
	["module_overlayfs,arch"]=""
)
#
# Install overlayroot for read-only root filesystem
#
function module_overlayfs() {
	local title="overlayfs"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_overlayfs,example"]}"

	OVERLAYFS_BASE="${SOFTWARE_FOLDER}/overlayfs"

	case "$1" in
		"${commands[0]}")
			pkg_install --reinstall -o Dpkg::Options::="--force-confold" overlayroot busybox-static
			cat > /etc/overlayroot.conf <<-EOT
			# overlayroot config - managed by configng
			overlayroot_cfgdisk="disabled"
			overlayroot="tmpfs"
			EOT
			rm -f /etc/update-motd.d/97-overlayroot

			if dialog_yesno " Reboot required " "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
			reboot
			fi
		;;
		"${commands[1]}")
			overlayroot-chroot rm /etc/overlayroot.conf > /dev/null 2>&1
			if dialog_yesno " Reboot required " "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
			reboot
			fi
		;;
		"${commands[2]}")
			overlayroot-chroot true > /dev/null 2>&1
			case $? in
				0) return 0 ;;
				*) return 1 ;;
			esac
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_overlayfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_overlayfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;
		*)
			${module_options["module_overlayfs,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_nfsd,author"]="@igorpecovnik"
	["module_nfsd,feature"]="module_nfsd"
	["module_nfsd,desc"]="Install nfsd server"
	["module_nfsd,example"]="install remove manage add status clients servers help"
	["module_nfsd,port"]=""
	["module_nfsd,status"]="Active"
	["module_nfsd,arch"]=""
)
#
# Module nfsd
#
function module_nfsd () {
	local title="nfsd"
	local condition=$(which "$title" 2>/dev/null)?

	local service_name=nfs-server.service

	# we will store our config in subfolder
	mkdir -p /etc/exports.d/

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfsd,example"]}"

	NFSD_BASE="${SOFTWARE_FOLDER}/nfsd"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common nfs-kernel-server
			# add some exports
			${module_options["module_nfsd,feature"]} ${commands[2]}
			srv_restart $service_name
		;;
		"${commands[1]}")
			pkg_remove nfs-kernel-server
		;;
		"${commands[2]}")
			while true; do
				LIST=() IFS=$'\n' LIST=($(grep "^[^#;]" /etc/exports.d/armbian.exports))
				LIST_LENGTH=${#LIST[@]}
				if [[ "${LIST_LENGTH}" -ge 1 ]]; then
					line=$(dialog --no-items \
					--title "Select export to edit" \
					--ok-label "Add" \
					--cancel-label "Apply" \
					--extra-button \
					--extra-label "Delete" \
					--menu "" \
					$((${LIST_LENGTH} + 6)) \
					80 \
					$((${LIST_LENGTH})) \
					${LIST[@]} 3>&1 1>&2 2>&3)
					exitstatus=$?
					case "$exitstatus" in
						0)
							${module_options["module_nfsd,feature"]} ${commands[3]}
						;;
						1)
							break
						;;
						3)
							sed -i '\?^'$line'?d' /etc/exports.d/armbian.exports
						;;
					esac
				else
					${module_options["module_nfsd,feature"]} ${commands[3]}
					break
				fi
			done
			srv_restart $service_name
		;;
		"${commands[3]}")
			# choose between most common options
			LIST=()
			LIST=("ro" "Allow read only requests" On)
			LIST+=("rw" "Allow read and write requests" OFF)
			LIST+=("sync" "Immediate sync all writes" On)
			LIST+=("fsid=0" "Check man pages" OFF)
			LIST+=("no_subtree_check" "Disables subtree checking, improves reliability" On)
			LIST_LENGTH=$((${#LIST[@]}/3))
			if add_folder=$(dialog --title \
							"Which folder do you want to export?" \
							--inputbox "" \
							6 80 "${SOFTWARE_FOLDER}" 3>&1 1>&2 2>&3); then
				if add_ip=$(dialog --title \
							"Which IP or range can access this folder?" \
							--inputbox "\nExamples: 192.168.1.1, 192.168.1.0/24" \
							8 80 "${LOCALSUBNET}" 3>&1 1>&2 2>&3); then
					if add_options=$(dialog --separate-output \
							--nocancel \
							--title "NFS volume options" \
							--checklist "" \
							$((${LIST_LENGTH} + 6)) 80 ${LIST_LENGTH} "${LIST[@]}" 3>&1 1>&2 2>&3); then
							echo "$add_folder $add_ip($(echo $add_options | tr ' ' ','))" \
							>> /etc/exports.d/armbian.exports
							[[ -n "${add_folder}" ]] && mkdir -p "${add_folder}"
					fi
				fi
			fi
		;;
		"${commands[4]}")
			pkg_installed nfs-kernel-server
		;;
		"${commands[5]}")
			show_message <<< $(printf '%s\n' "${NFS_CLIENTS_CONNECTED[@]}")
		;;
		"${commands[6]}")

			if ! pkg_installed nmap; then
				pkg_install nmap
			fi

			LIST=($(nmap -oG - -p2049 ${LOCALSUBNET} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there
					LIST=($(showmount -e "${nfs_server}" | tail -n +2 | cut -d" " -f1 | sort))
					VERIFIED_LIST=()
					local tempfolder=$(mktemp -d)
					local alreadymounted=$(df | grep $nfs_server | cut -d" " -f1 | xargs)
					for i in "${LIST[@]}"; do
						mount -n -t nfs $nfs_server:$i ${tempfolder} 2>/dev/null
						if [[ $? -eq 0 ]]; then
							if echo "${alreadymounted}" | grep -vq $i; then
							VERIFIED_LIST+=($i)
							fi
							umount ${tempfolder}
						fi
					done
					VERIFIED_LIST_LENGTH=$((${#VERIFIED_LIST[@]}))
					if shares=$(dialog --no-items \
						--title "Network filesystem (NFS) shares on ${nfs_server}" \
						--menu "" \
						$((${VERIFIED_LIST_LENGTH} + 6)) \
						80 \
						$((${VERIFIED_LIST_LENGTH})) \
						${VERIFIED_LIST[@]} 3>&1 1>&2 2>&3)
						then
							if mount_folder=$(dialog --title \
							"Where do you want to mount $shares ?" \
							--inputbox "" \
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
								if mount_options=$(dialog --title \
								"Which mount options do you want to use?" \
							--inputbox "" \
							6 80 "auto,noatime 0 0" 3>&1 1>&2 2>&3); then
								mkdir -p ${mount_folder}
								read
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								srv_daemon_reload
								mount ${mount_options}
							fi
							fi
						fi
					fi
		;;
		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_nfsd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfsd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tmanage\t- Edit exports in $title."
			echo -e "\tadd\t- Add exports to $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_nfsd,feature"]} ${commands[7]}
		;;
	esac
}

module_options+=(
	["change_system_hostname,author"]="@igorpecovnik"
	["change_system_hostname,ref_link"]=""
	["change_system_hostname,feature"]="Change hostname"
	["change_system_hostname,desc"]="change_system_hostname"
	["change_system_hostname,example"]="change_system_hostname"
	["change_system_hostname,status"]="Active"
)
#
# @description Change system hostname
#
function change_system_hostname() {
	local new_hostname=$(dialog_inputbox "Enter new hostname" "" "" 7 50)
	[ $? -eq 0 ] && [ -n "${new_hostname}" ] && hostnamectl set-hostname "${new_hostname}"
}


module_options+=(
	["module_tuning_profile,author"]="@igorpecovnik"
	["module_tuning_profile,maintainer"]="@igorpecovnik"
	["module_tuning_profile,feature"]="module_tuning_profile"
	["module_tuning_profile,desc"]="Kernel and CPU tuning profiles for the machine's actual role"
	["module_tuning_profile,example"]="select apply status list reset cpu help"
	["module_tuning_profile,port"]=""
	["module_tuning_profile,status"]="Active"
	["module_tuning_profile,arch"]="x86-64 arm64 armhf riscv64"
	["module_tuning_profile,doc_link"]="https://docs.armbian.com/User-Guide_Fine-Tuning/"
	["module_tuning_profile,group"]="System"
	["module_tuning_profile,config_file"]="/etc/sysctl.d/99-zz-armbian-tuning-profile.conf"
	# Custom command help descriptions
	["module_tuning_profile,help_select"]="Pick a tuning profile from a menu"
	["module_tuning_profile,help_apply"]="Apply a profile by name: apply sbc|balanced|desktop|builder|nas"
	["module_tuning_profile,help_status"]="Show the active profile and the live kernel values"
	["module_tuning_profile,help_list"]="List available profiles and what each one is for"
	["module_tuning_profile,help_reset"]="Remove the profile and return to distribution defaults"
	["module_tuning_profile,help_cpu"]="CPU frequency per cluster: cpu [select|status|apply|reset|set <all|policy<list>> <governor|min|max|boost|clear> [value]]"
)
#
# Tuning profiles
#
# Armbian's defaults are tuned for the machine most Armbian users have: an SBC
# booting from a microSD card, where flash write endurance is the scarce
# resource and RAM is measured in hundreds of megabytes. Those defaults defer
# writeback for two minutes and swap eagerly into zram.
#
# The same userspace also runs on 32-thread NVMe build servers, NAS boxes and
# desktops, where that tuning is not merely suboptimal but actively harmful.
# Observed on an Armbian CI build host, 2026-09-26: deferred writeback meant a
# full sync could not complete inside the build framework's 30s timeout; the
# timed-out sync could not be killed (SIGKILL does not reap a task blocked in
# sync_inodes_sb) and the caller spawned another. 1600+ stuck syncs, load
# average 1424, CPU 98% idle, on hardware that was not the constraint.
#
# So: name the roles, and let the machine be told which one it has.
#
# What a profile owns:
#   - vm.swappiness                  how eagerly anonymous pages are swapped
#   - vm dirty thresholds            how much unwritten data may accumulate
#   - vm writeback/expire intervals  how often the flusher threads run
#   - ext4 commit interval on /      how long the journal batches metadata
#   - CPU energy/performance bias    where on the power/speed curve to sit
#
# The "cpu" command manages governor and frequency limits per CPU cluster. A
# profile does not change those; see "CPU frequency" below.
#
# The ext4 commit interval goes in /etc/fstab, where a mount option belongs. It
# is tempting to avoid that file and apply the option with `mount -o remount`
# from a boot-time unit instead, on the grounds that a bad fstab does not boot.
# That trade is worse than it looks: it leaves fstab and the live mount
# disagreeing, so the next person to read either one is misled, and `findmnt`
# stops being the answer to "what are we mounted with". The editing is made safe
# instead -- timestamped backup, only the root line's commit= token touched, the
# candidate checked before it replaces the real file, and the backup restored if
# it does not pass.

# 99-zz- and not 99-: systemd-sysctl applies /etc/sysctl.d in filename order and
# the last writer wins. Armbian ships vm.swappiness in 99-armbian-memory.conf AND
# again in /etc/sysctl.conf, which is linked in as 99-sysctl.conf -- and "sysctl"
# sorts after "armbian", so a file named 99-armbian-* loses to it on every boot.
# Sorting after everything numeric is the only placement that reliably wins. The
# apply step verifies the outcome rather than trusting this, because a local file
# can always be added later that sorts after even this one.
declare -g TP_SYSCTL_FILE="/etc/sysctl.d/99-zz-armbian-tuning-profile.conf"
declare -g TP_UNIT_FILE="/etc/systemd/system/armbian-tuning-profile.service"
declare -g TP_STATE_FILE="/etc/default/armbian-tuning-profile"

# Total RAM in kB.
function _tp_mem_kb() {
	awk '/^MemTotal:/{print $2; exit}' /proc/meminfo 2>/dev/null || echo 0
}

# _tp_scaled <percent> <cap_bytes> -> bytes
# A percentage of RAM, optionally capped. Percentages alone do not travel: 20%
# is 200 MB on a 1 GB board and 25 GB on a 125 GB server, and 25 GB of dirty
# data is far more than any single sync should ever have to flush. The cap is
# what keeps a flush bounded in time on a large machine; the percentage is what
# keeps it sane on a small one.
function _tp_scaled() {
	local pct="$1" cap="$2" mem_kb bytes
	mem_kb="$(_tp_mem_kb)"
	bytes=$(( mem_kb / 100 * pct * 1024 ))
	[[ -n "$cap" && "$cap" -gt 0 && "$bytes" -gt "$cap" ]] && bytes="$cap"
	# never below 32 MiB, or a tiny board throttles writers constantly
	[[ "$bytes" -lt 33554432 ]] && bytes=33554432
	echo "$bytes"
}

# Is / on ext4? The commit interval is an ext4 mount option; on btrfs/f2fs/xfs
# there is nothing to set here and we say so rather than failing.
function _tp_root_is_ext4() {
	[[ "$(findmnt -no FSTYPE / 2>/dev/null)" == "ext4" ]]
}

# Does this CPU expose an energy/performance preference? (intel_pstate and
# amd-pstate-epp do; most ARM cpufreq drivers do not.)
function _tp_has_epp() {
	[[ -e /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]
}

# _tp_profile_list -> "name|one-line description" per profile
function _tp_profile_list() {
	cat <<- 'PROFILES'
		sbc|SD card or eMMC boot - minimise writes, trade latency for flash life
		balanced|Distribution defaults - no strong bias either way
		desktop|Interactive use - keep the UI responsive, flush little and often
		builder|Compile or CI host on SSD/NVMe - keep sync cheap, CPU at full tilt
		nas|File server - absorb large streaming writes, modest CPU
	PROFILES
}

# _tp_is_profile <name>
function _tp_is_profile() {
	local name="$1"
	_tp_profile_list | cut -d'|' -f1 | grep -qx -- "$name"
}

# _tp_emit_sysctl <profile> -> the sysctl body for that profile
#
# Byte-based dirty limits are used wherever the machine may be large;
# ratio-based ones where the SBC default is the point. Setting *_bytes zeroes
# the corresponding *_ratio and vice versa, so a profile picks one form and
# states it, rather than leaving both half-set.
function _tp_emit_sysctl() {
	local profile="$1"

	case "$profile" in
		sbc)
			cat <<- EOF
				# Flash endurance first. Writeback is deferred so that many small
				# writes coalesce into few erase blocks, and zram is preferred over
				# any real swap device.
				vm.swappiness = 100
				vm.dirty_ratio = 20
				vm.dirty_background_ratio = 1
				vm.dirty_writeback_centisecs = 12000
				vm.dirty_expire_centisecs = 12000
				vm.vfs_cache_pressure = 50
			EOF
			;;
		balanced)
			cat <<- EOF
				# Kernel defaults. Reasonable when the machine has no strong role.
				vm.swappiness = 60
				vm.dirty_ratio = 20
				vm.dirty_background_ratio = 10
				vm.dirty_writeback_centisecs = 500
				vm.dirty_expire_centisecs = 3000
				vm.vfs_cache_pressure = 100
			EOF
			;;
		desktop)
			cat <<- EOF
				# Responsiveness first. Small dirty limits mean the flusher never
				# has a large backlog, so an application that calls fsync does not
				# stall the desktop behind somebody else's writeback.
				vm.swappiness = 10
				vm.dirty_bytes = $(_tp_scaled 10 2147483648)
				vm.dirty_background_bytes = $(_tp_scaled 3 536870912)
				vm.dirty_writeback_centisecs = 500
				vm.dirty_expire_centisecs = 3000
				vm.vfs_cache_pressure = 100
			EOF
			;;
		builder)
			cat <<- EOF
				# Compile/CI host on SSD or NVMe.
				#
				# The build framework calls sync(1) from many places, under a
				# timeout. sync(1) is global: it flushes every filesystem, so
				# concurrent builds wait on each other's dirty pages. A task
				# blocked in sync_inodes_sb cannot be killed, so a sync that
				# exceeds its timeout leaks and the caller starts another.
				#
				# The cap below exists so that a full flush always completes well
				# inside such a timeout: a few GB on a device sustaining hundreds
				# of MB/s is seconds, not minutes.
				vm.swappiness = 1
				vm.dirty_bytes = $(_tp_scaled 10 4294967296)
				vm.dirty_background_bytes = $(_tp_scaled 3 1073741824)
				vm.dirty_writeback_centisecs = 500
				vm.dirty_expire_centisecs = 3000
				vm.vfs_cache_pressure = 100
			EOF
			;;
		nas)
			cat <<- EOF
				# File server. Large sequential writes benefit from a deeper buffer
				# than the desktop profile allows, but writeback still runs often
				# enough that a client's fsync is not waiting on a huge backlog.
				vm.swappiness = 10
				vm.dirty_bytes = $(_tp_scaled 20 8589934592)
				vm.dirty_background_bytes = $(_tp_scaled 5 2147483648)
				vm.dirty_writeback_centisecs = 1500
				vm.dirty_expire_centisecs = 3000
				vm.vfs_cache_pressure = 50
			EOF
			;;
	esac
}

# _tp_commit_interval <profile> -> ext4 commit seconds
function _tp_commit_interval() {
	case "$1" in
		sbc)      echo 120 ;;
		balanced) echo 5 ;;
		desktop)  echo 15 ;;
		builder)  echo 30 ;;
		nas)      echo 30 ;;
	esac
}

# _tp_epp <profile> -> energy_performance_preference value, or empty for none
function _tp_epp() {
	case "$1" in
		sbc)      echo "power" ;;
		balanced) echo "default" ;;
		desktop)  echo "balance_performance" ;;
		builder)  echo "performance" ;;
		nas)      echo "balance_power" ;;
	esac
}

# _tp_set_fstab_commit <seconds|"">
#
# Set, replace or remove the ext4 commit= option on the root line of /etc/fstab.
# An empty argument removes it, returning the filesystem to the kernel default.
#
# The root line is found by mount point (field 2 == "/"), not by matching the
# device: a UUID regex would also have to cope with LABEL=, PARTUUID= and a bare
# /dev path, and would silently do nothing on whichever form it did not expect.
#
# The result is checked structurally rather than with `findmnt --verify`: that
# command also reports on whether each source is reachable, so it fails on a
# perfectly well-formed fstab whose devices are not present, and using it as the
# gate here would refuse the edit on machines that have some unrelated warning.
# What actually matters is narrower and fully checkable: still exactly one root
# line, its device, mount point and filesystem type untouched, and the commit
# option in the state we asked for. Anything else and the backup goes back.
function _tp_set_fstab_commit() {
	local commit="$1" fstab="/etc/fstab" backup tmp
	local before_root after_root

	[[ -f "$fstab" ]] || { echo "  no /etc/fstab -- skipping commit interval"; return 0; }

	# Is there a root line to edit at all? Some systems mount / from the kernel
	# command line and carry no fstab entry for it.
	if ! awk '$1 !~ /^#/ && $2 == "/" {found=1} END{exit !found}' "$fstab"; then
		echo "  no root entry in /etc/fstab -- skipping commit interval"
		return 0
	fi

	backup="${fstab}.armbian-tuning.$(date +%Y%m%d-%H%M%S)"
	cp -a "$fstab" "$backup" || { echo "  could not back up ${fstab}" >&2; return 1; }
	tmp="$(mktemp)" || return 1

	# device, mount point and fstype of the root line, as they are now
	before_root="$(awk '$1 !~ /^#/ && $2 == "/" {print $1, $2, $3; exit}' "$fstab")"

	awk -v commit="$commit" '
		# Comments and every non-root line pass through untouched.
		$1 ~ /^#/ || $2 != "/" { print; next }
		{
			n = split($4, opts, ",")
			out = ""
			for (i = 1; i <= n; i++) {
				if (opts[i] ~ /^commit=/) continue          # drop any existing one
				out = (out == "" ? opts[i] : out "," opts[i])
			}
			if (out == "") out = "defaults"                 # never leave the field empty
			if (commit != "") out = out ",commit=" commit
			$4 = out
			# Rebuild with tabs, matching how fstab is conventionally written.
			print $1 "\t" $2 "\t" $3 "\t" $4 "\t" ($5 == "" ? "0" : $5) "\t" ($6 == "" ? "1" : $6)
		}
	' "$fstab" > "$tmp" || { rm -f "$tmp"; return 1; }

	# Check the candidate before it becomes /etc/fstab, so the real file is never
	# briefly wrong.
	after_root="$(awk '$1 !~ /^#/ && $2 == "/" {print $1, $2, $3; exit}' "$tmp")"

	if [[ "$(awk '$1 !~ /^#/ && $2 == "/"' "$tmp" | wc -l)" -ne 1 ]]; then
		rm -f "$tmp"
		echo "  refusing to write /etc/fstab: expected exactly one root entry" >&2
		return 1
	fi
	if [[ "$after_root" != "$before_root" ]]; then
		rm -f "$tmp"
		echo "  refusing to write /etc/fstab: root entry changed unexpectedly" >&2
		echo "    before: ${before_root}" >&2
		echo "    after:  ${after_root}" >&2
		return 1
	fi
	# And the option itself is in the state we asked for.
	if [[ -n "$commit" ]]; then
		awk -v c="commit=${commit}" '$1 !~ /^#/ && $2 == "/" && $4 ~ ("(^|,)" c "($|,)")' "$tmp" | grep -q . || {
			rm -f "$tmp"; echo "  refusing to write /etc/fstab: commit=${commit} not present in result" >&2; return 1; }
	else
		awk '$1 !~ /^#/ && $2 == "/" && $4 ~ /(^|,)commit=/' "$tmp" | grep -q . && {
			rm -f "$tmp"; echo "  refusing to write /etc/fstab: commit= still present after removal" >&2; return 1; }
	fi

	cat "$tmp" > "$fstab"
	rm -f "$tmp"

	# Apply now as well, so fstab and the live mount agree without waiting for a
	# reboot -- the whole reason the option is in fstab rather than applied by a
	# unit is that those two should never tell different stories.
	#
	# Remounting the root filesystem in place is safe: it is not an unmount, so
	# nothing is detached, no open file descriptors are invalidated, and a failure
	# leaves the mount exactly as it was rather than half-changed. It does force a
	# journal commit, so it takes as long as there is pending metadata to write --
	# measured at ~2.5s on a busy build host, which is why this is not done in a
	# loop anywhere.
	#
	# When removing the option, remount to ext4's own default rather than leaving
	# the running value in place. 5 is written literally because that is the
	# documented ext4 default (see man ext4); usefully, ext4 stops reporting
	# commit= once it matches the default, so the live mount then shows exactly
	# what fstab now says, which is nothing.
	mount -o "remount,commit=${commit:-5}" / > /dev/null 2>&1 \
		|| echo "  fstab updated; live remount failed (applies at next boot)"

	echo "  /etc/fstab updated (backup: ${backup})"
	return 0
}

# The boot-time unit carries the CPU bias only. Unlike a mount option it has no
# declarative home -- there is no file the kernel reads at boot to set it -- so a
# unit is the right mechanism rather than a workaround.
function _tp_write_unit() {
	local profile="$1" epp
	epp="$(_tp_epp "$profile")"

	# Nothing to install when this machine has no such knob: the commit interval
	# lives in fstab now, so the CPU bias is all this unit was for.
	if [[ -z "$epp" ]] || ! _tp_has_epp; then
		rm -f "$TP_UNIT_FILE"
		return 0
	fi

	{
		cat <<- EOF
			[Unit]
			Description=Armbian tuning profile (${profile}): CPU energy/performance bias
			Documentation=https://docs.armbian.com/User-Guide_Fine-Tuning/
			After=multi-user.target

			[Service]
			Type=oneshot
			RemainAfterExit=yes
		EOF

		# The [ -w ] test still guards each write: a CPU may be offline at boot,
		# and the glob would then name a path that cannot be written.
		cat <<- EOF
			ExecStart=/bin/sh -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do [ -w "\$f" ] && echo ${epp} > "\$f"; done; exit 0'
		EOF

		cat <<- EOF

			[Install]
			WantedBy=multi-user.target
		EOF
	} > "$TP_UNIT_FILE"
}

# Apply a profile: sysctl now and at boot, unit now and at boot, record it.
function _tp_apply() {
	local profile="$1" commit

	if ! _tp_is_profile "$profile"; then
		echo "Unknown profile: ${profile}"
		echo "Available: $(_tp_profile_list | cut -d'|' -f1 | tr '\n' ' ')"
		return 1
	fi

	commit="$(_tp_commit_interval "$profile")"

	# See TP_SYSCTL_FILE above for why the filename matters.
	{
		echo "# Armbian tuning profile: ${profile}"
		echo "#"
		echo "# Generated by armbian-config (module_tuning_profile) on $(date -Is)."
		echo "# Edit the profile, not this file -- it is rewritten on every apply."
		echo "#"
		echo "# Named to sort after every other sysctl.d file, including 99-sysctl.conf"
		echo "# (a symlink to /etc/sysctl.conf), which also sets vm.swappiness. The last"
		echo "# file applied wins, so this one has to be last."
		echo ""
		_tp_emit_sysctl "$profile"
	} > "$TP_SYSCTL_FILE"

	# Stale opposite-form keys: the kernel treats dirty_bytes and dirty_ratio as
	# mutually exclusive, and a previously applied profile may have set the form
	# this one does not use. Clearing is implicit -- writing either form zeroes
	# the other -- but a reload of every drop-in is what makes the result match
	# the file on disk rather than the union of everything applied this boot.
	sysctl --system > /dev/null 2>&1

	# ...and then re-assert our own file, because `sysctl --system` applies
	# /etc/sysctl.conf LAST, after every drop-in directory, regardless of what
	# anything in /etc/sysctl.d is called. Distributions ship vm.swappiness in
	# that file, so without this line the reload above silently undoes the
	# profile's value the moment it is applied -- measured on two hosts: apply
	# took vm.swappiness from 1 to 100 and the verification below then reported
	# the profile's own failure.
	#
	# The 99-zz- filename still matters: at boot systemd-sysctl reads only the
	# drop-in directories, where ordering decides. This handles the other path.
	# A failure here means the profile is not live: stop before recording it as
	# the active profile.
	if ! sysctl -qp "$TP_SYSCTL_FILE" > /dev/null 2>&1; then
		echo "Failed to apply tuning profile sysctl settings from ${TP_SYSCTL_FILE}" >&2
		return 1
	fi

	# ext4 commit interval, in fstab, applied live as well.
	if _tp_root_is_ext4; then
		_tp_set_fstab_commit "$commit" || \
			echo "  commit interval NOT changed (fstab left as it was)" >&2
	fi

	_tp_write_unit "$profile"
	systemctl daemon-reload > /dev/null 2>&1
	if [[ -f "$TP_UNIT_FILE" ]]; then
		# enable, then RESTART -- not `enable --now`. `--now` means start, and
		# starting an already-active Type=oneshot with RemainAfterExit=yes is a
		# no-op, so switching from one profile to another would rewrite the unit
		# and never re-run it: the CPU bias would stay on the old profile's value
		# until the next reboot. restart re-runs ExecStart unconditionally.
		systemctl enable armbian-tuning-profile.service > /dev/null 2>&1
		systemctl restart armbian-tuning-profile.service > /dev/null 2>&1
	else
		# A previous profile on this machine may have installed it; if this one
		# has nothing for it to do, take it away rather than leaving it enabled
		# with the old profile's value.
		systemctl disable --now armbian-tuning-profile.service > /dev/null 2>&1
	fi

	{
		echo "# Active Armbian tuning profile. Managed by armbian-config."
		echo "PROFILE=${profile}"
		echo "APPLIED=$(date -Is)"
	} > "$TP_STATE_FILE"

	# Verify rather than assume. A profile that quietly lost a filename race is
	# worse than one that refused to apply, because nothing tells you.
	_tp_verify_sysctl "$profile" || true

	echo "Applied tuning profile: ${profile}"
	if _tp_root_is_ext4; then
		echo "  ext4 commit interval on / : $(findmnt -no OPTIONS / 2>/dev/null | tr ',' '\n' | grep '^commit=' | cut -d= -f2 || echo "${commit} (at next boot)")s"
	else
		echo "  ext4 commit interval      : skipped (/ is $(findmnt -no FSTYPE / 2>/dev/null))"
	fi
	if _tp_has_epp; then
		echo "  CPU energy/performance    : $(_tp_epp "$profile")"
	else
		echo "  CPU energy/performance    : not available on this CPU"
	fi
	return 0
}

# _tp_verify_sysctl <profile>
#
# Check that the kernel actually ended up with the values the profile asked for,
# and if not, name the file that won. Filename ordering is necessary but not
# sufficient: /etc/sysctl.conf is linked in as 99-sysctl.conf, distributions put
# vm.swappiness in it, and an admin can always add a file that sorts later still.
# Trusting the ordering is how a profile silently does nothing -- which is worth
# catching here rather than leaving someone to wonder why swappiness is wrong
# weeks later.
function _tp_verify_sysctl() {
	local profile="$1" key want live winner f mismatch=0

	while read -r key _ want; do
		[[ "$key" == vm.* ]] || continue
		live="$(sysctl -n "$key" 2>/dev/null)"
		[[ "$live" == "$want" ]] && continue

		# Find the last file in load order that sets this key. systemd-sysctl
		# merges the standard directories and applies them sorted by basename, so
		# sorting basenames across all of them is the same order it uses.
		winner=""
		while read -r f; do
			grep -qE "^[[:space:]]*${key//./\\.}[[:space:]]*=" "$f" 2>/dev/null && winner="$f"
		done < <(
			# find, not a glob: a directory with no .conf files makes an unmatched
			# glob, which some shells expand to the literal pattern and others
			# treat as an error. Neither is wanted in a loop that must not fail.
			find /etc/sysctl.d /run/sysctl.d /usr/lib/sysctl.d \
				-maxdepth 1 -name '*.conf' 2> /dev/null \
				| awk -F/ '{print $NF "\t" $0}' | sort | cut -f2
			# /etc/sysctl.conf last and outside the sort: `sysctl --system`
			# applies it after every directory, whatever the drop-ins are named,
			# so when it sets a key it is the winner by definition. Leaving it out
			# of this scan is why a conflict here could be detected but not named.
			[ -f /etc/sysctl.conf ] && echo /etc/sysctl.conf
		)

		mismatch=1
		echo "  WARNING: ${key} is ${live}, profile asked for ${want}" >&2
		if [[ -n "$winner" && "$winner" != "$TP_SYSCTL_FILE" ]]; then
			echo "           overridden by ${winner}" >&2
			# A symlinked /etc/sysctl.conf is the usual culprit and the least
			# obvious, so resolve it rather than naming the link.
			[[ -L "$winner" ]] && echo "           (which is a link to $(readlink -f "$winner"))" >&2
		fi
	done < <(_tp_emit_sysctl "$profile" | grep -E '^vm\.')

	if [[ "$mismatch" -eq 1 ]]; then
		echo "           remove the conflicting setting, or the profile will not hold across reboots" >&2
		return 1
	fi
	return 0
}

function _tp_active() {
	# Callers read the output, not the status -- "no profile" is a normal answer,
	# not a failure, and returning non-zero for it makes `active="$(_tp_active)"`
	# an error under set -e.
	[[ -f "$TP_STATE_FILE" ]] && grep -oP '^PROFILE=\K.*' "$TP_STATE_FILE" 2>/dev/null
	return 0
}

#
# CPU frequency
#
# The cpufrequtils package is EOL and Armbian no longer ships it. Its config
# file stays: the build framework writes the board's CPUMIN, CPUMAX and GOVERNOR
# to /etc/default/cpufrequtils, and armbian-hardware-optimization applies
# MIN_SPEED, MAX_SPEED, GOVERNOR and BOOST=true to every policy at boot. That
# file is the single source of truth here too, in the same KEY=value form.
#
# One value for all CPUs does not fit big.LITTLE and DynamIQ parts (RK3399,
# RK3588, S922X, Exynos 5422): each cluster has its own frequency table and
# often its own best governor. A cluster can override the global keys with
# POLICY<n>_GOVERNOR, POLICY<n>_MIN_SPEED and POLICY<n>_MAX_SPEED, where <n> is
# the first CPU of policy<n>. Board configs set them at build time (build
# CPUMIN_POLICY<n> etc.). Older armbian-hardware-optimization ignores them, so
# armbian-cpufreq.service applies the file after it when that is necessary.
#
# BOOST keeps its old meaning. "true" enables boost. "false", which the build
# writes for every board, keeps the kernel default. "off" disables boost.
# Reading "false" as "off" would disable turbo on every x86 image.
declare -g TP_CPU_CONF="/etc/default/cpufrequtils"
declare -g TP_CPU_DEFAULTS="/etc/default/cpufrequtils.armbian-default"
declare -g TP_CPU_UNIT_FILE="/etc/systemd/system/armbian-cpufreq.service"
declare -g TP_CPU_SYS="/sys/devices/system/cpu"

# _tp_cpu_policies -> one cpufreq directory per policy, in CPU order
function _tp_cpu_policies() {
	local -a dirs=()
	local d
	for d in "$TP_CPU_SYS"/cpufreq/policy[0-9]*; do
		[[ -d "$d" ]] && dirs+=("$d")
	done
	# Old vendor kernels have no policy<n> directories. There the first CPU of
	# a policy has a real cpufreq directory and the other CPUs a symlink to it.
	if [[ ${#dirs[@]} -eq 0 ]]; then
		for d in "$TP_CPU_SYS"/cpu[0-9]*/cpufreq; do
			[[ -d "$d" && ! -L "$d" ]] && dirs+=("$d")
		done
	fi
	[[ ${#dirs[@]} -gt 0 ]] && printf '%s\n' "${dirs[@]}" | sort -V
	return 0
}

# _tp_cpu_id <policy dir> -> <n> of policy<n>
function _tp_cpu_id() {
	local n="${1##*/policy}"
	if [[ "$n" == "$1" ]]; then
		n="${1%/cpufreq}"
		n="${n##*/cpu}"
	fi
	echo "$n"
}

# _tp_cpu_dirs "0-3,8" -> policy dirs of policy0-3 and policy8
function _tp_cpu_dirs() {
	local d
	while read -r d; do
		_tp_cpu_in_list "$(_tp_cpu_id "$d")" "$1" && echo "$d"
	done < <(_tp_cpu_policies)
	return 0
}

function _tp_cpu_read() {
	cat "$1/$2" 2> /dev/null
}

# _tp_cpu_write <file> <value>; a failed write is not an error at boot
function _tp_cpu_write() {
	[[ -w "$1" ]] && echo "$2" 2> /dev/null > "$1"
	return 0
}

# A policy whose CPUs are all offline keeps its directory but refuses access.
function _tp_cpu_online() {
	[[ -n "$(_tp_cpu_read "$1" affected_cpus | tr -d ' \n')" ]]
}

# _tp_cpu_range "0 1 2 3 6" -> "0-3,6"
function _tp_cpu_range() {
	awk '{
		out = ""; s = $1; p = $1
		for (i = 2; i <= NF + 1; i++) {
			if (i <= NF && $i == p + 1) { p = $i; continue }
			out = out (out == "" ? "" : ",") (s == p ? s : s "-" p)
			s = $i; p = $i
		}
		print out
	}' <<< "$1"
}

# _tp_cpu_in_list <cpu> "0-3,8" -> status
function _tp_cpu_in_list() {
	local cpu="$1" r IFS=,
	for r in $2; do
		if [[ "$r" == *-* ]]; then
			((cpu >= ${r%-*} && cpu <= ${r#*-})) && return 0
		else
			[[ "$cpu" == "$r" ]] && return 0
		fi
	done
	return 1
}

# _tp_cpu_core <cpu> -> core name, or nothing when it is not known
function _tp_cpu_core() {
	local cpu="$1" impl part uarch
	# Intel hybrid parts list P-cores and E-cores as two PMUs.
	if [[ -r /sys/devices/cpu_core/cpus ]] && _tp_cpu_in_list "$cpu" "$(< /sys/devices/cpu_core/cpus)"; then
		echo "P-core"
		return 0
	fi
	if [[ -r /sys/devices/cpu_atom/cpus ]] && _tp_cpu_in_list "$cpu" "$(< /sys/devices/cpu_atom/cpus)"; then
		echo "E-core"
		return 0
	fi
	read -r impl part uarch < <(awk -v cpu="$cpu" '
		BEGIN { FS = "[ \t]*:[ \t]*" }
		$1 == "processor" { p = $2 }
		p == cpu && $1 == "CPU implementer" { impl = $2 }
		p == cpu && $1 == "CPU part" { part = $2 }
		p == cpu && $1 == "uarch" { uarch = $2 }
		END { print (impl == "" ? "-" : impl), (part == "" ? "-" : part), uarch }
	' /proc/cpuinfo 2> /dev/null)
	# RISC-V names the core itself, e.g. "spacemit,x60".
	[[ -n "$uarch" ]] && { echo "${uarch#*,}"; return 0; }
	[[ "$impl" == "0x41" ]] || { [[ "$part" != "-" ]] && echo "${impl}/${part}"; return 0; }
	case "$part" in
		0xc05) echo "Cortex-A5" ;;   0xc07) echo "Cortex-A7" ;;   0xc08) echo "Cortex-A8" ;;
		0xc09) echo "Cortex-A9" ;;   0xc0d) echo "Cortex-A12" ;;  0xc0e) echo "Cortex-A17" ;;
		0xc0f) echo "Cortex-A15" ;;  0xd01) echo "Cortex-A32" ;;  0xd03) echo "Cortex-A53" ;;
		0xd04) echo "Cortex-A35" ;;  0xd05) echo "Cortex-A55" ;;  0xd07) echo "Cortex-A57" ;;
		0xd08) echo "Cortex-A72" ;;  0xd09) echo "Cortex-A73" ;;  0xd0a) echo "Cortex-A75" ;;
		0xd0b) echo "Cortex-A76" ;;  0xd0c) echo "Neoverse-N1" ;; 0xd0d) echo "Cortex-A77" ;;
		0xd40) echo "Neoverse-V1" ;; 0xd41) echo "Cortex-A78" ;;  0xd44) echo "Cortex-X1" ;;
		0xd46) echo "Cortex-A510" ;; 0xd47) echo "Cortex-A710" ;; 0xd48) echo "Cortex-X2" ;;
		0xd49) echo "Neoverse-N2" ;; 0xd4d) echo "Cortex-A715" ;; 0xd4e) echo "Cortex-X3" ;;
		0xd80) echo "Cortex-A520" ;; 0xd81) echo "Cortex-A720" ;; 0xd82) echo "Cortex-X4" ;;
		0xd85) echo "Cortex-X925" ;; 0xd87) echo "Cortex-A725" ;;
		*) echo "Arm ${part}" ;;
	esac
}

function _tp_cpu_mhz() {
	[[ "$1" =~ ^[0-9]+$ ]] && echo "$(($1 / 1000))" || echo "?"
}

# _tp_cpu_cpus <policy dir> -> "4 5"
function _tp_cpu_cpus() {
	local cpus
	cpus="$(_tp_cpu_read "$1" related_cpus)"
	[[ -z "$cpus" ]] && cpus="$(_tp_cpu_read "$1" affected_cpus)"
	echo "$cpus"
}

# _tp_cpu_kind <policy dir> -> "Cortex-A72, 408-1800 MHz"
function _tp_cpu_kind() {
	local d="$1" cpus core
	cpus="$(_tp_cpu_cpus "$d")"
	core="$(_tp_cpu_core "${cpus%% *}")"
	echo "${core:+${core}, }$(_tp_cpu_mhz "$(_tp_cpu_read "$d" cpuinfo_min_freq)")-$(_tp_cpu_mhz "$(_tp_cpu_read "$d" cpuinfo_max_freq)") MHz"
}

# _tp_cpu_label <policy dir>... -> "CPU4-5 Cortex-A72, 408-1800 MHz"
function _tp_cpu_label() {
	local d kind cpus=""
	for d in "$@"; do
		cpus+=" $(_tp_cpu_cpus "$d")"
	done
	cpus="$(tr ' ' '\n' <<< "$cpus" | grep . | sort -un | tr '\n' ' ')"
	kind="$(_tp_cpu_kind "$1")"
	[[ "$kind" == *,* ]] && echo "CPU$(_tp_cpu_range "$cpus") ${kind}" || echo "CPU$(_tp_cpu_range "$cpus"), ${kind}"
}

# _tp_cpu_groups -> "<policy list> <policy dir>..." per group of policies with
# the same core and hardware range. x86 drivers make one policy per CPU.
function _tp_cpu_groups() {
	local d key
	local -A ids=() dirs=()
	local -a order=()
	while read -r d; do
		key="$(_tp_cpu_kind "$d")"
		[[ -n "${ids[$key]:-}" ]] || order+=("$key")
		ids[$key]+="$(_tp_cpu_id "$d") "
		dirs[$key]+="$d "
	done < <(_tp_cpu_policies)
	for key in "${order[@]}"; do
		echo "$(_tp_cpu_range "${ids[$key]}") ${dirs[$key]}"
	done
}

# _tp_cpu_freqs <policy dir>... -> table frequencies in kHz, boost ones included
function _tp_cpu_freqs() {
	local d
	for d in "$@"; do
		_tp_cpu_read "$d" scaling_available_frequencies
		_tp_cpu_read "$d" scaling_boost_frequencies
	done | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un
}

# _tp_cpu_governors <policy dir>... -> governors that all the policies offer
function _tp_cpu_governors() {
	local d
	for d in "$@"; do
		_tp_cpu_read "$d" scaling_available_governors | tr ' ' '\n' | grep . | sort -u
	done | sort | uniq -c | awk -v n="$#" '$1 == n { print $2 }'
}

function _tp_cpu_get() {
	[[ -r "$TP_CPU_CONF" ]] && sed -n "s/^${1}=//p" "$TP_CPU_CONF" | tail -n 1 | tr -d "\"'"
	return 0
}

# _tp_cpu_put <key> <value>; an empty value removes the key
function _tp_cpu_put() {
	local tmp
	tmp="$(mktemp)" || return 1
	[[ -f "$TP_CPU_CONF" ]] && grep -v "^${1}=" "$TP_CPU_CONF" > "$tmp"
	[[ -n "$2" ]] && echo "${1}=${2}" >> "$tmp"
	cat "$tmp" > "$TP_CPU_CONF"
	rm -f "$tmp"
}

# _tp_cpu_want <policy dir> <GOVERNOR|MIN_SPEED|MAX_SPEED> -> per-policy or global value
function _tp_cpu_want() {
	local v
	v="$(_tp_cpu_get "POLICY$(_tp_cpu_id "$1")_$2")"
	[[ -n "$v" ]] && echo "$v" || _tp_cpu_get "$2"
}

function _tp_cpu_has_boost() {
	[[ -e "$TP_CPU_SYS/cpufreq/boost" || -e "$TP_CPU_SYS/intel_pstate/no_turbo" ]] \
		|| compgen -G "$TP_CPU_SYS/cpufreq/policy*/boost" > /dev/null
}

# _tp_cpu_boost_live -> on|off|""
function _tp_cpu_boost_live() {
	local v
	if [[ -r "$TP_CPU_SYS/cpufreq/boost" ]]; then
		v="$(< "$TP_CPU_SYS/cpufreq/boost")"
	elif [[ -r "$TP_CPU_SYS/intel_pstate/no_turbo" ]]; then
		v=$((1 - $(< "$TP_CPU_SYS/intel_pstate/no_turbo")))
	else
		v="$(cat "$TP_CPU_SYS"/cpufreq/policy*/boost 2> /dev/null | sort -u | tail -n 1)"
	fi
	case "$v" in 1) echo on ;; 0) echo off ;; esac
}

# _tp_cpu_write_boost <1|0>
function _tp_cpu_write_boost() {
	local val="$1" d
	if [[ -e "$TP_CPU_SYS/cpufreq/boost" ]]; then
		_tp_cpu_write "$TP_CPU_SYS/cpufreq/boost" "$val"
	elif [[ -e "$TP_CPU_SYS/intel_pstate/no_turbo" ]]; then
		_tp_cpu_write "$TP_CPU_SYS/intel_pstate/no_turbo" "$((1 - val))"
	else
		for d in "$TP_CPU_SYS"/cpufreq/policy*/boost; do
			_tp_cpu_write "$d" "$val"
		done
	fi
}

function _tp_cpu_apply_boost() {
	case "$(_tp_cpu_get BOOST)" in
		true) _tp_cpu_write_boost 1 ;;
		off) _tp_cpu_write_boost 0 ;;
	esac
	return 0
}

# The kernel has no interface for its default boost state. Record the live state
# before the first override (BOOST_KERNEL_DEFAULT) and write it back when the
# override goes away. <mode> is the new BOOST value.
function _tp_cpu_boost_default() {
	local mode="$1" prev saved live
	prev="$(_tp_cpu_get BOOST)"
	saved="$(_tp_cpu_get BOOST_KERNEL_DEFAULT)"
	if [[ "$mode" == "true" || "$mode" == "off" ]]; then
		if [[ "$prev" != "true" && "$prev" != "off" && -z "$saved" ]]; then
			live="$(_tp_cpu_boost_live)"
			[[ -n "$live" ]] && _tp_cpu_put BOOST_KERNEL_DEFAULT "$([[ "$live" == on ]] && echo 1 || echo 0)"
		fi
	elif [[ -n "$saved" ]]; then
		_tp_cpu_write_boost "$saved"
		_tp_cpu_put BOOST_KERNEL_DEFAULT ""
	fi
	return 0
}

function _tp_cpu_apply_policy() {
	local d="$1" gov min max hwmin hwmax
	_tp_cpu_online "$d" || return 0
	gov="$(_tp_cpu_want "$d" GOVERNOR)"
	min="$(_tp_cpu_want "$d" MIN_SPEED)"
	max="$(_tp_cpu_want "$d" MAX_SPEED)"
	hwmin="$(_tp_cpu_read "$d" cpuinfo_min_freq)"
	hwmax="$(_tp_cpu_read "$d" cpuinfo_max_freq)"

	if [[ -n "$gov" ]] && _tp_cpu_read "$d" scaling_available_governors | grep -qw -- "$gov"; then
		_tp_cpu_write "$d/scaling_governor" "$gov"
	fi

	# A global value can lie outside one cluster's range. Clamp it rather than
	# let an old kernel refuse it.
	if [[ "$hwmin" =~ ^[0-9]+$ && "$hwmax" =~ ^[0-9]+$ ]]; then
		[[ -n "$min" ]] && { ((min < hwmin)) && min="$hwmin"; ((min > hwmax)) && min="$hwmax"; }
		[[ -n "$max" ]] && { ((max < hwmin)) && max="$hwmin"; ((max > hwmax)) && max="$hwmax"; }
	fi

	# Max, min, max: old kernels refuse a min above the current max and a max
	# below the current min.
	[[ -n "$max" ]] && _tp_cpu_write "$d/scaling_max_freq" "$max"
	[[ -n "$min" ]] && _tp_cpu_write "$d/scaling_min_freq" "$min"
	[[ -n "$max" ]] && _tp_cpu_write "$d/scaling_max_freq" "$max"
	return 0
}

function _tp_cpu_apply() {
	local d
	# Boost first: the kernel hides boost frequencies until boost is on, so a
	# max frequency in the boost range would be clamped.
	_tp_cpu_apply_boost
	while read -r d; do
		_tp_cpu_apply_policy "$d"
	done < <(_tp_cpu_policies)
}

# True when armbian-hardware-optimization applies the file alone at boot: the
# service is enabled, per-policy keys need its policy support and policy*
# directories, and an explicit BOOST needs the global boost file.
function _tp_cpu_ho_covers() {
	local ho="${TP_CPU_HO:-/usr/lib/armbian/armbian-hardware-optimization}"
	[[ -x "$ho" ]] || return 1
	systemctl is-enabled --quiet armbian-hardware-optimize.service 2> /dev/null || return 1
	if grep -qE '^POLICY[0-9]+_[A-Z_]+' "$TP_CPU_CONF" 2> /dev/null; then
		grep -qF 'POLICY${n}_GOVERNOR' "$ho" || return 1
		compgen -G "$TP_CPU_SYS/cpufreq/policy*" > /dev/null || return 1
	fi
	if grep -qE '^BOOST=(true|off)' "$TP_CPU_CONF" 2> /dev/null; then
		[[ -e "$TP_CPU_SYS/cpufreq/boost" ]] || return 1
		grep -q '^BOOST=off' "$TP_CPU_CONF" && ! grep -qF 'POLICY${n}_GOVERNOR' "$ho" && return 1
	fi
	return 0
}

# Install the boot unit only when armbian-hardware-optimization cannot apply the
# file alone.
function _tp_cpu_sync_unit() {
	if ! _tp_cpu_ho_covers; then
		cat > "$TP_CPU_UNIT_FILE" <<- EOF
			[Unit]
			Description=Armbian CPU frequency settings
			Documentation=https://docs.armbian.com/User-Guide_Fine-Tuning/
			After=armbian-hardware-optimize.service

			[Service]
			Type=oneshot
			RemainAfterExit=yes
			ExecStart=/usr/bin/armbian-config --api module_tuning_profile cpu apply

			[Install]
			WantedBy=multi-user.target
		EOF
		systemctl daemon-reload > /dev/null 2>&1
		systemctl enable armbian-cpufreq.service > /dev/null 2>&1
	elif [[ -f "$TP_CPU_UNIT_FILE" ]]; then
		systemctl disable armbian-cpufreq.service > /dev/null 2>&1
		rm -f "$TP_CPU_UNIT_FILE"
		systemctl daemon-reload > /dev/null 2>&1
	fi
	return 0
}

# _tp_cpu_set <all|policy<list>> <governor|min|max|boost|clear> [value]
#
# Frequencies are in kHz, as in sysfs and in the config file. "all" writes the
# global key and drops the per-policy overrides of that key. A list such as
# policy0-3,8 writes the key of each policy in it.
function _tp_cpu_set() {
	local target="$1" key="$2" value="$3" p d n lo="" hi="" other
	local -a dirs=() online=() prefixes=()

	if [[ "$target" == "all" ]]; then
		mapfile -t dirs < <(_tp_cpu_policies)
		prefixes=("")
	elif [[ "$target" =~ ^policy([0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*)$ ]]; then
		mapfile -t dirs < <(_tp_cpu_dirs "${BASH_REMATCH[1]}")
		for d in "${dirs[@]}"; do
			prefixes+=("POLICY$(_tp_cpu_id "$d")_")
		done
	fi
	if [[ ${#dirs[@]} -eq 0 ]]; then
		echo "No CPU frequency policy '${target}'. Use 'all' or one of: $(_tp_cpu_policies | while read -r d; do printf 'policy%s ' "$(_tp_cpu_id "$d")"; done)" >&2
		return 1
	fi
	for d in "${dirs[@]}"; do
		_tp_cpu_online "$d" && online+=("$d")
	done
	[[ ${#online[@]} -gt 0 ]] || { echo "All CPUs of ${target} are offline." >&2; return 1; }

	# Keep a copy of the board defaults that the build wrote, for reset. No file
	# means no defaults.
	if [[ ! -f "$TP_CPU_DEFAULTS" ]]; then
		if [[ -f "$TP_CPU_CONF" ]]; then
			cp -a "$TP_CPU_CONF" "$TP_CPU_DEFAULTS"
		else
			: > "$TP_CPU_DEFAULTS"
		fi
	fi
	# ENABLE was for the cpufrequtils package. Nothing reads it now.
	sed -i '/^ENABLE=/d' "$TP_CPU_CONF" 2> /dev/null

	case "$key" in
		governor)
			if [[ -n "$value" ]] && ! _tp_cpu_governors "${online[@]}" | grep -qx -- "$value"; then
				echo "Governor '${value}' is not available for ${target/#all/all CPUs}. Available: $(_tp_cpu_governors "${online[@]}" | tr '\n' ' ')" >&2
				return 1
			fi
			[[ "$target" != "all" ]] || sed -i '/^POLICY[0-9]*_GOVERNOR=/d' "$TP_CPU_CONF" 2> /dev/null
			for p in "${prefixes[@]}"; do
				_tp_cpu_put "${p}GOVERNOR" "$value"
			done
			;;
		min | max)
			if [[ -n "$value" ]]; then
				[[ "$value" =~ ^[0-9]+$ ]] || { echo "Frequency must be a number in kHz: '${value}'" >&2; return 1; }
				for d in "${online[@]}"; do
					n="$(_tp_cpu_read "$d" cpuinfo_min_freq)"
					[[ -z "$lo" || "$n" -lt "$lo" ]] && lo="$n"
					n="$(_tp_cpu_read "$d" cpuinfo_max_freq)"
					[[ -z "$hi" || "$n" -gt "$hi" ]] && hi="$n"
				done
				if ((value < lo || value > hi)); then
					echo "Frequency ${value} kHz is outside ${lo}-${hi} kHz for ${target}." >&2
					return 1
				fi
				# Compare with the effective opposite bound of each policy, both
				# clamped to that policy's hardware range, as apply does.
				for d in "${online[@]}"; do
					[[ "$key" == "min" ]] && other="$(_tp_cpu_want "$d" MAX_SPEED)" || other="$(_tp_cpu_want "$d" MIN_SPEED)"
					[[ -n "$other" ]] || continue
					lo="$(_tp_cpu_read "$d" cpuinfo_min_freq)"
					hi="$(_tp_cpu_read "$d" cpuinfo_max_freq)"
					n="$value"
					((n < lo)) && n="$lo"; ((n > hi)) && n="$hi"
					((other < lo)) && other="$lo"; ((other > hi)) && other="$hi"
					if [[ "$key" == "min" ]] && ((n > other)); then
						echo "Minimum ${value} kHz is above maximum ${other} kHz of policy$(_tp_cpu_id "$d")." >&2
						return 1
					fi
					if [[ "$key" == "max" ]] && ((n < other)); then
						echo "Maximum ${value} kHz is below minimum ${other} kHz of policy$(_tp_cpu_id "$d")." >&2
						return 1
					fi
				done
			fi
			key="${key^^}_SPEED"
			[[ "$target" != "all" ]] || sed -i "/^POLICY[0-9]*_${key}=/d" "$TP_CPU_CONF" 2> /dev/null
			# The widened limit must reach sysfs too: apply only writes what is set.
			if [[ -z "$value" ]]; then
				for d in "${online[@]}"; do
					if [[ "$key" == "MIN_SPEED" ]]; then
						_tp_cpu_write "$d/scaling_min_freq" "$(_tp_cpu_read "$d" cpuinfo_min_freq)"
					else
						_tp_cpu_write "$d/scaling_max_freq" "$(_tp_cpu_read "$d" cpuinfo_max_freq)"
					fi
				done
			fi
			for p in "${prefixes[@]}"; do
				_tp_cpu_put "${p}${key}" "$value"
			done
			;;
		boost)
			[[ "$target" == "all" ]] || { echo "Boost is set for all CPUs only." >&2; return 1; }
			_tp_cpu_has_boost || { echo "This CPU has no boost control." >&2; return 1; }
			case "$value" in
				true | on) value=true ;;
				off) ;;
				false | default | "") value=false ;;
				*) echo "Boost must be on, off or default." >&2; return 1 ;;
			esac
			_tp_cpu_boost_default "$value"
			_tp_cpu_put BOOST "$value"
			;;
		clear)
			[[ "$target" != "all" ]] || { echo "Clear needs a policy, for example: cpu set policy4 clear" >&2; return 1; }
			for p in "${prefixes[@]}"; do
				sed -i "/^${p}/d" "$TP_CPU_CONF" 2> /dev/null
			done
			for d in "${online[@]}"; do
				_tp_cpu_write "$d/scaling_min_freq" "$(_tp_cpu_read "$d" cpuinfo_min_freq)"
				_tp_cpu_write "$d/scaling_max_freq" "$(_tp_cpu_read "$d" cpuinfo_max_freq)"
			done
			;;
		*)
			echo "Unknown setting '${key}'. Use governor, min, max, boost or clear." >&2
			return 1
			;;
	esac

	_tp_cpu_apply
	_tp_cpu_sync_unit
}

# Return to the board defaults that the build wrote.
function _tp_cpu_reset() {
	local d boost=false
	[[ -f "$TP_CPU_DEFAULTS" ]] && boost="$(sed -n 's/^BOOST=//p' "$TP_CPU_DEFAULTS" | tail -n 1)"
	_tp_cpu_boost_default "${boost:-false}"
	if [[ -f "$TP_CPU_DEFAULTS" ]]; then
		grep -v '^ENABLE=' "$TP_CPU_DEFAULTS" > "$TP_CPU_CONF"
		rm -f "$TP_CPU_DEFAULTS"
	else
		sed -i -E '/^POLICY[0-9]+_/d; /^BOOST=off/d; /^ENABLE=/d' "$TP_CPU_CONF" 2> /dev/null
	fi
	# Open the hardware range first, so limits that are not set any more go away.
	while read -r d; do
		_tp_cpu_online "$d" || continue
		_tp_cpu_write "$d/scaling_max_freq" "$(_tp_cpu_read "$d" cpuinfo_max_freq)"
		_tp_cpu_write "$d/scaling_min_freq" "$(_tp_cpu_read "$d" cpuinfo_min_freq)"
	done < <(_tp_cpu_policies)
	_tp_cpu_apply
	_tp_cpu_sync_unit
	echo "CPU frequency settings returned to board defaults."
}

# Exit status 1 when the system has no CPU frequency scaling.
function _tp_cpu_status() {
	local d n line
	if [[ -z "$(_tp_cpu_policies)" ]]; then
		echo "No CPU frequency scaling on this system."
		return 1
	fi
	echo "Driver: $(_tp_cpu_read "$(_tp_cpu_policies | head -n 1)" scaling_driver)"
	_tp_cpu_has_boost && echo "Boost:  $(_tp_cpu_boost_live) (BOOST=$(_tp_cpu_get BOOST))"
	echo ""
	while read -r d; do
		n="$(_tp_cpu_id "$d")"
		if ! _tp_cpu_online "$d"; then
			printf '  policy%-3s %s: offline\n' "$n" "$(_tp_cpu_label "$d")"
			continue
		fi
		printf '  policy%-3s %s\n' "$n" "$(_tp_cpu_label "$d")"
		printf '             %s, %s-%s MHz, now %s MHz\n' \
			"$(_tp_cpu_read "$d" scaling_governor)" \
			"$(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_min_freq)")" \
			"$(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_max_freq)")" \
			"$(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_cur_freq)")"
	done < <(_tp_cpu_policies)
	echo ""
	echo "Settings in ${TP_CPU_CONF}:"
	line="$(grep -E '^(POLICY[0-9]+_)?(GOVERNOR|MIN_SPEED|MAX_SPEED)=|^BOOST=' "$TP_CPU_CONF" 2> /dev/null)"
	echo "${line:-  (none)}" | sed 's/^\([^ ]\)/  \1/'
	return 0
}

# _tp_cpu_pick_freq <title> <current kHz> <policy dir>... -> kHz, or nothing
function _tp_cpu_pick_freq() {
	local title="$1" cur="$2" f mhz v state
	shift 2
	local -a freqs opts=()
	mapfile -t freqs < <(_tp_cpu_freqs "$@")
	if [[ ${#freqs[@]} -gt 0 ]]; then
		for f in "${freqs[@]}"; do
			state=off
			[[ "$f" == "$cur" ]] && state=on
			opts+=("$f" "$(_tp_cpu_mhz "$f") MHz" "$state")
		done
		dialog_radiolist "$title" "Select a frequency:" 0 50 12 "${opts[@]}"
		return 0
	fi
	# CPPC, intel_pstate and some SCMI drivers have no frequency table.
	mhz="$(_tp_cpu_mhz "$cur")"
	[[ "$mhz" == "?" ]] && mhz=""
	v="$(dialog_inputbox "$title" "Enter the frequency in MHz:" "$mhz" 9 50)"
	[[ "$v" =~ ^[0-9]+$ ]] && echo "$((v * 1000))"
	return 0
}

# _tp_cpu_tui_target <all|policy<list>>
function _tp_cpu_tui_target() {
	local target="$1" title gov min max min_label max_label choice value out g state
	local -a dirs=() opts
	if [[ "$target" == "all" ]]; then
		title="All CPUs"
		# Offline clusters cannot take a value now, so do not offer their lists.
		while read -r g; do
			_tp_cpu_online "$g" && dirs+=("$g")
		done < <(_tp_cpu_policies)
	else
		mapfile -t dirs < <(_tp_cpu_dirs "${target#policy}")
		title="${target}: $(_tp_cpu_label "${dirs[@]}")"
	fi

	while true; do
		if [[ "$target" == "all" ]]; then
			gov="$(_tp_cpu_get GOVERNOR)"
			min="$(_tp_cpu_get MIN_SPEED)"
			max="$(_tp_cpu_get MAX_SPEED)"
		else
			gov="$(_tp_cpu_want "${dirs[0]}" GOVERNOR)"
			min="$(_tp_cpu_want "${dirs[0]}" MIN_SPEED)"
			max="$(_tp_cpu_want "${dirs[0]}" MAX_SPEED)"
		fi
		[[ -n "$min" ]] && min_label="$(_tp_cpu_mhz "$min") MHz" || min_label="hardware limit"
		[[ -n "$max" ]] && max_label="$(_tp_cpu_mhz "$max") MHz" || max_label="hardware limit"
		opts=(
			"governor" "Governor: ${gov:-kernel default}"
			"min" "Minimum: ${min_label}"
			"max" "Maximum: ${max_label}"
		)
		[[ "$target" != "all" ]] && opts+=("clear" "Use the values for all CPUs")
		choice="$(dialog_menu "$title" "Changes apply now and at every boot." 0 70 6 "${opts[@]}")"
		[[ -z "$choice" ]] && return 0

		value=""
		case "$choice" in
			governor)
				opts=()
				while read -r g; do
					state=off
					[[ "$g" == "$gov" ]] && state=on
					opts+=("$g" "" "$state")
				done < <(_tp_cpu_governors "${dirs[@]}")
				value="$(dialog_radiolist "Governor" "Select a governor for ${title}:" 0 60 10 "${opts[@]}")"
				;;
			min) value="$(_tp_cpu_pick_freq "Minimum frequency" "${min:-$(_tp_cpu_read "${dirs[0]}" scaling_min_freq)}" "${dirs[@]}")" ;;
			max) value="$(_tp_cpu_pick_freq "Maximum frequency" "${max:-$(_tp_cpu_read "${dirs[0]}" scaling_max_freq)}" "${dirs[@]}")" ;;
		esac
		[[ "$choice" != "clear" && -z "$value" ]] && continue
		out="$(_tp_cpu_set "$target" "$choice" "$value" 2>&1)" || dialog_msgbox "Not applied" "$out" 10 70
	done
}

function _tp_cpu_tui() {
	local choice d ids sum s boost out
	local -a opts policies groups members
	mapfile -t policies < <(_tp_cpu_policies)
	mapfile -t groups < <(_tp_cpu_groups)
	if [[ ${#policies[@]} -eq 0 ]]; then
		dialog_msgbox "CPU frequency" "This system has no CPU frequency scaling." 8 60
		return 0
	fi

	while true; do
		opts=("all" "All CPUs: $(_tp_cpu_get GOVERNOR | grep . || echo "kernel default")")
		# One entry per CPU type. Skip the list when there is only one.
		if [[ ${#groups[@]} -gt 1 ]]; then
			for d in "${groups[@]}"; do
				read -r ids d <<< "$d"
				read -r -a members <<< "$d"
				sum=""
				for d in "${members[@]}"; do
					if _tp_cpu_online "$d"; then
						s="$(_tp_cpu_read "$d" scaling_governor), $(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_min_freq)")-$(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_max_freq)") MHz"
					else
						s="offline"
					fi
					[[ -z "$sum" || "$sum" == "$s" ]] && sum="$s" || { sum="mixed"; break; }
				done
				opts+=("policy${ids}" "$(_tp_cpu_label "${members[@]}") [${sum}]")
			done
		fi
		if _tp_cpu_has_boost; then
			boost="$(_tp_cpu_get BOOST)"
			case "$boost" in true) boost=on ;; off) ;; *) boost="kernel default" ;; esac
			opts+=("boost" "Boost: ${boost} (now $(_tp_cpu_boost_live))")
		fi
		opts+=("reset" "Return to board defaults")

		choice="$(dialog_menu "CPU frequency" "Driver: $(_tp_cpu_read "${policies[0]}" scaling_driver)\n\nSelect CPUs to configure:" 0 78 12 "${opts[@]}")"
		case "$choice" in
			"") return 0 ;;
			boost)
				choice="$(dialog_radiolist "Boost" "Boost runs the CPU above its base frequency when thermal limits allow." 0 70 3 \
					"on" "Enable boost" "$([[ "$boost" == on ]] && echo on || echo off)" \
					"off" "Disable boost" "$([[ "$boost" == off ]] && echo on || echo off)" \
					"default" "Keep the kernel default" "$([[ "$boost" == "kernel default" ]] && echo on || echo off)")"
				[[ -n "$choice" ]] && { out="$(_tp_cpu_set all boost "$choice" 2>&1)" || dialog_msgbox "Not applied" "$out" 10 70; }
				;;
			reset)
				dialog_yesno "Reset" "Return the CPU frequency settings to the board defaults?" && _tp_cpu_reset > /dev/null
				;;
			*) _tp_cpu_tui_target "$choice" ;;
		esac
	done
}

function module_tuning_profile() {
	local title="Tuning Profiles"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_tuning_profile,example"]}"

	case "$1" in

		"${commands[0]}") # select
			local active menu_text choice
			active="$(_tp_active)"
			menu_text="Armbian's defaults assume an SBC booting from a memory card.\n"
			menu_text+="Pick the profile that matches what this machine actually does.\n\n"
			menu_text+="Active profile: ${active:-none (distribution defaults)}\n"
			menu_text+="RAM: $(( $(_tp_mem_kb) / 1024 )) MB   Root: $(findmnt -no FSTYPE / 2>/dev/null)\n\n"
			menu_text+="Select a profile:"

			choice=$(dialog_menu "$title" "$menu_text" 22 78 6 \
				"sbc" "SD card / eMMC - minimise writes, protect flash life" \
				"balanced" "Distribution defaults - no strong bias" \
				"desktop" "Desktop - keep the interface responsive" \
				"builder" "Build / CI host on SSD or NVMe - keep sync cheap" \
				"nas" "File server - absorb large streaming writes" \
				"reset" "Remove profile - return to distribution defaults")

			[[ -z "$choice" ]] && return 0

			if [[ "$choice" == "reset" ]]; then
				module_tuning_profile reset
				return $?
			fi

			local preview
			preview="Profile: ${choice}\n\nThe following will be applied now and at every boot:\n\n"
			preview+="$(_tp_emit_sysctl "$choice" | grep -v '^#' | grep -v '^$' | sed 's/^/  /')\n\n"
			if _tp_root_is_ext4; then
				preview+="  ext4 commit on /          = $(_tp_commit_interval "$choice")s\n"
			fi
			if _tp_has_epp; then
				preview+="  CPU energy/performance    = $(_tp_epp "$choice")\n"
			fi
			preview+="\nApply this profile?"

			if dialog_yesno "Apply ${choice}" "$preview"; then
				local out
				if out="$(_tp_apply "$choice" 2>&1)"; then
					dialog_msgbox "Profile Applied" "${out}\n\nNothing needs restarting; the settings are live." 14 74
				else
					dialog_msgbox "Profile Apply Failed" "${out}" 14 74
					return 1
				fi
			fi
			# Answering "no" to the confirmation is a choice, not an error; without
			# this the branch would exit with dialog_yesno's non-zero status.
			return 0
			;;

		"${commands[1]}") # apply <profile>
			_tp_apply "$2"
			;;

		"${commands[2]}") # status
			local active
			active="$(_tp_active)"
			if [[ -z "$active" ]]; then
				echo "No tuning profile applied (distribution defaults in effect)."
			else
				echo "Active tuning profile: ${active}"
				grep -oP '^APPLIED=\K.*' "$TP_STATE_FILE" 2>/dev/null | sed 's/^/  applied: /'
			fi
			echo ""
			echo "Live values:"
			local k
			for k in vm.swappiness vm.dirty_ratio vm.dirty_background_ratio \
				vm.dirty_bytes vm.dirty_background_bytes \
				vm.dirty_writeback_centisecs vm.dirty_expire_centisecs vm.vfs_cache_pressure; do
				printf '  %-32s %s\n' "$k" "$(sysctl -n "$k" 2>/dev/null)"
			done
			printf '  %-32s %s\n' "ext4 commit on /" \
				"$(findmnt -no OPTIONS / 2>/dev/null | tr ',' '\n' | grep '^commit=' || echo '(default)')"
			if _tp_has_epp; then
				printf '  %-32s %s\n' "cpu energy_performance_preference" \
					"$(cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null | sort -u | tr '\n' ' ')"
			fi
			# status is also the condition used by the menu: a profile is active
			# or it is not, and the caller branches on the exit code.
			[[ -n "$active" ]]
			;;

		"${commands[3]}") # list
			echo "Available tuning profiles:"
			echo ""
			local line name desc
			while IFS='|' read -r name desc; do
				[[ -z "$name" ]] && continue
				printf '  %-10s %s\n' "$name" "$desc"
			done < <(_tp_profile_list)
			echo ""
			echo "Apply with: armbian-config --api module_tuning_profile apply <name>"
			;;

		"${commands[4]}") # reset
			if [[ ! -f "$TP_SYSCTL_FILE" && ! -f "$TP_UNIT_FILE" ]]; then
				echo "No tuning profile is applied."
				return 0
			fi
			systemctl disable --now armbian-tuning-profile.service > /dev/null 2>&1
			rm -f "$TP_UNIT_FILE" "$TP_SYSCTL_FILE" "$TP_STATE_FILE"
			systemctl daemon-reload > /dev/null 2>&1

			# Deleting the drop-in is not enough. `sysctl --system` only writes
			# the keys the remaining files declare; a key that no file mentions
			# keeps whatever value it currently holds. Most systems have no
			# drop-in for vm.dirty_bytes or vm.dirty_expire_centisecs, so without
			# this the profile's values would stay live while `status` reported no
			# profile applied -- the configuration gone but its effects still in
			# place, which is the worst of both.
			#
			# So write the kernel's own defaults explicitly first. The `balanced`
			# profile is exactly those defaults, which is what makes it usable as
			# the reset target rather than a third opinion. Setting the ratio form
			# also zeroes the byte form, so this clears dirty_bytes without naming
			# it.
			local key val
			while read -r key _ val; do
				[[ "$key" == vm.* ]] || continue
				sysctl -qw "${key}=${val}" > /dev/null 2>&1
			done < <(_tp_emit_sysctl balanced | grep -E '^vm\.')

			# Then reload, so any remaining drop-in (the distribution's own
			# swappiness, for instance) gets the last word over those defaults.
			sysctl --system > /dev/null 2>&1
			# Take the commit= option back out of fstab, returning / to the
			# kernel default. Removing the option is the honest inverse of adding
			# it; writing some other number would be a third opinion.
			if _tp_root_is_ext4; then
				_tp_set_fstab_commit "" || \
					echo "  fstab left as it was; remove commit= by hand if you want the default" >&2
			fi
			echo "Tuning profile removed; distribution defaults reloaded."
			# The CPU bias is the one thing with no file to revert it to: the unit
			# that set it is gone, but the value it wrote is still in the hardware.
			# Say so rather than implying the machine is wholly back to stock.
			#
			# `if`, not `_tp_has_epp && echo`: as the last command in this branch
			# that idiom makes the whole verb exit non-zero on every machine
			# without the knob -- which is most ARM hardware -- so reset would
			# report failure after doing its job correctly.
			if _tp_has_epp; then
				echo "Note: the CPU energy/performance preference stays as last set until reboot."
			fi
			return 0
			;;

		"${commands[5]}") # cpu [select|status|apply|reset|set ...]
			case "$2" in
				"" | select) _tp_cpu_tui ;;
				status) _tp_cpu_status ;;
				apply) _tp_cpu_apply ;;
				reset) _tp_cpu_reset ;;
				set) _tp_cpu_set "$3" "$4" "$5" ;;
				*)
					echo "Usage: module_tuning_profile cpu [select|status|apply|reset|set <all|policy<list>> <governor|min|max|boost|clear> [value]]" >&2
					return 1
					;;
			esac
			;;

		"${commands[6]}") # help
			show_module_help "module_tuning_profile" "$title"
			;;

		*)
			show_module_help "module_tuning_profile" "$title"
			;;
	esac
}

module_options+=(
	["module_armbian_kvmtest,author"]="@igorpecovnik"
	["module_armbian_kvmtest,feature"]="module_armbian_kvmtest"
	["module_armbian_kvmtest,desc"]="Deploy Armbian KVM instances"
	["module_armbian_kvmtest,example"]="install remove save drop restore list help"
	["module_armbian_kvmtest,port"]=""
	["module_armbian_kvmtest,status"]="Active"
	["module_armbian_kvmtest,arch"]="x86-64"
)
#
# Module deploy Armbian QEMU KVM instances
# module_armbian_kvmtest - Manage the lifecycle of Armbian KVM virtual machines.
#
# This function deploys, configures, and manages Armbian-based KVM instances. It supports a suite of
# commands (install, remove, save, drop, restore, list, help) to handle the entire virtual machine lifecycle.
# Depending on the command, the function performs operations such as downloading cloud-based Armbian images,
# resizing and mounting VM disk images, customizing network settings, and executing provisioning scripts.
#
# Globals:
#   module_options - An associative array with module metadata (author, features, command examples, etc.).
#
# Arguments:
#   The first argument specifies the command to execute (e.g., install, remove, save, drop, restore, list, help).
#   Additional arguments should be provided as key=value pairs to customize the operation. Supported keys include:
#     instances     - Number of VM instances to deploy (default: "01").
#     provisioning  - Path to a provisioning script to be run on the first boot of each VM.
#     firstconfig   - File with initial configuration commands for the VMs.
#     startingip    - Starting IP address (with underscores replacing dots, e.g., 192_168_1_100).
#     gateway       - Gateway IP address (with underscores replacing dots, e.g., 192_168_1_1).
#     keyword       - Image filter keyword; supports comma-separated values (converted internally to a regex).
#     arch          - Architecture of the VM image (default: "x86").
#     kvmprefix     - Prefix used for naming VMs (default: "kvmtest").
#     network       - Network configuration (default: "default", or set to "bridge=[bridge]" if a bridge is specified).
#     bridge        - Overrides the default network by specifying a network bridge.
#     memory        - Memory allocation for each VM, in MB (default: "3072").
#     vcpus         - Number of virtual CPUs allocated per VM (default: "2").
#     size          - Additional disk space in GB to allocate to each VM (default: "10").
#
# Outputs:
#   The function prints deployment progress, image URLs (when listing), and usage instructions to STDOUT.
#
# Returns:
#   This function does not return a value; it executes commands with side effects.
#
# Example:
#   To deploy three VMs using a custom provisioning script, increased memory, and specific IP settings:
#     module_armbian_kvmtest install instances=03 memory=4096 vcpus=4 startingip=192_168_1_100 gateway=192_168_1_1 provisioning=/path/to/script keyword=Focal
#
#   To remove all deployed VMs:
#     module_armbian_kvmtest remove
function module_armbian_kvmtest () {

	local title="kvmtest"
	local condition=$(which "$title" 2>/dev/null)

	# read additional parameters from command line
	local parameter
	declare -A params
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for selected in ${parameter[@]}; do
			IFS='=' read -r -a split <<< "${selected}"
			# Only accept known parameters for security
			case "${split[0]}" in
				instances|provisioning|firstconfig|startingip|gateway|keyword|arch|kvmprefix|network|bridge|memory|vcpus|size|destination|channel)
					params["${split[0]}"]="${split[1]}"
					;;
			esac
		done
	done

	# Extract parameters from array
	instances="${params[instances]:-}"
	provisioning="${params[provisioning]:-}"
	firstconfig="${params[firstconfig]:-}"
	startingip="${params[startingip]:-}"
	gateway="${params[gateway]:-}"
	keyword="${params[keyword]:-}"
	arch="${params[arch]:-}"
	kvmprefix="${params[kvmprefix]:-}"
	network="${params[network]:-}"
	bridge="${params[bridge]:-}"
	memory="${params[memory]:-}"
	vcpus="${params[vcpus]:-}"
	size="${params[size]:-}"
	destination="${params[destination]:-}"
	channel="${params[channel]:-nightly}"

	# if we provide startingip and gateway, set network
	if [[ -n "${startingip}" && -n "${gateway}" ]]; then
		PRESET_NET_CHANGE_DEFAULTS="1"
	fi

	local startingip=$(echo "${startingip:-}" | sed "s/_/./g")
	local gateway=$(echo "${gateway:-}" | sed "s/_/./g")

	local arch="${arch:-x86}" # VM architecture
	local network="${network:-default}"
	if [[ -n "${bridge}" ]]; then network="bridge=${bridge}"; fi
	local instances="${instances:-01}" # number of instances
	local size="${size:-10}" # additional disk space in GB
	local destination="${destination:-/var/lib/libvirt/images}"
	local kvmprefix="${kvmprefix:-kvmtest}"
	local memory="${memory:-3072}"
	local vcpus="${vcpus:-2}"
	local startingip="${startingip:-10.0.60.60}"
	local gateway="${gateway:-10.0.60.1}"
	local keyword=$(echo "${keyword:-}" | sed "s/,/|/g") # convert

	# Define image arrays for different channels
	local qcowimages_nightly=(
		"https://dl.armbian.com/nightly/uefi-${arch}/Forky_cloud_minimal-qcow2"
		"https://dl.armbian.com/nightly/uefi-${arch}/Resolute_cloud_minimal-qcow2"
	)

	local qcowimages_stable=(
		"https://dl.armbian.com/uefi-${arch}/Noble_cloud_minimal-qcow2"
		"https://dl.armbian.com/uefi-${arch}/Trixie_cloud_minimal-qcow2"
	)

	# Select image array based on channel parameter
	case "${channel}" in
		stable)
			qcowimages=("${qcowimages_stable[@]}")
			;;
		nightly|*)
			qcowimages=("${qcowimages_nightly[@]}")
			;;
	esac

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_kvmtest,example"]}"

	case "$1" in

		"${commands[0]}")

			pkg_install virtinst libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils dnsmasq

			# start network
			virsh net-start default 2>/dev/null
			virsh net-autostart default 2>/dev/null

			# download images
			tempfolder=$(mktemp -d)
			trap '{ rm -rf -- "$tempfolder"; }' EXIT
			for qcowimage in ${qcowimages[@]}; do
				[[ -n "${keyword}" && ! $qcowimage =~ ${keyword} ]] && continue # skip not needed ones
				local filename=$(basename "$qcowimage" | sed "s/-qcow2/.qcow2/g")
				local output_file="${tempfolder}/${filename}"

				# Download with real progress based on file size
				(
					# Get expected file size
					expected_size=$(curl -sI "$qcowimage" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
					[[ -z "$expected_size" || "$expected_size" -eq 0 ]] && expected_size=100000000

					# Start download in background
					curl -sL "$qcowimage" -o "$output_file" &
					curl_pid=$!

					# Monitor file size and report progress
					while kill -0 $curl_pid 2>/dev/null; do
						if [[ -f "$output_file" ]]; then
							current_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
							percent=$((current_size * 100 / expected_size))
							[[ $percent -gt 95 ]] && percent=95
							echo $percent
						fi
						sleep 0.5
					done
					echo 100
					wait $curl_pid
				) | dialog_gauge "Download" "$filename" 8 70

				# decompress
				if [[ "$(file $output_file --extension -b)" == "xz" ]]; then
					dialog_infobox "Decompressing" "$(basename $output_file)" 6 60
					mv "$output_file" "$output_file".xz
					xz -d "$output_file".xz
				fi




			done

			# we will mount qcow image
			modprobe nbd max_part=8

			mounttempfolder=$(mktemp -d)
			trap '{ umount "$mounttempfolder" 2>/dev/null; rm -rf -- "$tempfolder"; }' EXIT

			# Deploy several instances
			local j=0  # Initialize IP address counter
			for i in $(seq -w 01 $instances); do
				for qcowimage in ${qcowimages[@]}; do
					[[ ! $qcowimage =~ ${keyword/,/|} ]] && continue # skip not needed ones
					local filename=$(basename $qcowimage | sed "s/-qcow2/.qcow2/g") # identify filename
					local domain=$i-${kvmprefix}-$(basename $qcowimage | sed "s/-qcow2//g") # without qcow2
					local image="$i"-"${kvmprefix}"-"${filename}" # get image name
					cp ${tempfolder}/${filename} ${destination}/${image} # make a copy under different number
					sync
					qemu-img resize ${destination}/${image} +"${size}G" 2>/dev/null # expand
					qemu-nbd --connect=/dev/nbd0 ${destination}/${image} 2>/dev/null # connect to qemu image
					printf "fix\n" | sudo parted ---pretend-input-tty /dev/nbd0 print >/dev/null # fix resize
					mount /dev/nbd0p3 ${mounttempfolder} # 3rd partition on uefi images is rootfs
					# Check if it reads and display OS info
					local os_name=$(cat ${mounttempfolder}/etc/os-release | grep ARMBIAN_PRETTY_NAME | cut -d"=" -f2 | sed 's/"//g')
					dialog_infobox "" "$os_name" 6 60
					# commands for changing follows here
					j=$(( j + 1 ))
					local ip_address=$(awk -F\. '{ print $1"."$2"."$3"."$4+'$j' }' <<< $startingip )

					# script that is executed at firstrun
					if [[ -f ${provisioning} ]]; then
						echo "INSTANCE=$i" > ${mounttempfolder}/root/provisioning.sh
						cat "${provisioning}" >> ${mounttempfolder}/root/provisioning.sh
						chmod +x ${mounttempfolder}/root/provisioning.sh
					fi

					# first config
					if [[ ${firstconfig} ]]; then
						if [[ -f ${firstconfig} ]]; then
							cat "${firstconfig}" >> ${mounttempfolder}/root/.not_logged_in_yet
						fi
					else
					dialog_infobox "Applying first config" "$domain" 6 60
					cat <<- EOF >> ${mounttempfolder}/root/.not_logged_in_yet
					PRESET_NET_CHANGE_DEFAULTS="${PRESET_NET_CHANGE_DEFAULTS}"
					PRESET_NET_ETHERNET_ENABLED="1"
					PRESET_NET_USE_STATIC="1"
					PRESET_NET_STATIC_IP="${ip_address}"
					PRESET_NET_STATIC_MASK="255.255.255.0"
					PRESET_NET_STATIC_GATEWAY="${gateway}"
					PRESET_NET_STATIC_DNS="9.9.9.9 8.8.4.4"
					SET_LANG_BASED_ON_LOCATION="y"
					PRESET_LOCALE="${LANG:-en_US.UTF-8}"
					PRESET_TIMEZONE="$(cat /etc/timezone)"
					PRESET_ROOT_PASSWORD="armbian"
					PRESET_USER_NAME="armbian"
					PRESET_USER_PASSWORD="armbian"
					PRESET_USER_KEY=""
					PRESET_DEFAULT_REALNAME="Armbian user"
					PRESET_USER_SHELL="bash"
					EOF
					fi

					umount /dev/nbd0p3 # unmount
					qemu-nbd --disconnect /dev/nbd0 >/dev/null # disconnect from qemu image
					# install and start VM
					sleep 3
					virt-install \
					--name ${domain} \
					--memory ${memory} \
					--vcpus ${vcpus} \
					--autostart \
					--disk ${destination}/${image},bus=sata \
					--import \
					--os-variant ubuntu24.04 \
					--network ${network} \
					--noautoconsole
				done
			done

		;;
		"${commands[1]}")
			dialog_infobox "Info" "Removing VMs..." 6 60
			local shutdown_success=false
			for i in {1..10}; do
				for j in $(virsh list --all --name | grep ${kvmprefix}); do
					dialog_infobox "Shutting Down" "Stopping VM: $(virsh shutdown $j)" 6 60

					snapshots=($(virsh snapshot-list $j | tail -n +3 | head -n -1 | cut -d' ' -f2))
					if [[ ${#snapshots[@]} -gt 0 ]]; then
						local count=0
						local total=${#snapshots[@]}
						for snapshot in "${snapshots[@]}"; do
							count=$((count + 1))
							percent=$((count * 100 / total))
							echo $percent
							virsh snapshot-delete $j $snapshot
						done | dialog_gauge "Removing Snapshots" "Deleting snapshots from $j" 8 70
					fi
				done
				sleep 2
				if [[ -z "$(virsh list --name | grep ${kvmprefix})" ]]; then
					shutdown_success=true
					break
				fi
			done
			# Force destroy any VMs that didn't shut down gracefully
			if ! $shutdown_success; then
				for j in $(virsh list --name | grep ${kvmprefix}); do
					dialog_infobox "Force Stopping" "Destroying VM: $j" 6 60
					virsh destroy $j
				done
			fi
			vms=($(virsh list --all --name | grep ${kvmprefix}))
			if [[ ${#vms[@]} -gt 0 ]]; then
				local count=0
				local total=${#vms[@]}
				for j in "${vms[@]}"; do
					count=$((count + 1))
					percent=$((count * 100 / total))
					echo $percent
					virsh undefine $j --remove-all-storage
				done | dialog_gauge "Removing VMs" "Undefining and removing VM storage" 8 70
			fi
		;;
		"${commands[2]}")
			dialog_infobox "" "Saving VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# create snapshots
				virsh snapshot-create-as --domain ${j} --name "initial-state"
			done
		;;
		"${commands[3]}")
			dialog_infobox "" "Dropping VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				# drop snapshots
				virsh snapshot-delete "${j}" "initial-state"
			done
		;;
		"${commands[4]}")
			dialog_infobox "" "Restoring VM states..." 6 60
			for j in $(virsh list --all --name | grep ${kvmprefix}); do
				virsh shutdown $j 2>/dev/null
				virsh snapshot-revert --domain $j --snapshotname "initial-state" --running
				virsh shutdown $j 2>/dev/null
				for i in {1..20}; do
					sleep 2
					if [[ "$(virsh domstate $j | grep "shut off")" == "shut off" ]]; then break; fi
				done
				virsh start $j 2>/dev/null
			done
		;;
		"${commands[5]}")
			for qcowimage in ${qcowimages[@]}; do
				[[ -n "${keyword}" && ! $qcowimage =~ ${keyword} ]] && continue # skip not needed ones
				echo $qcowimage
			done
		;;
		"${commands[6]}")
			local help_text="Usage: ${module_options["module_armbian_kvmtest,feature"]} <command> [switches]\n\n"
			help_text+="Commands:  ${module_options["module_armbian_kvmtest,example"]}\n\n"
			help_text+="Available commands:\n\n"
			help_text+="  install  - Install $title\n"
			help_text+="  remove   - Remove all virtual machines $title\n"
			help_text+="  save     - Save state of all VM $title\n"
			help_text+="  restore  - Restore all saved state of VM $title\n"
			help_text+="  drop     - Drop all saved states of VM $title\n"
			help_text+="  list     - Show available VM machines $title\n"
			help_text+="\nAvailable switches:\n\n"
			help_text+="  kvmprefix     - Name prefix (default = kvmtest)\n"
			help_text+="  memory        - KVM memory (default = 3072)\n"
			help_text+="  vcpus         - Virtual CPUs (default = 2)\n"
			help_text+="  bridge        - Use network bridge br0,br1,... instead of default interface\n"
			help_text+="  instances     - Number of instances (default = 01)\n"
			help_text+="  provisioning  - File of command that is executed at first run\n"
			help_text+="  firstconfig   - Armbian first config\n"
			help_text+="  keyword       - Select only certain image, example: Focal_Jammy VM image\n"
			help_text+="  arch          - Architecture of VM image (default = x86)\n"
			help_text+="  size          - Additional disk space in GB (default = 10)\n"
			help_text+="  startingip    - Starting IP address (default = 10.0.60.60)\n"
			help_text+="  gateway       - Gateway IP address (default = 10.0.60.1)\n"
			help_text+="  channel       - Image channel: stable or nightly (default = nightly)\n"

			if [[ "$DIALOG" == "read" ]]; then
				echo -e "$help_text"
			else
				dialog_msgbox "Armbian KVM Test Help" "$help_text" 25 80
			fi
		;;
		*)
			${module_options["module_armbian_kvmtest,feature"]} ${commands[6]}
		;;
	esac
}


module_options+=(
	["module_memory,author"]="@igorpecovnik"
	["module_memory,maintainer"]="@igorpecovnik"
	["module_memory,feature"]="module_memory"
	["module_memory,desc"]="Memory management and tuning interface"
	["module_memory,example"]="install remove status tune help"
	["module_memory,port"]=""
	["module_memory,status"]="Active"
	["module_memory,arch"]="x86-64 arm64"
	["module_memory,doc_link"]="https://docs.armbian.com/User-Guide_Fine-Tuning/"
	["module_memory,group"]="System"
	["module_memory,config_file"]="/etc/default/armbian-zram-config"
	# Custom command help descriptions
	["module_memory,help_tune"]="Fine-tune ZRAM compression and system memory parameters"
)
#
# Module Memory Management
#
function module_memory () {
	local title="Memory Management"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_memory,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already enabled
			if module_memory status >/dev/null 2>&1; then
				echo "Memory management is already enabled."
				return 0
			fi

			# Check if zram-config package is installed
			if ! pkg_installed zram-config; then
				echo "Installing zram-config package..."
				pkg_install zram-config || {
					echo "Failed to install zram-config package."
					return 1
				}
			fi

			# Enable and start the service
			echo "Enabling ZRAM memory compression..."
			srv_enable armbian-zram-config
			srv_start armbian-zram-config

			# Set recommended swappiness for ZRAM
			if [[ ! -f /etc/sysctl.d/99-armbian-memory.conf ]]; then
				echo "vm.swappiness=100" > /etc/sysctl.d/99-armbian-memory.conf
				sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1
			fi

			echo "Memory management enabled successfully."
			echo "Use 'armbian-config' → 'System' → 'Storage' → 'Tune Memory' to configure settings."
		;;

		"${commands[1]}") # remove
			if ! module_memory status >/dev/null 2>&1; then
				echo "Memory management is not enabled."
				return 0
			fi

			# Stop and disable the service
			echo "Disabling ZRAM memory compression..."
			srv_stop armbian-zram-config
			srv_disable armbian-zram-config

			# Remove swappiness override created during install
			if [[ -f /etc/sysctl.d/99-armbian-memory.conf ]]; then
				rm -f /etc/sysctl.d/99-armbian-memory.conf
				sysctl --system >/dev/null 2>&1
			fi

			echo "Memory management disabled successfully."
		;;

		"${commands[2]}") # status
			if srv_active armbian-zram-config; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # tune
			# Check if memory management is enabled
			if ! module_memory status >/dev/null 2>&1; then
				dialog_msgbox "Memory Management Not Enabled" \
					"Memory management is not enabled.\n\nPlease enable it first:\nSystem → Storage → Memory" 11 70
				return 1
			fi

			local config_file="/etc/default/armbian-zram-config"
			local backup_file="${config_file}.bak"

			# Get current system memory in MB
			local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
			local total_mem_mb=$((total_mem_kb / 1024))
			local total_mem_gb=$((total_mem_mb / 1024))
			local cpu_cores=$(nproc 2>/dev/null || echo "4")
			local recommended_devices=$(( cpu_cores > 8 ? 8 : cpu_cores ))

			# Calculate recommended values based on system memory
			local recommended_zram_percentage=50
			local recommended_mem_limit=50
			local recommended_swappiness=100

			if [[ $total_mem_gb -ge 4 ]]; then
				recommended_zram_percentage=25
				recommended_mem_limit=25
				recommended_swappiness=80
			fi

			# Read current configuration
			local zram_enabled=$(grep "^ENABLED=" "$config_file" 2>/dev/null | cut -d= -f2)
			local zram_swap_enabled=$(grep "^SWAP=" "$config_file" 2>/dev/null | cut -d= -f2)
			local zram_percentage=$(grep "^ZRAM_PERCENTAGE=" "$config_file" 2>/dev/null | cut -d= -f2)
			local mem_limit_percentage=$(grep "^MEM_LIMIT_PERCENTAGE=" "$config_file" 2>/dev/null | cut -d= -f2)
			local max_devices=$(grep "^ZRAM_MAX_DEVICES=" "$config_file" 2>/dev/null | cut -d= -f2)
			local swap_algorithm=$(grep "^SWAP_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local ramlog_algorithm=$(grep "^RAMLOG_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local tmp_algorithm=$(grep "^TMP_ALGORITHM=" "$config_file" 2>/dev/null | cut -d= -f2)
			local tmp_size=$(grep "^TMP_SIZE=" "$config_file" 2>/dev/null | cut -d= -f2)

			# Set defaults if not found
			zram_enabled=${zram_enabled:-true}
			zram_swap_enabled=${zram_swap_enabled:-true}
			zram_percentage=${zram_percentage:-50}
			mem_limit_percentage=${mem_limit_percentage:-50}
			max_devices=${max_devices:-4}
			swap_algorithm=${swap_algorithm:-lzo}
			ramlog_algorithm=${ramlog_algorithm:-zstd}
			tmp_algorithm=${tmp_algorithm:-zstd}
			tmp_size=${tmp_size:-500M}

			# Get current swappiness
			local swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "100")

			# Main tuning menu
			while true; do
				# Build status string
				local status_string="Disabled"
				[[ "$zram_enabled" = "true" ]] && status_string="Enabled"

				# Build menu text
				local menu_text="System Memory: ${total_mem_mb} MB (${total_mem_gb} GB)\nCPU Cores: ${cpu_cores}\n\n"
				menu_text+="Current ZRAM Settings:\n"
				menu_text+="Status: ${status_string}\n"
				menu_text+="Swap Size: ${zram_percentage}% of RAM (= $((total_mem_mb * zram_percentage / 100)) MB)\n"
				menu_text+="Memory Limit: ${mem_limit_percentage}% of RAM\n"
				menu_text+="Max Devices: ${max_devices}\n"
				menu_text+="Compression Algorithm: ${swap_algorithm}\n\n"
				menu_text+="System Parameters:\n"
				menu_text+="Swappiness: ${swappiness}\n\n"
				menu_text+="Select a parameter to tune:"

				local choice=$(dialog_menu "Memory Management Tuning" "$menu_text" 30 80 6 \
					"1" "ZRAM Settings - Configure ZRAM compression parameters" \
					"2" "System Parameters - Configure swappiness" \
					"3" "Reset to Defaults - Restore recommended settings" \
					"4" "Show Current Configuration - Display current config file" \
					"5" "Save & Apply Configuration - Save changes and restart ZRAM service")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # ZRAM Settings submenu
						while true; do
							# Build status string for menu
							local zram_status="Disabled"
							[[ "$zram_enabled" = "true" ]] && zram_status="Enabled"

							local zram_choice=$(dialog_menu "ZRAM Settings" \
								"Configure ZRAM compression parameters\n\nSystem: ${total_mem_mb} MB RAM, ${cpu_cores} cores" 18 80 7 \
								"1" "Enable/Disable ZRAM - Current: ${zram_status}" \
								"2" "ZRAM Size Percentage - Current: ${zram_percentage}% of RAM (recommended: ${recommended_zram_percentage}%)" \
								"3" "Memory Limit Percentage - Current: ${mem_limit_percentage}% (recommended: ${recommended_mem_limit}%)" \
								"4" "Max Devices - Current: ${max_devices} (recommended: ${recommended_devices})" \
								"5" "Swap Compression Algorithm - Current: ${swap_algorithm}" \
								"6" "RAM & Temp Compression - RAMLOG: ${ramlog_algorithm}, /tmp: ${tmp_algorithm}, Size: ${tmp_size}" \
								"7" "Back to Main Menu - Return to main menu")

							[[ -z "$zram_choice" ]] && break

							case $zram_choice in
								1) # Toggle ZRAM enable/disable
									if [[ "$zram_enabled" = "true" ]]; then
										if dialog_yesno "Disable ZRAM" \
											"Disable ZRAM compression?\n\nThis will reduce available memory."; then
											zram_enabled=false
											zram_swap_enabled=false
										fi
									else
										if dialog_yesno "Enable ZRAM" \
											"Enable ZRAM compression?\n\nThis will improve performance on memory-constrained systems."; then
											zram_enabled=true
											zram_swap_enabled=true
										fi
									fi
									;;
								2) # ZRAM percentage
									local new_percentage=$(dialog_inputbox "ZRAM Size Percentage" \
										"Enter ZRAM size as percentage of RAM:\n\nRecommended: ${recommended_zram_percentage}%\nCurrent: ${zram_percentage}%\n\nRange: 10-300%\nHigher values = more swap space (compressed)" \
										"$zram_percentage" 14 70)

									if [[ -n "$new_percentage" ]]; then
										if [[ "$new_percentage" =~ ^[0-9]+$ ]] && [[ $new_percentage -ge 10 ]] && [[ $new_percentage -le 300 ]]; then
											zram_percentage=$new_percentage
										else
											dialog_msgbox "Invalid Value" \
												"ZRAM percentage must be between 10 and 300." 8 50
										fi
									fi
									;;
								3) # Memory limit percentage
									local new_limit=$(dialog_inputbox "Memory Limit Percentage" \
										"Enter memory limit as percentage of RAM:\n\nRecommended: ${recommended_mem_limit}%\nCurrent: ${mem_limit_percentage}%\n\nRange: 10-100%\nThis limits actual memory usage by ZRAM" \
										"$mem_limit_percentage" 14 70)

									if [[ -n "$new_limit" ]]; then
										if [[ "$new_limit" =~ ^[0-9]+$ ]] && [[ $new_limit -ge 10 ]] && [[ $new_limit -le 100 ]]; then
											mem_limit_percentage=$new_limit
										else
											dialog_msgbox "Invalid Value" \
												"Memory limit must be between 10 and 100." 8 50
										fi
									fi
									;;
								4) # Max devices
									local new_devices=$(dialog_inputbox "Max ZRAM Devices" \
										"Enter maximum number of ZRAM devices:\n\nRecommended: ${recommended_devices}\nCurrent: ${max_devices}\n\nRange: 1-8\nUsually set to number of CPU cores" \
										"$max_devices" 13 70)

									if [[ -n "$new_devices" ]]; then
										if [[ "$new_devices" =~ ^[0-9]+$ ]] && [[ $new_devices -ge 1 ]] && [[ $new_devices -le 8 ]]; then
											max_devices=$new_devices
										else
											dialog_msgbox "Invalid Value" \
												"Max devices must be between 1 and 8." 8 50
										fi
									fi
									;;
								5) # Swap compression algorithm
									# Set default selection
									local lzo_selected="off"
									local lzo_rle_selected="off"
									local lz4_selected="off"
									local zstd_selected="off"

									case "$swap_algorithm" in
										lzo) lzo_selected="on" ;;
										lzo-rle) lzo_rle_selected="on" ;;
										lz4) lz4_selected="on" ;;
										zstd) zstd_selected="on" ;;
										*) lzo_selected="on" ;;
									esac

									local new_algorithm=$(dialog_radiolist "Swap Compression Algorithm" \
										"Choose compression algorithm for ZRAM swap:\n\nlzo: Best for ARM (recommended)\nlz4: Faster, less compression\nzstd: Best compression, slower" 15 80 4 \
										"lzo" "LZO - Best for ARM (recommended)" "$lzo_selected" \
										"lz4" "LZ4 - Faster compression" "$lz4_selected" \
										"zstd" "ZSTD - Best compression ratio" "$zstd_selected")

									if [[ -n "$new_algorithm" ]]; then
										swap_algorithm=$new_algorithm
									fi
									;;
								6) # RAM & Temp compression
									local ramtmp_choice=$(dialog_menu "RAM & Temp Compression" \
										"Configure compression for RAM log and /tmp partitions" 14 70 3 \
										"1" "RAMLOG Algorithm - Current: ${ramlog_algorithm}" \
										"2" "/tmp Algorithm - Current: ${tmp_algorithm}" \
										"3" "/tmp Size - Current: ${tmp_size}")

									case $ramtmp_choice in
										1) # RAMLOG algorithm
											# Pre-calculate radiolist selection states
											local lzo_selected="off"
											local lz4_ram_selected="off"
											local zstd_ram_selected="off"

											case "$ramlog_algorithm" in
												lzo) lzo_selected="on" ;;
												lz4) lz4_ram_selected="on" ;;
												zstd) zstd_ram_selected="on" ;;
											esac

											local new_ramlog=$(dialog_radiolist "RAMLOG Compression" \
												"Choose compression algorithm for /var/log:" 13 70 3 \
												"lzo" "LZO - Fast compression" "$lzo_selected" \
												"lz4" "LZ4 - Faster compression" "$lz4_ram_selected" \
												"zstd" "ZSTD - Best compression" "$zstd_ram_selected")

											if [[ -n "$new_ramlog" ]]; then
												ramlog_algorithm=$new_ramlog
											fi
											;;
										2) # /tmp algorithm
											# Pre-calculate radiolist selection states
											local lzo_tmp_selected="off"
											local lz4_tmp_selected="off"
											local zstd_tmp_selected="off"

											case "$tmp_algorithm" in
												lzo) lzo_tmp_selected="on" ;;
												lz4) lz4_tmp_selected="on" ;;
												zstd) zstd_tmp_selected="on" ;;
											esac

											local tmp_choice_alg=$(dialog_radiolist "/tmp Compression" \
												"Choose compression algorithm for /tmp:" 13 70 3 \
												"lzo" "LZO - Fast compression" "$lzo_tmp_selected" \
												"lz4" "LZ4 - Faster compression" "$lz4_tmp_selected" \
												"zstd" "ZSTD - Best compression" "$zstd_tmp_selected")

											if [[ -n "$tmp_choice_alg" ]]; then
												tmp_algorithm=$tmp_choice_alg
											fi
											;;
										3) # /tmp size
											local new_tmp_size=$(dialog_inputbox "/tmp Size" \
												"Enter size for ZRAM-based /tmp partition:\n\nCurrent: ${tmp_size}\n\nExamples: 500M, 1G, 2G\nDefault: Half of RAM if not specified" \
												"$tmp_size" 13 70)

											if [[ -n "$new_tmp_size" ]]; then
												tmp_size=$new_tmp_size
											fi
											;;
									esac
									;;
							esac
						done
						;;

					2) # System parameters
						local recommendation=""
						if [[ $swappiness -lt 80 ]]; then
							recommendation="\n\nNote: For ZRAM systems, values 80-100 are recommended\nto ensure aggressive swapping to compressed RAM."
						fi

						local new_swappiness=$(dialog_inputbox "Swappiness" \
							"Enter vm.swappiness (1-100):\n\nCurrent: ${swappiness}${recommendation}\n\nLower = swap less (1)\nHigher = swap more to ZRAM (100)" \
							"$swappiness" 15 70)

						if [[ -n "$new_swappiness" ]]; then
							if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [[ $new_swappiness -ge 1 ]] && [[ $new_swappiness -le 100 ]]; then
								# Apply immediately
								echo "vm.swappiness=$new_swappiness" > /etc/sysctl.d/99-armbian-memory.conf
								sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1
								swappiness=$new_swappiness
								dialog_msgbox "Swappiness Updated" \
									"Swappiness set to ${swappiness}\n\nSetting saved to /etc/sysctl.d/99-armbian-memory.conf" 10 60
							else
								dialog_msgbox "Invalid Value" \
									"Swappiness must be between 1 and 100." 8 50
							fi
						fi
						;;

					3) # Reset to defaults
						if dialog_yesno "Reset to Defaults" \
							"Reset all parameters to Armbian recommended defaults?\n\nThis will restore optimal settings for your system."; then
							# Reset to recommended values
							zram_enabled=true
							zram_swap_enabled=true
							zram_percentage=$recommended_zram_percentage
							mem_limit_percentage=$recommended_mem_limit
							max_devices=$recommended_devices
							swap_algorithm="lzo"
							ramlog_algorithm="zstd"
							tmp_algorithm="zstd"
							tmp_size="500M"
							swappiness=$recommended_swappiness

							dialog_msgbox "Reset Complete" \
								"Parameters reset to recommended defaults.\n\nApply changes to take effect." 11 70
						fi
						;;

					4) # Show current configuration
						local show_text="Current ZRAM Configuration:\n\n"
						show_text+="ENABLED=${zram_enabled}\n"
						show_text+="SWAP=${zram_swap_enabled}\n"
						show_text+="ZRAM_PERCENTAGE=${zram_percentage}\n"
						show_text+="MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}\n"
						show_text+="ZRAM_MAX_DEVICES=${max_devices}\n"
						show_text+="SWAP_ALGORITHM=${swap_algorithm}\n"
						show_text+="RAMLOG_ALGORITHM=${ramlog_algorithm}\n"
						show_text+="TMP_ALGORITHM=${tmp_algorithm}\n"
						show_text+="TMP_SIZE=${tmp_size}\n\n"
						show_text+="System Parameters:\n"
						show_text+="vm.swappiness=${swappiness}\n\n"
						show_text+="Configuration file: ${config_file}\n\n"
						show_text+="Active swap devices:\n"

						# Get active swap info
						local swap_info=$(swapon --show 2>/dev/null)
						if [[ -n "$swap_info" ]]; then
							show_text+="$swap_info"
						else
							show_text+="(No swap devices active)"
						fi

						dialog_msgbox "Current Configuration" "$show_text" 20 75
						;;

					5) # Save & Apply
						local config_preview="The following settings will be saved to:\n${config_file}\n\n"
						config_preview+="ENABLED=${zram_enabled}\n"
						config_preview+="SWAP=${zram_swap_enabled}\n"
						config_preview+="ZRAM_PERCENTAGE=${zram_percentage}%\n"
						config_preview+="MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}%\n"
						config_preview+="ZRAM_MAX_DEVICES=${max_devices}\n"
						config_preview+="SWAP_ALGORITHM=${swap_algorithm}\n"
						config_preview+="RAMLOG_ALGORITHM=${ramlog_algorithm}\n"
						config_preview+="TMP_ALGORITHM=${tmp_algorithm}\n"
						config_preview+="TMP_SIZE=${tmp_size}\n\n"
						config_preview+="vm.swappiness=${swappiness}\n\n"
						config_preview+="Save and apply these settings?"

						if dialog_yesno "Save Configuration" "$config_preview"; then
							# Backup existing config
							if [[ -f "$config_file" ]]; then
								cp "$config_file" "$backup_file" || {
									dialog_msgbox "Backup Failed" "Failed to backup existing configuration.\n\nContinuing without backup."
								}
							fi

							# Write new configuration, preserving unknown keys
							local tmp_config
							tmp_config=$(mktemp)

							# Collect keys we manage
							declare -A managed_keys=(
								[ENABLED]="${zram_enabled}"
								[SWAP]="${zram_swap_enabled}"
								[ZRAM_PERCENTAGE]="${zram_percentage}"
								[MEM_LIMIT_PERCENTAGE]="${mem_limit_percentage}"
								[ZRAM_MAX_DEVICES]="${max_devices}"
								[SWAP_ALGORITHM]="${swap_algorithm}"
								[RAMLOG_ALGORITHM]="${ramlog_algorithm}"
								[TMP_ALGORITHM]="${tmp_algorithm}"
								[TMP_SIZE]="${tmp_size}"
							)

							# If existing config, update known keys and preserve the rest
							if [[ -f "$config_file" ]]; then
								while IFS= read -r line; do
									local key="${line%%=*}"
									if [[ -n "${managed_keys[$key]+x}" ]]; then
										echo "${key}=${managed_keys[$key]}"
										unset "managed_keys[$key]"
									else
										echo "$line"
									fi
								done < "$config_file" > "$tmp_config"
								# Append any managed keys not already in file
								for key in "${!managed_keys[@]}"; do
									echo "${key}=${managed_keys[$key]}" >> "$tmp_config"
								done
							else
								{
									echo "# ZRAM Configuration - Generated by Armbian config"
									echo "# Generated on $(date)"
									echo ""
									echo "ENABLED=${zram_enabled}"
									echo "SWAP=${zram_swap_enabled}"
									echo "ZRAM_PERCENTAGE=${zram_percentage}"
									echo "MEM_LIMIT_PERCENTAGE=${mem_limit_percentage}"
									echo "ZRAM_MAX_DEVICES=${max_devices}"
									echo "SWAP_ALGORITHM=${swap_algorithm}"
									echo "RAMLOG_ALGORITHM=${ramlog_algorithm}"
									echo "TMP_ALGORITHM=${tmp_algorithm}"
									echo "TMP_SIZE=${tmp_size}"
								} > "$tmp_config"
							fi

							mv "$tmp_config" "$config_file"

							# Persist swappiness
							echo "vm.swappiness=${swappiness}" > /etc/sysctl.d/99-armbian-memory.conf
							sysctl -p /etc/sysctl.d/99-armbian-memory.conf >/dev/null 2>&1

							# Notify about backup
							if [[ -f "$backup_file" ]]; then
								dialog_msgbox "Configuration Saved" \
									"Configuration saved successfully.\n\nPrevious configuration backed up to:\n${backup_file}\n\nYou can restore it manually if needed." 12 70
							fi

							# Restart service to apply changes
							if dialog_yesno "Apply Changes" \
								"Configuration saved.\n\nRestart ZRAM service to apply changes?\n\nThis will briefly stop swap operations."; then
								systemctl restart armbian-zram-config

								if systemctl is-active --quiet armbian-zram-config; then
									dialog_msgbox "Success" \
										"ZRAM service restarted successfully.\n\nNew settings are now active." 11 70
								else
									dialog_msgbox "Warning" \
										"ZRAM service may not have restarted properly.\n\nCheck 'systemctl status armbian-zram-config'" 11 70
								fi
							fi

							break
						fi
						;;
				esac
			done
		;;

		"${commands[4]}") # help
			show_module_help "module_memory" "$title"
		;;

		*)
			show_module_help "module_memory" "$title"
		;;
	esac
}


module_options+=(
	["module_devicetree_edit,author"]="@igorpecovnik"
	["module_devicetree_edit,maintainer"]="@igorpecovnik"
	["module_devicetree_edit,feature"]="module_devicetree_edit"
	["module_devicetree_edit,desc"]="Edit device tree source and compile"
	["module_devicetree_edit,example"]="install remove status edit help"
	["module_devicetree_edit,port"]=""
	["module_devicetree_edit,status"]="Active"
	["module_devicetree_edit,arch"]="aarch64 armhf"
	["module_devicetree_edit,doc_link"]="https://docs.kernel.org/devicetree/usage-model.html"
	["module_devicetree_edit,group"]="Kernel"
)
#
# @description Edit device tree blob: decompile, edit, recompile
#
function module_devicetree_edit() {
	local title="Device Tree Editor"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_devicetree_edit,example"]}"

	case "$1" in
		"${commands[0]}") # install
			if module_devicetree_edit status >/dev/null 2>&1; then
				echo "Device tree compiler is already installed."
				return 0
			fi
			echo "Installing device tree compiler..."
			pkg_install device-tree-compiler || {
				echo "Failed to install device tree compiler."
				return 1
			}
			echo "Device tree compiler installed successfully."
		;;

		"${commands[1]}") # remove
			if ! module_devicetree_edit status >/dev/null 2>&1; then
				echo "Device tree compiler is not installed."
				return 0
			fi
			pkg_remove device-tree-compiler
			echo "Device tree compiler removed."
		;;

		"${commands[2]}") # status
			if pkg_installed device-tree-compiler; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # edit
			# Ensure dtc is available
			if ! command -v dtc >/dev/null 2>&1; then
				if dialog_yesno "Missing Dependency" \
					"The device tree compiler (dtc) is not installed.\n\nInstall it now?" "Install" "Cancel"; then
					pkg_install device-tree-compiler || {
						dialog_msgbox "Error" "Failed to install device tree compiler." 8 50
						return 1
					}
				else
					return 1
				fi
			fi

			# Find DTB directory
			local dtb_dir
			dtb_dir=$(find /boot/dtb/ -maxdepth 1 -type d ! -name dtb ! -name overlay ! -name overlays 2>/dev/null | head -n1)
			[[ -z "$dtb_dir" ]] && dtb_dir="/boot/dtb"

			if [[ ! -d "$dtb_dir" ]]; then
				dialog_msgbox "Error" "Device tree directory not found.\n\n/boot/dtb/ does not exist." 9 50
				return 1
			fi

			# Determine currently active DTB from /proc/device-tree/model or fdtfile
			local active_dtb=""
			if [[ -f /boot/armbianEnv.txt ]]; then
				active_dtb=$(awk -F'=' '/^fdtfile/ {print $2}' /boot/armbianEnv.txt)
			fi

			local backup_dir="/boot/dtb/backup"

			while true; do
				# Build menu
				local menu_items=()
				menu_items+=("1" "Select and edit a device tree blob")
				if [[ -n "$active_dtb" ]]; then
					menu_items+=("2" "Edit active DTB: ${active_dtb}")
				fi
				menu_items+=("3" "Restore DTB from backup")
				menu_items+=("4" "View current device tree info")

				local choice
				choice=$(dialog_menu "$title" \
					"\nEdit device tree blobs: decompile to source,\nedit with a text editor, and recompile.\n\nDTB directory: ${dtb_dir}\n" \
					0 0 0 "${menu_items[@]}")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # Select DTB file
						local dtb_files=()
						while IFS= read -r -d '' dtb_file; do
							local basename="${dtb_file##*/}"
							dtb_files+=("$basename" "")
						done < <(find "$dtb_dir" -maxdepth 1 -name '*.dtb' -print0 | sort -z)

						if [[ ${#dtb_files[@]} -eq 0 ]]; then
							dialog_msgbox "No DTB Files" "No .dtb files found in ${dtb_dir}" 8 50
							continue
						fi

						local selected
						selected=$(dialog_menu "Select Device Tree" \
							"\nChoose a DTB file to edit:\n" \
							0 0 0 "${dtb_files[@]}")

						[[ -z "$selected" ]] && continue
						_devicetree_edit_dtb "${dtb_dir}/${selected}" "$backup_dir"
						;;
					2) # Edit active DTB
						if [[ -n "$active_dtb" ]]; then
							local dtb_path="/boot/dtb/${active_dtb}"
							if [[ -f "$dtb_path" ]]; then
								_devicetree_edit_dtb "$dtb_path" "$backup_dir"
							else
								dialog_msgbox "Error" "Active DTB file not found:\n${active_dtb}" 9 50
							fi
						fi
						;;
					3) # Restore from backup
						_devicetree_restore_backup "$backup_dir" "$dtb_dir"
						;;
					4) # View device tree info
						_devicetree_show_info "$dtb_dir"
						;;
				esac
			done
		;;

		"${commands[4]}") # help
			show_module_help "module_devicetree_edit" "$title" \
				"Edit device tree blobs by decompiling to source,\nediting with a text editor, and recompiling.\n\nRequires: device-tree-compiler (dtc)"
		;;

		*)
			${module_options["module_devicetree_edit,feature"]} ${commands[4]}
		;;
	esac
}

#
# @description Decompile, edit, and recompile a DTB file
# @param $1 Full path to the DTB file
# @param $2 Backup directory
#
function _devicetree_edit_dtb() {
	local dtb_path="$1"
	local backup_dir="$2"
	local dtb_name="${dtb_path##*/}"
	local tmp_dts
	tmp_dts=$(mktemp /tmp/devicetree-XXXXXX.dts)

	# Decompile DTB to DTS
	if ! dtc -I dtb -O dts -o "$tmp_dts" "$dtb_path" 2>/dev/null; then
		dialog_msgbox "Error" "Failed to decompile ${dtb_name}\n\nThe file may be corrupted or not a valid DTB." 10 60
		rm -f "$tmp_dts"
		return 1
	fi

	# Record checksum before editing
	local checksum_before
	checksum_before=$(md5sum "$tmp_dts" | awk '{print $1}')

	# Open editor
	${EDITOR:-nano} "$tmp_dts"

	# Check if file was modified
	local checksum_after
	checksum_after=$(md5sum "$tmp_dts" | awk '{print $1}')

	if [[ "$checksum_before" == "$checksum_after" ]]; then
		dialog_msgbox "No Changes" "No modifications were made to ${dtb_name}" 8 50
		rm -f "$tmp_dts"
		return 0
	fi

	# Validate the edited DTS by attempting to compile
	local tmp_dtb
	tmp_dtb=$(mktemp /tmp/devicetree-XXXXXX.dtb)

	if ! dtc -I dts -O dtb -o "$tmp_dtb" "$tmp_dts" 2>/tmp/dtc_errors.txt; then
		local errors
		errors=$(cat /tmp/dtc_errors.txt)
		dialog_msgbox "Compilation Error" \
			"The edited device tree source has errors:\n\n${errors}\n\nNo changes were applied." 18 70
		rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
		return 1
	fi

	# Confirm before applying
	if dialog_yesno "Apply Changes" \
		"Device tree compiled successfully.\n\nApply changes to:\n${dtb_path}\n\nA backup will be created automatically." \
		"Apply" "Cancel" 13 65; then

		# Create backup
		mkdir -p "$backup_dir"
		local timestamp
		timestamp=$(date +%Y%m%d_%H%M%S)
		if ! cp "$dtb_path" "${backup_dir}/${dtb_name}.${timestamp}.bak" || \
			[[ ! -r "${backup_dir}/${dtb_name}.${timestamp}.bak" ]]; then
			dialog_msgbox "Error" "Failed to create backup of ${dtb_name}.\n\nChanges were NOT applied." 10 60
			rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
			return 1
		fi

		# Install the new DTB
		cp "$tmp_dtb" "$dtb_path"

		dialog_msgbox "Success" \
			"Device tree updated successfully.\n\nBackup saved to:\n${backup_dir}/${dtb_name}.${timestamp}.bak\n\nA reboot is required for changes to take effect." 13 65

		if dialog_yesno "Reboot Required" \
			"A reboot is required to apply the changes.\nShall we reboot now?" "Reboot" "Cancel" 9 50; then
			reboot
		fi
	fi

	rm -f "$tmp_dts" "$tmp_dtb" /tmp/dtc_errors.txt
}

#
# @description Restore a DTB from backup
# @param $1 Backup directory
# @param $2 DTB directory
#
function _devicetree_restore_backup() {
	local backup_dir="$1"
	local dtb_dir="$2"

	if [[ ! -d "$backup_dir" ]] || [[ -z $(ls "$backup_dir"/*.bak 2>/dev/null) ]]; then
		dialog_msgbox "No Backups" "No device tree backups found in:\n${backup_dir}" 8 55
		return 1
	fi

	local backup_files=()
	while IFS= read -r -d '' bak_file; do
		local basename="${bak_file##*/}"
		# Extract original name and timestamp from backup filename
		local display="${basename%.bak}"
		backup_files+=("$basename" "$display")
	done < <(find "$backup_dir" -maxdepth 1 -name '*.bak' -print0 | sort -rz)

	local selected
	selected=$(dialog_menu "Restore Device Tree Backup" \
		"\nSelect a backup to restore:\n" \
		0 0 0 "${backup_files[@]}")

	[[ -z "$selected" ]] && return 0

	# Extract original DTB name (everything before the timestamp)
	local original_name="${selected%%.[0-9]*}"

	# Find where to restore
	local restore_path
	restore_path=$(find "$dtb_dir" -maxdepth 2 -name "$original_name" 2>/dev/null | head -n1)

	if [[ -z "$restore_path" ]]; then
		# If can't auto-detect, ask for confirmation with default path
		restore_path="${dtb_dir}/${original_name}"
	fi

	if dialog_yesno "Confirm Restore" \
		"Restore backup:\n${selected}\n\nTo:\n${restore_path}" "Restore" "Cancel"; then
		if cp "${backup_dir}/${selected}" "$restore_path"; then
			dialog_msgbox "Restored" \
				"Device tree restored successfully.\n\nA reboot is required for changes to take effect." 10 60

			if dialog_yesno "Reboot Required" \
				"A reboot is required to apply the changes.\nShall we reboot now?" "Reboot" "Cancel" 9 50; then
				reboot
			fi
		else
			dialog_msgbox "Restore Failed" \
				"Failed to restore backup.\n\nSource: ${backup_dir}/${selected}\nDestination: ${restore_path}" 10 65
		fi
	fi
}

#
# @description Show current device tree information
# @param $1 DTB directory
#
function _devicetree_show_info() {
	local dtb_dir="$1"
	local info_text=""

	# Device model
	if [[ -f /proc/device-tree/model ]]; then
		info_text+="Model: $(tr -d '\0' < /proc/device-tree/model 2>/dev/null)\n"
	fi

	# Compatible strings
	if [[ -f /proc/device-tree/compatible ]]; then
		info_text+="Compatible: $(tr '\0' ', ' < /proc/device-tree/compatible 2>/dev/null)\n"
	fi

	# Active DTB from armbianEnv
	if [[ -f /boot/armbianEnv.txt ]]; then
		local fdtfile
		fdtfile=$(awk -F'=' '/^fdtfile/ {print $2}' /boot/armbianEnv.txt)
		[[ -n "$fdtfile" ]] && info_text+="Active DTB: ${fdtfile}\n"
	fi

	# DTB directory contents
	local dtb_count
	dtb_count=$(find "$dtb_dir" -maxdepth 1 -name '*.dtb' 2>/dev/null | wc -l)
	info_text+="\nDTB Directory: ${dtb_dir}\n"
	info_text+="DTB Files: ${dtb_count}\n"

	# Backup status
	if [[ -d /boot/dtb/backup ]]; then
		local backup_count
		backup_count=$(find /boot/dtb/backup -name '*.bak' 2>/dev/null | wc -l)
		info_text+="Backups: ${backup_count}\n"
	else
		info_text+="Backups: none\n"
	fi

	# DTC version
	if command -v dtc >/dev/null 2>&1; then
		info_text+="\nDTC Version: $(dtc --version 2>&1 | head -n1)\n"
	else
		info_text+="\nDTC: not installed\n"
	fi

	dialog_msgbox "Device Tree Information" "$info_text" 20 70
}

# This module is used only for generating documentation. Where we use command from the menu directly, there is no module behind.
# We assume that when calling command directly, its multiarch
module_options+=(
	["module_generic,author"]="@armbian"
	["module_generic,maintainer"]="@armbian"
	["module_generic,status"]="Active"
	["module_generic,doc_link"]="https://forum.armbian.com/"
	["module_generic,arch"]="x86-64 aarch64 armhf riscv64"
)

declare -A module_options
module_options+=(
	["module_armbian_upgrades,author"]="@igorpecovnik"
	["module_armbian_upgrades,feature"]="module_armbian_upgrades"
	["module_armbian_upgrades,desc"]="Install and configure automatic updates"
	["module_armbian_upgrades,example"]="install remove configure status defaults help"
	["module_armbian_upgrades,port"]=""
	["module_armbian_upgrades,status"]="Active"
	["module_armbian_upgrades,arch"]=""
)
#
# Module configure automatic updates
#
function module_armbian_upgrades () {

	local title="package updates"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_upgrades,example"]}"

	case "$1" in

		"${commands[0]}")
			pkg_update
			pkg_install -o Dpkg::Options::="--force-confold" unattended-upgrades
			# set Armbian defaults
			${module_options["module_armbian_upgrades,feature"]} ${commands[4]}
		;;
		"${commands[1]}")
			pkg_remove unattended-upgrades
			# drop the generated config (current + legacy names) so no
			# periodic/unattended settings linger after disabling.
			rm -f /etc/apt/apt.conf.d/20-armbian-auto-upgrades \
				/etc/apt/apt.conf.d/50-armbian-unattended-upgrades \
				/etc/apt/apt.conf.d/20auto-upgrades \
				/etc/apt/apt.conf.d/50unattended-upgrades
		;;
		"${commands[2]}")
			# Systems set up by older armbian-config have only the legacy-named
			# files, which the edits below would miss. Write the Armbian-named
			# ones first; defaults also drops the legacy files.
			if [[ ! -f /etc/apt/apt.conf.d/20-armbian-auto-upgrades || ! -f /etc/apt/apt.conf.d/50-armbian-unattended-upgrades ]]; then
				${module_options["module_armbian_upgrades,feature"]} ${commands[4]}
			fi
			# read values from 20-armbian-auto-upgrades
			if [[ -f "/etc/apt/apt.conf.d/20-armbian-auto-upgrades" ]]; then
				Unattended_Upgrade=$(
					awk -F'"' '/APT::Periodic::Unattended-Upgrade/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20-armbian-auto-upgrades
					)
				Update_Package_Lists=$(
					awk -F'"' '/APT::Periodic::Update-Package-Lists/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20-armbian-auto-upgrades
					)
				Download_Upgradeable_Packages=$(
					awk -F'"' '/APT::Periodic::Download-Upgradeable-Packages/ {print ($2 == 1) ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/20-armbian-auto-upgrades
					)
			fi
			# read values from 50-armbian-unattended-upgrades
			if [[ -f "/etc/apt/apt.conf.d/50-armbian-unattended-upgrades" ]]; then
				AutoFixInterruptedDpkg=$(
					awk -F'"' '/Unattended-Upgrade::AutoFixInterruptedDpkg/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50-armbian-unattended-upgrades
					)
				Remove_New_Unused_Dependencies=$(
					awk -F'"' '/Unattended-Upgrade::Remove-New-Unused-Dependencies/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50-armbian-unattended-upgrades
					)
				Automatic_Reboot=$(
					awk -F'"' '/Unattended-Upgrade::Automatic-Reboot "/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50-armbian-unattended-upgrades
					)
				Automatic_Reboot_WithUsers=$(
					awk -F'"' '/Unattended-Upgrade::Automatic-Reboot-WithUsers/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50-armbian-unattended-upgrades
					)
				Remove_Unused_Dependencies=$(
					awk -F'"' '/Unattended-Upgrade::Remove-Unused-Dependencies/ {print ($2 == "true") ? "ON" : "OFF"}' \
					/etc/apt/apt.conf.d/50-armbian-unattended-upgrades
					)
			fi
			# toggle options
			if target_sync=$(dialog_checklist "Select an Option" \
				"\nConfigure unattended-upgrade options:" 16 78 8 --notags \
				"Unattended-Upgrade" "Automatic security and package updates system." ${Unattended_Upgrade:-ON} \
				"Update-Package-Lists" "Automatically updates the list of available packages." ${Update_Package_Lists:-OFF} \
				"Download-Upgradeable-Packages" "Downloads upgradeable packages without installing them." ${Download_Upgradeable_Packages:-OFF} \
				"AutoFixInterruptedDpkg" "Fixes interrupted package installations during upgrades." ${AutoFixInterruptedDpkg:-OFF} \
				"Remove-New-Unused-Dependencies" "Removes dependencies no longer required after upgrades." ${Remove_New_Unused_Dependencies:-OFF} \
				"Automatic-Reboot" "Reboots the system automatically if required after upgrades." ${Automatic_Reboot:-OFF} \
				"Automatic-Reboot-WithUsers" "Reboots even if users are logged in." ${Automatic_Reboot_WithUsers:-OFF} \
				"Remove-Unused-Dependencies" "Removes packages that are no longer required after upgrades." ${Remove_Unused_Dependencies:-OFF}); then
				# set all to 0 or false
				sed -i 's/"[0-9]"/"0"/g' /etc/apt/apt.conf.d/20-armbian-auto-upgrades
				sed -i 's/"true"/"false"/g' /etc/apt/apt.conf.d/50-armbian-unattended-upgrades
				for choice in $(echo ${target_sync} | tr -d '"'); do
					sed -i "s/\($choice \"\)0\(\";\)/\11\2/" /etc/apt/apt.conf.d/20-armbian-auto-upgrades
					sed -i "s/\($choice \"\)false\(\";\)/\1true\2/" /etc/apt/apt.conf.d/50-armbian-unattended-upgrades
				done
				# APT::Periodic::Enable is the master switch — apt.systemd.daily exits
				# when it is 0. The image ships no periodic config of its own, so this
				# file is the only place that sets it; force it on here (the reset above
				# cleared it).
				if grep -Eq '^[[:space:]]*APT::Periodic::Enable[[:space:]]*"' /etc/apt/apt.conf.d/20-armbian-auto-upgrades; then
					sed -i '/^[[:space:]]*APT::Periodic::Enable[[:space:]]*"/s/"[^"]*"/"1"/' /etc/apt/apt.conf.d/20-armbian-auto-upgrades
				else
					sed -i '1i APT::Periodic::Enable "1";' /etc/apt/apt.conf.d/20-armbian-auto-upgrades
				fi
			fi
			srv_restart unattended-upgrades
		;;
		"${commands[3]}")
			if pkg_installed unattended-upgrades; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")

			# global options
			cat > "/etc/apt/apt.conf.d/20-armbian-auto-upgrades" <<- EOT
			APT::Periodic::Enable "1";
			APT::Periodic::Update-Package-Lists "1";
			APT::Periodic::Download-Upgradeable-Packages "1";
			APT::Periodic::AutocleanInterval "7";
			APT::Periodic::Unattended-Upgrade "1";
			EOT

			# unattended-upgrades
			cat > "/etc/apt/apt.conf.d/50-armbian-unattended-upgrades" <<- EOT
			// armbian-config generated
			Unattended-Upgrade::Origins-Pattern {
				"o=${DISTRO},n=${DISTROID},l=${DISTRO}";
				"o=${DISTRO},n=${DISTROID}-updates,l=${DISTRO}";
				"o=${DISTRO},n=${DISTROID}-security,l=${DISTRO}-Security";
				"o=armbian.github.io/configurator,c=main,l=armbian.github.io/configurator";
			};
			// black list
			// Unattended-Upgrade::Package-Blacklist {
			//    "armbian-";
			//    "linux-";
			//};

			// This option allows you to control if on a unclean dpkg exit
			// unattended-upgrades will automatically run
			//   dpkg --force-confold --configure -a
			// The default is true, to ensure updates keep getting installed
			Unattended-Upgrade::AutoFixInterruptedDpkg "true";

			// Do automatic removal of newly unused dependencies after the upgrade
			Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

			// Do automatic removal of unused packages after the upgrade
			// (equivalent to apt-get autoremove)
			Unattended-Upgrade::Remove-Unused-Dependencies "true";

			// Automatically reboot *WITHOUT CONFIRMATION* if
			//  the file /var/run/reboot-required is found after the upgrade.
			// Disabled by default — Armbian does not reboot unattended; the
			// user reboots when convenient (toggle via armbian-config).
			Unattended-Upgrade::Automatic-Reboot "false";

			// Automatically reboot even if there are users currently logged in
			// when Unattended-Upgrade::Automatic-Reboot is set to true
			Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
			EOT

			# Remove any legacy / distro-named files so they cannot shadow the
			# Armbian-named ones. Older armbian-config and the Debian/Ubuntu
			# unattended-upgrades package both use 20auto-upgrades /
			# 50unattended-upgrades; since apt merges all of apt.conf.d and
			# 50unattended-upgrades sorts AFTER 50-armbian-unattended-upgrades, a
			# leftover would override these settings (e.g. re-enable auto reboot).
			rm -f /etc/apt/apt.conf.d/20auto-upgrades \
				/etc/apt/apt.conf.d/50unattended-upgrades

		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_armbian_upgrades,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_upgrades,example"]}"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install Armbian $title."
			echo -e "\tremove\t\t- Remove Armbian $title."
			echo -e "\tconfigure\t- Configure Armbian $title."
			echo -e "\tstatus\t\t- Status of Armbian $title."
			echo -e "\tdefaults\t- Set to Armbian defalt $title config."
			echo
		;;
		*)
			${module_options["module_armbian_upgrades,feature"]} ${commands[5]}
		;;
	esac
}

module_options+=(
	["module_nfs,author"]="@igorpecovnik"
	["module_nfs,feature"]="module_nfs"
	["module_nfs,desc"]="Install nfs client"
	["module_nfs,example"]="install remove servers mounts help"
	["module_nfs,port"]=""
	["module_nfs,status"]="Active"
	["module_nfs,arch"]=""
)
#
# Module nfs client
#
function module_nfs () {
	local title="nfs"
	local condition=$(which "$title" 2>/dev/null)?

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfs,example"]}"

	nfs_BASE="${SOFTWARE_FOLDER}/nfs"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common
		;;
		"${commands[1]}")
			pkg_remove nfs-common
		;;
		"${commands[2]}")

			if ! pkg_installed nmap; then pkg_install nmap; fi
			if ! pkg_installed nfs-common; then pkg_install nfs-common; fi

			local subnet=$(dialog_inputbox "Choose subnet to search for NFS server" "\\nValid format: <IP Address>/<Subnet Mask Length>" "${LOCALSUBNET}" 9 60)
			LIST=($(nmap -oG - -p2049 ${subnet} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there. adding timeout kill as it can hang if server doesn't share to this client
					LIST=($(timeout --kill 10s 5s showmount -e "${nfs_server}" 2>/dev/null | tail -n +2 | cut -d" " -f1 | sort))
					VERIFIED_LIST=()
					local tempfolder=$(mktemp -d)
					local alreadymounted=$(df | grep $nfs_server | cut -d" " -f1 | xargs)
					for i in "${LIST[@]}"; do
						mount -n -t nfs $nfs_server:$i ${tempfolder} 2>/dev/null
						if [[ $? -eq 0 ]]; then
							if echo "${alreadymounted}" | grep -vq $i; then
							VERIFIED_LIST+=($i)
							fi
							umount ${tempfolder}
						fi
					done
					VERIFIED_LIST_LENGTH=$((${#VERIFIED_LIST[@]}))
					if shares=$(dialog --no-items \
						--title "Network filesystem (NFS) shares on ${nfs_server}" \
						--menu "" \
						$((${VERIFIED_LIST_LENGTH} + 6)) \
						80 \
						$((${VERIFIED_LIST_LENGTH})) \
						${VERIFIED_LIST[@]} 3>&1 1>&2 2>&3)
						then
							if mount_folder=$(dialog --title \
							"Where do you want to mount $shares ?" \
							--inputbox "" \
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
								if mount_options=$(dialog --title \
								"Which mount options do you want to use?" \
							--inputbox "" \
							6 80 "auto,noatime 0 0" 3>&1 1>&2 2>&3); then
								mkdir -p ${mount_folder}
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								srv_daemon_reload
								mount ${mount_folder}
								show_message <<< $(mount -t nfs4 | cut -d" " -f1)
							fi
							fi
						fi
					fi
		;;
		"${commands[3]}")
			local list=($(mount --type=nfs4 | cut -d" " -f1))
			if shares=$(dialog --no-items \
						--title "Mounted NFS shares" \
						--menu "" \
						$((${#list[@]} + 6)) \
						80 \
						$((${#list[@]})) \
						${list[@]} 3>&1 1>&2 2>&3); then
						echo "Chosen $mount"
			read
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_nfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tservers\t- Find and mount shares $title."
			echo
		;;
		*)
			${module_options["module_nfs,feature"]} ${commands[4]}
		;;
	esac
}


module_options+=(
	["release_upgrade,author"]="@igorpecovnik"
	["release_upgrade,ref_link"]=""
	["release_upgrade,feature"]="Upgrade upstream distribution release"
	["release_upgrade,desc"]="Upgrade to next stable or rolling release"
	["release_upgrade,example"]="release_upgrade stable verify"
	["release_upgrade,status"]="Active"
)
#
# Upgrade distribution
#
release_upgrade(){

	local upgrade_type=$1
	local verify=$2

	local distroid=${DISTROID}

	if [[ "${upgrade_type}" == stable ]]; then
		local filter=$(grep "supported" /etc/armbian-distribution-status | cut -d"=" -f1 | grep -v "^${distroid}")
	elif [[ "${upgrade_type}" == rolling ]]; then
		local filter=$(grep "eos\|csc" /etc/armbian-distribution-status | cut -d"=" -f1 | sed "s/sid/testing/g" | grep -v "^${distroid}")
	else
		local filter=$(cat /etc/armbian-distribution-status | cut -d"=" -f1 | grep -v "^${distroid}")
	fi

	local upgrade=$(for j in $filter; do
		for i in $(grep "^${distroid}" /etc/armbian-distribution-status | cut -d";" -f2 | cut -d"=" -f2 | sed "s/,/ /g"); do
			if [[ $i == $j ]]; then
				echo $i
			fi
		done
	done | tail -1)

	if [[ -z "${upgrade}" ]]; then
		return 1;
	elif [[ -z "${verify}" ]]; then
		[[ -f /etc/apt/sources.list.d/ubuntu.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/ubuntu.sources
		[[ -f /etc/apt/sources.list.d/debian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/debian.sources
		[[ -f /etc/apt/sources.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list
		[[ "${upgrade}" == "testing" ]] && upgrade="sid" # our repo and everything is tied to sid
		[[ -f /etc/apt/sources.list.d/armbian.sources ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.sources
		[[ -f /etc/apt/sources.list.d/armbian.list ]] && sed -i "s/$distroid/$upgrade/g" /etc/apt/sources.list.d/armbian.list
		pkg_update
		pkg_upgrade -o Dpkg::Options::="--force-confold" --without-new-pkgs
		pkg_fix || return 1 # Hacks for Ubuntu
		pkg_full_upgrade -o Dpkg::Options::="--force-confold"
		pkg_fix || return 1 # Hacks for Ubuntu
		pkg_full_upgrade -o Dpkg::Options::="--force-confold"
		pkg_fix || return 1 # Hacks for Ubuntu
		# Deliberate, whole-system orphan sweep for a just-completed release
		# upgrade (standard end-of-upgrade cleanup, same as `do-release-upgrade`).
		# NOT pkg_remove: pkg_remove now does a scoped `purge` of only the
		# package(s) it's given (see module_package.sh, #712) and would no-op
		# here since this call passes none - call apt-get directly instead so
		# this sweep keeps working as intended.
		DEBIAN_FRONTEND=noninteractive apt-get -y autopurge
	fi
}

module_options+=(
	["module_armbian_runners,author"]="@igorpecovnik"
	["module_armbian_runners,feature"]="module_armbian_runners"
	["module_armbian_runners,desc"]="Manage self hosted runners"
	["module_armbian_runners,example"]="install remove remove_online purge status help"
	["module_armbian_runners,port"]=""
	["module_armbian_runners,status"]="Active"
	["module_armbian_runners,arch"]=""
)

#
# Module Armbian self hosted Github runners
#
function module_armbian_runners () {

	local title="runners"
	local condition=$(which "$title" 2>/dev/null)

	# read parameters from command install
	#
	# Assigned with printf -v against an allow-list rather than eval: these
	# values come straight off the command line, and `eval "$feature=$value"`
	# ran anything a value contained. Splitting on the FIRST '=' only also
	# keeps values that themselves contain '=' intact - the old
	# IFS='=' read -a split kept just the first field, silently truncating
	# such a value.
	local var kv key value
	for var in "$@"; do
		# shellcheck disable=SC2086 # deliberate word split: one argument may carry several key=value pairs
		for kv in ${var}; do
			[[ "${kv}" == *=* ]] || continue
			key="${kv%%=*}"
			value="${kv#*=}"
			case "${key}" in
				gh_token|runner_name|start|stop|label_primary|label_secondary|organisation|owner|repository)
					printf -v "${key}" '%s' "${value}" ;;
			esac
		done
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_runners,example"]}"

	# Derive the GitHub registration target (org or owner/repo) for ALL
	# subcommands — not just install — so remove/remove_online/purge can
	# reach the API too. Previously these lived inside the install case, so
	# every other subcommand built a malformed '//actions/runners' URL.
	local registration_url="${organisation:-armbian}"
	local prefix="orgs"
	if [[ -n "${owner}" && -n "${repository}" ]]; then
		registration_url="${owner}/${repository}"
		prefix="repos"
	fi

	case "$1" in

		"${commands[0]}")

			# Prompt using dialog if parameters are missing AND in interactive mode
			if [[ -t 1 ]]; then
				if [[ -z "$gh_token" ]]; then
					gh_token=$(dialog_inputbox "" "Enter your GitHub token:" "" 8 60)
				fi

				if [[ -z "$runner_name" ]]; then
					runner_name=$(dialog_inputbox "" "Enter runner name:" "armbian" 8 60)
				fi

				if [[ -z "$start" ]]; then
					start=$(dialog_inputbox "" "Enter start index:" "01" 8 60)
				fi

				if [[ -z "$stop" ]]; then
					stop=$(dialog_inputbox "" "Enter stop index:" "01" 8 60)
				fi

				if [[ -z "$label_primary" ]]; then
					label_primary=$(dialog_inputbox "" "Enter primary label(s):" "alfa" 8 60)
				fi

				if [[ -z "$label_secondary" ]]; then
					label_secondary=$(dialog_inputbox "" "Enter secondary label(s):" "fast,images" 8 60)
				fi

				if [[ -z "$organisation" ]]; then
					organisation=$(dialog_inputbox "" "Enter GitHub organisation:" "armbian" 8 60)
				fi
			fi

			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				exit 1
			fi

			# default values if not defined
			local gh_token="${gh_token}"
			local runner_name="${runner_name:-armbian}"
			local start="${start:-01}"
			local stop="${stop:-01}"
			local organisation="${organisation:-armbian}"
			local owner="${owner}"
			local repository="${repository}"

			# workaround. Remove when parameters handling is fixed
			label_primary="${label_primary//_/,}"
			label_secondary="${label_secondary//_/,}"

			# Label fallback.
			#
			# These used to be "${label_primary:-alfa}" and
			# "${label_secondary:-fast,images}", but :- cannot tell an empty
			# value from an unset one, so deliberately clearing the secondary
			# label silently brought back "fast,images" on every runner after
			# the first. An empty secondary now means "label them like the
			# first one", and an empty primary falls back to the label GitHub
			# gives every self-hosted runner anyway.
			[[ -z "${label_primary}" ]] && label_primary="self-hosted"
			[[ -z "${label_secondary}" ]] && label_secondary="${label_primary}"

			# Docker preinstall is needed for our build framework
			pkg_installed docker-ce || module_docker install
			pkg_update
			pkg_install jq curl libicu-dev mktorrent rsync

			# download latest runner package
			local temp_dir=$(mktemp -d)
			trap '{ rm -rf -- "$temp_dir"; }' EXIT

			# That trap is shell-scoped, not function-scoped: it fires when
			# armbian-config exits, not when this returns. Without an explicit
			# call the directory survives every early return, and on success the
			# ~200MB runner tarball sits there for the rest of the session.
			runner_temp_cleanup() { rm -rf -- "${temp_dir}"; trap - EXIT; }
			[[ "$ARCH" == "x86_64" ]] && local arch=x64 || local arch=arm64
			# Ask GitHub for the latest runner release, authenticated with the
			# same token the registration calls use: unauthenticated api.github.com
			# allows 60 requests an hour per IP, and once that is spent the reply
			# is an error object rather than the expected array, which used to end
			# as `jq: Cannot index object with number` and an empty LATEST.
			#
			# releases/latest rather than tags[0]: it states which release is
			# current instead of trusting the order tags come back in.
			local LATEST
			LATEST=$(curl -fsSL \
				-H "Accept: application/vnd.github+json" \
				${gh_token:+-H "Authorization: Bearer ${gh_token}"} \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name // empty' | sed "s/^v//")

			# Everything below removes the running runners before reinstalling
			# them, so refuse to start when the version lookup failed - otherwise
			# a rate-limited API call deletes the fleet and cannot rebuild it.
			if [[ ! "${LATEST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
				echo "Could not determine the latest actions/runner release (got '${LATEST:-<empty>}')." >&2
				echo "Pass a GitHub token if you are being rate limited; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			local runner_tarball="${temp_dir}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz"
			# --fail, or curl writes the 404 body to the file, reports 100% and
			# leaves tar to complain that stdin is not in gzip format.
			if ! curl --fail --progress-bar --create-dirs --output-dir ${temp_dir} -o \
				actions-runner-linux-${ARCH}-${LATEST}.tar.gz -L \
				https://github.com/actions/runner/releases/download/v${LATEST}/actions-runner-linux-${arch}-${LATEST}.tar.gz; then
				echo "Download of actions-runner ${LATEST} (${arch}) failed; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			# Verify the archive before anything is removed.
			if ! tar tzf "${runner_tarball}" >/dev/null 2>&1; then
				echo "Downloaded actions-runner ${LATEST} archive is not a valid tarball; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			# make runners each under its own user.
			#
			# The index list is materialised first so the "is this the first
			# runner" test can compare against what seq actually produced.
			# seq -w pads to the width of the widest bound, so `start=1
			# stop=10` yields 01..10 and the old `[[ "$i" == "${start}" ]]`
			# never matched - with unpadded bounds no runner got the primary
			# label at all.
			local -a runner_indices=()
			mapfile -t runner_indices < <(seq -w "${start}" "${stop}")
			if [[ ${#runner_indices[@]} -eq 0 ]]; then
				echo "Refusing to install: start='${start}' stop='${stop}' selects no runners." >&2
				runner_temp_cleanup
				return 1
			fi
			local first_index="${runner_indices[0]}"
			local install_failed=0

			echo "Installing runners ${runner_indices[0]}..${runner_indices[-1]} for ${prefix}/${registration_url}"
			echo "  ${runner_name}-${first_index} labels: ${label_primary}"
			if [[ ${#runner_indices[@]} -gt 1 ]]; then
				echo "  remaining runners labels: ${label_secondary}"
			fi

			local i
			for i in "${runner_indices[@]}"
			do
				local token
				token=$(curl -s \
				-X POST \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}"\
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/${prefix}/${registration_url}/actions/runners/registration-token | jq -r '.token // empty')

				# A rejected token, a wrong org or a rate limit all return a
				# JSON error object here. Without this the empty/"null" token
				# was handed to config.sh, which failed after the user had
				# already been created and the old runner removed.
				if [[ -z "${token}" ]]; then
					echo "Could not get a registration token for ${prefix}/${registration_url} (runner ${i}); check the GitHub token and its scopes." >&2
					install_failed=1
					continue
				fi

				if ! ${module_options["module_armbian_runners,feature"]} ${commands[1]} ${runner_name} "${i}"; then
					# `remove` returns non-zero when GitHub refused
					# the DELETE — almost always because the runner
					# is currently running a job. Skip this index;
					# the existing runner keeps doing its work
					# untouched, and the next install pass will
					# pick it up when it's idle.
					echo "Skipping install of runner ${i} (${runner_name}-${i}) — currently busy on GitHub" >&2
					continue
				fi

				adduser --quiet --disabled-password --shell /bin/bash \
				--home /home/actions-runner-${i} --gecos "actions-runner-${i}" actions-runner-${i}

				# add to sudoers via a drop-in, validated before it counts.
				# Appending to /etc/sudoers directly means one malformed line
				# locks every user out of sudo on the machine, with no way
				# back in without a rescue boot.
				install -d -m 0755 /etc/sudoers.d
				local sudoers_tmp="/etc/sudoers.d/.actions-runner-${i}.tmp"
				printf '%s ALL=(ALL) NOPASSWD: ALL\n' "actions-runner-${i}" > "${sudoers_tmp}"
				chmod 0440 "${sudoers_tmp}"
				if visudo -cf "${sudoers_tmp}" >/dev/null 2>&1; then
					mv -f "${sudoers_tmp}" "/etc/sudoers.d/actions-runner-${i}"
				else
					rm -f "${sudoers_tmp}"
					echo "Refusing to grant sudo to actions-runner-${i}: generated sudoers rule did not validate" >&2
					install_failed=1
					continue
				fi
				usermod -aG docker actions-runner-${i}
				tar xzf "${runner_tarball}" -C /home/actions-runner-${i}
				chown -R actions-runner-${i}:actions-runner-${i} /home/actions-runner-${i}

				# 1st runner has different labels
				local label="${label_secondary}"
				if [[ "${i}" == "${first_index}" ]]; then
					label="${label_primary}"
				fi

				# config.sh is what actually registers the runner with GitHub. Its
				# exit status has to be checked: svc.sh ships inside the tarball, so
				# the -f test below is true whether or not registration succeeded, and
				# installing a service for an unregistered runner leaves a unit that
				# can never start. Unchecked, a failure here also left install_failed
				# at 0 and the whole install reported success.
				if ! runuser -l "actions-runner-${i}" -c \
					"./config.sh --url https://github.com/${registration_url} \
					--token ${token} --labels '${label}' --name '${runner_name}-${i}' --unattended"; then
					echo "Failed to register runner ${runner_name}-${i} with ${registration_url}; skipping its service install." >&2
					install_failed=1
					continue
				fi
				if [[ -f /home/actions-runner-${i}/svc.sh ]]; then
					sh -c "cd /home/actions-runner-${i} ; \
					sudo ./svc.sh install actions-runner-${i} 2>/dev/null; \
					sudo ./svc.sh start actions-runner-${i} >/dev/null"
				fi
			done

			# Install the runner-cleanup maintenance helper alongside
			# the runners themselves. Script + systemd units are
			# always overwritten so a `module_armbian_runners install`
			# brings them up to date; the operator-edited conf at
			# /etc/armbian/runner-cleanup.conf is preserved on
			# re-install (template dropped as .conf.dist so admins
			# can diff for new defaults).
			#
			# Asset path resolution: in a source checkout the assets
			# sit next to this module under tools/modules/system/.
			# In the installed .deb they ship to
			# /usr/share/armbian-config/runner-cleanup/ — debian.conf
			# adds the rule, mirroring how the desktops assets are
			# laid out. Try BASH_SOURCE-relative first (dev), fall
			# back to the install path (production).
			local cleanup_src=""
			if [[ -d "$(dirname "${BASH_SOURCE[0]}")/runner-cleanup" ]]; then
				cleanup_src="$(dirname "${BASH_SOURCE[0]}")/runner-cleanup"
			elif [[ -d /usr/share/armbian-config/runner-cleanup ]]; then
				cleanup_src=/usr/share/armbian-config/runner-cleanup
			fi
			if [[ -n "$cleanup_src" ]]; then
				install -m 0755 "${cleanup_src}/runner-cleanup"         /usr/local/sbin/runner-cleanup
				install -m 0644 "${cleanup_src}/runner-cleanup.service" /etc/systemd/system/runner-cleanup.service
				install -m 0644 "${cleanup_src}/runner-cleanup.timer"   /etc/systemd/system/runner-cleanup.timer
				install -d /etc/armbian
				if [[ ! -e /etc/armbian/runner-cleanup.conf ]]; then
					install -m 0644 "${cleanup_src}/runner-cleanup.conf" /etc/armbian/runner-cleanup.conf
				fi
				install -m 0644 "${cleanup_src}/runner-cleanup.conf" /etc/armbian/runner-cleanup.conf.dist
				# Event-driven per-runner _diag/pages cleanup. The hourly
				# runner-cleanup timer is the catch-all; this layer fires
				# on every runner unit start/stop so collisions never
				# survive a quick restart cycle. install-runner-hooks
				# scans every actions.runner.*.service installed by the
				# svc.sh step above and drops in ExecStartPre/StopPost
				# wired to /usr/local/sbin/runner-clean-pages.
				install -m 0755 "${cleanup_src}/runner-clean-pages"     /usr/local/sbin/runner-clean-pages
				# Per-job workspace chown. Docker builds leave root-owned
				# files under _work that break the next job's checkout
				# cleanup. The runner runs this after every job via
				# ACTIONS_RUNNER_HOOK_JOB_COMPLETED (wired into each
				# runner's .env below).
				# The GitHub runner validates the hook path and rejects it
				# unless it ends in .sh/.ps1/.js, so the installed name keeps
				# the .sh extension. Remove the old extensionless copy left by
				# earlier installs.
				install -m 0755 "${cleanup_src}/runner-job-completed.sh" /usr/local/sbin/runner-job-completed.sh
				rm -f /usr/local/sbin/runner-job-completed
				systemctl daemon-reload
				# Don't silence errors here — a failed timer install
				# means the cleanup never fires and the host quietly
				# accumulates disk. Show stderr; on the first command's
				# failure, fall back to enable + start separately so we
				# can pinpoint which half went wrong, and log each.
				if ! systemctl enable --now runner-cleanup.timer; then
					echo "Warning: 'systemctl enable --now runner-cleanup.timer' failed; retrying separately" >&2
					systemctl enable runner-cleanup.timer || \
						echo "Error: 'systemctl enable runner-cleanup.timer' failed" >&2
					systemctl start  runner-cleanup.timer || \
						echo "Error: 'systemctl start runner-cleanup.timer' failed" >&2
				fi
				# Wire up the systemd drop-ins for every runner unit
				# that the svc.sh loop above just installed. Runs after
				# daemon-reload so the new drop-ins take effect on the
				# next runner restart cycle. Non-fatal — runner units
				# already started above keep working without hooks
				# until the operator restarts them.
				if ! bash "${cleanup_src}/install-runner-hooks"; then
					echo "Warning: install-runner-hooks failed; runner-clean-pages systemd hooks not in place" >&2
				fi

				# Wire the post-job chown hook into every runner's .env. The
				# runner loads ACTIONS_RUNNER_HOOK_JOB_COMPLETED from .env at
				# service start and runs it (as the runner user, which has
				# passwordless sudo) after each job. Idempotent; covers
				# already-installed runners too. Takes effect on each runner's
				# next (re)start, so we don't force-restart busy ones here.
				local job_hook_path="/usr/local/sbin/runner-job-completed.sh"
				local runner_home runner_owner env_file
				for runner_home in /home/actions-runner-*; do
					[[ -d "$runner_home" ]] || continue
					runner_owner="$(stat -c '%U' "$runner_home")"
					env_file="${runner_home}/.env"
					touch "$env_file"
					if grep -q '^ACTIONS_RUNNER_HOOK_JOB_COMPLETED=' "$env_file"; then
						sed -i "s#^ACTIONS_RUNNER_HOOK_JOB_COMPLETED=.*#ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${job_hook_path}#" "$env_file"
					else
						echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${job_hook_path}" >> "$env_file"
					fi
					chown "${runner_owner}:${runner_owner}" "$env_file"
				done
			else
				echo "Warning: runner-cleanup assets not found in source tree next to module or at /usr/share/armbian-config/runner-cleanup; skipping maintenance helper install" >&2
			fi

			runner_temp_cleanup
			return $install_failed

		;;
		"${commands[1]}")
			# `remove` is called two ways:
			#   * internally by install/purge with positional args:
			#       remove <runner_name> <index>
			#   * directly via --api with named params and an index range:
			#       remove runner_name=<n> [start=<a> stop=<b>] [organisation=..]
			#     start/stop default to 01, so a bare runner_name removes <n>-01.
			# A bare (no '=') $2 is the positional form; otherwise the named
			# params parsed above drive a start..stop range.
			if [[ -z "${gh_token}" ]]; then
				echo "Error: Github token is mandatory" >&2
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				return 1
			fi

			local rm_name rm_indices
			if [[ -n "$2" && "$2" != *=* ]]; then
				rm_name="$2"
				rm_indices="$3"
			else
				rm_name="${runner_name:-armbian}"
				# Default the range to 01..01, the same way purge does. Leaving
				# it empty fell through to the bare-name branch below, which
				# looks for a runner literally called "<runner_name>" -- but
				# runners are registered as "<runner_name>-NN", so
				# `remove runner_name=xxx` matched nothing, could not map to a
				# local user either, and reported success having done nothing.
				rm_indices="$(seq -w "${start:-01}" "${stop:-01}")"
			fi

			local rm_failed=0 idx target runner_home
			for idx in ${rm_indices:-__bare__}; do
				if [[ "$idx" == "__bare__" ]]; then
					target="${rm_name}"
				else
					target="${rm_name}-${idx}"
				fi

				echo "Removing runner ${target} on GitHub"
				if ! ${module_options["module_armbian_runners,feature"]} ${commands[2]} "${target}"; then
					# Most common failure: GitHub returned 422 because
					# the runner is currently running a job. Don't proceed
					# with the local cleanup — that would leave a state
					# where GitHub still thinks the runner exists, the
					# host has no install, and the subsequent config.sh
					# would fail with 'A runner exists with the same name'.
					echo "Skipping local removal of actions-runner-${idx} — GitHub delete failed (runner likely busy)" >&2
					rm_failed=1
					continue
				fi

				# Without an index we can't map to a local user — GitHub-only.
				[[ "$idx" == "__bare__" ]] && continue

				echo "Removing runner ${idx} locally"
				runner_home=$(getent passwd "actions-runner-${idx}" | cut -d: -f6)
				if [[ -f "${runner_home}/svc.sh" ]]; then
					sh -c "cd ${runner_home} ; sudo ./svc.sh stop actions-runner-${idx} >/dev/null; sudo ./svc.sh uninstall actions-runner-${idx} >/dev/null"
				fi
				userdel -r -f actions-runner-${idx} 2>/dev/null
				groupdel actions-runner-${idx} 2>/dev/null
				rm -f "/etc/sudoers.d/actions-runner-${idx}"
				# Older installs appended straight to /etc/sudoers; clear those too.
				sed -i "/^actions-runner-${idx}[[:space:]]/d" /etc/sudoers
				[[ -n "${runner_home}" && ${runner_home} != "/" ]] && rm -rf "${runner_home}"
			done
			return $rm_failed
		;;
		"${commands[2]}")
			local DELETE="$2"
			if [[ -z "${gh_token}" ]]; then
				echo "Error: Github token is mandatory" >&2
				return 1
			fi
			if [[ -z "${DELETE}" ]]; then
				echo "Error: no runner name given to ${commands[2]}" >&2
				return 1
			fi

			# Failure flag — set on any non-204 DELETE response. The
			# most common case is HTTP 422 'runner is currently
			# running a job', which we don't want to silently swallow:
			# without it the caller proceeds with local cleanup and
			# leaves a half-state where GitHub thinks the runner exists
			# but the host has nothing for it.
			local delete_failed=0 x=1 page_body page_code listed
			local per_page=100
			# Track what we actually saw. Without this a name that matches
			# nothing is indistinguishable from a successful delete: the caller
			# printed "Removing runner X on GitHub", we silently matched zero
			# runners, returned 0, and the caller went on to tear down the local
			# side. That is how a stale registration survived a "successful"
			# remove and then broke config.sh with "a runner exists with the
			# same name".
			local matched=0 seen=0

			# Walk pages until one comes back short. The old loop asked for
			# pages 1..9 unconditionally - nine API calls to delete one
			# runner, and its own comment admitted a tenth page was out of
			# reach. per_page=100 means one call covers most fleets.
			while true; do
				page_body=$(mktemp)
				page_code=$(curl -s -L \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-o "${page_body}" -w '%{http_code}' \
				"https://api.github.com/${prefix}/${registration_url}/actions/runners?per_page=${per_page}&page=${x}")

				# A bad token, a missing scope or a wrong org returns a JSON
				# error object, whose .runners is null. Piping that straight
				# into `.runners[]` is what produced
				#   jq: error (at <stdin>:4): Cannot iterate over null (null)
				# and then carried on as if no runners existed.
				if [[ "${page_code}" != "200" ]]; then
					echo "Listing runners for ${prefix}/${registration_url} failed with HTTP ${page_code}:" >&2
					jq -r '.message // empty' "${page_body}" >&2 2>/dev/null || cat "${page_body}" >&2
					rm -f "${page_body}"
					return 1
				fi

				if ! listed=$(jq -r '(.runners // [])[] | "\(.id),\(.name)"' "${page_body}" 2>/dev/null); then
					echo "Could not parse the runner list for ${prefix}/${registration_url}" >&2
					rm -f "${page_body}"
					return 1
				fi
				rm -f "${page_body}"

				[[ -z "${listed}" ]] && break

				local DATA RUNNER_ID RUNNER_NAME
				while IFS= read -r DATA; do
					[[ -z "${DATA}" ]] && continue
					RUNNER_ID="${DATA%%,*}"
					RUNNER_NAME="${DATA#*,}"
					# Quoted: an unquoted right-hand side is a glob, so a
					# runner name containing * or ? matched - and deleted -
					# every other runner in the org.
					seen=$(( seen + 1 ))
					if [[ "${RUNNER_NAME}" == "${DELETE}" ]]; then
						matched=$(( matched + 1 ))
						echo "Delete existing: ${RUNNER_NAME}"
						local resp_body http_code
						resp_body=$(mktemp)
						http_code=$(curl -s -L \
						-X DELETE \
						-H "Accept: application/vnd.github+json" \
						-H "Authorization: Bearer ${gh_token}"\
						-H "X-GitHub-Api-Version: 2022-11-28" \
						-o "${resp_body}" -w '%{http_code}' \
						"https://api.github.com/${prefix}/${registration_url}/actions/runners/${RUNNER_ID}")
						if [[ "$http_code" != "204" ]]; then
							echo "  ! DELETE ${RUNNER_NAME} returned HTTP ${http_code}:" >&2
							cat "${resp_body}" >&2
							echo >&2
							delete_failed=1
						fi
						rm -f "${resp_body}"
					fi
				done <<< "${listed}"

				# A short page is the last page.
				[[ "$(printf '%s\n' "${listed}" | wc -l)" -lt "${per_page}" ]] && break
				x=$(( x + 1 ))
			done

			# Say so when the name matched nothing. Not an error -- an already
			# absent runner is the desired end state, and install's pre-remove
			# step relies on that -- but it must not look like a deletion.
			if (( matched == 0 )); then
				echo "No runner named '${DELETE}' is registered in ${prefix}/${registration_url} (${seen} runner(s) listed); nothing to delete." >&2
			fi
			return $delete_failed
		;;
		"${commands[3]}")
			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				exit 1
			fi
			# seq with empty bounds errors out; default them the way remove does.
			local purge_failed=0 i
			for i in $(seq -w "${start:-01}" "${stop:-01}"); do
				${module_options["module_armbian_runners,feature"]} ${commands[1]} "${runner_name:-armbian}" "${i}" || purge_failed=1
			done
			return $purge_failed
		;;
		"${commands[4]}")
			if [[ $(systemctl list-units --type=service --no-legend 2>/dev/null | grep -c actions.runner) -gt 0 ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_armbian_runners,feature"]} <command> [switches]"
			echo -e "Commands:  install remove remove_online purge status help"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install or reinstall $title."
			echo -e "\tremove\t\t- Remove runners (locally and on GitHub); start/stop default to 01."
			echo -e "\tremove_online\t- Remove matching runners on GitHub only."
			echo -e "\tpurge\t\t- Purge $title."
			echo -e "\tstatus\t\t- Status of $title."
			echo -e "\thelp\t\t- Show this help."
			echo -e "\nAvailable switches:\n"
			echo -e "\tgh_token\t- token with rights to admin runners."
			echo -e "\trunner_name\t- name of the runner (series)."
			echo -e "\tstart\t\t- start of serie (01)."
			echo -e "\tstop\t\t- stop (01)."
			echo -e "\tlabel_primary\t- runner tags for first runner (empty: self-hosted)."
			echo -e "\tlabel_secondary\t- runner tags for all others (empty: same as label_primary)."
			echo -e "\torganisation\t- GitHub organisation name (armbian)."
			echo -e "\towner\t\t- GitHub owner."
			echo -e "\trepository\t- GitHub repository (if adding only for repo)."
			echo ""
		;;
		*)
			${module_options["module_armbian_runners,feature"]} ${commands[5]}
		;;
	esac
}

# shellcheck shell=bash
# This is a sourced armbian-config module fragment, not a standalone script.
declare -A module_options
module_options+=(
	["module_partitioner,author"]="@igorpecovnik"
	["module_partitioner,maintainer"]="@igorpecovnik"
	["module_partitioner,feature"]="module_partitioner"
	["module_partitioner,example"]="run install detect plan help bootloader"
	["module_partitioner,desc"]="Armbian installer (transfer rootfs to eMMC/NVMe/SATA/USB/UFS)"
	["module_partitioner,status"]="review"
	["module_partitioner,doc_link"]="https://docs.armbian.com"
	["module_partitioner,group"]="System"
	["module_partitioner,port"]=""
	["module_partitioner,arch"]=""
)

#
# module_partitioner.sh - armbian-install frontend.
#
# Thin layer over module_install_engine.sh: it collects the target disk, boot
# mode and filesystem (interactively via dialog, or from CLI flags) and then
# calls the single shared entrypoint install_run_scenario. No install logic
# lives here.
#
# Invocation:
#   module_partitioner run                         interactive dialog TUI
#   module_partitioner install --target /dev/sdX --boot emmc --fs ext4 --yes
#   module_partitioner detect                      TSV inventory (machine)
#   module_partitioner plan --target /dev/sdX --boot uefi --fs ext4
#
# The /usr/bin/armbian-install shim shipped by the bsp package execs:
#   armbian-config --api module_partitioner "$@"
# so a bare `armbian-install` lands in the TUI and `armbian-install --target …`
# runs unattended.

# Where the rsync exclude list lives (shipped by the bsp package).
: "${INSTALL_EXCLUDE:=/usr/lib/armbian-install/exclude.txt}"

# Which whole disk hosts the currently running rootfs (excluded as a target).
partitioner_root_disk() {
	local root_uuid root_part disk medium
	root_uuid=$(sed -e 's/^.*root=//' -e 's/ .*$//' </proc/cmdline)
	root_part=$(blkid | tr -d '":' | grep -w "${root_uuid#UUID=}" | awk '{print $1}' | head -1)
	[[ -z "$root_part" ]] && root_part=$(findmnt -no SOURCE --nofsroot / 2>/dev/null)
	disk=$(lsblk -ndo pkname "$root_part" 2>/dev/null | head -1)
	# Live ISO: / is an overlay over a squashfs, with no backing disk, so the above
	# is empty. Exclude the boot MEDIUM instead - the USB/disk the ISO is running
	# from - so we never offer to wipe the device we booted from.
	if [[ -z "$disk" ]]; then
		medium=$(findmnt -no SOURCE /run/live/medium 2>/dev/null)
		if [[ -n "$medium" ]]; then
			disk=$(lsblk -ndo pkname "$medium" 2>/dev/null | head -1)   # medium is a partition
			[[ -z "$disk" ]] && disk=$(lsblk -ndo name "$medium" 2>/dev/null | head -1)  # ...or a whole disk
		fi
	fi
	echo "$disk"
}

# A human label for one detect record (TSV: name role size sector bus rota model).
partitioner_disk_label() {
	local name="$1" role="$2" size_bytes="$3" bus="$4" model="$5"
	local human
	human=$(numfmt --to=iec --suffix=B "$size_bytes" 2>/dev/null || echo "${size_bytes}B")
	# "-" is the detect placeholder for an absent bus/model column.
	local info="$role"
	[[ -n "$bus" && "$bus" != "null" && "$bus" != "-" ]] && info="$bus $role"
	[[ -n "$model" && "$model" != "null" && "$model" != "-" ]] && info="$model"
	printf '%-10s %8s  %s' "/dev/$name" "$human" "$info"
}

# Echo the eMMC whole-disk device (empty if none). eMMC exposes a boot0 hardware
# boot partition and/or reports device type MMC; SD cards report type SD and have
# no boot0. Used to offer "boot from eMMC, root on NVMe/SATA/USB" only when an
# eMMC actually exists.
partitioner_emmc_device() {
	local d n
	for d in /dev/mmcblk[0-9]; do
		[[ -b "$d" ]] || continue
		n="${d#/dev/}"
		if [[ -b "${d}boot0" || "$(cat "/sys/block/$n/device/type" 2>/dev/null)" == "MMC" ]]; then
			echo "$d"; return 0
		fi
	done
}

# Echo the SPI/MTD device+partition list the board's u-boot lives on (empty if
# none), space-separated, in the format write_uboot_platform_mtd expects: the
# mtdblock whole-devices first, then any char-device SPL/boot partitions as
# "mtdN:label" (e.g. "mtdblock0 mtd0:uboot"). Mirrors the classic installer's
# mtdcheck. Used to offer "boot from SPI/MTD, root on NVMe/SATA/USB" and to feed
# INSTALL_MTD_LIST to the engine.
#
# Contract for board-provided write_uboot_platform_mtd (in /usr/lib/u-boot/
# platform_install.sh): the engine calls it as
#   write_uboot_platform_mtd "$DIR" "/dev/<first-entry>" "$LOG" "$INSTALL_MTD_LIST"
# i.e. the FIRST list entry (with any ":label" stripped) is the primary boot
# device, and the FULL list is passed as the 4th argument. Implementations
# should accept both the "mtdblockN" and "mtdN:label" forms and pick the right
# partition(s) to flash from the full list. When the board declares
# BOOTLOADER_MTD_IMAGE (and optionally BOOTLOADER_MTD_IMAGE_SATA), the engine
# passes the image for the install target as a 5th argument; write only that.
# platform_install.sh may also set BOOTLOADER_NAME (default "u-boot") to name
# the firmware it writes in the bootloader flash messages, and
# BOOTLOADER_BOOTS_FROM to list the disk roles (nvme sata usb) its bootloader
# loads /boot from, which enables the "standalone" mode for those targets
# and, when set, limits "spi" to them. A board can also list only mmc, as
# the Turris Omnia does, to offer neither.
partitioner_mtd_list() {
	local list chr
	list="$(grep 'mtdblock' /proc/partitions 2>/dev/null | awk '{print $NF}' | xargs)"
	if [[ -f /proc/mtd ]]; then
		chr="$(grep -iE '^mtd[0-9]+:.*(spl|boot|uboot).*' /proc/mtd 2>/dev/null | awk '{print $1$NF}' | sed 's/"//g' | xargs)"
		list="${list}${list:+ }${chr}"
	fi
	echo "$list" | xargs 2>/dev/null   # trim
}

# Boot modes that actually work on this system for a given target, gated by
# capability so we never offer a mode whose bootloader cannot be written:
#   * UEFI firmware present            -> GRUB EFI (uefi, +dualboot with Windows)
#   * u-boot board (ARM)               -> media-specific u-boot modes
#   * x86 legacy BIOS (no EFI/u-boot)  -> GRUB BIOS (grub-pc)
#   * none of the above, Raspberry Pi-style firmware confirmed present
#     (config.txt + cmdline.txt)       -> "sd" (root only) or "native" (full
#     self-contained install - the board's own firmware can boot straight off
#     the target, so the SD card becomes removable)
#   * none of the above, board unrecognised -> "sd" only: it moves root and
#     never touches the boot media, so it needs no board capability to be safe.
partitioner_modes_for() {
	local role="$1" disk="$2"
	local -a m=()
	local have_uboot=0
	[[ "$(type -t write_uboot_platform)" == function ]] && have_uboot=1

	if [[ -d /sys/firmware/efi ]]; then
		if [[ -n "$disk" ]] && install_detect_windows "/dev/$disk" >/dev/null 2>&1; then
			m+=(uefi-dualboot)
		fi
		m+=(uefi)
	fi
	if [[ "$have_uboot" -eq 1 ]]; then
		case "$role" in
			mmc)           m+=(emmc sd) ;;   # eMMC: full install or just root
			nvme|sata|usb)
				# The SoC bootrom can't load u-boot from NVMe/SATA/USB, so boot
				# lives elsewhere. Prefer SPI/MTD flash when the board can write
				# u-boot there and an MTD device is present (e.g. Odroid M1 SPI +
				# NVMe root): the board then boots straight from internal flash,
				# independent of the removable media staying inserted — so offer
				# it FIRST (top / default).
				local have_mtd=""; have_mtd="$(partitioner_mtd_list)"
				if [[ "$(type -t write_uboot_platform_mtd)" == function && -n "$have_mtd" ]]; then
					m+=(mtd)
				elif [[ -n "$have_mtd" && ( -z "${BOOTLOADER_BOOTS_FROM:-}" || " ${BOOTLOADER_BOOTS_FROM:-} " == *" $role "* ) ]]; then
					# SPI/MTD flash is present but the board has no installer
					# hook to write u-boot into it (e.g. SpacemiT K3: u-boot is
					# flashed once via fastboot/DFU, not from the OS). The board
					# still boots from that SPI and its boot script scans this
					# NVMe/SATA/USB for /boot/boot.scr - so a fully self-contained
					# install here (local /boot + root, no dependency on the
					# removable media) is bootable. Offer it FIRST (top / default).
					# A set BOOTLOADER_BOOTS_FROM must list this role (Turris Omnia: eMMC first).
					m+=(spi)
				fi
				# u-boot on SD/eMMC loads /boot from this role: full install, media untouched.
				[[ " ${BOOTLOADER_BOOTS_FROM:-} " == *" $role "* ]] && m+=(standalone)
				m+=(sd)                       # keep boot on current media, root here
				# ...or from an internal eMMC (if present, not the target, nothing on it mounted).
				local emmc; emmc="$(partitioner_emmc_device)"
				[[ -n "$emmc" && "/dev/$disk" != "$emmc" ]] && ! install_disk_in_use "$emmc" && m+=(split-emmc)
				;;
			ufs)           m+=(ufs) ;;
		esac
	fi
	# x86 legacy BIOS: neither EFI firmware nor a u-boot board.
	local have_bios=0
	if [[ ! -d /sys/firmware/efi && "$have_uboot" -eq 0 ]] && command -v grub-install >/dev/null 2>&1; then
		m+=(bios); have_bios=1
	fi
	# No EFI, no u-boot hooks, no GRUB either: the board boots via its own
	# firmware, and there is no board-provided bootloader-write hook to gate
	# on. "sd" mode only moves root and leaves the current boot media
	# untouched - but only when that media's config can be rewired
	# (install_sd_capable). When that firmware is confirmed to be Raspberry
	# Pi-style (reads a plain FAT32 boot partition off whatever bus it's on),
	# "native" is safe too: a full self-contained install straight to the
	# target, so the SD card becomes removable — offer it first.
	if [[ ! -d /sys/firmware/efi && "$have_uboot" -eq 0 && "$have_bios" -eq 0 ]]; then
		install_rpi_style_boot && m+=(native)
		install_sd_capable && m+=(sd)
	fi

	# No writable boot mode for this firmware/disk: emit nothing so the caller
	# can show a clear error rather than offer a mode guaranteed to fail.
	echo "${m[@]}"
}

partitioner_mode_desc() {
	case "$1" in
		uefi-dualboot) echo "Dual-boot: shrink Windows, install Armbian alongside it" ;;
		uefi) echo "UEFI install with GRUB (ERASES the disk)" ;;
		bios) echo "Legacy BIOS install with GRUB (ERASES the disk)" ;;
		emmc) echo "Full install to this device (boot + system)" ;;
		native) echo "Full install to this disk — SD card no longer needed" ;;
		sd)   echo "Keep boot on current media, system on this disk" ;;
		split-emmc) echo "Boot from eMMC, system on this disk (+ /emmc_storage)" ;;
		mtd)  echo "Boot from SPI/MTD flash, system on this disk" ;;
		spi)  echo "Boot from on-board SPI flash, full system on this disk" ;;
		standalone) echo "Keep the current ${BOOTLOADER_NAME:-u-boot}, full system on this disk" ;;
		ufs)  echo "Boot idblock on UFS boot LUN, system on UFS" ;;
		*)    echo "$1" ;;
	esac
}

# Ensure mkfs.<fs> is available (the engine refuses to wipe without it). Offers
# to install the providing package. interactive=1 uses dialogs, 0 prints/plain.
# Returns 0 when the tool is usable.
partitioner_ensure_fs_tool() {
	local fs="$1" interactive="${2:-1}" pkg=""
	command -v "mkfs.$fs" >/dev/null 2>&1 && return 0
	case "$fs" in btrfs) pkg="btrfs-progs" ;; f2fs) pkg="f2fs-tools" ;; *) return 1 ;; esac
	if [[ "$interactive" == 1 ]]; then
		dialog_yesno " Install $pkg " "\nmkfs.$fs is not installed.\n\nInstall $pkg now?" "Install" "Cancel" 9 60 || return 1
		dialog_infobox " Armbian installer " "\nInstalling $pkg ..." 5 44 2>/dev/null
	else
		echo "Installing $pkg ..."
	fi
	pkg_install "$pkg" >>"${INSTALL_LOG:-/dev/null}" 2>&1
	command -v "mkfs.$fs" >/dev/null 2>&1
}

# ---- interactive TUI --------------------------------------------------------

partitioner_tui() {
	local title="Armbian installer"
	INSTALL_LOG="/var/log/armbian-install.log"
	{ : >>"$INSTALL_LOG"; } 2>/dev/null || INSTALL_LOG=/dev/stderr
	local root_disk; root_disk="$(partitioner_root_disk)"

	# 1) target disk
	local records; records="$(install_detect_targets "$root_disk")"
	if [[ -z "$records" ]]; then
		dialog_msgbox " $title " "\nNo installation targets were found.\n\nAttach an eMMC/NVMe/SATA/USB disk and try again."
		return "$INSTALL_EX_NODEV"
	fi
	local -a menu=() names=() roles=()
	local name role size sec bus rota model
	while IFS=$'\t' read -r name role size sec bus rota model; do
		[[ -n "$name" ]] || continue
		names+=("$name"); roles+=("$role")
		menu+=("$name" "$(partitioner_disk_label "$name" "$role" "$size" "$bus" "$model")")
	done <<<"$records"

	local disk
	disk=$(dialog_menu " $title " "\nSelect the destination disk:" 0 76 10 -- "${menu[@]}")
	[[ -z "$disk" ]] && return "$INSTALL_EX_OK"
	local disk_role="mmc" i
	for i in "${!names[@]}"; do [[ "${names[$i]}" == "$disk" ]] && disk_role="${roles[$i]}"; done
	if install_disk_in_use "/dev/$disk"; then
		dialog_msgbox " $title " "\n/dev/$disk is in use: it is mounted, holds swap, or lsblk failed on it.\n\nUnmount it or turn its swap off, and try again."
		return "$INSTALL_EX_USAGE"
	fi

	# 2) boot mode (dual-boot is offered when Windows is detected on the disk)
	local -a modes; read -r -a modes <<<"$(partitioner_modes_for "$disk_role" "$disk")"
	if [[ ${#modes[@]} -eq 0 ]]; then
		dialog_msgbox " $title " "\nNo bootable install method is available for /dev/$disk on this system (no EFI firmware, no GRUB, and no board u-boot support)."
		return "$INSTALL_EX_BOOTLOADER"
	fi
	# When the disk holds a BitLocker Windows, dual-boot is impossible (ntfsresize
	# cannot shrink it). Explain why and let the user either cancel or wipe the
	# whole disk, instead of the option silently vanishing.
	if [[ -d /sys/firmware/efi && " ${modes[*]} " != *" uefi-dualboot "* ]] \
		&& install_disk_has_bitlocker "/dev/$disk"; then
		if ! dialog_yesno " $title " "\n/dev/$disk has a Windows install with \Zb\Z1BitLocker\Zn device encryption, which cannot be resized for dual-boot.\n\nTo dual-boot: turn off Device Encryption / BitLocker in Windows ('manage-bde -off C:'), let it fully decrypt, then re-run.\n\nOr WIPE the whole disk and install Armbian only?" "Wipe & install" "Cancel" 15 76; then
			return "$INSTALL_EX_OK"
		fi
	fi
	local boot
	if [[ "${#modes[@]}" -eq 1 ]]; then
		boot="${modes[0]}"
	else
		local -a mmenu=()
		for i in "${modes[@]}"; do mmenu+=("$i" "$(partitioner_mode_desc "$i")"); done
		boot=$(dialog_menu " $title " "\nChoose how /dev/$disk should boot:" 0 76 8 -- "${mmenu[@]}")
		[[ -z "$boot" ]] && return "$INSTALL_EX_OK"
	fi

	# 3) filesystem - only offer what the running kernel can actually mount
	# (mkfs.f2fs can succeed on a kernel with no f2fs driver, then mount fails).
	local fs
	local -a fsmenu=(ext4 "Default, most compatible")
	install_fs_kernel_supported btrfs && fsmenu+=(btrfs "Copy-on-write, compression, snapshots")
	install_fs_kernel_supported f2fs  && fsmenu+=(f2fs "Flash-friendly log-structured fs")
	fs=$(dialog_menu " $title " "\nRoot filesystem for /dev/$disk:" 0 60 6 -- "${fsmenu[@]}")
	[[ -z "$fs" ]] && return "$INSTALL_EX_OK"
	if ! partitioner_ensure_fs_tool "$fs" 1; then
		dialog_msgbox " $title " "\nCannot format as $fs: mkfs.$fs is unavailable.\n\nInstall the package and try again."
		return "$INSTALL_EX_TOOL"
	fi

	# 4) dual-boot needs a size; other modes erase the whole disk.
	local want_bytes=0
	if [[ "$boot" == uefi-dualboot ]]; then
		# Tell the user up-front (and before touching the disk) if Windows can't be
		# shrunk - BitLocker or an unclean/hibernated NTFS - with the exact fix.
		local blocker
		if ! blocker="$(install_dualboot_blocker "/dev/$disk")"; then
			# dialog honours literal "\n" but collapses real newlines - convert so
			# the numbered steps render on separate lines.
			dialog_msgbox " Cannot dual-boot yet " "\n${blocker//$'\n'/\\n}"
			return "$INSTALL_EX_USAGE"
		fi
		local gib
		gib=$(dialog_inputbox " $title " "\nGiB to give Armbian (taken by shrinking Windows):" "32")
		[[ "$gib" =~ ^[0-9]+$ && "$gib" -gt 0 ]] || { dialog_msgbox " $title " "\nInvalid size."; return "$INSTALL_EX_USAGE"; }
		want_bytes=$(( gib * 1024 * 1024 * 1024 ))
		if ! dialog_yesno " WARNING " "\nThis will SHRINK Windows on /dev/$disk and install Armbian ($fs, ${gib}GiB) alongside it.\n\nBack up first. Proceed?" "Shrink and install" "Cancel" 11 72; then
			return "$INSTALL_EX_OK"
		fi
	elif [[ "$boot" == split-emmc ]]; then
		local emmc; emmc="$(partitioner_emmc_device)"
		if ! dialog_yesno " WARNING " "\nThis will ERASE BOTH devices:\n  $emmc (eMMC) -> u-boot + /boot + /emmc_storage\n  /dev/$disk -> Armbian root ($fs)\n\nProceed?" "Erase and install" "Cancel" 12 74; then
			return "$INSTALL_EX_OK"
		fi
	elif [[ "$boot" == mtd ]]; then
		if ! dialog_yesno " WARNING " "\nThis will ERASE /dev/$disk (Armbian root, $fs) AND overwrite the bootloader on SPI/MTD flash:\n  [ $(partitioner_mtd_list) ]\n\nProceed?" "Erase and install" "Cancel" 12 74; then
			return "$INSTALL_EX_OK"
		fi
	elif [[ "$boot" == spi ]]; then
		if ! dialog_yesno " WARNING " "\nThis will ERASE /dev/$disk and install a self-contained Armbian ($fs): boot + system both on this disk.\n\nu-boot is NOT touched - the board boots from its on-board SPI flash and loads /boot from this disk. The install stays bootable on its own (no dependency on removable media).\n\nProceed?" "Erase and install" "Cancel" 13 74; then
			return "$INSTALL_EX_OK"
		fi
	elif [[ "$boot" == standalone ]]; then
		if ! dialog_yesno " WARNING " "\nThis will ERASE /dev/$disk and install a self-contained Armbian ($fs): boot + system both on this disk.\n\n${BOOTLOADER_NAME:-u-boot} and the current boot media are NOT touched - the bootloader loads /boot from this disk, and the current system stays bootable as a fallback.\n\nProceed?" "Erase and install" "Cancel" 13 74; then
			return "$INSTALL_EX_OK"
		fi
	else
		if ! dialog_yesno " WARNING " "\nThis will ERASE /dev/$disk and install Armbian ($boot, $fs).\n\nProceed?" "Erase and install" "Cancel" 10 70; then
			return "$INSTALL_EX_OK"
		fi
	fi

	# 5) run - pipe the transfer percentage into a gauge, capture the real rc.
	local rc_file; rc_file="$(mktemp)"
	{
		if [[ "$boot" == uefi-dualboot ]]; then
			install_run_dualboot "/dev/$disk" "$fs" "$INSTALL_EXCLUDE" "$want_bytes"
		elif [[ "$boot" == split-emmc ]]; then
			install_run_split "$(partitioner_emmc_device)" "/dev/$disk" "$fs" "$INSTALL_EXCLUDE"
		else
			# mtd mode writes u-boot to SPI/MTD; hand the engine the device list.
			[[ "$boot" == mtd ]] && export INSTALL_MTD_LIST="$(partitioner_mtd_list)"
			install_run_scenario "$boot" "/dev/$disk" "$fs" "$INSTALL_EXCLUDE"
		fi
		echo "$?" >"$rc_file"
	} 2>>"$INSTALL_LOG" | dialog_gauge " $title " "\nInstalling to /dev/$disk - please wait..." 10 74
	local rc; rc="$(cat "$rc_file")"; rm -f "$rc_file"

	if [[ "$rc" == "0" && "$boot" == standalone ]]; then
		dialog_msgbox " $title " "\nInstallation to /dev/$disk finished successfully.\n\nKeep the current boot media in place: ${BOOTLOADER_NAME:-u-boot} stays there and loads the system from /dev/$disk. Reboot when ready."
	elif [[ "$rc" == "0" ]]; then
		dialog_msgbox " $title " "\nInstallation to /dev/$disk finished successfully.\n\nRemove the boot media (if applicable) and reboot."
	else
		dialog_msgbox " $title " "\nInstallation FAILED (code $rc).\n\nSee ${INSTALL_LOG:-the install log} for details."
	fi
	return "$rc"
}

# ---- flash bootloader only --------------------------------------------------

# Block devices u-boot can be written to (SD/eMMC whole-disks). The SoC bootrom
# only loads u-boot from SD/eMMC (or SPI/MTD, offered separately) - never from
# NVMe/SATA/USB - so only mmcblk* whole devices are listed (boot0/boot1 hw
# partitions skipped). Emits "<name>\t<human size>\t<note>" per line.
partitioner_uboot_block_targets() {
	local root_disk emmc d name secs
	root_disk="$(partitioner_root_disk)"
	emmc="$(partitioner_emmc_device)"; emmc="${emmc#/dev/}"
	for d in /sys/block/mmcblk[0-9]; do
		[[ -e "$d" ]] || continue
		name="$(basename "$d")"
		secs="$(cat "$d/size" 2>/dev/null || echo 0)"
		local note="SD"; [[ "$name" == "$emmc" ]] && note="eMMC"
		[[ "$name" == "$root_disk" ]] && note="$note, running root"
		printf '%s\t%s\t%s\n' "$name" \
			"$(numfmt --to=iec --suffix=B $(( secs * 512 )) 2>/dev/null || echo $(( secs / 2 ))K)" "$note"
	done
}

# Standalone "flash the bootloader only" flow: write the RUNNING system's u-boot
# to SPI/MTD or an SD/eMMC device, without partitioning or touching any rootfs.
# For bringup scenarios (e.g. running from NVMe, initial boot via Maskrom/ramboot)
# where you just need u-boot on internal flash or the SD - the old armbian-install
# could do this; the new one only did it as part of a full install. Reuses the
# same install_write_bootloader path the installer uses, so it's no riskier than
# the install's bootloader step.
partitioner_flash_uboot_tui() {
	local title="Armbian installer - bootloader"
	INSTALL_LOG="/var/log/armbian-install.log"
	{ : >>"$INSTALL_LOG"; } 2>/dev/null || INSTALL_LOG=/dev/stderr

	local bl="${BOOTLOADER_NAME:-u-boot}"
	local mtd_list; mtd_list="$(partitioner_mtd_list)"
	local -a menu=()
	[[ "$(type -t write_uboot_platform_mtd)" == function && -n "$mtd_list" ]] \
		&& menu+=("mtd" "SPI / on-board flash ($bl)")
	if [[ "$(type -t write_uboot_platform)" == function ]]; then
		local name size note
		while IFS=$'\t' read -r name size note; do
			[[ -n "$name" ]] || continue
			menu+=("$name" "/dev/$name   $size   ($note)")
		done < <(partitioner_uboot_block_targets)
	fi

	if [[ ${#menu[@]} -eq 0 ]]; then
		dialog_msgbox " $title " "\nThis board has no writable u-boot target: no SPI/MTD flash, and no board u-boot hook for SD/eMMC."
		return "$INSTALL_EX_BOOTLOADER"
	fi

	local sel
	sel=$(dialog_menu " $title " "\nWrite the running system's $bl (bootloader) to:" 0 78 10 -- "${menu[@]}")
	[[ -z "$sel" ]] && return "$INSTALL_EX_OK"

	local mode target warn
	if [[ "$sel" == "mtd" ]]; then
		mode="mtd"; target="/dev/${mtd_list%% *}"; warn="the on-board SPI / MTD flash"
	else
		mode="sd"; target="/dev/$sel"; warn="$target"
	fi

	if ! dialog_yesno " WARNING " "\nThis will OVERWRITE the bootloader ($bl) on:\n\n  $warn\n\nwith $bl from the running system. Your OS install and data are not touched.\n\nProceed?" "Flash bootloader" "Cancel" 13 74; then
		return "$INSTALL_EX_OK"
	fi

	local rc_file; rc_file="$(mktemp)"
	{
		install_write_bootloader "$mode" "$target" "/" "${DIR:-/usr/lib/u-boot}" "$mtd_list"
		echo "$?" >"$rc_file"
	} 2>>"$INSTALL_LOG" | dialog_gauge " $title " "\nWriting $bl to $warn - please wait..." 9 74
	local rc; rc="$(cat "$rc_file")"; rm -f "$rc_file"

	if [[ "$rc" == "0" ]]; then
		dialog_msgbox " $title " "\nBootloader ($bl) written to $warn successfully."
	else
		dialog_msgbox " $title " "\nFlashing FAILED (code $rc).\n\nSee ${INSTALL_LOG:-the install log} for details."
	fi
	return "$rc"
}

# Top-level action picker for the interactive installer: full install vs the
# standalone bootloader flash. Built from what is ACTUALLY actionable on this
# machine - so a board with no spare install target (e.g. booting from SPI with
# root on NVMe, nothing left to install onto) just offers the u-boot update, and
# a board that can only install (x86, no u-boot) goes straight to install. Only
# shows the menu when both are possible; runs the single option directly otherwise.
partitioner_menu() {
	local title="Armbian installer"
	local root_disk; root_disk="$(partitioner_root_disk)"

	local -a menu=(); local nact=0
	if [[ -n "$(install_detect_targets "$root_disk")" ]]; then
		menu+=("install" "Install Armbian to a disk (SD / eMMC / NVMe / SATA / USB)"); ((nact++))
	fi
	if [[ "$(type -t write_uboot_platform)" == function || "$(type -t write_uboot_platform_mtd)" == function ]]; then
		menu+=("bootloader" "Flash / update the bootloader (${BOOTLOADER_NAME:-u-boot}) only"); ((nact++))
	fi

	local act
	if [[ "$nact" -eq 0 ]]; then
		partitioner_tui; return "$?"                # nothing to flash & no target -> install shows its "no targets" msg
	elif [[ "$nact" -eq 1 ]]; then
		act="${menu[0]}"                            # only one action possible -> run it, skip the pointless menu
	else
		act=$(dialog_menu " $title " "\nWhat would you like to do?" 0 78 4 -- "${menu[@]}") || return "$INSTALL_EX_OK"
	fi

	case "$act" in
		install)    partitioner_tui ;;
		bootloader) partitioner_flash_uboot_tui ;;
		*)          return "$INSTALL_EX_OK" ;;
	esac
}

# ---- non-interactive CLI ----------------------------------------------------

partitioner_cli_install() {
	# partitioner_cli_install --target /dev/X --boot MODE --fs FS [--size GiB] [--yes]
	local target="" boot="" fs="ext4" assume_yes=0 size_gib=0
	INSTALL_LOG="/var/log/armbian-install.log"
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--target) [[ $# -ge 2 ]] || { echo "armbian-install: --target requires a value" >&2; return "$INSTALL_EX_USAGE"; }; target="$2"; shift 2 ;;
			--boot)   [[ $# -ge 2 ]] || { echo "armbian-install: --boot requires a value" >&2; return "$INSTALL_EX_USAGE"; }; boot="$2"; shift 2 ;;
			--fs)     [[ $# -ge 2 ]] || { echo "armbian-install: --fs requires a value" >&2; return "$INSTALL_EX_USAGE"; }; fs="$2"; shift 2 ;;
			--size)   [[ $# -ge 2 ]] || { echo "armbian-install: --size requires a value" >&2; return "$INSTALL_EX_USAGE"; }; size_gib="$2"; shift 2 ;;
			--yes|-y) assume_yes=1; shift ;;
			*) echo "armbian-install: unknown argument '$1'" >&2; return "$INSTALL_EX_USAGE" ;;
		esac
	done

	[[ -b "$target" ]] || { echo "armbian-install: --target must be a block device" >&2; return "$INSTALL_EX_NODEV"; }
	# The checks and the engine use kernel names, so resolve /dev/disk/by-id
	# or by-path links.
	local given="$target"
	target="$(readlink -f "$target")"
	case "$boot" in uefi|uefi-dualboot|bios|emmc|sd|mtd|spi|standalone|ufs|native|split-emmc) ;; *) echo "armbian-install: --boot must be one of uefi|uefi-dualboot|bios|emmc|sd|mtd|spi|standalone|ufs|native|split-emmc" >&2; return "$INSTALL_EX_USAGE" ;; esac
	case "$fs"   in ext4|btrfs|f2fs) ;;     *) echo "armbian-install: --fs must be one of ext4|btrfs|f2fs" >&2; return "$INSTALL_EX_USAGE" ;; esac
	[[ -f "$INSTALL_EXCLUDE" ]] || { echo "armbian-install: exclude list $INSTALL_EXCLUDE missing" >&2; return "$INSTALL_EX_TRANSFER"; }

	if [[ "$assume_yes" -ne 1 ]]; then
		echo "armbian-install: refusing to modify $target without --yes" >&2
		return "$INSTALL_EX_USAGE"
	fi
	! install_disk_in_use "$target" || { echo "armbian-install: $target is in use (mounted, swap, or lsblk failed) - refusing to modify it" >&2; return "$INSTALL_EX_USAGE"; }
	if [[ "$boot" == standalone || ( "$boot" == spi && -n "${BOOTLOADER_BOOTS_FROM:-}" ) ]]; then
		# Same gate as the TUI: u-boot must load /boot from the target's role.
		local records role
		records="$(install_detect_targets "$(partitioner_root_disk)")" \
			|| { echo "armbian-install: could not list the install targets" >&2; return "$INSTALL_EX_NODEV"; }
		role="$(awk -F'\t' -v d="${target#/dev/}" '$1 == d { print $2 }' <<<"$records")"
		if [[ -z "$role" || " ${BOOTLOADER_BOOTS_FROM:-} " != *" $role "* ]]; then
			echo "armbian-install: --boot $boot needs a disk ${BOOTLOADER_NAME:-u-boot} boots from (BOOTLOADER_BOOTS_FROM='${BOOTLOADER_BOOTS_FROM:-}', $target is '${role:-not a target}')" >&2
			return "$INSTALL_EX_USAGE"
		fi
	fi
	local emmc=""
	if [[ "$boot" == split-emmc ]]; then
		# Refuse before partitioner_ensure_fs_tool, which may install packages.
		emmc="$(partitioner_emmc_device)"
		[[ -n "$emmc" ]] || { echo "armbian-install: --boot split-emmc needs an eMMC, none detected" >&2; return "$INSTALL_EX_NODEV"; }
		[[ "$emmc" != "$target" ]] || { echo "armbian-install: --boot split-emmc target must differ from the eMMC ($emmc)" >&2; return "$INSTALL_EX_USAGE"; }
		! install_disk_in_use "$emmc" || { echo "armbian-install: --boot split-emmc would erase the eMMC ($emmc), which is in use (mounted, swap, or lsblk failed)" >&2; return "$INSTALL_EX_USAGE"; }
	fi
	if ! partitioner_ensure_fs_tool "$fs" 0; then
		echo "armbian-install: mkfs.$fs unavailable; install its package and retry" >&2
		return "$INSTALL_EX_TOOL"
	fi
	# A package install takes a while. Stop if the given link points elsewhere now.
	[[ "$(readlink -f "$given")" == "$target" && -b "$target" ]] \
		|| { echo "armbian-install: $given no longer points at $target - refusing to continue" >&2; return "$INSTALL_EX_NODEV"; }

	if [[ "$boot" == uefi-dualboot ]]; then
		[[ "$size_gib" =~ ^[0-9]+$ && "$size_gib" -gt 0 ]] || { echo "armbian-install: --size <GiB> is required for uefi-dualboot" >&2; return "$INSTALL_EX_USAGE"; }
		# Explain up-front (before touching the disk) if Windows can't be shrunk.
		local blocker
		if ! blocker="$(install_dualboot_blocker "$target")"; then
			echo "$blocker" >&2
			return "$INSTALL_EX_USAGE"
		fi
		echo "Installing Armbian alongside Windows on $target (${size_gib}GiB, $fs)..."
		install_run_dualboot "$target" "$fs" "$INSTALL_EXCLUDE" $(( size_gib * 1024 * 1024 * 1024 ))
	elif [[ "$boot" == split-emmc ]]; then
		echo "Installing Armbian: boot on $emmc (eMMC), root on $target ($fs), data at /emmc_storage..."
		install_run_split "$emmc" "$target" "$fs" "$INSTALL_EXCLUDE"
	else
		if [[ "$boot" == mtd ]]; then
			export INSTALL_MTD_LIST="$(partitioner_mtd_list)"
			[[ -n "$INSTALL_MTD_LIST" ]] || { echo "armbian-install: --boot mtd but no MTD/SPI device found (need mtdblock or /proc/mtd spl/boot)" >&2; return "$INSTALL_EX_NODEV"; }
			echo "Installing Armbian: boot on MTD/SPI [$INSTALL_MTD_LIST], root on $target ($fs)..."
		else
			echo "Installing Armbian to $target ($boot, $fs)..."
		fi
		install_run_scenario "$boot" "$target" "$fs" "$INSTALL_EXCLUDE"
	fi
	local rc=$?
	[[ "$rc" == 0 ]] && echo "Done." || echo "Failed (code $rc). See ${INSTALL_LOG:-install log}." >&2
	return "$rc"
}

# Non-interactive bootloader flash - the CLI counterpart of partitioner_flash_uboot_tui:
#   armbian-install bootloader --target <mtd|/dev/mmcblkN> --yes
# Writes the running system's u-boot to SPI/MTD or an SD/eMMC device, no rootfs.
# Refuses to write without --yes (it overwrites the bootloader).
partitioner_cli_flash() {
	local target="" assume_yes=0
	INSTALL_LOG="/var/log/armbian-install.log"
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--target) [[ $# -ge 2 ]] || { echo "armbian-install bootloader: --target requires a value" >&2; return "$INSTALL_EX_USAGE"; }
				target="$2"; shift 2 ;;
			--yes|-y) assume_yes=1; shift ;;
			*) echo "armbian-install bootloader: unknown option '$1'" >&2; return "$INSTALL_EX_USAGE" ;;
		esac
	done
	[[ -n "$target" ]] || { echo "armbian-install bootloader: --target <mtd|/dev/mmcblkN> required" >&2; return "$INSTALL_EX_USAGE"; }

	local bl="${BOOTLOADER_NAME:-u-boot}" mtd_list mode dev shown
	mtd_list="$(partitioner_mtd_list)"
	if [[ "$target" == "mtd" ]]; then
		[[ "$(type -t write_uboot_platform_mtd)" == function && -n "$mtd_list" ]] \
			|| { echo "armbian-install bootloader: no SPI/MTD u-boot target on this board" >&2; return "$INSTALL_EX_BOOTLOADER"; }
		mode="mtd"; dev="/dev/${mtd_list%% *}"; shown="the on-board SPI / MTD flash"
	else
		[[ "$(type -t write_uboot_platform)" == function ]] \
			|| { echo "armbian-install bootloader: board has no write_uboot_platform hook" >&2; return "$INSTALL_EX_BOOTLOADER"; }
		# Only whole SD/eMMC disks - u-boot is dd'd at fixed offsets, so a partition
		# or a non-boot disk (NVMe/SATA/USB) would get its partition table clobbered.
		[[ "$target" =~ ^/dev/mmcblk[0-9]+$ ]] \
			|| { echo "armbian-install bootloader: '$target' is not an SD/eMMC whole device (expected /dev/mmcblkN or 'mtd')" >&2; return "$INSTALL_EX_USAGE"; }
		[[ -b "$target" ]] || { echo "armbian-install bootloader: '$target' is not a block device" >&2; return "$INSTALL_EX_USAGE"; }
		mode="sd"; dev="$target"; shown="$target"
	fi

	if [[ "$assume_yes" != 1 ]]; then
		echo "armbian-install bootloader: refusing to write $bl to $shown without --yes (overwrites the bootloader)." >&2
		return "$INSTALL_EX_USAGE"
	fi

	echo "Writing $bl to $shown..."
	install_write_bootloader "$mode" "$dev" "/" "${DIR:-/usr/lib/u-boot}" "$mtd_list"
	local rc=$?
	[[ "$rc" == 0 ]] && echo "Done." || echo "Failed (code $rc). See ${INSTALL_LOG:-install log}." >&2
	return "$rc"
}

# ---- --api helpers (machine-readable, for scripts and tests) ----------------

partitioner_api() {
	# partitioner_api detect|plan [flags]
	local what="$1"; shift
	case "$what" in
		detect)
			install_detect_targets "$(partitioner_root_disk)" ;;
		plan)
			local target="" boot="" fs="ext4"
			while [[ $# -gt 0 ]]; do
				case "$1" in
					--target) target="$2"; shift 2 ;;
					--boot)   boot="$2";   shift 2 ;;
					--fs)     fs="$2";     shift 2 ;;
					*) shift ;;
				esac
			done
			local cap=0 sec=512 uefi=0
			if [[ -b "$target" ]]; then
				cap="$(blockdev --getsize64 "$target" 2>/dev/null || echo 0)"
				sec="$(cat "/sys/block/$(basename "$target")/queue/physical_block_size" 2>/dev/null || echo 512)"
			fi
			[[ "$boot" == uefi ]] && uefi=1
			install_plan_layout "$boot" "$fs" "$uefi" "$cap" "$sec" 0 ;;
		*)
			echo "usage: armbian-install --api {detect|plan}" >&2; return "$INSTALL_EX_USAGE" ;;
	esac
}

partitioner_help() {
	# editorconfig-checker-disable
	cat <<-EOF
	Armbian installer - transfer the running system to internal storage.

	Interactive:
	  armbian-install

	Non-interactive:
	  armbian-install --target /dev/sdX --boot <mode> --fs <fs> --yes
	    --boot   uefi | uefi-dualboot | bios | emmc | sd | mtd | spi | standalone | ufs | native | split-emmc
	             native: full self-contained install on a board with no
	                     u-boot/EFI/GRUB (e.g. Raspberry Pi) - target boots on
	                     its own, no other media needed
	             split-emmc: boot from eMMC, root on --target (NVMe/SATA/USB),
	                         eMMC remainder mounted at /emmc_storage
	             standalone: full self-contained install on --target, for boards
	                         whose bootloader loads /boot from that disk
	                         (BOOTLOADER_BOOTS_FROM) - current media untouched
	    --fs     ext4 | btrfs | f2fs
	    --size   GiB for Armbian (uefi-dualboot only; shrinks Windows)
	    --yes    required to actually modify the target

	Dual-boot with Windows 10/11 (UEFI):
	  armbian-install --target /dev/sdX --boot uefi-dualboot --fs ext4 --size 32 --yes

	Flash the bootloader (u-boot) only - no partitioning, no rootfs:
	  armbian-install bootloader --target mtd --yes            # to SPI/MTD
	  armbian-install bootloader --target /dev/mmcblk1 --yes   # to SD/eMMC
	    writes the running system's u-boot; the interactive TUI offers it too

	Machine-readable:
	  armbian-install --api detect
	  armbian-install --api plan --target /dev/sdX --boot uefi --fs ext4
	EOF
	# editorconfig-checker-enable
}

# ---- dispatch ---------------------------------------------------------------

module_partitioner() {
	# Source the board u-boot hooks so install_write_bootloader can find them.
	[[ -f /usr/lib/u-boot/platform_install.sh ]] && source /usr/lib/u-boot/platform_install.sh

	local commands
	IFS=' ' read -r -a commands <<<"${module_options["module_partitioner,example"]}"

	case "$1" in
		"${commands[0]}"|"")              # run (or bare invocation) -> TUI
			partitioner_menu ;;
		"${commands[1]}")                 # install -> non-interactive
			shift; partitioner_cli_install "$@" ;;
		"${commands[2]}")                 # detect -> engine inventory
			partitioner_api detect ;;
		"${commands[3]}")                 # plan -> engine planner
			shift; partitioner_api plan "$@" ;;
		"${commands[4]}"|-h|--help)       # help
			partitioner_help ;;
		"${commands[5]}")                 # bootloader -> flash u-boot only
			shift; partitioner_cli_flash "$@" ;;
		--target)                         # bare flags from the shim -> CLI
			partitioner_cli_install "$@" ;;
		--api)                            # bare --api from the shim
			shift; partitioner_api "$@" ;;
		*)
			partitioner_help; return "$INSTALL_EX_USAGE" ;;
	esac
}

module_options+=(
	["module_zfs,author"]="@igorpecovnik"
	["module_zfs,maintainer"]="@igorpecovnik"
	["module_zfs,feature"]="module_zfs"
	["module_zfs,desc"]="Install ZFS filesystem support"
	["module_zfs,example"]="install remove status tune scan import kernel_max zfs_version zfs_installed_version help"
	["module_zfs,port"]=""
	["module_zfs,status"]="Active"
	["module_zfs,arch"]="x86-64 arm64"
	["module_zfs,doc_link"]="https://openzfs.github.io/openzfs-docs/"
	["module_zfs,group"]="System"
	["module_zfs,config_file"]="/etc/modprobe.d/zfs.conf"
	# Custom command help descriptions
	["module_zfs,help_tune"]="Fine-tune ZFS performance parameters (ARC, dirty data, TXG, compression)"
	["module_zfs,help_scan"]="Scan for ZFS pools that can be imported"
	["module_zfs,help_import"]="Import a selected ZFS pool with optional alternate mount point"
	["module_zfs,help_kernel_max"]="Determine maximum supported kernel version for ZFS"
	["module_zfs,help_zfs_version"]="Get ZFS version from DKMS"
	["module_zfs,help_zfs_installed_version"]="Read installed ZFS version"
)
#
# Module OpenZFS
#
function module_zfs () {
	local title="zfs"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zfs,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if the module is already installed
			if pkg_installed zfsutils-linux; then
				echo "ZFS is already installed."
				return 0
			fi

			# Headers are needed, install them if not already present
			if ! module_headers status >/dev/null 2>&1; then
				echo "Installing kernel headers (required for ZFS)..."
				module_headers install
			fi

			echo "Installing ZFS packages..."
			# Suppress DKMS license prompt during ZFS compilation
			pkg_install zfsutils-linux zfs-dkms || return 1
		;;
		"${commands[1]}") # remove
			echo "Removing ZFS packages..."
			pkg_remove zfsutils-linux zfs-dkms
			# Note: We don't remove kernel headers as they may be needed by other modules
		;;
		"${commands[2]}") # status
			if pkg_installed zfsutils-linux; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}") # tune
			# Check if ZFS is installed
			if ! pkg_installed zfsutils-linux; then
				dialog_msgbox "ZFS Not Installed" \
					"ZFS is not installed. Please install ZFS first before tuning parameters."
				return 1
			fi

			# Check if ZFS module is loaded
			if ! lsmod | grep -q "^zfs "; then
				dialog_msgbox "ZFS Not Loaded" \
					"ZFS kernel module is not loaded. Loading module now..."
				modprobe zfs 2>/dev/null || {
					dialog_msgbox "Failed to Load ZFS" \
						"Failed to load ZFS kernel module. Please check your installation."
					return 1
				}
			fi

			local config_file="${module_options["module_zfs,config_file"]}"
			local backup_file="${config_file}.bak"

			# Get current system memory in MB
			local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
			local total_mem_mb=$((total_mem_kb / 1024))
			local total_mem_gb=$((total_mem_mb / 1024))

			# Calculate recommended values based on system memory
			local recommended_arc_min=$((total_mem_mb / 8))
			local recommended_arc_max=$((total_mem_mb / 2))
			local recommended_dirty=$((total_mem_mb / 25))  # 4% of RAM

			# Get current ARC settings
			local arc_min_current=$(cat /sys/module/zfs/parameters/zfs_arc_min 2>/dev/null || echo "0")
			local arc_max_current=$(cat /sys/module/zfs/parameters/zfs_arc_max 2>/dev/null || echo "0")
			local arc_min_mb=$((arc_min_current / 1024 / 1024))
			local arc_max_mb=$((arc_max_current / 1024 / 1024))

			# Convert to readable format
			local arc_max_display="${arc_max_mb} MB"
			if [[ $arc_max_mb -eq 0 ]]; then
				arc_max_display="Default (all RAM)"
			fi

			# Get current dirty data settings
			local dirty_max_current=$(cat /sys/module/zfs/parameters/zfs_dirty_data_max 2>/dev/null || echo "0")
			local dirty_max_mb=$((dirty_max_current / 1024 / 1024))

			# Get TXG timeout
			local txg_timeout=$(cat /sys/module/zfs/parameters/zfs_txg_timeout 2>/dev/null || echo "5")

			# Create tuning menu
			while true; do
				local menu_text="System Memory: ${total_mem_mb} MB (${total_mem_gb} GB)\n\n"
				menu_text+="Current Settings:\n"
				menu_text+="ARC Min: ${arc_min_mb} MB\n"
				menu_text+="ARC Max: ${arc_max_display}\n"
				menu_text+="Dirty Data Max: ${dirty_max_mb} MB\n"
				menu_text+="TXG Timeout: ${txg_timeout} sec\n\n"
				menu_text+="Select a parameter to tune:"

				local choice=$(dialog_menu "ZFS Performance Tuning" "$menu_text" 23 80 7 \
					"1" "ARC Cache Size (zfs_arc_min/max)" \
					"2" "Dirty Data Limits (zfs_dirty_data_max)" \
					"3" "TXG Timeout (zfs_txg_timeout)" \
					"4" "Advanced Settings" \
					"5" "Reset to Defaults" \
					"6" "Save & Apply Configuration" \
					"7" "Show Current Configuration")

				[[ -z "$choice" ]] && break

				case $choice in
					1) # ARC Cache Size Tuning
						dialog_msgbox "ARC Cache Size Tuning" \
							"The ARC (Adaptive Replacement Cache) is ZFS's intelligent cache.\n\nRecommended Settings:\n- zfs_arc_min: ${recommended_arc_min} MB (1/8 of RAM)\n- zfs_arc_max: ${recommended_arc_max} MB (1/2 of RAM)\n\nCurrent: ${arc_min_mb} MB / ${arc_max_display}" 16 80

						local new_arc_min_mb=$(dialog_inputbox "ARC Min Size" \
							"Enter ARC Min Size in MB:\n\n  Recommended: ${recommended_arc_min} MB\n  Existing value: ${arc_min_mb} MB\n\nPress OK to accept or change value:" \
							"${arc_min_mb}" 11 70)
						[[ -z "$new_arc_min_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_arc_min_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "ARC Min must be a positive number!" 8 60
							continue
						fi

						local new_arc_max_mb=$(dialog_inputbox "ARC Max Size" \
							"Enter ARC Max Size in MB:\n\n  Recommended: ${recommended_arc_max} MB (0 = all RAM)\n  Existing value: ${arc_max_mb} MB\n\nPress OK to accept or change value:" \
							"${arc_max_mb}" 11 70)
						[[ -z "$new_arc_max_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_arc_max_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "ARC Max must be a positive number (or 0)!" 8 60
							continue
						fi

						# Validate relationship
						if [[ $new_arc_min_mb -gt $new_arc_max_mb ]] && [[ $new_arc_max_mb -ne 0 ]]; then
							dialog_msgbox "Invalid Values" "ARC Min cannot be greater than ARC Max!" 10 65
							continue
						fi

						arc_min_mb=$new_arc_min_mb
						arc_max_mb=$new_arc_max_mb

						# Update display
						arc_max_display="${arc_max_mb} MB"
						[[ $arc_max_mb -eq 0 ]] && arc_max_display="Default (all RAM)"

						dialog_msgbox "Values Updated" "ARC settings updated.\n\nApply changes to take effect." 10 65
						;;

					2) # Dirty Data Limits
						dialog_msgbox "Dirty Data Limits" \
							"Dirty data is data that has been changed but not yet written to disk.\n\nRecommended: ${recommended_dirty} MB (4% of RAM)\n\nHigher values = better performance but more data loss risk on power failure." 14 75

						local new_dirty_max_mb=$(dialog_inputbox "Dirty Data Max" \
							"Enter Dirty Data Max in MB:\n\n  Recommended: ${recommended_dirty} MB\n  Existing value: ${dirty_max_mb} MB\n\nPress OK to accept or change value:" \
							"${dirty_max_mb}" 11 70)
						[[ -z "$new_dirty_max_mb" ]] && continue

						# Validate numeric input
						if ! [[ "$new_dirty_max_mb" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "Dirty Data Max must be a positive number!" 8 60
							continue
						fi

						dirty_max_mb=$new_dirty_max_mb

						dialog_msgbox "Value Updated" "Dirty data max updated.\n\nApply changes to take effect." 10 65
						;;

					3) # TXG Timeout
						dialog_msgbox "TXG (Transaction Group) Timeout" \
							"Controls how often ZFS writes dirty data to disk.\n\nDefault: 5 seconds\n\nLower values = more frequent writes, better data safety, lower performance\nHigher values = less frequent writes, better performance, more data loss risk" 15 75

						local new_txg_timeout=$(dialog_inputbox "TXG Timeout" \
							"Enter TXG Timeout in seconds (1-30):\n\n  Recommended: 5 seconds\n  Existing value: ${txg_timeout} seconds\n\nPress OK to accept or change value:" \
							"${txg_timeout}" 11 70)
						[[ -z "$new_txg_timeout" ]] && continue

						# Validate numeric input
						if ! [[ "$new_txg_timeout" =~ ^[0-9]+$ ]]; then
							dialog_msgbox "Invalid Input" "TXG timeout must be a positive number!" 8 60
							continue
						fi

						# Validate range
						if [[ $new_txg_timeout -lt 1 ]] || [[ $new_txg_timeout -gt 30 ]]; then
							dialog_msgbox "Invalid Value" "TXG timeout must be between 1 and 30 seconds!" 10 65
							continue
						fi

						txg_timeout=$new_txg_timeout

						dialog_msgbox "Value Updated" "TXG timeout updated.\n\nApply changes to take effect." 10 65
						;;

					4) # Advanced Settings
						local adv_choice=$(dialog_menu "Advanced ZFS Tuning" \
							"WARNING: Only change these if you know what you're doing!" 20 80 6 \
							"1" "Prefetch Settings" \
							"2" "Sync Settings" \
							"3" "VDEV Settings" \
							"4" "Debug & Logging" \
							"5" "View Current module parameters" \
							"6" "Back")

						[[ -z "$adv_choice" ]] && continue

						case $adv_choice in
							1)
								local prefetch_current=$(cat /sys/module/zfs/parameters/zfs_prefetch_disable 2>/dev/null || echo "0")
								local prefetch_status="Enabled"
								[[ $prefetch_current -eq 1 ]] && prefetch_status="Disabled"

								if dialog_yesno "Disable ZFS Prefetch?" \
									"Current: ${prefetch_status}\n\nDisabling can help with certain workloads but usually hurts performance.\n\nDisable prefetch?"; then
									dialog_msgbox "Info" "Prefetch settings can be manually added to the config.\n\nEdit: ${config_file}\n\nAdd: options zfs zfs_prefetch_disable=1" 13 75
								else
									dialog_msgbox "Info" "Prefetch will remain enabled.\n\nCurrent default: enabled" 11 70
								fi
								;;
							2)
								dialog_msgbox "Sync Settings" \
									"zfs_sync_taskq_batch_pct controls sync task batching.\n\nDefault: Auto-tuned\n\nIncreasing can improve sync-heavy workloads (databases).\n\nCan be manually set in: ${config_file}" 13 70
								;;
							3)
								dialog_msgbox "VDEV Settings" \
									"zfs_vdev_* parameters control VDEV behavior.\n\nMost are auto-tuned. Manual tuning rarely needed.\n\nCommon parameters:\n- zfs_vdev_async_write_min_active\n- zfs_vdev_max_active\n- zfs_vdev_open_max_ms" 14 70
								;;
							4)
								dialog_msgbox "Debug & Logging" \
									"zfs_deadman_enabled, zfs_flags, etc.\n\nOnly enable for debugging purposes.\n\nWARNING: Can significantly impact performance.\n\nAdd to config manually if needed." 13 70
								;;
							5)
								if [[ -d /sys/module/zfs/parameters ]]; then
									local params_text="Current ZFS module parameters:\n\n"
									# Use ls to get parameter files safely
									for param_file in /sys/module/zfs/parameters/*; do
										if [[ -f "$param_file" ]]; then
											local name=$(basename "$param_file")
											local value
											value=$(cat "$param_file" 2>/dev/null || echo "N/A")
											# Truncate long values for display
											if [[ ${#value} -gt 50 ]]; then
												value="${value:0:47}..."
											fi
											params_text+="${name} = ${value}\n"
										fi
									done
									# Count total parameters
									local param_count=$(ls -1 /sys/module/zfs/parameters/* 2>/dev/null | wc -l)
									params_text+="\nTotal: ${param_count} parameters"
									dialog_msgbox "ZFS Module Parameters" "$params_text" 20 75
								else
									dialog_msgbox "Not Available" "ZFS module parameters not available.\n\nEnsure ZFS module is loaded."
								fi
								;;
						esac
						;;

					5) # Reset to defaults
						if dialog_yesno "Reset to Defaults" \
							"Reset all ZFS parameters to defaults?\n\nThis will remove any custom tuning."; then
							arc_min_mb=0
							arc_max_mb=0
							dirty_max_mb=$recommended_dirty
							txg_timeout=5
							# Update display
							arc_max_display="Default (all RAM)"
							dialog_msgbox "Reset Complete" "Parameters reset to defaults.\n\nApply changes to take effect." 11 70
						fi
						;;

					6) # Save & Apply
						local config_preview="The following settings will be saved to:\n${config_file}\n\n"
						if [[ $arc_min_mb -gt 0 ]]; then
							config_preview+="zfs_arc_min=$((arc_min_mb * 1024 * 1024)) bytes\n"
						fi
						if [[ $arc_max_mb -gt 0 ]]; then
							config_preview+="zfs_arc_max=$((arc_max_mb * 1024 * 1024)) bytes\n"
						else
							config_preview+="# zfs_arc_max=0  (use all RAM, default)\n"
						fi
						config_preview+="zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024)) bytes\n"
						config_preview+="zfs_txg_timeout=${txg_timeout} seconds\n"

						dialog_msgbox "Saving ZFS Configuration" "$config_preview"

						# Backup existing config if it exists
						if [[ -f "$config_file" ]]; then
							cp "$config_file" "$backup_file" || {
								dialog_msgbox "Backup Failed" "Failed to backup existing configuration.\n\nContinuing without backup."
							}
						fi

						# Build configuration file
						{
							echo "# ZFS Performance Tuning Configuration"
							echo "# Generated by Armbian config on $(date)"
							echo ""
							echo "# ARC Cache Settings"
							if [[ $arc_min_mb -gt 0 ]]; then
								echo "options zfs zfs_arc_min=$((arc_min_mb * 1024 * 1024))"
							fi
							if [[ $arc_max_mb -gt 0 ]]; then
								echo "options zfs zfs_arc_max=$((arc_max_mb * 1024 * 1024))"
							else
								echo "# options zfs zfs_arc_max=0  # 0 = use all RAM (default)"
							fi
							echo ""
							echo "# Dirty Data Settings"
							echo "options zfs zfs_dirty_data_max=$((dirty_max_mb * 1024 * 1024))"
							echo ""
							echo "# Transaction Group Settings"
							echo "options zfs zfs_txg_timeout=${txg_timeout}"
						} > "$config_file"

						# Notify about backup
						if [[ -f "$backup_file" ]]; then
							dialog_msgbox "Configuration Saved" \
								"Configuration saved successfully.\n\nPrevious configuration backed up to:\n${backup_file}\n\nYou can restore it manually if needed." 12 70
						fi

						# Apply changes
						dialog_msgbox "Applying Changes" \
							"Configuration saved.\n\nTo apply changes, ZFS module must be reloaded.\n\nThis requires either:\n1. Reboot\n2. Manual: rmmod zfs && modprobe zfs\n\nWARNING: Unloading ZFS requires exporting all pools first." 16 75

						if dialog_yesno "Reload ZFS Module" \
							"WARNING: All ZFS pools must be exported first!\n\nContinue?"; then
							if [[ -n "$(zpool list -H 2>/dev/null)" ]]; then
								dialog_msgbox "Cannot Reload" \
									"ZFS pools are imported.\n\nPlease export all pools first:\nzpool export -a" 11 70
							else
								# Try to unload ZFS module
								if rmmod zfs 2>/dev/null; then
									# rmmod succeeded, now try to load ZFS module
									if modprobe zfs 2>/dev/null; then
										# Success
										dialog_msgbox "Success" \
											"ZFS module reloaded successfully.\n\nNew settings are now active." 11 70
									else
										# modprobe failed - system without ZFS!
										# Try retry
										if modprobe zfs 2>/dev/null; then
											dialog_msgbox "Success" \
												"ZFS module reloaded after retry.\n\nNew settings are now active." 11 70
										else
											# Recovery failed - show dmesg and recovery instructions
											local dmesg_output
											dmesg_output=$(dmesg | tail -20 2>/dev/null || echo "Cannot retrieve dmesg output")
											dialog_msgbox "Critical Error" \
												"ZFS module unload succeeded but reload FAILED!\n\nSystem is running without ZFS support.\n\nLast dmesg entries:\n${dmesg_output}\n\nRecovery:\n1. Reboot to restore ZFS\n2. Or try manually: modprobe zfs" 18 75
										fi
									fi
								else
									# rmmod failed - module probably in use
									dialog_msgbox "Unload Failed" \
										"Failed to unload ZFS module.\n\nModule may be in use.\n\nTry rebooting to apply new settings." 11 70
								fi
							fi
						fi

						break
						;;

					7) # Show current configuration
						local show_text="Current ZFS Configuration:\n\n"
						if [[ $arc_min_mb -gt 0 ]]; then
							show_text+="ARC Min: ${arc_min_mb} MB ($((arc_min_mb * 1024 * 1024)) bytes)\n"
						else
							show_text+="ARC Min: (not set, using default)\n"
						fi
						if [[ $arc_max_mb -gt 0 ]]; then
							show_text+="ARC Max: ${arc_max_mb} MB ($((arc_max_mb * 1024 * 1024)) bytes)\n"
						else
							show_text+="ARC Max: (not set, will use all RAM)\n"
						fi
						show_text+="Dirty Data Max: ${dirty_max_mb} MB ($((dirty_max_mb * 1024 * 1024)) bytes)\n"
						show_text+="TXG Timeout: ${txg_timeout} seconds\n\n"
						show_text+="Configuration file: ${config_file}\n\n"
						if [[ -f "$config_file" ]]; then
							show_text+="Current file contents:\n\n"
							# Append file contents, converting actual newlines to \n escape sequences
							local file_contents
							file_contents=$(cat "$config_file" 2>/dev/null)
							if [[ -n "$file_contents" ]]; then
								while IFS= read -r line; do
									show_text+="${line}\\n"
								done <<< "$file_contents"
							fi
						else
							show_text+="(No custom configuration file yet)"
						fi
						dialog_msgbox "Current ZFS Configuration" "$show_text" 22 80
						;;
				esac
			done
			;;
		"${commands[4]}") # scan
			# Check if ZFS is installed
			if ! pkg_installed zfsutils-linux; then
				return 1
			fi

			# Check if ZFS module is loaded
			if ! lsmod | grep -q "^zfs "; then
				modprobe zfs 2>/dev/null || return 1
			fi

			# Get list of pools that can be imported
			pool_list=$(zpool import 2>/dev/null)

			if [[ -z "$pool_list" ]]; then
				return 1
			fi

			# Parse pool list to extract pool names and info
			declare -A pool_altroot  # Store original altroot for each pool
			pools=()
			current_pool=""
			while IFS= read -r line; do
				# Lines starting with "pool:" indicate pool names
				if [[ "$line" =~ ^[[:space:]]*pool:[[:space:]]+(.+)$ ]]; then
					current_pool="${BASH_REMATCH[1]}"
					pools+=("$current_pool")
					pool_altroot["$current_pool"]=""
				# Extract altroot if present
				elif [[ "$line" =~ ^[[:space:]]*altroot:[[:space:]]+(.+)$ ]]; then
					altroot_value="${BASH_REMATCH[1]}"
					# Clean up the altroot value
					altroot_value=$(echo "$altroot_value" | sed 's/[[:space:]]*$//')
					pool_altroot["$current_pool"]="$altroot_value"
				fi
			done <<< "$pool_list"
			if [[ ${#pools[@]} -eq 0 ]]; then
				return 1
				else
				export POOLS=${#pools[@]}
			fi
			;;
		"${commands[5]}") # import

			if ! ${module_options["module_zfs,feature"]} ${commands[4]}; then
				return 1
			fi

			# Show pool selection menu
			# Build radiolist arguments - pool names as both tag and description
			local radiolist_args=()
			for pool in "${pools[@]}"; do
				radiolist_args+=("$pool" "$pool" "off")
			done

			local selected_pool
			selected_pool=$(dialog_radiolist "Import ZFS Pool" \
				"Select a ZFS pool to import:\n\nFound ${#pools[@]} pool(s) available for import." \
				18 80 8 -- "${radiolist_args[@]}")

			if [[ -z "$selected_pool" ]]; then
				return 0
			fi

			# Ask for alternate mount point (optional)
			local alt_root=""
			if dialog_yesno "Alternate Mount Point" \
				"Import pool '${selected_pool}' at an alternate mount point?\n\n- Yes: Specify custom mount path\n- No: Use pool's original mount points" "Yes" "No" 10 70 --defaultno; then
				# User wants custom mount point
				alt_root=$(dialog_inputbox "Alternate Mount Point" \
					"Enter alternate root mount point:\n\nExample: /mnt/pool\n\nPool datasets will be mounted under this path." \
					"/mnt/${selected_pool}" 12 70)

				if [[ -n "$alt_root" ]]; then
					# Validate the path
					if [[ ! "$alt_root" =~ ^/ ]]; then
						dialog_msgbox "Invalid Path" \
							"Mount point must be an absolute path (starting with /)." 8 50
						return 1
					fi

					# Create the directory if it doesn't exist
					if [[ ! -d "$alt_root" ]]; then
						mkdir -p "$alt_root" 2>/dev/null || {
							dialog_msgbox "Cannot Create Directory" \
								"Failed to create directory: ${alt_root}\n\nCheck permissions and try again." 9 60
							return 1
						}
					fi
				fi
			fi

			# selected_pool contains the pool name directly from the radiolist

			# Confirm import
			local confirm_msg="Import pool '${selected_pool}'?"
			if [[ -n "$alt_root" ]]; then
				confirm_msg+="\n\nMount point: ${alt_root}"
			else
				confirm_msg+="\n\nMount point: Pool's original mount points"
			fi
			confirm_msg+="\n\nNote: Force import (-f) will be used to ensure pool can be imported."

			if dialog_yesno "Confirm Import" "$confirm_msg"; then
				# Import the pool with -f flag to force import
				# Use altroot if specified and different from original
				local import_output
				local original_altroot="${pool_altroot[$selected_pool]}"

				# Check if user-provided altroot matches the pool's original
				if [[ -n "$alt_root" && "$alt_root" == "$original_altroot" ]]; then
					# Altroot matches original - import without altroot parameter
					dialog_msgbox "Using Original Mount Point" \
						"The specified mount point matches the pool's original altroot.\n\nImporting with original mount points." 10 70
					alt_root=""
				fi

				if [[ -n "$alt_root" ]]; then
					import_output=$(zpool import -f -o altroot="$alt_root" "$selected_pool" 2>&1)
				else
					import_output=$(zpool import -f "$selected_pool" 2>&1)
				fi

				if [[ $? -eq 0 ]]; then
					dialog_msgbox "Import Successful" \
						"Pool '${selected_pool}' imported successfully!" 8 50
				else
					dialog_msgbox "Import Failed" \
						"Failed to import pool '${selected_pool}'.\n\nError:\n${import_output}\n\nCheck 'dmesg' for more details." 14 70
					return 1
				fi
			fi
			;;
		"${commands[6]}") # kernel_max
			echo "${ZFS_KERNEL_MAX:-<not set>}"
		;;
		"${commands[7]}") # zfs_version
			if [[ -n "${ZFS_DKMS_VERSION}" ]]; then
				echo "v${ZFS_DKMS_VERSION}"
			else
				echo "<version not available>"
			fi
		;;
		"${commands[8]}") # zfs_installed_version
			if pkg_installed zfsutils-linux; then
				zfs --version 2>/dev/null | head -1 | cut -d"-" -f2
			else
				echo "ZFS is not installed"
				return 1
			fi
		;;
		"${commands[9]}") # help
			show_module_help "module_zfs" "ZFS" "Configuration file: ${module_options["module_zfs,config_file"]}" "native"
		;;
		*) # default - show help
			${module_options["module_zfs,feature"]} ${commands[9]}
		;;
	esac
}


module_options+=(

["adjust_motd,author"]="@igorpecovnik"
["adjust_motd,ref_link"]=""
["adjust_motd,feature"]="about_armbian_configng"
["adjust_motd,desc"]="Adjust welcome screen (motd)"
["adjust_motd,example"]="adjust_motd clear, header, sysinfo, tips, commands"
["adjust_motd,status"]="Active"
)
#
# @description Toggle message of the day items
#
function adjust_motd() {

	# show motd description
	motd_desc() {
		case $1 in
			clear|00-clear)
				echo "Clear screen on login"
				;;
			header|10-armbian-header)
				echo "Show header with logo and version info"
				;;
			ap-info|15-ap-info)
				echo "Display active Wi-Fi access point (SSID, channel)"
				;;
			ip-info|20-ip-info)
				echo "Show LAN/WAN IPv4 and IPv6 addresses"
				;;
			containers-info|25-containers-info)
				echo "List running Docker containers"
				;;
			sysinfo|30-armbian-sysinfo)
				echo "Display performance and system information"
				;;
			tips|35-armbian-tips)
				echo "Show helpful tips and Armbian resources"
				;;
			commands|41-commands)
				echo "Show recommended commands"
				;;
			autoreboot-warn|98-armbian-autoreboot-warn)
				echo "Warn about pending automatic reboot after update"
				;;
			*)
				echo "No description available"
				;;
		esac
	}

	# read status
	function motd_status() {
		source /etc/default/armbian-motd
		if [[ $MOTD_DISABLE == *$1* ]]; then
			echo "OFF"
		else
			echo "ON"
		fi
	}

	LIST=()
	for v in $(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"); do
		LIST+=("$v" "$(motd_desc $v)" "$(motd_status $v)")
	done

	INLIST=($(grep THIS_SCRIPT= /etc/update-motd.d/* | cut -d"=" -f2 | sed "s/\"//g"))
	CHOICES=$(dialog_checklist "Adjust welcome screen" "" 14 76 8 --separate-output --nocancel -- "${LIST[@]}")
	INSERT="$(echo "${INLIST[@]}" "${CHOICES[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ' | sed 's/ *$//')"
	# adjust motd config
	sed -i "s/^MOTD_DISABLE=.*/MOTD_DISABLE=\"$INSERT\"/g" /etc/default/armbian-motd
	reset
	clear
	find /etc/update-motd.d/. -type f -executable | sort | bash
	echo "Press any key to return to armbian-config"
	read
}

module_options+=(
	["manage_odroid_board,author"]="@GeoffClements"
	["manage_odroid_board,ref_link"]=""
	["manage_odroid_board,feature"]="Odroid board"
	["manage_odroid_board,desc"]="Select optimised Odroid board configuration"
	["manage_odroid_board,example"]="select"
	["manage_odroid_board,status"]="Stable"
	["manage_odroid_board,arch"]="armhf"
)
#
# @description Select optimised board configuration
#
function manage_odroid_board() {

	local board_list=("Odroid XU4" "Odroid XU3" "Odroid XU3 Lite" "Odroid HC1/HC2")
	local board_id=("xu4" "xu3" "xu3l" "hc1")
	local -a list
	local state

	local env_file=/boot/armbianEnv.txt
	local current_board=$(grep -oP '^board_name=\K.*' ${env_file})
	local target_board=${current_board}

	for board_num in $(seq 0 $((${#board_list[@]} - 1))); do
		if [[ "${board_id[${board_num}]}" == "${current_board}" ]]; then
			state=on
		else
			state=off
		fi
	list+=("${board_id[${board_num}]}" "${board_list[${board_num}]}" "${state}")
	done

	if target_board=$(dialog_radiolist "Select optimised board configuration" "" 10 42 4 --notags -- "${list[@]}"); then
		sed -i "s/^board_name=.*/board_name=${target_board}/" ${env_file} 2> /dev/null && \
		grep -q "^board_name=${target_board}" ${env_file} 2>/dev/null || \
		echo "board_name=${target_board}" >> ${env_file}
		sed -i "s/^BOARD_NAME.*/BOARD_NAME=\"Odroid ${target_board^^}\"/" /etc/armbian-release

		if dialog_yesno " Reboot required " "A reboot is required to apply the changes. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
		reboot
		fi
	fi
}

module_options+=(
	["toggle_ssh_lastlog,author"]="@Tearran"
	["toggle_ssh_lastlog,ref_link"]=""
	["toggle_ssh_lastlog,feature"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,desc"]="Toggle SSH lastlog"
	["toggle_ssh_lastlog,example"]="toggle_ssh_lastlog"
	["toggle_ssh_lastlog,status"]="Active"
)
#
# @description Toggle SSH lastlog
#
function toggle_ssh_lastlog() {

	if ! grep -q '^#\?PrintLastLog ' "${SDCARD}/etc/ssh/sshd_config"; then
		# If PrintLastLog is not found, append it with the value 'yes'
		echo 'PrintLastLog no' >> "${SDCARD}/etc/ssh/sshd_config"
		srv_restart ssh
	else
		# If PrintLastLog is found, toggle between 'yes' and 'no'
		sed -i '/^#\?PrintLastLog /
{
	s/PrintLastLog yes/PrintLastLog no/;
	t;
	s/PrintLastLog no/PrintLastLog yes/
}' "${SDCARD}/etc/ssh/sshd_config"
		srv_restart ssh
	fi

}


module_options+=(
	["module_armbian_rsyncd,author"]="@igorpecovnik"
	["module_armbian_rsyncd,maintainer"]="@igorpecovnik"
	["module_armbian_rsyncd,feature"]="module_armbian_rsyncd"
	["module_armbian_rsyncd,example"]="install remove status help"
	["module_armbian_rsyncd,desc"]="Install and configure Armbian rsyncd."
	["module_armbian_rsyncd,doc_link"]=""
	["module_armbian_rsyncd,group"]="Armbian"
	["module_armbian_rsyncd,status"]="Active"
	["module_armbian_rsyncd,port"]="873"
	["module_armbian_rsyncd,arch"]=""
)

function module_armbian_rsyncd() {
	local title="rsyncd"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_rsyncd,example"]}"

	case "$1" in
		"${commands[0]}")
			if export_path=$(dialog_inputbox "Where is armbian file storage located?" "" "/armbian/openssh-server/storage"); then

				# lets make temporally file
				rsyncd_config=$(mktemp)
				if target_sync=$(dialog_checklist "Select rsync target" "Choose which Armbian rsync targets to mirror" 15 60 6 \
				"apt" "Armbian stable packages" ON \
				"dl" "Stable images" ON \
				"beta" "Armbian unstable packages" OFF \
				"archive" "Old images" OFF \
				"oldarchive" "Very old archive" OFF \
				"cache" "Nightly and community images cache" OFF); then

					for choice in $(echo ${target_sync} | tr -d '"'); do
						cat <<- EOF >> $rsyncd_config
						[$choice]
						path = $export_path/$choice
						max connections = 8
						uid = nobody
						gid = users
						list = yes
						read only = yes
						write only = no
						use chroot = yes
						lock file = /run/lock/rsyncd-$choice
						EOF
					done
					mv $rsyncd_config /etc/rsyncd.conf
					pkg_update
					pkg_install rsync >/dev/null 2>&1
					srv_enable rsync >/dev/null 2>&1
					srv_start rsync >/dev/null 2>&1
				fi
			fi
		;;
		"${commands[1]}")
			srv_stop rsync >/dev/null 2>&1
			rm -f /etc/rsyncd.conf
		;;
		"${commands[2]}")
			if srv_active rsyncd; then
				return 0
			elif ! srv_enabled rsync; then
				return 1
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_armbian_rsyncd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_rsyncd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status of $title."
			echo
		;;
		*)
			${module_options["module_armbian_rsyncd,feature"]} ${commands[3]}
		;;
	esac
	}

