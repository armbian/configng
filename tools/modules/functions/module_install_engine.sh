# shellcheck shell=bash
# This is a sourced armbian-config module fragment, not a standalone script.
declare -A module_options
module_options+=(
	["module_install_engine,author"]="@igorpecovnik"
	["module_install_engine,maintainer"]="@igorpecovnik"
	["module_install_engine,feature"]="module_install_engine"
	["module_install_engine,example"]="detect plan"
	["module_install_engine,desc"]="Armbian installer engine (backend library, no UI)"
	["module_install_engine,status"]="review"
	["module_install_engine,doc_link"]="https://docs.armbian.com"
	["module_install_engine,group"]="System"
	["module_install_engine,port"]=""
	["module_install_engine,arch"]=""
)

#
# module_install_engine.sh - armbian-install backend.
#
# Pure, dialog-free, individually testable functions. Every function takes its
# inputs as explicit arguments (or on stdin) and returns data on stdout or a
# status code - nothing reaches into ambient globals. The dialog frontend
# (module_partitioner.sh) and the non-interactive CLI both call into this file;
# the bats suite under tests/bats/ sources it directly and drives the pure
# functions with fixtures.
#
# Design notes / bugs this shape fixes:
#   * install_detect_targets emits one TAB-separated record per device and never
#     space-joins names -> multi-disk concatenation (build#8738).
#   * install_plan_layout is a pure function of (boot_mode, fs, uefi, capacity,
#     sector_size, has_swap); it selects GPT when uefi | >2TiB | 4Kn and emits
#     explicit ESP/boot flags -> MBR-only & missing-boot-flag installs
#     (build#9454, #9794, #6905).
#   * install_apply_partitions lays partitions in MiB units so alignment is
#     valid on both 512-byte and 4Kn media (build#9454).
#   * install_write_bootconfig always populates the target /boot and
#     install_verify refuses an empty /boot -> unbootable installs
#     (build#10099, #10064).
#

# ---- named exit codes (replace the old scattered magic numbers) -------------
readonly INSTALL_EX_OK=0
readonly INSTALL_EX_USAGE=64          # bad arguments
readonly INSTALL_EX_NODEV=65          # no / invalid target device
readonly INSTALL_EX_NOSPACE=66        # target too small
readonly INSTALL_EX_TOOL=67           # required tool / package missing
readonly INSTALL_EX_PARTITION=68      # partitioning failed
readonly INSTALL_EX_FORMAT=69         # mkfs failed
readonly INSTALL_EX_TRANSFER=70       # rootfs copy failed
readonly INSTALL_EX_BOOTCFG=71        # boot config / fstab rewrite failed
readonly INSTALL_EX_BOOTLOADER=72     # bootloader write failed
readonly INSTALL_EX_VERIFY=73         # post-install verification failed

# Log sink. Callers may point INSTALL_LOG at a file; defaults to stderr.
INSTALL_LOG="${INSTALL_LOG:-/dev/stderr}"

install_log() {
	# install_log <LEVEL> <message...>
	local level="$1"; shift
	printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo now)" "$level" "$*" >>"$INSTALL_LOG" 2>/dev/null || true
}

# ---- capacity / geometry helpers -------------------------------------------

# 2 TiB in bytes - the msdos/MBR addressing ceiling on 512-byte sectors.
readonly INSTALL_TWO_TIB=$(( 2 * 1024 * 1024 * 1024 * 1024 ))

install_table_type() {
	# install_table_type <is_uefi> <capacity_bytes> <sector_size>
	# GPT when firmware is UEFI, the disk is larger than the MBR ceiling, or the
	# medium is 4Kn; msdos otherwise. Pure - no device access.
	local is_uefi="$1" cap="${2:-0}" sec="${3:-512}"
	if [[ "$is_uefi" == "1" || "$is_uefi" == "uefi" ]] \
		|| (( cap > INSTALL_TWO_TIB )) \
		|| (( sec == 4096 )); then
		echo "gpt"
	else
		echo "msdos"
	fi
}

# ---- detection --------------------------------------------------------------

# Thin, overridable wrapper around lsblk so tests can inject fixtures.
_install_lsblk_raw() {
	lsblk -b -d -o NAME,TYPE,SIZE,PHY-SEC,TRAN,ROTA,MODEL --json 2>/dev/null
}

