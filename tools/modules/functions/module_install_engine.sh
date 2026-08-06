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
#   * install_populate_boot always populates the target /boot and
#     install_verify_boot_dir refuses an empty /boot -> unbootable installs
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
	# install_table_type <is_uefi> <capacity_bytes> <sector_size> [preferred]
	# GPT when firmware is UEFI, the disk is larger than the MBR ceiling, or the
	# medium is 4Kn - these are hard requirements and override everything. When
	# none of those force the choice, honour <preferred> (gpt|msdos) if given -
	# this is how an eMMC/SD install replicates the running image's table type so
	# the board's u-boot can actually read it. Falls back to msdos. Pure - no
	# device access.
	local is_uefi="$1" cap="${2:-0}" sec="${3:-512}" preferred="${4:-}"
	if [[ "$is_uefi" == "1" || "$is_uefi" == "uefi" ]] \
		|| (( cap > INSTALL_TWO_TIB )) \
		|| (( sec == 4096 )); then
		echo "gpt"
		return 0
	fi
	case "$preferred" in
		gpt|msdos) echo "$preferred" ;;
		*)         echo "msdos" ;;
	esac
}

install_source_table_type() {
	# Echo the partition-table type (gpt|msdos) of the disk the board actually
	# boots from, or nothing if it can't be determined. An eMMC/SD install must
	# replicate this so the board's bootloader can read the result: Rockchip
	# vendor u-boot (2017.09) parses GPT only - an MBR eMMC gives endless
	# "Invalid GPT" and never finds the kernel - while Allwinner needs MBR
	# because its SPL at sector 16 (8KiB) overlaps a GPT partition-entry array.
	#
	# Prefer the device that holds /boot: that is the one u-boot reads, and it can
	# be a different disk with a different table than / (e.g. SD /boot + NVMe root).
	# Fall back to / when /boot is not its own mount. --nofsroot strips any bind or
	# subvolume suffix so lsblk gets a bare device. Impure: reads the live layout.
	local src disk ptt
	src="$(findmnt -no SOURCE --nofsroot /boot 2>/dev/null)"
	[[ "$src" == /dev/* ]] || src="$(findmnt -no SOURCE --nofsroot / 2>/dev/null)"
	[[ "$src" == /dev/* ]] || return 0
	disk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"
	[[ -n "$disk" ]] || return 0
	ptt="$(lsblk -ndo PTTYPE "/dev/$disk" 2>/dev/null | head -1)"
	case "$ptt" in
		gpt) echo "gpt" ;;
		dos) echo "msdos" ;;
	esac
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
	# role in {nvme,mmc,usb,sata,disk}. The disk hosting the running rootfs
	# (root_disk, a bare kernel name such as "mmcblk0") is excluded, as is SPI/MTD
	# flash (mtdblockN) - a boot device, not a target; it is offered as the mtd
	# boot mode once a real target is picked (see INSTALL_MTD_LIST).
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
		# eMMC exposes its read-only boot areas (mmcblkXboot0/boot1) and the
		# RPMB partition as their own TYPE=disk block devices. They are ~4 MB,
		# not writable as normal storage, and never valid install targets, so
		# drop them - only the main mmcblkX user-data device is a candidate.
		| select(.name | test("^mmcblk[0-9]+(boot[0-9]+|rpmb)$") | not)
		# SPI/MTD flash (mtdblockN) holds the bootloader, not a root filesystem -
		# it is a *boot* device (offered via the mtd boot mode after picking a
		# real target), never an install destination, so keep it out of the list.
		| select(.name | test("^mtdblock[0-9]+$") | not)
		| { n: .name, t: (.tran // ""), sz: (.size // 0),
			ps: (."phy-sec" // 512), ro: (.rota // false), md: ((.model // "") | gsub("\t"; " ")) }
		| .role = ( if   (.n | test("^nvme"))     then "nvme"
			elif (.n | test("^mmcblk"))   then "mmc"
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
	# install_plan_layout <boot_mode> <fs> <is_uefi> <capacity_bytes> <sector_size> [has_swap] [table_pref]
	#
	# table_pref (gpt|msdos): preferred partition table when capacity/sector/uefi
	# don't force GPT - used to replicate the running image's table type on an
	# eMMC/SD target so the board's u-boot can read it. Empty = default (msdos).
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
	# comma-separated subset of {esp,boot,bios_grub} ("" for none). Pure: no device I/O.
	local boot_mode="$1" fs="$2" is_uefi="$3" cap="${4:-0}" sec="${5:-512}" has_swap="${6:-0}" table_pref="${7:-}"
	local table
	table="$(install_table_type "$is_uefi" "$cap" "$sec" "$table_pref")"

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
		emmc-boot)
			# eMMC used as the BOOT device in a split install: the root filesystem
			# lives on another disk (e.g. NVMe, which the SoC bootrom cannot load
			# u-boot from). eMMC carries u-boot in the 16MiB gap, a dedicated ext4
			# /boot the board's u-boot can always read, and the remainder as a data
			# partition auto-mounted at /emmc_storage (the fs is fixed to ext4 here;
			# the <fs> argument applies to the root device, planned separately).
			parts+=("boot:512MiB:ext4:boot")
			parts+=("storage:100%:ext4:")
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

	# First-partition start offset, in MiB. emmc is the only mode that writes
	# u-boot to raw sectors of this same device (idbloader at 32KiB, u-boot.itb
	# at 8MiB on Rockchip et al.), so its first partition must clear that region
	# or the filesystem and the bootloader overwrite each other and the board
	# won't boot. 16MiB matches the classic installer's FIRSTSECTOR=32768 and
	# covers every SoC's bootloader area. All other modes keep u-boot off this
	# device (SPI/UFS) or on removable media, so 1MiB alignment is fine.
	local start_mib=1
	[[ "$boot_mode" == emmc || "$boot_mode" == emmc-boot ]] && start_mib=16

	echo "start=$start_mib"
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

	local table="" start_override="" ; local -a parts=()
	local line
	while IFS= read -r line; do
		case "$line" in
			table=*) table="${line#table=}" ;;
			start=*) start_override="${line#start=}" ;;
			part=*)  parts+=("${line#part=}") ;;
		esac
	done <<<"$plan"
	[[ -n "$table" && ${#parts[@]} -gt 0 ]] || { install_log ERR "apply_partitions: empty plan"; return "$INSTALL_EX_PARTITION"; }

	wipefs -aq "$device" >>"$INSTALL_LOG" 2>&1 || true
	dd if=/dev/zero of="$device" bs=1M count=10 conv=notrunc >>"$INSTALL_LOG" 2>&1 || true
	parted -s "$device" mklabel "$table" >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "apply_partitions: mklabel $table failed"; return "$INSTALL_EX_PARTITION"; }

	# Honour the plan's start offset (emmc reserves 16MiB for on-device u-boot);
	# default to 1MiB when a plan predates the directive.
	local start_mib="${start_override:-1}" idx=0
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
		# editorconfig-checker-disable
		rsync -ax --delete --info=progress2 --no-inc-recursive --exclude-from="$exclude" "$src" "$dest" \
			| stdbuf -oL tr '\r' '\n' \
			| stdbuf -oL sed -u -n 's/.*to-chk=\([0-9]*\)\/\([0-9]*\).*/\1 \2/p' \
			| stdbuf -oL awk -v lo="$lo" -v hi="$hi" '
				{ if ($2 > 0) { p = lo + int((hi-lo)*($2-$1)/$2);
				                if (p > hi) p = hi;
				                if (p != last) { print p; fflush(); last = p } } }' >&"$pfd"
		# editorconfig-checker-enable
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
	# install_gen_fstab <root_uuid> <root_fs> [boot_uuid] [boot_fs] [esp_uuid] [swap_uuid]
	# Emit a fresh fstab on stdout. root_* required; boot_* optional (separate
	# /boot); esp_uuid optional (UEFI /boot/efi); swap_uuid optional (a dedicated
	# swap partition). Mirrors the mount option set the image ships with.
	local root_uuid="$1" root_fs="$2" boot_uuid="${3:-}" boot_fs="${4:-ext4}" esp_uuid="${5:-}" swap_uuid="${6:-}"
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
	[[ -n "$swap_uuid" ]] && echo "${swap_uuid}	none	swap	sw	0	0"
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
	# Recognise every boot mechanism Armbian ships: boot.scr/boot.cmd (most
	# u-boot), boot.ini (amlogic/odroid), uEnv.txt (k3/TI and others),
	# extlinux.conf (distro boot), grub (x86/UEFI).
	[[ -f "$d/boot.scr" || -f "$d/boot.cmd" || -f "$d/boot.ini" || -f "$d/uEnv.txt" \
		|| -f "$d/extlinux/extlinux.conf" || -d "$d/grub" ]] && have_script=1
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
	# Some board u-boot hooks (notably TI k3: BeaglePlay/BeagleBone) copy files to
	# ${MOUNT}/boot instead of dd-ing to the device. The stock installers never
	# set MOUNT, so those files went to the RUNNING system's /boot, not the
	# target. Point MOUNT at the target rootfs so they land in the right place.
	export MOUNT="$rootfs"
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
		case "$(uname -m)" in
			x86_64) arch_target="x86_64-efi" ;;
			i?86) arch_target="i386-efi" ;;
			aarch64|arm64) arch_target="arm64-efi" ;;
			arm*) arch_target="arm-efi" ;;
			riscv64) arch_target="riscv64-efi" ;;
			*) install_log ERR "grub: unsupported UEFI architecture $(uname -m)"; return "$INSTALL_EX_BOOTLOADER" ;;
		esac
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
	# os-prober is unreliable inside the install chroot (it often misses Windows),
	# so also regenerate grub.cfg once on the first real boot.
	install_setup_grub_firstboot "$rootfs"
	# Unwind the API mounts regardless of outcome.
	awk -v r="$rootfs/sys" '$2 ~ "^"r {print $2}' /proc/mounts | sort -r | xargs -r umount -n 2>/dev/null
	umount "$rootfs/proc" 2>/dev/null
	umount "$rootfs/dev/pts" 2>/dev/null
	umount "$rootfs/dev" 2>/dev/null
	[[ "$rc" == 0 ]] || { install_log ERR "grub: install failed"; return "$INSTALL_EX_BOOTLOADER"; }
}

