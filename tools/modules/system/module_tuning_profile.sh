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
	["module_tuning_profile,config_file"]="/etc/sysctl.d/99-armbian-tuning-profile.conf"
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
# What it deliberately does not own: /etc/fstab. The ext4 commit interval is
# applied with `mount -o remount` from a systemd unit instead, so a profile can
# never leave a machine unbootable, and removing the profile removes the unit.

declare -g TP_SYSCTL_FILE="/etc/sysctl.d/99-armbian-tuning-profile.conf"
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

# The boot-time unit: CPU bias and the ext4 commit interval. Both are runtime
# settings that do not survive a reboot on their own, and neither belongs in a
# file that the boot depends on.
function _tp_write_unit() {
	local profile="$1" commit epp
	commit="$(_tp_commit_interval "$profile")"
	epp="$(_tp_epp "$profile")"

	{
		cat <<- EOF
			[Unit]
			Description=Armbian tuning profile (${profile}): CPU bias and filesystem commit interval
			Documentation=https://docs.armbian.com/User-Guide_Fine-Tuning/
			After=local-fs.target

			[Service]
			Type=oneshot
			RemainAfterExit=yes
		EOF

		# Only emit the CPU line where the knob exists. Most ARM cpufreq drivers
		# have no energy/performance preference, and a unit that claims to set
		# one on a board that has none contradicts what `apply` reports and
		# invites a puzzled reader. The [ -w ] test still guards the write, for
		# the case where a CPU appears offline at boot.
		if [[ -n "$epp" ]] && _tp_has_epp; then
			cat <<- EOF
				ExecStart=/bin/sh -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do [ -w "\$f" ] && echo ${epp} > "\$f"; done; exit 0'
			EOF
		fi

		if _tp_root_is_ext4; then
			cat <<- EOF
				# Journal commit interval, applied by remount rather than via fstab:
				# a profile must never be able to leave the machine unbootable.
				ExecStart=/bin/sh -c 'mount -o remount,commit=${commit} / || true'
			EOF
		fi

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

	# 99-armbian-tuning-profile sorts AFTER 99-armbian-memory.conf, which
	# module_memory writes with its own vm.swappiness. Later file wins, so the
	# profile's value is the one that takes effect. Renaming either file
	# without checking that order would silently hand swappiness back.
	{
		echo "# Armbian tuning profile: ${profile}"
		echo "#"
		echo "# Generated by armbian-config (module_tuning_profile) on $(date -Is)."
		echo "# Edit the profile, not this file -- it is rewritten on every apply."
		echo "#"
		echo "# Loaded after 99-armbian-memory.conf, so vm.swappiness here wins over"
		echo "# the value module_memory sets for zram."
		echo ""
		_tp_emit_sysctl "$profile"
	} > "$TP_SYSCTL_FILE"

	# Stale opposite-form keys: the kernel treats dirty_bytes and dirty_ratio as
	# mutually exclusive, and a previously applied profile may have set the form
	# this one does not use. Clearing is implicit -- writing either form zeroes
	# the other -- but a reload of every drop-in is what makes the result match
	# the file on disk rather than the union of everything applied this boot.
	sysctl --system > /dev/null 2>&1

	_tp_write_unit "$profile"
	systemctl daemon-reload > /dev/null 2>&1
	systemctl enable --now armbian-tuning-profile.service > /dev/null 2>&1

	{
		echo "# Active Armbian tuning profile. Managed by armbian-config."
		echo "PROFILE=${profile}"
		echo "APPLIED=$(date -Is)"
	} > "$TP_STATE_FILE"

	echo "Applied tuning profile: ${profile}"
	if _tp_root_is_ext4; then
		echo "  ext4 commit interval on / : ${commit}s"
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
			echo "Tuning profile removed; distribution defaults reloaded."
			echo "Note: the ext4 commit interval stays as it is until the next reboot."
			;;

		"${commands[5]}") # help
			show_module_help "module_tuning_profile" "$title"
			;;

		*)
			show_module_help "module_tuning_profile" "$title"
			;;
	esac
}
