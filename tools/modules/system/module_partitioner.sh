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
	local root_uuid root_part disk medium
	root_uuid=$(sed -e 's/^.*root=//' -e 's/ .*$//' </proc/cmdline)
	root_part=$(blkid | tr -d '":' | grep -w "${root_uuid#UUID=}" | awk '{print $1}' | head -1)
	[[ -z "$root_part" ]] && root_part=$(findmnt -no SOURCE / 2>/dev/null)
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
# device, and the FULL list is passed as the last argument. Implementations
# should accept both the "mtdblockN" and "mtdN:label" forms and pick the right
# partition(s) to flash from the full list.
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
				[[ "$(type -t write_uboot_platform_mtd)" == function && -n "$(partitioner_mtd_list)" ]] && m+=(mtd)
				m+=(sd)                       # keep boot on current media, root here
				# ...or from an internal eMMC (if present and not the target).
				local emmc; emmc="$(partitioner_emmc_device)"
				[[ -n "$emmc" && "/dev/$disk" != "$emmc" ]] && m+=(split-emmc)
				;;
			ufs)           m+=(ufs) ;;
		esac
	fi
	# x86 legacy BIOS: neither EFI firmware nor a u-boot board.
	if [[ ! -d /sys/firmware/efi && "$have_uboot" -eq 0 ]] && command -v grub-install >/dev/null 2>&1; then
		m+=(bios)
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
		sd)   echo "Keep boot on current media, system on this disk" ;;
		split-emmc) echo "Boot from eMMC, system on this disk (+ /emmc_storage)" ;;
		mtd)  echo "Boot from SPI/MTD flash, system on this disk" ;;
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
			--target) [[ $# -ge 2 ]] || { echo "armbian-install: --target requires a value" >&2; return "$INSTALL_EX_USAGE"; }; target="$2"; shift 2 ;;
			--boot)   [[ $# -ge 2 ]] || { echo "armbian-install: --boot requires a value" >&2; return "$INSTALL_EX_USAGE"; }; boot="$2"; shift 2 ;;
			--fs)     [[ $# -ge 2 ]] || { echo "armbian-install: --fs requires a value" >&2; return "$INSTALL_EX_USAGE"; }; fs="$2"; shift 2 ;;
			--size)   [[ $# -ge 2 ]] || { echo "armbian-install: --size requires a value" >&2; return "$INSTALL_EX_USAGE"; }; size_gib="$2"; shift 2 ;;
			--yes|-y) assume_yes=1; shift ;;
			*) echo "armbian-install: unknown argument '$1'" >&2; return "$INSTALL_EX_USAGE" ;;
		esac
	done

	[[ -b "$target" ]] || { echo "armbian-install: --target must be a block device" >&2; return "$INSTALL_EX_NODEV"; }
	case "$boot" in uefi|uefi-dualboot|bios|emmc|sd|mtd|ufs|split-emmc) ;; *) echo "armbian-install: --boot must be one of uefi|uefi-dualboot|bios|emmc|sd|mtd|ufs|split-emmc" >&2; return "$INSTALL_EX_USAGE" ;; esac
	case "$fs"   in ext4|btrfs|f2fs) ;;     *) echo "armbian-install: --fs must be one of ext4|btrfs|f2fs" >&2; return "$INSTALL_EX_USAGE" ;; esac
	[[ -f "$INSTALL_EXCLUDE" ]] || { echo "armbian-install: exclude list $INSTALL_EXCLUDE missing" >&2; return "$INSTALL_EX_TRANSFER"; }

	if [[ "$assume_yes" -ne 1 ]]; then
		echo "armbian-install: refusing to modify $target without --yes" >&2
		return "$INSTALL_EX_USAGE"
	fi
	if ! partitioner_ensure_fs_tool "$fs" 0; then
		echo "armbian-install: mkfs.$fs unavailable; install its package and retry" >&2
		return "$INSTALL_EX_TOOL"
	fi

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
		local emmc; emmc="$(partitioner_emmc_device)"
		[[ -n "$emmc" ]] || { echo "armbian-install: --boot split-emmc needs an eMMC, none detected" >&2; return "$INSTALL_EX_NODEV"; }
		[[ "$emmc" != "$target" ]] || { echo "armbian-install: --boot split-emmc target must differ from the eMMC ($emmc)" >&2; return "$INSTALL_EX_USAGE"; }
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
	    --boot   uefi | uefi-dualboot | bios | emmc | sd | mtd | ufs | split-emmc
	             split-emmc: boot from eMMC, root on --target (NVMe/SATA/USB),
	                         eMMC remainder mounted at /emmc_storage
	    --fs     ext4 | btrfs | f2fs
	    --size   GiB for Armbian (uefi-dualboot only; shrinks Windows)
	    --yes    required to actually modify the target

	Dual-boot with Windows 10/11 (UEFI):
	  armbian-install --target /dev/sdX --boot uefi-dualboot --fs ext4 --size 32 --yes

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