install_update_initramfs() {
	# install_update_initramfs <rootfs_mount> <fs>
	# Rebuild the target's initramfs so a module root filesystem (btrfs, f2fs)
	# is actually present at boot. Armbian sets MODULES=list, which does NOT
	# auto-include the root-fs module, and the installer inherits the source's
	# initramfs (built for the source's root fs) - so an f2fs/btrfs root would be
	# unbootable without this. Built-in filesystems (ext4/vfat) need nothing.
	# Best effort: a failure is logged, not fatal.
	local rootfs="$1" fs="$2"
	case "$fs" in ext2|ext3|ext4|vfat|msdos) return 0 ;; esac
	command -v chroot >/dev/null 2>&1 || return 0
	[[ -x "$rootfs/usr/sbin/update-initramfs" || -x "$rootfs/sbin/update-initramfs" ]] || {
		install_log WARN "update-initramfs: not present in target; $fs root may not boot"; return 0; }

	# Force the fs module into the initramfs module list (list mode ships only
	# what is listed here).
	local modfile="$rootfs/etc/initramfs-tools/modules"
	if [[ -f "$modfile" ]] && ! grep -qxF "$fs" "$modfile"; then
		echo "$fs" >>"$modfile"
	fi

	mkdir -p "$rootfs"/{dev,proc,sys}
	mount --bind /dev "$rootfs/dev"
	mount --bind /proc "$rootfs/proc"
	mount --bind /sys "$rootfs/sys"
	local rc=0
	chroot "$rootfs" /bin/bash -c "update-initramfs -u -k all" >>"$INSTALL_LOG" 2>&1 || rc=1
	umount "$rootfs/sys" 2>/dev/null
	umount "$rootfs/proc" 2>/dev/null
	umount "$rootfs/dev" 2>/dev/null
	[[ "$rc" == 0 ]] || install_log WARN "update-initramfs failed in target; $fs root may not boot"
	return 0
}

