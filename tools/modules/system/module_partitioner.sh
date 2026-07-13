# shellcheck shell=bash
# This is a sourced armbian-config module fragment, not a standalone script.
declare -A module_options
module_options+=(
	["module_partitioner,author"]="@igorpecovnik"
	["module_partitioner,maintainer"]="@igorpecovnik"
	["module_partitioner,feature"]="module_partitioner"
	["module_partitioner,example"]="run install detect plan help"
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
	local root_uuid root_part
	root_uuid=$(sed -e 's/^.*root=//' -e 's/ .*$//' </proc/cmdline)
	root_part=$(blkid | tr -d '":' | grep -w "${root_uuid#UUID=}" | awk '{print $1}' | head -1)
	[[ -z "$root_part" ]] && root_part=$(findmnt -no SOURCE / 2>/dev/null)
	lsblk -ndo pkname "$root_part" 2>/dev/null
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

# Boot modes that make sense for a given target role + firmware.
partitioner_modes_for() {
	local role="$1" disk="$2"
	if [[ -d /sys/firmware/efi ]]; then
		# Offer dual-boot first when an existing Windows/UEFI layout is present.
		if [[ -n "$disk" ]] && install_detect_windows "/dev/$disk" >/dev/null 2>&1; then
			echo "uefi-dualboot uefi"
		else
			echo "uefi"
		fi
		return
	fi
	case "$role" in
		mmc)          echo "emmc sd" ;;   # eMMC can host a full install or just root
		nvme|sata|usb) echo "sd" ;;       # boot stays on removable media, root here
		mtd)          echo "mtd" ;;
		ufs)          echo "ufs" ;;
		*)            echo "sd" ;;
	esac
}

partitioner_mode_desc() {
	case "$1" in
		uefi-dualboot) echo "Dual-boot: shrink Windows, install Armbian alongside it" ;;
		uefi) echo "UEFI install with GRUB (ERASES the disk)" ;;
		emmc) echo "Full install to this device (boot + system)" ;;
		sd)   echo "Keep boot on current media, system on this disk" ;;
		mtd)  echo "Boot from SPI/MTD flash, system on this disk" ;;
		ufs)  echo "Boot idblock on UFS boot LUN, system on UFS" ;;
		*)    echo "$1" ;;
	esac
}

# ---- interactive TUI --------------------------------------------------------

partitioner_tui() {
	local title="Armbian installer"
	INSTALL_LOG="/var/log/armbian-install.log"
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

	# 2) boot mode (dual-boot is offered when Windows is detected on the disk)
	local -a modes; read -r -a modes <<<"$(partitioner_modes_for "$disk_role" "$disk")"
	local boot
	if [[ "${#modes[@]}" -eq 1 ]]; then
		boot="${modes[0]}"
	else
		local -a mmenu=()
		for i in "${modes[@]}"; do mmenu+=("$i" "$(partitioner_mode_desc "$i")"); done
		boot=$(dialog_menu " $title " "\nChoose how /dev/$disk should boot:" 0 76 8 -- "${mmenu[@]}")
		[[ -z "$boot" ]] && return "$INSTALL_EX_OK"
	fi

	# 3) filesystem
	local fs
	fs=$(dialog_menu " $title " "\nRoot filesystem for /dev/$disk:" 0 60 6 -- \
		ext4 "Default, most compatible" \
		btrfs "Copy-on-write, compression, snapshots" \
		f2fs "Flash-friendly log-structured fs")
	[[ -z "$fs" ]] && return "$INSTALL_EX_OK"

	# 4) dual-boot needs a size; other modes erase the whole disk.
	local want_bytes=0
	if [[ "$boot" == uefi-dualboot ]]; then
		local gib
		gib=$(dialog_inputbox " $title " "\nGiB to give Armbian (taken by shrinking Windows):" "32")
		[[ "$gib" =~ ^[0-9]+$ && "$gib" -gt 0 ]] || { dialog_msgbox " $title " "\nInvalid size."; return "$INSTALL_EX_USAGE"; }
		want_bytes=$(( gib * 1024 * 1024 * 1024 ))
		if ! dialog_yesno " WARNING " "\nThis will SHRINK Windows on /dev/$disk and install Armbian ($fs, ${gib}GiB) alongside it.\n\nBack up first. Proceed?" "Shrink and install" "Cancel" 11 72; then
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
		else
			install_run_scenario "$boot" "/dev/$disk" "$fs" "$INSTALL_EXCLUDE"
		fi
		echo "$?" >"$rc_file"
	} | dialog_gauge " $title " "\nInstalling to /dev/$disk - please wait..." 10 74
	local rc; rc="$(cat "$rc_file")"; rm -f "$rc_file"

	if [[ "$rc" == "0" ]]; then
		dialog_msgbox " $title " "\nInstallation to /dev/$disk finished successfully.\n\nRemove the boot media (if applicable) and reboot."
	else
		dialog_msgbox " $title " "\nInstallation FAILED (code $rc).\n\nSee ${INSTALL_LOG:-the install log} for details."
	fi
	return "$rc"
}

