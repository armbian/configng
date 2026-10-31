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
	["module_tuning_profile,help_cpu"]="CPU frequency per cluster: cpu [select|status|apply|reset|set <all|policy<n>> <governor|min|max|boost|clear> [value]]"
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

# _tp_cpu_dir <n> -> policy dir for policy<n>, or nothing
function _tp_cpu_dir() {
	local d
	while read -r d; do
		[[ "$(_tp_cpu_id "$d")" == "$1" ]] && { echo "$d"; return 0; }
	done < <(_tp_cpu_policies)
	return 1
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

# _tp_cpu_label <policy dir> -> "CPU4-5 Cortex-A72, 408-1800 MHz"
function _tp_cpu_label() {
	local d="$1" cpus core
	cpus="$(_tp_cpu_read "$d" related_cpus)"
	[[ -z "$cpus" ]] && cpus="$(_tp_cpu_read "$d" affected_cpus)"
	core="$(_tp_cpu_core "${cpus%% *}")"
	echo "CPU$(_tp_cpu_range "$cpus")${core:+ ${core}}, $(_tp_cpu_mhz "$(_tp_cpu_read "$d" cpuinfo_min_freq)")-$(_tp_cpu_mhz "$(_tp_cpu_read "$d" cpuinfo_max_freq)") MHz"
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

function _tp_cpu_apply_boost() {
	local val d
	case "$(_tp_cpu_get BOOST)" in
		true) val=1 ;;
		off) val=0 ;;
		*) return 0 ;;
	esac
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