install_setup_grub_firstboot() {
	# install_setup_grub_firstboot <rootfs_mount>
	# Install a one-shot systemd unit that runs update-grub on the first real
	# boot, then removes itself - so os-prober picks up other OSes (Windows) that
	# it missed while running in the install chroot.
	local rootfs="$1"
	[[ -d "$rootfs/etc/systemd/system" ]] || return 0
	cat >"$rootfs/etc/systemd/system/armbian-grub-update.service" <<-'EOF'
		[Unit]
		Description=Regenerate GRUB config on first boot (detect other OSes)
		ConditionPathExists=/usr/sbin/update-grub
		After=multi-user.target

		[Service]
		Type=oneshot
		ExecStart=/usr/sbin/update-grub
		ExecStartPost=-/usr/bin/systemctl --no-reload disable armbian-grub-update.service
		ExecStartPost=-/bin/rm -f /etc/systemd/system/armbian-grub-update.service

		[Install]
		WantedBy=multi-user.target
	EOF
	# Enable via a wants symlink (chroot `systemctl enable` is unreliable).
	mkdir -p "$rootfs/etc/systemd/system/multi-user.target.wants"
	ln -sf ../armbian-grub-update.service \
		"$rootfs/etc/systemd/system/multi-user.target.wants/armbian-grub-update.service"
}

install_enable_os_prober() {
	# install_enable_os_prober <rootfs_mount>
	# Make grub-mkconfig scan for other operating systems (Windows). GRUB 2.06+
	# disables os-prober by default; re-enable it via the armbian drop-in.
	local rootfs="$1"
	mkdir -p "$rootfs/etc/default/grub.d"
	local cfg="$rootfs/etc/default/grub.d/98-armbian.cfg"
	# idempotent: repeated installs must not accumulate duplicate lines
	grep -qxF "GRUB_DISABLE_OS_PROBER=false" "$cfg" 2>/dev/null \
		|| echo "GRUB_DISABLE_OS_PROBER=false" >>"$cfg"
	command -v os-prober >/dev/null 2>&1 || chroot "$rootfs" /bin/bash -c "command -v os-prober" >/dev/null 2>&1 \
		|| install_log WARN "os-prober not present in target; Windows may be missing from the GRUB menu"
}

# ---- Windows dual-boot ------------------------------------------------------