# ---- non-interactive CLI ----------------------------------------------------

partitioner_cli_install() {
	# partitioner_cli_install --target /dev/X --boot MODE --fs FS [--size GiB] [--yes]
	local target="" boot="" fs="ext4" assume_yes=0 size_gib=0
	INSTALL_LOG="/var/log/armbian-install.log"
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--target) target="$2"; shift 2 ;;
			--boot)   boot="$2";   shift 2 ;;
			--fs)     fs="$2";     shift 2 ;;
			--size)   size_gib="$2"; shift 2 ;;
			--yes|-y) assume_yes=1; shift ;;
			*) echo "armbian-install: unknown argument '$1'" >&2; return "$INSTALL_EX_USAGE" ;;
		esac
	done

	[[ -b "$target" ]] || { echo "armbian-install: --target must be a block device" >&2; return "$INSTALL_EX_NODEV"; }
	case "$boot" in uefi|uefi-dualboot|emmc|sd|mtd|ufs) ;; *) echo "armbian-install: --boot must be one of uefi|uefi-dualboot|emmc|sd|mtd|ufs" >&2; return "$INSTALL_EX_USAGE" ;; esac
	case "$fs"   in ext4|btrfs|f2fs) ;;     *) echo "armbian-install: --fs must be one of ext4|btrfs|f2fs" >&2; return "$INSTALL_EX_USAGE" ;; esac
	[[ -f "$INSTALL_EXCLUDE" ]] || { echo "armbian-install: exclude list $INSTALL_EXCLUDE missing" >&2; return "$INSTALL_EX_TRANSFER"; }

	if [[ "$assume_yes" -ne 1 ]]; then
		echo "armbian-install: refusing to modify $target without --yes" >&2
		return "$INSTALL_EX_USAGE"
	fi

	if [[ "$boot" == uefi-dualboot ]]; then
		[[ "$size_gib" =~ ^[0-9]+$ && "$size_gib" -gt 0 ]] || { echo "armbian-install: --size <GiB> is required for uefi-dualboot" >&2; return "$INSTALL_EX_USAGE"; }
		echo "Installing Armbian alongside Windows on $target (${size_gib}GiB, $fs)..."
		install_run_dualboot "$target" "$fs" "$INSTALL_EXCLUDE" $(( size_gib * 1024 * 1024 * 1024 ))
	else
		echo "Installing Armbian to $target ($boot, $fs)..."
		install_run_scenario "$boot" "$target" "$fs" "$INSTALL_EXCLUDE"
	fi
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
	cat <<-EOF
	Armbian installer - transfer the running system to internal storage.

	Interactive:
	  armbian-install

	Non-interactive:
	  armbian-install --target /dev/sdX --boot <mode> --fs <fs> --yes
	    --boot   uefi | uefi-dualboot | emmc | sd | mtd | ufs
	    --fs     ext4 | btrfs | f2fs
	    --size   GiB for Armbian (uefi-dualboot only; shrinks Windows)
	    --yes    required to actually modify the target

	Dual-boot with Windows 10/11 (UEFI):
	  armbian-install --target /dev/sdX --boot uefi-dualboot --fs ext4 --size 32 --yes

	Machine-readable:
	  armbian-install --api detect
	  armbian-install --api plan --target /dev/sdX --boot uefi --fs ext4
	EOF
}

# ---- dispatch ---------------------------------------------------------------

module_partitioner() {
	# Source the board u-boot hooks so install_write_bootloader can find them.
	[[ -f /usr/lib/u-boot/platform_install.sh ]] && source /usr/lib/u-boot/platform_install.sh

	local commands
	IFS=' ' read -r -a commands <<<"${module_options["module_partitioner,example"]}"

	case "$1" in
		"${commands[0]}"|"")              # run (or bare invocation) -> TUI
			partitioner_tui ;;
		"${commands[1]}")                 # install -> non-interactive
			shift; partitioner_cli_install "$@" ;;
		"${commands[2]}")                 # detect -> engine inventory
			partitioner_api detect ;;
		"${commands[3]}")                 # plan -> engine planner
			shift; partitioner_api plan "$@" ;;
		"${commands[4]}"|-h|--help)       # help
			partitioner_help ;;
		--target)                         # bare flags from the shim -> CLI
			partitioner_cli_install "$@" ;;
		--api)                            # bare --api from the shim
			shift; partitioner_api "$@" ;;
		*)
			partitioner_help; return "$INSTALL_EX_USAGE" ;;
	esac
}