install_detect_targets() {
	# install_detect_targets [root_disk] [lsblk_json]
	# Emit one TAB-separated record per candidate whole disk:
	#   name <TAB> role <TAB> size_bytes <TAB> sector_size <TAB> bus <TAB> rota <TAB> model
	# role in {nvme,mmc,mtd,usb,sata,disk}. The disk hosting the running rootfs
	# (root_disk, a bare kernel name such as "mmcblk0") is excluded.
	local root_disk="${1:-}"
	local json="${2:-}"
	[[ -z "$json" ]] && json="$(_install_lsblk_raw)"
	[[ -z "$json" ]] && return "$INSTALL_EX_NODEV"

	# Note: empty fields are emitted as "-" (never ""), because a `read` loop with
	# IFS=$'\t' collapses consecutive tabs (tab is IFS-whitespace) and an empty
	# column would shift every field after it.
	echo "$json" | jq -r --arg root "$root_disk" '
		.blockdevices[]?
		| select(.type == "disk")
		| select(.name != $root)
		# Drop pseudo/virtual block devices that are never install targets:
		# zram (compressed RAM swap), ram disks, loop, optical (sr), floppy (fd),
		# and device-mapper (dm-) nodes.
		| select(.name | test("^(zram|ram|loop|sr|fd|dm-)[0-9-]") | not)
		| { n: .name, t: (.tran // ""), sz: (.size // 0),
		    ps: (."phy-sec" // 512), ro: (.rota // false), md: ((.model // "") | gsub("\t"; " ")) }
		| .role = ( if   (.n | test("^nvme"))     then "nvme"
		            elif (.n | test("^mmcblk"))   then "mmc"
		            elif (.n | test("^mtdblock")) then "mtd"
		            elif (.t == "usb")            then "usb"
		            elif (.t == "sata" or .t == "ata") then "sata"
		            else "disk" end )
		| [ .n, .role, (.sz|tostring), (.ps|tostring),
		    (if .t  == "" then "-" else .t  end),
		    (.ro|tostring),
		    (if .md == "" then "-" else .md end) ]
		| @tsv
	'
}

# ---- partition planning (pure) ---------------------------------------------

install_plan_layout() {
	# install_plan_layout <boot_mode> <fs> <is_uefi> <capacity_bytes> <sector_size> [has_swap]
	#
	# boot_mode: uefi | emmc | sd | mtd | ufs
	#   uefi  - full install to an internal disk with an ESP + GRUB
	#   emmc  - full self-contained install (boot + root) to eMMC/SD
	#   sd    - boot stays on removable media, only the rootfs lands on the target
	#   mtd   - boot lives in SPI/MTD flash, only the rootfs lands on the target
	#   ufs   - boot idblock on a UFS boot LUN, rootfs on the UFS general LUN
	#
	# Emits a declarative plan on stdout:
	#   table=gpt|msdos
	#   part=<role>:<size>:<fstype>:<flags>       (one line per partition, in order)
	# where size is an absolute "<N>MiB" or "100%" (fill), and flags is a
	# comma-separated subset of {esp,boot} ("" for none). Pure: no device I/O.
	local boot_mode="$1" fs="$2" is_uefi="$3" cap="${4:-0}" sec="${5:-512}" has_swap="${6:-0}"
	local table
	table="$(install_table_type "$is_uefi" "$cap" "$sec")"

	local -a parts=()
	case "$boot_mode" in
		uefi)
			# ESP is mandatory and the table is always GPT for UEFI.
			table="gpt"
			parts+=("esp:512MiB:vfat:esp,boot")
			parts+=("root:100%:${fs}:")
			;;
		bios)
			# x86 legacy BIOS install with GRUB (grub-pc). On GPT a 1MiB BIOS boot
			# partition is required for GRUB to embed core.img; on MBR it embeds in
			# the post-MBR gap, so the root partition just carries the boot flag.
			if [[ "$table" == "gpt" ]]; then
				parts+=("biosboot:1MiB::bios_grub")
				parts+=("root:100%:${fs}:")
			else
				parts+=("root:100%:${fs}:boot")
			fi
			;;
		emmc)
			if [[ "$fs" == "btrfs" || "$fs" == "f2fs" ]]; then
				# u-boot cannot read btrfs/f2fs -> a dedicated ext4 /boot.
				parts+=("boot:512MiB:ext4:boot")
				[[ "$has_swap" == "1" ]] && parts+=("swap:256MiB:swap:")
				parts+=("root:100%:${fs}:")
			else
				# ext4 keeps /boot as a directory on a single partition.
				parts+=("root:100%:ext4:boot")
			fi
			;;
		sd|mtd|ufs)
			# Only the rootfs lands here; boot lives elsewhere.
			parts+=("root:100%:${fs}:boot")
			;;
		*)
			install_log ERR "install_plan_layout: unknown boot mode '$boot_mode'"
			return "$INSTALL_EX_USAGE"
			;;
	esac

	echo "table=$table"
	local p
	for p in "${parts[@]}"; do
		echo "part=$p"
	done
}

# Map a logical filesystem to the hint parted understands (empty = let parted
# skip the type, e.g. f2fs which parted does not know about).
_install_parted_fs_hint() {
	case "$1" in
		vfat)  echo "fat32" ;;
		swap)  echo "linux-swap" ;;
		ext4)  echo "ext4" ;;
		btrfs) echo "btrfs" ;;
		*)     echo "" ;;
	esac
}

# ---- partitioning -----------------------------------------------------------

install_apply_partitions() {
	# install_apply_partitions <device> [plan]
	# Applies a plan (from arg or stdin) to <device> with parted, in MiB units so
	# alignment is correct on 512-byte and 4Kn media alike. Echoes one line per
	# created partition: "<role> <device_partition>" for the caller to consume.
	local device="$1"
	local plan="${2:-}"
	[[ -z "$plan" ]] && plan="$(cat)"
	[[ -b "$device" ]] || { install_log ERR "apply_partitions: '$device' is not a block device"; return "$INSTALL_EX_NODEV"; }

	local table="" ; local -a parts=()
	local line
	while IFS= read -r line; do
		case "$line" in
			table=*) table="${line#table=}" ;;
			part=*)  parts+=("${line#part=}") ;;
		esac
	done <<<"$plan"
	[[ -n "$table" && ${#parts[@]} -gt 0 ]] || { install_log ERR "apply_partitions: empty plan"; return "$INSTALL_EX_PARTITION"; }

	wipefs -aq "$device" >>"$INSTALL_LOG" 2>&1 || true
	dd if=/dev/zero of="$device" bs=1M count=10 conv=notrunc >>"$INSTALL_LOG" 2>&1 || true
	parted -s "$device" mklabel "$table" >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "apply_partitions: mklabel $table failed"; return "$INSTALL_EX_PARTITION"; }

	local start_mib=1 idx=0
	local spec role size fstype flags hint end
	for spec in "${parts[@]}"; do
		IFS=':' read -r role size fstype flags <<<"$spec"
		idx=$(( idx + 1 ))
		hint="$(_install_parted_fs_hint "$fstype")"
		if [[ "$size" == "100%" ]]; then
			end="100%"
		else
			# "<N>MiB" -> integer MiB, absolute end = start + N.
			end="$(( start_mib + ${size%MiB} ))MiB"
		fi
		# parted's fs-type hint is optional (e.g. f2fs is unknown) - build the
		# mkpart argv in an array so an empty hint drops out cleanly.
		local -a mkpart_args=(mkpart primary)
		[[ -n "$hint" ]] && mkpart_args+=("$hint")
		mkpart_args+=("${start_mib}MiB" "$end")
		parted -s -a optimal "$device" "${mkpart_args[@]}" >>"$INSTALL_LOG" 2>&1 \
			|| { install_log ERR "apply_partitions: mkpart $role failed"; return "$INSTALL_EX_PARTITION"; }

		# Flags are table-aware: on GPT parted aliases "boot" to the ESP flag, so
		# a plain bootable (non-ESP) partition must use legacy_boot instead.
		if [[ ",$flags," == *",esp,"* ]]; then
			parted -s "$device" set "$idx" esp on >>"$INSTALL_LOG" 2>&1 || true
		fi
		if [[ ",$flags," == *",boot,"* && ",$flags," != *",esp,"* ]]; then
			if [[ "$table" == "gpt" ]]; then
				parted -s "$device" set "$idx" legacy_boot on >>"$INSTALL_LOG" 2>&1 || true
			else
				parted -s "$device" set "$idx" boot on >>"$INSTALL_LOG" 2>&1 || true
			fi
		fi
		# BIOS boot partition on GPT: where GRUB embeds core.img (no filesystem).
		if [[ ",$flags," == *",bios_grub,"* ]]; then
			parted -s "$device" set "$idx" bios_grub on >>"$INSTALL_LOG" 2>&1 || true
		fi

		[[ "$size" != "100%" ]] && start_mib=$(( start_mib + ${size%MiB} ))
		echo "${role} $(_install_part_dev "$device" "$idx")"
	done

	partprobe "$device" >>"$INSTALL_LOG" 2>&1 || true
	udevadm settle >>"$INSTALL_LOG" 2>&1 || true
}

# Partition node naming: /dev/sda -> /dev/sda1 ; /dev/nvme0n1 -> /dev/nvme0n1p1.
_install_part_dev() {
	local dev="$1" n="$2"
	if [[ "$dev" =~ [0-9]$ ]]; then
		echo "${dev}p${n}"
	else
		echo "${dev}${n}"
	fi
}

# ---- filesystem creation ----------------------------------------------------

# Which package supplies mkfs.<fs>; empty for the always-present ones.
_install_fs_pkg() {
	case "$1" in
		btrfs) echo "btrfs-progs" ;;
		f2fs)  echo "f2fs-tools" ;;
		*)     echo "" ;;
	esac
}