# Install the boot unit only when armbian-hardware-optimization cannot apply the
# file alone: not an Armbian image, an older BSP without per-policy keys, or
# BOOST=off without the global boost file (intel_pstate, per-policy boost).
function _tp_cpu_sync_unit() {
	local ho="${TP_CPU_HO:-/usr/lib/armbian/armbian-hardware-optimization}"
	if [[ ! -x "$ho" ]] \
		|| { ! grep -qF 'POLICY${n}_GOVERNOR' "$ho" && grep -qE '^(POLICY[0-9]+_[A-Z_]+|BOOST=off)' "$TP_CPU_CONF" 2> /dev/null; } \
		|| { grep -q '^BOOST=off' "$TP_CPU_CONF" 2> /dev/null && [[ ! -e "$TP_CPU_SYS/cpufreq/boost" ]]; }; then
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

# _tp_cpu_set <all|policy<n>> <governor|min|max|boost|clear> [value]
#
# Frequencies are in kHz, as in sysfs and in the config file. "all" writes the
# global key and drops the per-policy overrides of that key.
function _tp_cpu_set() {
	local target="$1" key="$2" value="$3" prefix="" d n lo="" hi="" other
	local -a dirs=() online=()

	if [[ "$target" == "all" ]]; then
		mapfile -t dirs < <(_tp_cpu_policies)
	elif [[ "$target" =~ ^policy([0-9]+)$ ]]; then
		n="${BASH_REMATCH[1]}"
		prefix="POLICY${n}_"
		d="$(_tp_cpu_dir "$n")" && dirs=("$d")
	fi
	if [[ ${#dirs[@]} -eq 0 ]]; then
		echo "No CPU frequency policy '${target}'. Use 'all' or one of: $(_tp_cpu_policies | while read -r d; do printf 'policy%s ' "$(_tp_cpu_id "$d")"; done)" >&2
		return 1
	fi
	for d in "${dirs[@]}"; do
		_tp_cpu_online "$d" && online+=("$d")
	done
	[[ ${#online[@]} -gt 0 ]] || { echo "All CPUs of ${target} are offline." >&2; return 1; }

	# Keep a copy of the board defaults that the build wrote, for reset.
	[[ -f "$TP_CPU_CONF" && ! -f "$TP_CPU_DEFAULTS" ]] && cp -a "$TP_CPU_CONF" "$TP_CPU_DEFAULTS"

	case "$key" in
		governor)
			if [[ -n "$value" ]] && ! _tp_cpu_governors "${online[@]}" | grep -qx -- "$value"; then
				echo "Governor '${value}' is not available for ${target/#all/all CPUs}. Available: $(_tp_cpu_governors "${online[@]}" | tr '\n' ' ')" >&2
				return 1
			fi
			[[ -n "$prefix" ]] || sed -i '/^POLICY[0-9]*_GOVERNOR=/d' "$TP_CPU_CONF" 2> /dev/null
			_tp_cpu_put "${prefix}GOVERNOR" "$value"
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
				if [[ "$key" == "min" ]]; then
					other="$(_tp_cpu_get "${prefix}MAX_SPEED")"
					[[ -n "$other" ]] && ((value > other)) && { echo "Minimum ${value} kHz is above maximum ${other} kHz." >&2; return 1; }
				else
					other="$(_tp_cpu_get "${prefix}MIN_SPEED")"
					[[ -n "$other" ]] && ((value < other)) && { echo "Maximum ${value} kHz is below minimum ${other} kHz." >&2; return 1; }
				fi
			fi
			key="${key^^}_SPEED"
			[[ -n "$prefix" ]] || sed -i "/^POLICY[0-9]*_${key}=/d" "$TP_CPU_CONF" 2> /dev/null
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
			_tp_cpu_put "${prefix}${key}" "$value"
			;;
		boost)
			[[ -z "$prefix" ]] || { echo "Boost is set for all CPUs only." >&2; return 1; }
			_tp_cpu_has_boost || { echo "This CPU has no boost control." >&2; return 1; }
			case "$value" in
				true | on) value=true ;;
				off) ;;
				false | default | "") value=false ;;
				*) echo "Boost must be on, off or default." >&2; return 1 ;;
			esac
			_tp_cpu_put BOOST "$value"
			;;
		clear)
			[[ -n "$prefix" ]] || { echo "Clear needs a policy, for example: cpu set policy4 clear" >&2; return 1; }
			sed -i "/^${prefix}/d" "$TP_CPU_CONF" 2> /dev/null
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
	local d
	if [[ -f "$TP_CPU_DEFAULTS" ]]; then
		cat "$TP_CPU_DEFAULTS" > "$TP_CPU_CONF"
		rm -f "$TP_CPU_DEFAULTS"
	else
		sed -i -E '/^POLICY[0-9]+_/d; /^BOOST=off/d' "$TP_CPU_CONF" 2> /dev/null
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

# _tp_cpu_tui_target <all|policy<n>>
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
		dirs=("$(_tp_cpu_dir "${target#policy}")")
		title="${target}: $(_tp_cpu_label "${dirs[0]}")"
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
	local choice d n sum boost out
	local -a opts policies
	mapfile -t policies < <(_tp_cpu_policies)
	if [[ ${#policies[@]} -eq 0 ]]; then
		dialog_msgbox "CPU frequency" "This system has no CPU frequency scaling." 8 60
		return 0
	fi

	while true; do
		opts=("all" "All CPUs: $(_tp_cpu_get GOVERNOR | grep . || echo "kernel default")")
		# One entry per cluster. Skip the list when there is only one.
		if [[ ${#policies[@]} -gt 1 ]]; then
			for d in "${policies[@]}"; do
				n="$(_tp_cpu_id "$d")"
				if _tp_cpu_online "$d"; then
					sum="$(_tp_cpu_read "$d" scaling_governor), $(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_min_freq)")-$(_tp_cpu_mhz "$(_tp_cpu_read "$d" scaling_max_freq)") MHz"
				else
					sum="offline"
				fi
				opts+=("policy${n}" "$(_tp_cpu_label "$d") [${sum}]")
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
					echo "Usage: module_tuning_profile cpu [select|status|apply|reset|set <all|policy<n>> <governor|min|max|boost|clear> [value]]" >&2
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
