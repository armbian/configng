module_options+=(
	["module_tuning_profile,author"]="@igorpecovnik"
	["module_tuning_profile,maintainer"]="@igorpecovnik"
	["module_tuning_profile,feature"]="module_tuning_profile"
	["module_tuning_profile,desc"]="Kernel and CPU tuning profiles for the machine's actual role"
	["module_tuning_profile,example"]="select apply status list reset help"
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

	# ext4 commit interval, in fstab, applied live as well.
	if _tp_root_is_ext4; then
		_tp_set_fstab_commit "$commit" || \
			echo "  commit interval NOT changed (fstab left as it was)" >&2
	fi

	_tp_write_unit "$profile"
	systemctl daemon-reload > /dev/null 2>&1
	if [[ -f "$TP_UNIT_FILE" ]]; then
		systemctl enable --now armbian-tuning-profile.service > /dev/null 2>&1
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
	[[ -f "$TP_STATE_FILE" ]] && grep -oP '^PROFILE=\K.*' "$TP_STATE_FILE" 2>/dev/null
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
				out="$(_tp_apply "$choice" 2>&1)"
				dialog_msgbox "Profile Applied" "${out}\n\nNothing needs restarting; the settings are live." 14 74
			fi
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
			# Reload what remains, so the live values match the files that are
			# left rather than whatever this profile last set.
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
			_tp_has_epp && echo "Note: the CPU energy/performance preference stays as last set until reboot."
			;;

		"${commands[5]}") # help
			show_module_help "module_tuning_profile" "$title"
			;;

		*)
			show_module_help "module_tuning_profile" "$title"
			;;
	esac
}