install_check_fs_tools() {
	# install_check_fs_tools <fs> - returns 0 if mkfs.<fs> is present, else the
	# name of the package that provides it (on stdout) with a non-zero status.
	local fs="$1"
	command -v "mkfs.${fs}" >/dev/null 2>&1 && return 0
	_install_fs_pkg "$fs"
	return "$INSTALL_EX_TOOL"
}

install_fs_kernel_supported() {
	# install_fs_kernel_supported <fs> - true if the RUNNING kernel can mount it.
	# The mkfs tool can exist while the kernel lacks the driver (e.g. f2fs on a
	# cloud kernel): mkfs succeeds but the subsequent mount fails. Try to load the
	# module, then check /proc/filesystems.
	local fs="$1"
	case "$fs" in ext2|ext3|ext4|vfat|msdos) return 0 ;; esac   # always built in
	grep -qw "$fs" /proc/filesystems && return 0
	modprobe "$fs" >/dev/null 2>&1 || true
	grep -qw "$fs" /proc/filesystems
}

install_make_filesystems() {
	# install_make_filesystems <mapfile>
	# mapfile lines: "<role> <device_partition> <fstype>". Creates each fs after a
	# tool pre-flight; ext4 for mvebu drops the 64bit feature (ARMv7 u-boot).
	local map="$1"
	[[ -n "$map" ]] || { install_log ERR "make_filesystems: empty map"; return "$INSTALL_EX_FORMAT"; }
	local role dev fs
	local -a ext4_opts
	while read -r role dev fs; do
		[[ -n "$dev" && -n "$fs" ]] || continue
		if ! install_check_fs_tools "$fs" >/dev/null; then
			install_log ERR "make_filesystems: mkfs.$fs missing (install $(_install_fs_pkg "$fs"))"
			return "$INSTALL_EX_TOOL"
		fi
		case "$fs" in
			ext4)
				# ARMv7 mvebu u-boot cannot read the ext4 64bit feature.
				ext4_opts=(-qF)
				[[ "${LINUXFAMILY:-}" == "mvebu" ]] && ext4_opts=(-O '^64bit' -qF)
				mkfs.ext4 "${ext4_opts[@]}" "$dev" >>"$INSTALL_LOG" 2>&1 ;;
			vfat)  mkfs.vfat -F 32 "$dev" >>"$INSTALL_LOG" 2>&1 ;;
			btrfs) mkfs.btrfs -f "$dev" >>"$INSTALL_LOG" 2>&1 ;;
			f2fs)  mkfs.f2fs -f "$dev" >>"$INSTALL_LOG" 2>&1 ;;
			swap)  mkswap "$dev" >>"$INSTALL_LOG" 2>&1 ;;
			*)     install_log ERR "make_filesystems: unsupported fs '$fs'"; return "$INSTALL_EX_FORMAT" ;;
		esac || { install_log ERR "make_filesystems: mkfs.$fs on $dev failed"; return "$INSTALL_EX_FORMAT"; }
	done <<<"$map"
}

# ---- rootfs transfer --------------------------------------------------------

install_transfer_rootfs() {
	# install_transfer_rootfs <target_rootfs_mount> <exclude_file> [progress_fd]
	# rsync / -> target with the exclude list, emitting integer percentages to
	# progress_fd (default 1) for a gauge. Returns INSTALL_EX_TRANSFER on failure.
	# src defaults to "/" (the running rootfs); overridable for tests.
	# lo/hi scale the emitted percentage into a band, so the caller can reserve
	# the tail of the bar for the post-copy stages (grub, verify, ...).
	local dest="$1" exclude="$2" pfd="${3:-1}" src="${4:-/}" lo="${5:-0}" hi="${6:-100}"
	[[ -d "$dest" ]] || { install_log ERR "transfer: '$dest' is not a directory"; return "$INSTALL_EX_TRANSFER"; }
	[[ -f "$exclude" ]] || { install_log ERR "transfer: exclude file '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }

	# Track rsync's file-count progress (to-chk=REMAIN/TOTAL from --info=progress2)
	# rather than its byte percentage: for a rootfs (mostly small files) the byte
	# percentage rushes then crawls through the long small-file tail, while the
	# file count advances linearly. --no-inc-recursive fixes TOTAL up front so the
	# fraction is stable. progress2 rewrites its line with \r; split on \r.
	local rc_file; rc_file="$(mktemp)"
	{
		rsync -ax --delete --info=progress2 --no-inc-recursive --exclude-from="$exclude" "$src" "$dest" \
			| stdbuf -oL tr '\r' '\n' \
			| stdbuf -oL sed -u -n 's/.*to-chk=\([0-9]*\)\/\([0-9]*\).*/\1 \2/p' \
			| stdbuf -oL awk -v lo="$lo" -v hi="$hi" '
				{ if ($2 > 0) { p = lo + int((hi-lo)*($2-$1)/$2);
				                if (p > hi) p = hi;
				                if (p != last) { print p; fflush(); last = p } } }' >&"$pfd"
		echo "${PIPESTATUS[0]}" >"$rc_file"
	}
	local rc; rc="$(cat "$rc_file")"; rm -f "$rc_file"
	[[ "$rc" == "0" ]] || { install_log ERR "transfer: rsync exit $rc"; return "$INSTALL_EX_TRANSFER"; }

	# Second, quiet pass to catch files that changed during the first copy.
	rsync -ax --delete --exclude-from="$exclude" "$src" "$dest" >>"$INSTALL_LOG" 2>&1 || true
}

# ---- boot configuration -----------------------------------------------------

install_rewrite_bootenv() {
	# install_rewrite_bootenv <file> <rootdev> [rootfstype]
	# Rewrite an armbianEnv.txt-style key=value file to point at <rootdev>
	# (a "UUID=..." string or a device path) and, if given, <rootfstype>.
	# Idempotent: keys are updated in place or appended if absent. Pure text op.
	local file="$1" rootdev="$2" fstype="${3:-}"
	[[ -f "$file" ]] || return "$INSTALL_EX_BOOTCFG"
	if grep -q '^rootdev=' "$file"; then
		sed -i "s|^rootdev=.*|rootdev=${rootdev}|" "$file"
	else
		echo "rootdev=${rootdev}" >>"$file"
	fi
	if [[ -n "$fstype" ]]; then
		if grep -q '^rootfstype=' "$file"; then
			sed -i "s|^rootfstype=.*|rootfstype=${fstype}|" "$file"
		else
			echo "rootfstype=${fstype}" >>"$file"
		fi
	fi
}

install_gen_fstab() {
	# install_gen_fstab <root_uuid> <root_fs> [boot_uuid] [boot_fs] [esp_uuid]
	# Emit a fresh fstab on stdout. root_* required; boot_* optional (separate
	# /boot); esp_uuid optional (UEFI /boot/efi). Mirrors the mount option set
	# the image ships with.
	local root_uuid="$1" root_fs="$2" boot_uuid="${3:-}" boot_fs="${4:-ext4}" esp_uuid="${5:-}"
	local root_opts boot_opts
	case "$root_fs" in
		btrfs) root_opts="defaults,commit=120,compress=lzo,x-gvfs-hide,subvol=@	0	2" ;;
		f2fs)  root_opts="defaults,noatime,x-gvfs-hide	0	2" ;;
		*)     root_opts="defaults,noatime,commit=120,errors=remount-ro,x-gvfs-hide	0	1" ;;
	esac
	boot_opts="defaults,noatime,commit=120,errors=remount-ro,x-gvfs-hide	0	2"

	echo "# <file system>	<mount point>	<type>	<options>	<dump>	<pass>"
	echo "tmpfs	/tmp	tmpfs	defaults,nosuid	0	0"
	echo "${root_uuid}	/	${root_fs}	${root_opts}"
	[[ -n "$boot_uuid" ]] && echo "${boot_uuid}	/boot	${boot_fs}	${boot_opts}"
	[[ -n "$esp_uuid" ]]  && echo "${esp_uuid}	/boot/efi	vfat	defaults	0	2"
	return 0
}

