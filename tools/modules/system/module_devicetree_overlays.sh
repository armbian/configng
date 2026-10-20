
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
		[[ -n "$t" ]] && echo "$t (set above \"# Armbian config\", edit by hand)"
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