_install_windows_parts() {
	# _install_windows_parts <lsblk_json>
	# Pure: pick the ESP and the Windows system NTFS volume from lsblk --json.
	# The Windows volume is the LARGEST NTFS partition EXCLUDING the small Windows
	# recovery (WinRE) NTFS partition - so we shrink C:, never the recovery part.
	# size is sorted with tonumber (lsblk may emit it as a string, and a string
	# sort would rank 781MB above 63GB). Emits two lines: esp=<dev|> windows=<dev|>
	local json="$1" esp win
	# editorconfig-checker-disable
	esp="$(printf '%s' "$json" | jq -r '
		[ .blockdevices[]?.children[]?
		  | select(((.parttypename // "") | test("EFI";"i")) or (.fstype == "vfat"))
		  | .name ] | first // empty')"
	win="$(printf '%s' "$json" | jq -r '
		[ .blockdevices[]?.children[]?
		  | select(.fstype == "ntfs")
		  | select(((.parttypename // "") | test("recovery"; "i")) | not) ]
		| sort_by(.size | tonumber) | reverse | (.[0].name // empty)')"
	# editorconfig-checker-enable
	printf 'esp=%s\nwindows=%s\n' "$esp" "$win"
}

install_detect_windows() {
	# install_detect_windows <disk> [lsblk_json]
	# On a GPT disk carrying a Windows install, emit:
	#   esp=<esp_partition>          existing EFI System Partition (reused)
	#   windows=<ntfs_partition>     the Windows system NTFS volume (not WinRE)
	# Returns INSTALL_EX_NODEV if the disk is not a shrinkable Windows/UEFI layout.
	local disk="$1" json="${2:-}"
	if [[ -z "$json" ]]; then
		[[ -b "$disk" ]] || return "$INSTALL_EX_NODEV"
		# GPT is required for a UEFI Windows install.
		parted -sm "$disk" print 2>/dev/null | grep -q '^/dev/.*:gpt:' || return "$INSTALL_EX_NODEV"
		json="$(lsblk -b -po NAME,FSTYPE,PARTTYPENAME,SIZE --json "$disk" 2>/dev/null)"
	fi

	local esp win parts
	parts="$(_install_windows_parts "$json")"
	esp="$(sed -n 's/^esp=//p' <<<"$parts")"
	win="$(sed -n 's/^windows=//p' <<<"$parts")"
	if [[ -z "$esp" || -z "$win" ]]; then
		# A "Microsoft basic data" partition that is not plain NTFS is almost
		# always BitLocker-encrypted, which ntfsresize cannot shrink - say so.
		local enc
		# editorconfig-checker-disable
		enc="$(printf '%s' "$json" | jq -r '
			[ .blockdevices[]?.children[]?
			  | select(((.parttypename // "") | test("basic data"; "i")) and (.fstype != "ntfs"))
			  | .name ] | first // empty')"
		# editorconfig-checker-enable
		if [[ -n "$enc" ]]; then
			install_log ERR "detect_windows: $enc is not plain NTFS (likely BitLocker); disable device encryption in Windows to enable dual-boot"
		else
			install_log ERR "detect_windows: no ESP+NTFS pair on $disk"
		fi
		return "$INSTALL_EX_NODEV"
	fi
	echo "esp=$esp"
	echo "windows=$win"
}

install_disk_has_bitlocker() {
	# install_disk_has_bitlocker <disk> [lsblk_json]
	# True if the disk carries a BitLocker-encrypted volume. Used to explain why
	# dual-boot is unavailable (ntfsresize cannot shrink an encrypted volume).
	local disk="$1" json="${2:-}"
	[[ -z "$json" ]] && json="$(lsblk -b -po NAME,FSTYPE,PARTTYPENAME,SIZE --json "$disk" 2>/dev/null)"
	printf '%s' "$json" | jq -e 'any(.blockdevices[]?.children[]?; (.fstype // "") | test("bitlocker"; "i"))' >/dev/null 2>&1
}

install_dualboot_blocker() {
	# install_dualboot_blocker <disk>
	# If the disk's Windows volume cannot be shrunk for a dual-boot install, echo
	# a plain, user-facing reason AND the exact fix, and return non-zero. Prints
	# nothing and returns 0 when the disk is ready. The frontends show this text
	# directly (dialog / message) so the user is told what to do without reading
	# the install log.
	local disk="$1" wi win json winpart
	# Identify the Windows system partition INDEPENDENTLY OF FILESYSTEM TYPE first:
	# a BitLocker volume's fstype is "BitLocker", not "ntfs", so install_detect_
	# windows (which keys on ntfs) fails on it - and we must still report BitLocker,
	# not "no Windows". Pick the largest "Microsoft basic data" partition, minus the
	# WinRE recovery one.
	json="$(lsblk -b -po NAME,FSTYPE,PARTTYPENAME,SIZE --json "$disk" 2>/dev/null)"
	winpart="$(printf '%s' "$json" | jq -r '
		[ .blockdevices[]?.children[]?
		  | select(((.parttypename // "") | test("basic data"; "i")))
		  | select(((.parttypename // "") | test("recovery"; "i")) | not) ]
		| sort_by(.size | tonumber) | reverse | (.[0].name // empty)' 2>/dev/null)"
	# BitLocker FIRST (an encrypted volume also fails the ntfsresize probe below and
	# must not be reported as "dirty"), scoped to THAT partition only: its lsblk/blkid
	# fstype, or its boot sector's "-FVE-FS-" signature (a plain NTFS volume has
	# "NTFS" there) - so a locked volume is caught even if lsblk didn't tag it.
	if [[ -n "$winpart" ]] && { [[ "$(lsblk -no FSTYPE "$winpart" 2>/dev/null)" == *[Bb]it[Ll]ocker* ]] \
		|| dd if="$winpart" bs=512 count=1 2>/dev/null | tr -d '\0' | grep -qa 'FVE-FS'; }; then
		printf '%s\n' \
			"The Windows volume on $disk is BitLocker-encrypted, so it cannot be resized for dual-boot." \
			"" \
			"Fix it in Windows, then run the installer again:" \
			"1) Turn off BitLocker / Device Encryption: manage-bde -off C:" \
			"2) Wait until it reports fully decrypted."
		return 1
	fi
	# Not BitLocker: need a real (shrinkable) Windows/UEFI layout to proceed.
	wi="$(install_detect_windows "$disk")" || {
		echo "No Windows/UEFI install was found on $disk - there is nothing to dual-boot alongside. Use a normal (erase) install instead, or pick the disk that has Windows on it."
		return 1
	}
	win="$(sed -n 's/^windows=//p' <<<"$wi")"
	# ntfsresize refuses a hibernated / Fast-Startup / unclean volume ("NTFS is
	# inconsistent"). This is the most common blocker.
	if ! ntfsresize -f --info "$win" >/dev/null 2>&1; then
		printf '%s\n' \
			"The Windows volume on $disk is hibernated or has Fast Startup enabled, so it cannot be shrunk for dual-boot." \
			"" \
			"Fix it in Windows, then run the installer again:" \
			"1) In an admin Command Prompt, run: powercfg /h off" \
			"2) Then run: chkdsk /f C:  (reboot if it asks)" \
			"3) Shut Windows down fully (not Restart)."
		return 1
	fi
	return 0
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
	# Leave 16MiB slack past the shrunk fs, then round the end UP to a 1 MiB
	# boundary so the partition created in the freed space starts aligned
	# (a misaligned start makes parted warn and prompt, and hurts performance).
	new_end_b=$(( start_b + new_bytes + 16 * 1024 * 1024 ))
	new_end_b=$(( (new_end_b + 1048575) / 1048576 * 1048576 ))
	# parted refuses to shrink a partition non-interactively even with --script;
	# ---pretend-input-tty answers its Yes/No prompts (data-loss, closest-location).
	printf 'Yes\nYes\n' | parted ---pretend-input-tty "$disk" unit B resizepart "$pnum" "${new_end_b}B" >>"$INSTALL_LOG" 2>&1 \
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
	# Largest free block (MiB) from parted's free-space report - track its END too.
	local fstart fend fsize best_start="" best_end="" best_size=0
	while IFS=: read -r _ fstart fend fsize _; do
		[[ "$fsize" == *MiB ]] || continue
		local s="${fstart%MiB}" e="${fend%MiB}" z="${fsize%MiB}"
		s="${s%.*}"; e="${e%.*}"; z="${z%.*}"
		if (( z > best_size )); then best_size="$z"; best_start="$s"; best_end="$e"; fi
	done < <(parted -sm "$disk" unit MiB print free 2>/dev/null | grep ':free;$')
	[[ -n "$best_start" ]] || { install_log ERR "create_free: no free space on $disk"; return "$INSTALL_EX_NOSPACE"; }

	# Record existing partition numbers: parted numbers by creation order but
	# LISTS by position, so "the last line" is the wrong partition when the free
	# space sits before a trailing partition (e.g. a Windows recovery at the disk
	# end). Diff before/after to find the number that was actually created.
	local before_nums
	before_nums="$(parted -sm "$disk" print 2>/dev/null | awk -F: '/^[0-9]/{print $1}')"

	# Fill exactly the free region (best_start..best_end), NOT 100% - 100% would
	# collide with a trailing partition and force parted to clamp/prompt.
	local -a mkpart_args=(mkpart primary)
	[[ -n "$hint" ]] && mkpart_args+=("$hint")
	mkpart_args+=("${best_start}MiB" "${best_end}MiB")
	printf 'Yes\nYes\n' | parted ---pretend-input-tty -a optimal "$disk" unit MiB "${mkpart_args[@]}" >>"$INSTALL_LOG" 2>&1 \
		|| { install_log ERR "create_free: mkpart failed"; return "$INSTALL_EX_PARTITION"; }
	partprobe "$disk" >>"$INSTALL_LOG" 2>&1 || true
	udevadm settle >>"$INSTALL_LOG" 2>&1 || true

	# The new partition is the number that is present now but was not before.
	local n newnum=""
	while IFS= read -r n; do
		grep -qxF "$n" <<<"$before_nums" || { newnum="$n"; break; }
	done < <(parted -sm "$disk" print 2>/dev/null | awk -F: '/^[0-9]/{print $1}')
	[[ -n "$newnum" ]] || { install_log ERR "create_free: cannot identify the new partition"; return "$INSTALL_EX_PARTITION"; }
	echo "$(_install_part_dev "$disk" "$newnum")"
}

# ---- orchestration ----------------------------------------------------------

install_uuid() {
	# install_uuid <device_partition> -> "UUID=<uuid>" (empty on failure)
	local u; u="$(blkid -s UUID -o value "$1" 2>/dev/null)"
	[[ -n "$u" ]] && echo "UUID=$u"
}

install_map_current_boot() {
	# install_map_current_boot <target_fstab> <target_root_mount>
	# For "sd" mode (boot stays on the current media, rootfs on the target):
	# make the current media's /boot visible inside the target at /boot so kernel
	# and initramfs upgrades on the target land where u-boot actually reads them.
	# Mirrors the classic armbian-install behaviour:
	#   * dedicated /boot partition  -> mount it straight at /boot
	#   * /boot is a dir on the root -> mount that partition at /media/boot-media
	#                                   and bind /media/boot-media/boot -> /boot
	# All entries use nofail so a later-removed boot medium never blocks boot.
	local fstab="$1" mp="$2"
	local boot_src boot_uuid boot_fstype
	boot_src="$(findmnt -no SOURCE /boot 2>/dev/null || true)"
	if [[ -n "$boot_src" ]]; then
		boot_uuid="$(install_uuid "$boot_src")"
		boot_fstype="$(findmnt -no FSTYPE /boot 2>/dev/null || true)"
		[[ -n "$boot_uuid" && -n "$boot_fstype" ]] \
			|| { install_log ERR "boot-map: cannot resolve current /boot partition ($boot_src)"; return "$INSTALL_EX_BOOTCFG"; }
		printf '%s\t/boot\t%s\tdefaults,nofail\t0\t2\n' "$boot_uuid" "$boot_fstype" >>"$fstab"
		install_log INFO "boot-map: target /boot -> current boot partition $boot_src ($boot_fstype)"
		return 0
	fi
	# /boot is a directory on the current media's root partition.
	local root_src root_media_uuid root_media_fstype
	root_src="$(findmnt -no SOURCE / 2>/dev/null || true)"
	root_media_uuid="$(install_uuid "$root_src")"
	root_media_fstype="$(findmnt -no FSTYPE / 2>/dev/null || true)"
	[[ -n "$root_media_uuid" && -n "$root_media_fstype" ]] \
		|| { install_log ERR "boot-map: cannot resolve current root partition ($root_src)"; return "$INSTALL_EX_BOOTCFG"; }
	mkdir -p "$mp/media/boot-media" || { install_log ERR "boot-map: mkdir /media/boot-media failed"; return "$INSTALL_EX_BOOTCFG"; }
	printf '%s\t/media/boot-media\t%s\tdefaults,nofail\t0\t2\n' "$root_media_uuid" "$root_media_fstype" >>"$fstab"
	printf '/media/boot-media/boot\t/boot\tnone\tbind,nofail\t0\t0\n' >>"$fstab"
	install_log INFO "boot-map: target /boot -> bind of current root $root_src (/media/boot-media/boot)"
	return 0
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
	# SPI/MTD flash (mtdblockN) is a boot device, never a root target. Detection
	# filters it from the menu, but refuse it here too so an explicit
	# --target /dev/mtdblockN (or a TUI selection) can't repartition the SPI.
	[[ "$disk" != /dev/mtdblock* ]] || { install_log ERR "scenario: '$disk' is SPI/MTD flash, not a valid install target"; return "$INSTALL_EX_NODEV"; }
	[[ -f "$exclude" ]] || { install_log ERR "scenario: exclude file '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }
	# Pre-flight: confirm we can make the target bootable AND format it BEFORE
	# wiping anything - never destroy a disk we cannot finish installing to.
	install_bootloader_available "$boot_mode" \
		|| { install_log ERR "scenario: no bootloader method for '$boot_mode' on this system (u-boot hooks or grub-install missing) - refusing to modify $disk"; return "$INSTALL_EX_BOOTLOADER"; }
	# mtd mode flashes u-boot to the SPI/MTD device list; refuse before wiping the
	# target if the frontend handed us an empty list (e.g. the device vanished
	# between menu and run) rather than failing after partitioning.
	[[ "$boot_mode" != mtd || -n "${INSTALL_MTD_LIST:-}" ]] \
		|| { install_log ERR "scenario: mtd boot but no MTD/SPI device (INSTALL_MTD_LIST empty) - refusing to modify $disk"; return "$INSTALL_EX_NODEV"; }
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

	# eMMC/SD/MTD installs must use the same partition-table type as the running
	# image so the board's u-boot can read the result (Rockchip vendor u-boot
	# reads GPT only; Allwinner needs MBR). For mtd the /boot lands on the target
	# and is read by the SPI u-boot, so it matters there too. Replicate the
	# source; the planner still upgrades to GPT when capacity/sector size demand.
	local table_pref=""
	case "$boot_mode" in
		emmc|sd|mtd) table_pref="$(install_source_table_type)"
			[[ -n "$table_pref" ]] && install_log INFO "scenario: inheriting source partition table '$table_pref' for $boot_mode" ;;
	esac

	local plan; plan="$(install_plan_layout "$boot_mode" "$fs" "$is_uefi" "$cap" "$sec" "$has_swap" "$table_pref")" \
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
	if [[ -n "$esp_dev" ]]; then mkdir -p "$mp/boot/efi"; fi

	# One-shot loop so a failing step can `break` straight to teardown. The bar is
	# staged: rsync fills 0-90, the remaining steps advance it to 100 so it never
	# freezes at ~90% during /boot sync, grub-install and verification.
	local rc=0
	while :; do
		install_transfer_rootfs "$mp" "$exclude" 1 / 0 90 || { rc=$INSTALL_EX_TRANSFER; break; }
		echo 92
		# A separate boot partition must be mounted before /boot is synced onto it;
		# a silent mount failure would leave the boot partition empty (unbootable),
		# mirroring the ESP mount guard below.
		if [[ -n "$boot_dev" ]]; then
			mkdir -p "$mp/boot"
			mount "$boot_dev" "$mp/boot" \
				|| { install_log ERR "scenario: mount boot partition $boot_dev failed"; rc=$INSTALL_EX_BOOTCFG; break; }
		fi
		install_populate_boot "$mp" "$copy_boot" || { rc=$INSTALL_EX_BOOTCFG; break; }

		# fstab from the real, freshly-created UUIDs.
		local root_uuid boot_uuid="" esp_uuid="" swap_uuid=""
		root_uuid="$(install_uuid "$root_dev")"
		[[ -n "$boot_dev" ]] && boot_uuid="$(install_uuid "$boot_dev")"
		[[ -n "$esp_dev" ]]  && esp_uuid="$(install_uuid "$esp_dev")"
		[[ -n "$swap_dev" ]] && swap_uuid="$(install_uuid "$swap_dev")"
		install_gen_fstab "$root_uuid" "$fs" "$boot_uuid" ext4 "$esp_uuid" "$swap_uuid" >"$mp/etc/fstab" \
			|| { rc=$INSTALL_EX_BOOTCFG; break; }
		# No dedicated swap partition -> carry over the host's swap entries (e.g. a
		# /var/swap swapfile) so the target keeps swap.
		if [[ -z "$swap_dev" ]] && grep -qE '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab 2>/dev/null; then
			grep -E '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab >>"$mp/etc/fstab"
		fi

		# Point the board's boot env at the new root (u-boot scenarios only; GRUB
		# modes are handled by grub-mkconfig).
		case "$boot_mode" in
			emmc|mtd|ufs)
				local env_file="$mp/boot/armbianEnv.txt"
				[[ -f "$env_file" ]] && install_rewrite_bootenv "$env_file" "$root_uuid" "$fs" ;;
			sd)
				# Boot stays on the current media (the SD/eMMC the board booted
				# from); only the rootfs moved to $disk. Two things are needed:
				#   1. point the CURRENT media's boot env at the new root, so u-boot
				#      (loaded from that media) keeps loading the kernel from there
				#      but tells the kernel to mount rootfs from $disk; and
				#   2. map that media's /boot into the target at /boot, so kernel and
				#      initramfs upgrades on the target land where u-boot reads them.
				# Without (1) the board keeps booting its old rootfs.
				local env_file="/boot/armbianEnv.txt"
				if [[ ! -f "$env_file" ]]; then
					install_log ERR "scenario: sd mode but current boot env ($env_file) is missing; cannot make $disk bootable"
					rc=$INSTALL_EX_BOOTCFG; break
				fi
				install_rewrite_bootenv "$env_file" "$root_uuid" "$fs" \
					|| { install_log ERR "scenario: failed to point current boot env ($env_file) at new root $root_uuid"; rc=$INSTALL_EX_BOOTCFG; break; }
				install_map_current_boot "$mp/etc/fstab" "$mp" \
					|| { install_log ERR "scenario: failed to map current /boot into target fstab"; rc=$INSTALL_EX_BOOTCFG; break; }
				install_log INFO "scenario: pointed current boot media ($env_file) at new root $root_uuid ($fs) and mapped its /boot into the target" ;;
		esac

		# Rebuild the target initramfs so a module root fs (btrfs/f2fs) boots
		# under MODULES=list. Only when the target owns its /boot.
		[[ "$copy_boot" == 1 ]] && install_update_initramfs "$mp" "$fs"

		echo 95
		# ESP must be mounted before GRUB runs.
		[[ -n "$esp_dev" ]] && { mount "$esp_dev" "$mp/boot/efi" || { rc=$INSTALL_EX_BOOTLOADER; break; }; }
		# In sd mode the bootloader already lives on the current boot media (left
		# untouched) and the boot env there was rewired above; writing u-boot to
		# $disk would target the wrong device - e.g. the Rockchip bootrom cannot
		# load u-boot from NVMe/USB/SATA, so it would silently fail to boot.
		if [[ "$boot_mode" != sd ]]; then
			install_write_bootloader "$boot_mode" "$disk" "$mp" "$uboot_dir" "${INSTALL_MTD_LIST:-}" "${INSTALL_UFS_BOOT_LUN:-}" \
				|| { rc=$INSTALL_EX_BOOTLOADER; break; }
		fi

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

install_run_split() {
	# install_run_split <boot_disk> <root_disk> <fs> <exclude_file> [uboot_dir]
	#
	# "Split" ARM install: the SoC bootrom cannot load u-boot from NVMe/SATA/USB,
	# so boot lives on an internal eMMC while the root filesystem lives on the
	# fast/large target. The eMMC gets u-boot (raw sectors) + a dedicated ext4
	# /boot that the board's u-boot can always read + the remaining space as a
	# data partition auto-mounted at /emmc_storage. The target disk gets only the
	# rootfs; its fstab mounts /boot from the eMMC boot partition. Restores the
	# classic installer's "Boot from eMMC - system on SATA/USB/NVMe".
	local boot_disk="$1" root_disk="$2" fs="$3" exclude="$4" uboot_dir="${5:-${DIR:-}}"
	export LC_ALL=C LANG=C
	[[ -b "$boot_disk" ]] || { install_log ERR "split: boot device '$boot_disk' is not a block device"; return "$INSTALL_EX_NODEV"; }
	[[ -b "$root_disk" ]] || { install_log ERR "split: root device '$root_disk' is not a block device"; return "$INSTALL_EX_NODEV"; }
	[[ "$root_disk" != /dev/mtdblock* ]] || { install_log ERR "split: root device '$root_disk' is SPI/MTD flash, not a valid install target"; return "$INSTALL_EX_NODEV"; }
	[[ "$boot_disk" != "$root_disk" ]] || { install_log ERR "split: boot and root device must differ ('$boot_disk')"; return "$INSTALL_EX_USAGE"; }
	[[ -f "$exclude" ]] || { install_log ERR "split: exclude file '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }
	# Pre-flight: u-boot hook + filesystem tooling must exist BEFORE we wipe.
	[[ "$(type -t write_uboot_platform)" == function ]] \
		|| { install_log ERR "split: write_uboot_platform hook missing - refusing to modify $boot_disk"; return "$INSTALL_EX_BOOTLOADER"; }
	install_check_fs_tools "$fs" >/dev/null \
		|| { install_log ERR "split: mkfs.$fs not installed (need $(_install_fs_pkg "$fs")) - refusing to modify $root_disk"; return "$INSTALL_EX_TOOL"; }
	install_fs_kernel_supported "$fs" \
		|| { install_log ERR "split: running kernel cannot mount $fs - refusing to modify $root_disk"; return "$INSTALL_EX_TOOL"; }

	# Geometry for each device feeds the pure planner.
	local bcap bsec rcap rsec
	bcap="$(blockdev --getsize64 "$boot_disk" 2>/dev/null || echo 0)"
	bsec="$(cat "/sys/block/$(basename "$boot_disk")/queue/physical_block_size" 2>/dev/null || echo 512)"
	rcap="$(blockdev --getsize64 "$root_disk" 2>/dev/null || echo 0)"
	rsec="$(cat "/sys/block/$(basename "$root_disk")/queue/physical_block_size" 2>/dev/null || echo 512)"
	# eMMC must carry a table its u-boot can read (Rockchip vendor = GPT only);
	# replicate the running image's table type.
	local table_pref; table_pref="$(install_source_table_type)"

	local bplan rplan
	bplan="$(install_plan_layout emmc-boot ext4 0 "$bcap" "$bsec" 0 "$table_pref")" \
		|| { install_log ERR "split: eMMC boot planning failed"; return "$INSTALL_EX_PARTITION"; }
	rplan="$(install_plan_layout sd "$fs" 0 "$rcap" "$rsec" 0 "$table_pref")" \
		|| { install_log ERR "split: root planning failed"; return "$INSTALL_EX_PARTITION"; }
	install_log INFO "split: boot device $boot_disk"$'\n'"$bplan"$'\n'"split: root device $root_disk"$'\n'"$rplan"

	# Partition both devices before formatting anything.
	local bpartmap rpartmap
	bpartmap="$(install_apply_partitions "$boot_disk" "$bplan")" || return "$INSTALL_EX_PARTITION"
	rpartmap="$(install_apply_partitions "$root_disk" "$rplan")" || return "$INSTALL_EX_PARTITION"

	local boot_part="" storage_part="" root_part="" role dev mkfs_map=""
	while read -r role dev; do
		[[ -n "$dev" ]] || continue
		case "$role" in
			boot)    boot_part="$dev";    mkfs_map+="boot $dev ext4"$'\n' ;;
			storage) storage_part="$dev"; mkfs_map+="storage $dev ext4"$'\n' ;;
		esac
	done <<<"$bpartmap"
	while read -r role dev; do
		[[ -n "$dev" ]] || continue
		[[ "$role" == root ]] && { root_part="$dev"; mkfs_map+="root $dev $fs"$'\n'; }
	done <<<"$rpartmap"
	[[ -b "$boot_part" && -b "$root_part" ]] || { install_log ERR "split: expected boot+root partitions not created"; return "$INSTALL_EX_PARTITION"; }
	install_make_filesystems "$mkfs_map" || return "$INSTALL_EX_FORMAT"

	local mp; mp="$(mktemp -d /mnt/armbian-install.XXXXXX)" || return "$INSTALL_EX_TRANSFER"
	mount "$root_part" "$mp" || { install_log ERR "split: mount root $root_part failed"; rmdir "$mp"; return "$INSTALL_EX_TRANSFER"; }

	local rc=0
	while :; do
		install_transfer_rootfs "$mp" "$exclude" 1 / 0 90 || { rc=$INSTALL_EX_TRANSFER; break; }
		echo 92
		# The eMMC boot partition carries /boot (kernel, dtb, boot script); mount it
		# before populating or the files land on the rootfs and u-boot never sees them.
		mkdir -p "$mp/boot"
		mount "$boot_part" "$mp/boot" || { install_log ERR "split: mount boot $boot_part failed"; rc=$INSTALL_EX_BOOTCFG; break; }
		install_populate_boot "$mp" 1 || { rc=$INSTALL_EX_BOOTCFG; break; }

		local root_uuid boot_uuid storage_uuid
		root_uuid="$(install_uuid "$root_part")"
		boot_uuid="$(install_uuid "$boot_part")"
		storage_uuid="$(install_uuid "$storage_part")"

		# fstab: root on the target, /boot from the eMMC boot partition, and the
		# eMMC data partition at /emmc_storage (nofail - never block boot on it).
		install_gen_fstab "$root_uuid" "$fs" "$boot_uuid" ext4 "" "" >"$mp/etc/fstab" \
			|| { rc=$INSTALL_EX_BOOTCFG; break; }
		if [[ -n "$storage_uuid" ]]; then
			mkdir -p "$mp/emmc_storage"
			printf '%s\t/emmc_storage\text4\tdefaults,nofail\t0\t2\n' "$storage_uuid" >>"$mp/etc/fstab"
		fi

		# Point the eMMC boot env at the root that now lives on the target device.
		local env_file="$mp/boot/armbianEnv.txt"
		[[ -f "$env_file" ]] && { install_rewrite_bootenv "$env_file" "$root_uuid" "$fs" \
			|| { install_log ERR "split: failed to point $env_file at root $root_uuid"; rc=$INSTALL_EX_BOOTCFG; break; }; }

		# Module root fs (btrfs/f2fs) needs its driver in the eMMC /boot initramfs.
		install_update_initramfs "$mp" "$fs"

		echo 95
		# u-boot goes to the eMMC whole device (raw sectors), never the target.
		install_write_bootloader emmc "$boot_disk" "$mp" "$uboot_dir" \
			|| { rc=$INSTALL_EX_BOOTLOADER; break; }

		echo 99
		install_verify_boot_dir "$mp/boot" || { rc=$INSTALL_EX_VERIFY; break; }
		install_verify_fstab "$mp/etc/fstab" || { rc=$INSTALL_EX_VERIFY; break; }
		echo 100
		break
	done 2>>"$INSTALL_LOG"

	# Teardown (best effort).
	sync
	mountpoint -q "$mp/boot" && umount "$mp/boot" 2>/dev/null
	umount "$mp" 2>/dev/null
	rmdir "$mp" 2>/dev/null

	[[ "$rc" == 0 ]] && install_log INFO "split: boot on $boot_disk, root on $root_disk completed"
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
	# Backstop for direct engine callers (the TUI/CLI already surface this to the
	# user before we get here): refuse - before any change - if Windows can't be
	# shrunk (BitLocker / unclean NTFS), logging the actionable reason.
	local blocker; blocker="$(install_dualboot_blocker "$disk")" \
		|| { install_log ERR "dualboot: cannot shrink Windows on $disk"$'\n'"$blocker"; return "$INSTALL_EX_PARTITION"; }

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
		install_update_initramfs "$mp" "$fs"
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