install_populate_boot() {
	# install_populate_boot <target_rootfs_mount> [copy:0|1] [src]
	# Sync the running /boot into the target's /boot. The main rootfs rsync
	# excludes /boot, so this is what actually places the kernel/dtb/boot script -
	# onto a separate boot partition if one is mounted at <rootfs>/boot, otherwise
	# into the rootfs itself. copy=0 leaves /boot empty (ARM "sd" mode: boot stays
	# on the removable media). Guard against build#10099 (empty /boot).
	local rootfs="$1" copy="${2:-1}" src="${3:-/boot}"
	[[ -d "$rootfs" ]] || { install_log ERR "populate_boot: rootfs '$rootfs' missing"; return "$INSTALL_EX_BOOTCFG"; }
	mkdir -p "$rootfs/boot"
	[[ "$copy" == "1" ]] || return 0
	# No -x here: on ARM /boot is often a separate mount, and one-filesystem would
	# skip its contents. Exclude a mounted ESP (that is handled separately).
	rsync -aq --exclude 'efi/**' "$src"/ "$rootfs/boot"/ >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "populate_boot: copy $src -> $rootfs/boot failed"; return "$INSTALL_EX_BOOTCFG"; }
	return 0
}

# ---- verification -----------------------------------------------------------

install_verify_boot_dir() {
	# install_verify_boot_dir <boot_dir>
	# Assert the directory holds something u-boot/GRUB can actually boot:
	# a kernel image AND a boot script/config. build#10099/#6905 guard.
	local d="$1"
	[[ -d "$d" ]] || { install_log ERR "verify: boot dir '$d' missing"; return "$INSTALL_EX_VERIFY"; }
	local have_kernel=0 have_script=0
	compgen -G "$d/vmlinu*" >/dev/null 2>&1 && have_kernel=1
	compgen -G "$d/Image*"  >/dev/null 2>&1 && have_kernel=1
	compgen -G "$d/zImage*" >/dev/null 2>&1 && have_kernel=1
	compgen -G "$d/uImage*" >/dev/null 2>&1 && have_kernel=1
	[[ -f "$d/boot.scr" || -f "$d/boot.cmd" || -f "$d/extlinux/extlinux.conf" || -d "$d/grub" ]] && have_script=1
	if (( have_kernel == 0 || have_script == 0 )); then
		install_log ERR "verify: '$d' is not bootable (kernel=$have_kernel script=$have_script)"
		return "$INSTALL_EX_VERIFY"
	fi
	return 0
}

install_verify_fstab() {
	# install_verify_fstab <fstab_file>
	# Every UUID= referenced must resolve to a real device (blkid). Catches a
	# root/boot UUID that was never written or points at the wrong partition.
	local fstab="$1"
	[[ -f "$fstab" ]] || { install_log ERR "verify: fstab '$fstab' missing"; return "$INSTALL_EX_VERIFY"; }
	local uuid rc=0
	while read -r uuid; do
		[[ -n "$uuid" ]] || continue
		if ! blkid -U "$uuid" >/dev/null 2>&1; then
			install_log ERR "verify: fstab UUID $uuid does not resolve"
			rc="$INSTALL_EX_VERIFY"
		fi
	done < <(grep -oE 'UUID=[0-9A-Fa-f-]+' "$fstab" | cut -d= -f2)
	return "$rc"
}

# ---- bootloader -------------------------------------------------------------

install_bootloader_available() {
	# install_bootloader_available <boot_mode>
	# True if the bootloader method for this mode can actually run on this system.
	# Called BEFORE any destructive step so we never wipe a disk we can't make
	# bootable (e.g. a u-boot mode on x86, which has no write_uboot_platform).
	case "$1" in
		uefi|uefi-dualboot|bios) command -v grub-install >/dev/null 2>&1 ;;
		emmc|sd) [[ "$(type -t write_uboot_platform)" == function ]] ;;
		mtd)     [[ "$(type -t write_uboot_platform_mtd)" == function ]] ;;
		ufs)     [[ "$(type -t write_uboot_platform_ufs)" == function ]] ;;
		*)       return 1 ;;
	esac
}

install_write_bootloader() {
	# install_write_bootloader <boot_mode> <target_disk> <rootfs_mount> [uboot_dir] [mtd_list] [ufs_boot_lun]
	# Dispatches to the board-provided u-boot hooks (sourced at runtime from
	# /usr/lib/u-boot/platform_install.sh) or GRUB for UEFI. Returns
	# INSTALL_EX_BOOTLOADER on failure.
	local boot_mode="$1" disk="$2" rootfs="$3" uboot_dir="${4:-${DIR:-}}" mtd_list="${5:-}" ufs_boot="${6:-}"
	case "$boot_mode" in
		uefi)
			install_grub_install "$rootfs" solo ;;
		bios)
			install_grub_install "$rootfs" bios "$disk" ;;
		mtd)
			[[ "$(type -t write_uboot_platform_mtd)" == function ]] || { install_log ERR "bootloader: write_uboot_platform_mtd missing"; return "$INSTALL_EX_BOOTLOADER"; }
			write_uboot_platform_mtd "$uboot_dir" "/dev/${mtd_list%% *}" "$INSTALL_LOG" "$mtd_list" \
				|| { install_log ERR "bootloader: MTD write failed"; return "$INSTALL_EX_BOOTLOADER"; } ;;
		ufs)
			[[ "$(type -t write_uboot_platform_ufs)" == function ]] || { install_log ERR "bootloader: write_uboot_platform_ufs missing"; return "$INSTALL_EX_BOOTLOADER"; }
			write_uboot_platform_ufs "$uboot_dir" "$ufs_boot" "$disk" \
				|| { install_log ERR "bootloader: UFS write failed"; return "$INSTALL_EX_BOOTLOADER"; } ;;
		emmc|sd)
			[[ "$(type -t write_uboot_platform)" == function ]] || { install_log ERR "bootloader: write_uboot_platform missing"; return "$INSTALL_EX_BOOTLOADER"; }
			write_uboot_platform "$uboot_dir" "$disk" \
				|| { install_log ERR "bootloader: u-boot write to $disk failed"; return "$INSTALL_EX_BOOTLOADER"; } ;;
		*)
			install_log ERR "bootloader: unknown boot mode '$boot_mode'"; return "$INSTALL_EX_USAGE" ;;
	esac
}

install_grub_install() {
	# install_grub_install <rootfs_mount> [mode] [disk]
	# Bind-mount /dev,/proc,/sys and run grub-install + grub-mkconfig in the
	# target.
	#   mode=solo     (default) sole-OS UEFI install: --removable, so it boots
	#                 even without a working NVRAM entry (typical for wiped disks).
	#                 The ESP must already be mounted at <rootfs>/boot/efi.
	#   mode=dualboot keep an existing OS (Windows): NO --removable (leave the
	#                 /EFI/BOOT fallback alone) and turn on os-prober so the
	#                 GRUB menu offers the other OS. ESP mounted at /boot/efi.
	#   mode=bios     x86 legacy BIOS: grub-pc to <disk>'s MBR, no ESP.
	local rootfs="$1" mode="${2:-solo}" disk="${3:-}" arch_target grub_cmd
	if [[ "$mode" == bios ]]; then
		[[ -b "$disk" ]] || { install_log ERR "grub: bios install needs a disk"; return "$INSTALL_EX_BOOTLOADER"; }
		grub_cmd="grub-install --target=i386-pc --recheck $disk"
	else
		mountpoint -q "$rootfs/boot/efi" || { install_log ERR "grub: ESP not mounted at $rootfs/boot/efi"; return "$INSTALL_EX_BOOTLOADER"; }
		arch_target=$([[ "$(arch)" == x86_64 ]] && echo "x86_64-efi" || echo "arm64-efi")
		grub_cmd="grub-install --target=$arch_target --efi-directory=/boot/efi --bootloader-id=Armbian"
		if [[ "$mode" == dualboot ]]; then
			install_enable_os_prober "$rootfs"
		else
			grub_cmd+=" --removable"
		fi
	fi
	mkdir -p "$rootfs"/{dev,proc,sys}
	mount --bind /dev "$rootfs/dev"
	mount --make-rslave --bind /dev/pts "$rootfs/dev/pts"
	mount --bind /proc "$rootfs/proc"
	mount --make-rslave --rbind /sys "$rootfs/sys"
	local rc=0
	chroot "$rootfs" /bin/bash -c "$grub_cmd" >>"$INSTALL_LOG" 2>&1 || rc=1
	chroot "$rootfs" /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" >>"$INSTALL_LOG" 2>&1 || rc=1
	# Unwind the API mounts regardless of outcome.
	awk -v r="$rootfs/sys" '$2 ~ "^"r {print $2}' /proc/mounts | sort -r | xargs -r umount -n 2>/dev/null
	umount "$rootfs/proc" 2>/dev/null
	umount "$rootfs/dev/pts" 2>/dev/null
	umount "$rootfs/dev" 2>/dev/null
	[[ "$rc" == 0 ]] || { install_log ERR "grub: install failed"; return "$INSTALL_EX_BOOTLOADER"; }
}

install_enable_os_prober() {
	# install_enable_os_prober <rootfs_mount>
	# Make grub-mkconfig scan for other operating systems (Windows). GRUB 2.06+
	# disables os-prober by default; re-enable it via the armbian drop-in.
	local rootfs="$1"
	mkdir -p "$rootfs/etc/default/grub.d"
	echo "GRUB_DISABLE_OS_PROBER=false" >>"$rootfs/etc/default/grub.d/98-armbian.cfg"
	command -v os-prober >/dev/null 2>&1 || chroot "$rootfs" /bin/bash -c "command -v os-prober" >/dev/null 2>&1 \
		|| install_log WARN "os-prober not present in target; Windows may be missing from the GRUB menu"
}

# ---- Windows dual-boot ------------------------------------------------------

install_detect_windows() {
	# install_detect_windows <disk>
	# On a GPT disk carrying a Windows install, emit:
	#   esp=<esp_partition>          existing EFI System Partition (reused)
	#   windows=<ntfs_partition>     the largest NTFS (Microsoft basic data) part
	# Returns INSTALL_EX_NODEV if the disk is not a Windows/UEFI layout.
	local disk="$1"
	[[ -b "$disk" ]] || return "$INSTALL_EX_NODEV"
	# GPT is required for a UEFI Windows install.
	parted -sm "$disk" print 2>/dev/null | grep -q '^/dev/.*:gpt:' || return "$INSTALL_EX_NODEV"

	local json esp win
	json="$(lsblk -b -po NAME,FSTYPE,PARTTYPENAME,SIZE --json "$disk" 2>/dev/null)"
	esp="$(echo "$json" | jq -r '
		[.blockdevices[]?.children[]?
		 | select(((.parttypename // "") | test("EFI";"i")) or (.fstype == "vfat"))
		 | .name] | first // empty')"
	win="$(echo "$json" | jq -r '
		[.blockdevices[]?.children[]?
		 | select(.fstype == "ntfs")]
		 | sort_by(.size) | reverse | (.[0].name // empty)')"
	[[ -n "$esp" && -n "$win" ]] || { install_log ERR "detect_windows: no ESP+NTFS pair on $disk"; return "$INSTALL_EX_NODEV"; }
	echo "esp=$esp"
	echo "windows=$win"
}

install_windows_min_bytes() {
	# install_windows_min_bytes <ntfs_partition>
	# Smallest size ntfsresize will shrink the volume to, in bytes (0 on failure).
	local dev="$1" out
	out="$(ntfsresize -f --info "$dev" 2>/dev/null \
		| grep -iE 'You might resize' | grep -oE '[0-9]+ bytes' | grep -oE '[0-9]+' | head -1)"
	[[ -z "$out" ]] && out="$(ntfsresize -f --info "$dev" 2>/dev/null \
		| awk -F'[:(]' '/[Cc]urrent volume size/ {gsub(/[^0-9]/,"",$2); print $2; exit}')"
	echo "${out:-0}"
}

install_dualboot_plan() {
	# install_dualboot_plan <win_size_bytes> <win_min_bytes> <tail_free_bytes> <want_bytes>
	# Pure: decide how small Windows must become to free <want_bytes> for Armbian,
	# keeping a safety margin above the NTFS minimum. Echoes "shrink_to=<bytes>"
	# (the new Windows size) or fails with INSTALL_EX_NOSPACE if it will not fit.
	local wsize="$1" wmin="$2" tail="${3:-0}" want="$4"
	local margin=$(( 8 * 1024 * 1024 * 1024 ))          # keep >=8GiB above the ntfs min
	local shrinkable=$(( wsize - (wmin + margin) ))
	(( shrinkable < 0 )) && shrinkable=0
	local avail=$(( shrinkable + tail ))
	if (( want > avail )); then
		install_log ERR "dualboot: need $want bytes but only $avail free (shrinkable=$shrinkable, tail=$tail)"
		return "$INSTALL_EX_NOSPACE"
	fi
	# Use any existing free tail first, only then eat into Windows.
	local from_win=0
	(( want > tail )) && from_win=$(( want - tail ))
	echo "shrink_to=$(( wsize - from_win ))"
}

install_shrink_windows() {
	# install_shrink_windows <disk> <windows_partition> <new_size_bytes>
	# Shrink the NTFS filesystem, then pull the GPT partition end in to match.
	# The volume must be clean (run chkdsk in Windows first) or ntfsresize aborts.
	local disk="$1" win="$2" new_bytes="$3"
	# Feed the "Are you sure?" answer with a here-string, NOT `yes |`: an infinite
	# `yes` producer dies of SIGPIPE when ntfsresize exits, which under a caller's
	# `set -o pipefail` would mask ntfsresize's real (successful) exit code.
	ntfsresize -f --size "$new_bytes" "$win" <<<'y' >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "shrink: ntfsresize of $win to $new_bytes failed (is the volume clean? boot Windows and disable Fast Startup / run chkdsk)"; return "$INSTALL_EX_PARTITION"; }

	local pnum start_b new_end_b
	pnum="$(grep -oE '[0-9]+$' <<<"$win")"
	start_b="$(parted -sm "$disk" unit B print 2>/dev/null | awk -F: -v p="$pnum" '$1==p {gsub("B","",$2); print $2}')"
	[[ -n "$start_b" ]] || { install_log ERR "shrink: cannot read start of partition $pnum"; return "$INSTALL_EX_PARTITION"; }
	# Leave 16MiB slack so the partition end sits safely past the shrunk fs.
	new_end_b=$(( start_b + new_bytes + 16 * 1024 * 1024 ))
	# parted refuses to shrink a partition non-interactively even with --script;
	# ---pretend-input-tty lets us answer its "are you sure?" prompt with "Yes".
	printf 'Yes\n' | parted ---pretend-input-tty "$disk" unit B resizepart "$pnum" "${new_end_b}B" >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "shrink: resizepart $pnum to ${new_end_b}B failed"; return "$INSTALL_EX_PARTITION"; }
	partprobe "$disk" >>"$INSTALL_LOG" 2>&1 || true
	udevadm settle >>"$INSTALL_LOG" 2>&1 || true
}

install_create_free_partition() {
	# install_create_free_partition <disk> <fs>
	# Create one partition filling the largest free region and echo its device.
	# Does NOT relabel or wipe - existing partitions are preserved.
	local disk="$1" fs="$2" hint
	hint="$(_install_parted_fs_hint "$fs")"
	# Largest free block (MiB) from parted's free-space report.
	local fstart fend fsize best_start="" best_size=0 line
	while IFS=: read -r _ fstart fend fsize _; do
		[[ "$fsize" == *MiB ]] || continue
		local s="${fstart%MiB}" z="${fsize%MiB}"
		s="${s%.*}"; z="${z%.*}"
		if (( z > best_size )); then best_size="$z"; best_start="$s"; fi
	done < <(parted -sm "$disk" unit MiB print free 2>/dev/null | grep ':free;$')
	[[ -n "$best_start" ]] || { install_log ERR "create_free: no free space on $disk"; return "$INSTALL_EX_NOSPACE"; }

	local -a mkpart_args=(mkpart primary)
	[[ -n "$hint" ]] && mkpart_args+=("$hint")
	mkpart_args+=("${best_start}MiB" "100%")
	# ---pretend-input-tty + "Yes" accepts parted's alignment adjustment
	# ("the closest location we can manage is ...") which --script would reject.
	printf 'Yes\n' | parted ---pretend-input-tty -a optimal "$disk" unit MiB "${mkpart_args[@]}" >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "create_free: mkpart failed"; return "$INSTALL_EX_PARTITION"; }
	partprobe "$disk" >>"$INSTALL_LOG" 2>&1 || true
	udevadm settle >>"$INSTALL_LOG" 2>&1 || true

	# The new partition is the highest-numbered one.
	local newnum
	newnum="$(parted -sm "$disk" print 2>/dev/null | awk -F: '/^[0-9]/ {n=$1} END{print n}')"
	echo "$(_install_part_dev "$disk" "$newnum")"
}

# ---- orchestration ----------------------------------------------------------

install_uuid() {
	# install_uuid <device_partition> -> "UUID=<uuid>" (empty on failure)
	local u; u="$(blkid -s UUID -o value "$1" 2>/dev/null)"
	[[ -n "$u" ]] && echo "UUID=$u"
}

install_run_scenario() {
	# install_run_scenario <boot_mode> <target_disk> <fs> <exclude_file> [uboot_dir]
	#
	# The single entrypoint shared by the dialog TUI and the non-interactive CLI.
	# Composes the tested primitives (plan -> apply -> mkfs -> transfer -> boot
	# config -> bootloader -> verify) for one target. Side-effecting; validated by
	# the loopback integration test and by board/KVM smoke before rollout.
	local boot_mode="$1" disk="$2" fs="$3" exclude="$4" uboot_dir="${5:-${DIR:-}}"
	# Deterministic tool output (parted/blkid flag names etc. are localised).
	# The scenario is a terminal operation, so exporting here is fine.
	export LC_ALL=C LANG=C
	[[ -b "$disk" ]] || { install_log ERR "scenario: '$disk' is not a block device"; return "$INSTALL_EX_NODEV"; }
	[[ -f "$exclude" ]] || { install_log ERR "scenario: exclude file '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }
	# Pre-flight: confirm we can make the target bootable AND format it BEFORE
	# wiping anything - never destroy a disk we cannot finish installing to.
	install_bootloader_available "$boot_mode" \
		|| { install_log ERR "scenario: no bootloader method for '$boot_mode' on this system (u-boot hooks or grub-install missing) - refusing to modify $disk"; return "$INSTALL_EX_BOOTLOADER"; }
	install_check_fs_tools "$fs" >/dev/null \
		|| { install_log ERR "scenario: mkfs.$fs not installed (need $(_install_fs_pkg "$fs")) - refusing to modify $disk"; return "$INSTALL_EX_TOOL"; }
	install_fs_kernel_supported "$fs" \
		|| { install_log ERR "scenario: running kernel cannot mount $fs (no driver) - refusing to modify $disk"; return "$INSTALL_EX_TOOL"; }

	# Geometry + firmware context feed the pure planner.
	local cap sec is_uefi=0 has_swap=0
	cap="$(blockdev --getsize64 "$disk" 2>/dev/null || echo 0)"
	sec="$(cat "/sys/block/$(basename "$disk")/queue/physical_block_size" 2>/dev/null || echo 512)"
	[[ "$boot_mode" == uefi ]] && is_uefi=1
	grep -q swap /etc/fstab 2>/dev/null && has_swap=1

	local plan; plan="$(install_plan_layout "$boot_mode" "$fs" "$is_uefi" "$cap" "$sec" "$has_swap")" \
		|| { install_log ERR "scenario: planning failed"; return "$INSTALL_EX_PARTITION"; }
	install_log INFO "scenario: $boot_mode on $disk (${cap}B, ${sec}B sectors) fs=$fs"$'\n'"$plan"

	# Partition, then build the mkfs map + remember the role->device mapping.
	local partmap; partmap="$(install_apply_partitions "$disk" "$plan")" || return "$INSTALL_EX_PARTITION"
	local esp_dev="" boot_dev="" root_dev="" swap_dev="" role dev
	local mkfs_map=""
	while read -r role dev; do
		[[ -n "$dev" ]] || continue
		case "$role" in
			esp)  esp_dev="$dev";  mkfs_map+="esp $dev vfat"$'\n' ;;
			boot) boot_dev="$dev"; mkfs_map+="boot $dev ext4"$'\n' ;;
			swap) swap_dev="$dev"; mkfs_map+="swap $dev swap"$'\n' ;;
			root) root_dev="$dev"; mkfs_map+="root $dev $fs"$'\n' ;;
		esac
	done <<<"$partmap"
	[[ -b "$root_dev" ]] || { install_log ERR "scenario: no root partition created"; return "$INSTALL_EX_PARTITION"; }
	install_make_filesystems "$mkfs_map" || return "$INSTALL_EX_FORMAT"

	# The shipped exclude list drops /boot from the main rootfs rsync (it belongs
	# on its own partition/tree, synced separately below). /boot is populated into
	# the target unless boot stays on the removable media (classic ARM "sd" mode).
	local copy_boot=1
	[[ "$boot_mode" == sd ]] && copy_boot=0

	# Mount the freshly-formatted target.
	local mp; mp="$(mktemp -d /mnt/armbian-install.XXXXXX)" || return "$INSTALL_EX_TRANSFER"
	mount "$root_dev" "$mp" || { install_log ERR "scenario: mount root failed"; rmdir "$mp"; return "$INSTALL_EX_TRANSFER"; }
	# A separate boot partition mounts at /boot; /boot is then synced onto it.
	if [[ -n "$boot_dev" ]]; then mkdir -p "$mp/boot"; mount "$boot_dev" "$mp/boot"; fi
	if [[ -n "$esp_dev" ]]; then mkdir -p "$mp/boot/efi"; fi

	# One-shot loop so a failing step can `break` straight to teardown. The bar is
	# staged: rsync fills 0-90, the remaining steps advance it to 100 so it never
	# freezes at ~90% during /boot sync, grub-install and verification.
	local rc=0
	while :; do
		install_transfer_rootfs "$mp" "$exclude" 1 / 0 90 || { rc=$INSTALL_EX_TRANSFER; break; }
		echo 92
		install_populate_boot "$mp" "$copy_boot" || { rc=$INSTALL_EX_BOOTCFG; break; }

		# fstab from the real, freshly-created UUIDs.
		local root_uuid boot_uuid="" esp_uuid=""
		root_uuid="$(install_uuid "$root_dev")"
		[[ -n "$boot_dev" ]] && boot_uuid="$(install_uuid "$boot_dev")"
		[[ -n "$esp_dev" ]]  && esp_uuid="$(install_uuid "$esp_dev")"
		install_gen_fstab "$root_uuid" "$fs" "$boot_uuid" ext4 "$esp_uuid" >"$mp/etc/fstab" \
			|| { rc=$INSTALL_EX_BOOTCFG; break; }
		grep -q '^tmpfs.*swap' /etc/fstab 2>/dev/null && grep swap /etc/fstab >>"$mp/etc/fstab"

		# Point the board's boot env at the new root (u-boot scenarios only; GRUB
		# modes are handled by grub-mkconfig).
		case "$boot_mode" in
			emmc|sd|mtd|ufs)
				local env_file="$mp/boot/armbianEnv.txt"
				[[ -f "$env_file" ]] && install_rewrite_bootenv "$env_file" "$root_uuid" "$fs" ;;
		esac

		echo 95
		# ESP must be mounted before GRUB runs.
		[[ -n "$esp_dev" ]] && { mount "$esp_dev" "$mp/boot/efi" || { rc=$INSTALL_EX_BOOTLOADER; break; }; }
		install_write_bootloader "$boot_mode" "$disk" "$mp" "$uboot_dir" "${INSTALL_MTD_LIST:-}" "${INSTALL_UFS_BOOT_LUN:-}" \
			|| { rc=$INSTALL_EX_BOOTLOADER; break; }

		echo 99
		# Refuse to declare success on an unbootable result. (sd mode boots from
		# the removable media, so the target has no local /boot to verify.)
		[[ "$copy_boot" == 1 ]] && { install_verify_boot_dir "$mp/boot" || { rc=$INSTALL_EX_VERIFY; break; }; }
		install_verify_fstab "$mp/etc/fstab" || { rc=$INSTALL_EX_VERIFY; break; }
		echo 100
		break
	done 2>>"$INSTALL_LOG"

	# Teardown (best effort).
	sync
	mountpoint -q "$mp/boot/efi" && umount "$mp/boot/efi" 2>/dev/null
	mountpoint -q "$mp/boot" && umount "$mp/boot" 2>/dev/null
	umount "$mp" 2>/dev/null
	rmdir "$mp" 2>/dev/null

	[[ "$rc" == 0 ]] && install_log INFO "scenario: $boot_mode install to $disk completed"
	return "$rc"
}

install_run_dualboot() {
	# install_run_dualboot <disk> <fs> <exclude_file> <armbian_bytes> [uboot_dir]
	#
	# Non-destructive UEFI install alongside Windows: shrink the NTFS volume,
	# create an Armbian partition in the freed tail, reuse the existing Windows
	# ESP, and set up GRUB + os-prober dual-boot. The disk keeps its partition
	# table and every existing partition.
	local disk="$1" fs="$2" exclude="$3" want="$4"
	export LC_ALL=C LANG=C
	[[ -b "$disk" ]] || { install_log ERR "dualboot: '$disk' not a block device"; return "$INSTALL_EX_NODEV"; }
	[[ -f "$exclude" ]] || { install_log ERR "dualboot: exclude '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }
	[[ "$want" =~ ^[0-9]+$ && "$want" -gt 0 ]] || { install_log ERR "dualboot: bad size '$want'"; return "$INSTALL_EX_USAGE"; }
	command -v ntfsresize >/dev/null 2>&1 || { install_log ERR "dualboot: ntfsresize missing - install the ntfs-3g package"; return "$INSTALL_EX_TOOL"; }
	install_check_fs_tools "$fs" >/dev/null || { install_log ERR "dualboot: mkfs.$fs not installed (need $(_install_fs_pkg "$fs")) - refusing to modify $disk"; return "$INSTALL_EX_TOOL"; }
	install_fs_kernel_supported "$fs" || { install_log ERR "dualboot: running kernel cannot mount $fs (no driver) - refusing to modify $disk"; return "$INSTALL_EX_TOOL"; }
	command -v grub-install >/dev/null 2>&1 || { install_log ERR "dualboot: grub-install missing - refusing to modify $disk"; return "$INSTALL_EX_BOOTLOADER"; }

	# 1) locate the existing Windows ESP + NTFS volume (nothing is touched yet).
	local wi esp win
	wi="$(install_detect_windows "$disk")" || { install_log ERR "dualboot: no Windows/UEFI layout on $disk"; return "$INSTALL_EX_NODEV"; }
	esp="$(sed -n 's/^esp=//p' <<<"$wi")"
	win="$(sed -n 's/^windows=//p' <<<"$wi")"
	install_log INFO "dualboot: ESP=$esp Windows=$win on $disk"

	# 2) plan how far to shrink Windows to free <want> bytes.
	local wsize wmin new_win plan
	wsize="$(blockdev --getsize64 "$win")"
	wmin="$(install_windows_min_bytes "$win")"
	plan="$(install_dualboot_plan "$wsize" "$wmin" 0 "$want")" || return "$INSTALL_EX_NOSPACE"
	new_win="$(sed -n 's/^shrink_to=//p' <<<"$plan")"

	# 3) shrink Windows (only if we must eat into it).
	if (( new_win < wsize )); then
		install_shrink_windows "$disk" "$win" "$new_win" || return "$INSTALL_EX_PARTITION"
	fi

	# 4) create + format the Armbian partition in the freed tail.
	local root_dev
	root_dev="$(install_create_free_partition "$disk" "$fs")" || return "$INSTALL_EX_PARTITION"
	[[ -b "$root_dev" ]] || { install_log ERR "dualboot: new partition '$root_dev' missing"; return "$INSTALL_EX_PARTITION"; }
	install_make_filesystems "root $root_dev $fs" || return "$INSTALL_EX_FORMAT"

	# 5) install into it, reusing the existing ESP for GRUB.
	local mp rc=0
	mp="$(mktemp -d /mnt/armbian-install.XXXXXX)" || return "$INSTALL_EX_TRANSFER"
	mount "$root_dev" "$mp" || { install_log ERR "dualboot: mount root failed"; rmdir "$mp"; return "$INSTALL_EX_TRANSFER"; }
	mkdir -p "$mp/boot/efi"
	while :; do
		install_transfer_rootfs "$mp" "$exclude" 1 / 0 90 || { rc=$INSTALL_EX_TRANSFER; break; }
		echo 92
		install_populate_boot "$mp" || { rc=$INSTALL_EX_BOOTCFG; break; }
		local root_uuid esp_uuid
		root_uuid="$(install_uuid "$root_dev")"
		esp_uuid="$(install_uuid "$esp")"
		install_gen_fstab "$root_uuid" "$fs" "" ext4 "$esp_uuid" >"$mp/etc/fstab" || { rc=$INSTALL_EX_BOOTCFG; break; }
		echo 95
		mount "$esp" "$mp/boot/efi" || { install_log ERR "dualboot: mount ESP failed"; rc=$INSTALL_EX_BOOTLOADER; break; }
		install_grub_install "$mp" dualboot || { rc=$INSTALL_EX_BOOTLOADER; break; }
		echo 99
		install_verify_boot_dir "$mp/boot" || { rc=$INSTALL_EX_VERIFY; break; }
		install_verify_fstab "$mp/etc/fstab" || { rc=$INSTALL_EX_VERIFY; break; }
		# The Windows volume must have survived intact.
		[[ "$(blkid -s TYPE -o value "$win")" == ntfs ]] || { install_log ERR "dualboot: Windows NTFS vanished after install"; rc=$INSTALL_EX_VERIFY; break; }
		echo 100
		break
	done 2>>"$INSTALL_LOG"

	sync
	mountpoint -q "$mp/boot/efi" && umount "$mp/boot/efi" 2>/dev/null
	umount "$mp" 2>/dev/null
	rmdir "$mp" 2>/dev/null
	[[ "$rc" == 0 ]] && install_log INFO "dualboot: Armbian installed alongside Windows on $disk"
	return "$rc"
}

# ---- entrypoint dispatch (for `armbian-config module_install_engine ...`) ----

module_install_engine() {
	local commands
	IFS=' ' read -r -a commands <<<"${module_options["module_install_engine,example"]}"
	case "$1" in
		"${commands[0]}")   # detect
			shift; install_detect_targets "$@" ;;
		"${commands[1]}")   # plan
			shift; install_plan_layout "$@" ;;
		*)
			echo "Usage: module_install_engine {detect|plan} ..." >&2
			return "$INSTALL_EX_USAGE" ;;
	esac
}
