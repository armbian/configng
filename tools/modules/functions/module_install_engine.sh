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

	echo "$json" | jq -r --arg root "$root_disk" '
		.blockdevices[]?
		| select(.type == "disk")
		| select(.name != $root)
		| { n: .name, t: (.tran // ""), sz: (.size // 0),
		    ps: (."phy-sec" // 512), ro: (.rota // false), md: ((.model // "") | gsub("\t"; " ")) }
		| .role = ( if   (.n | test("^nvme"))     then "nvme"
		            elif (.n | test("^mmcblk"))   then "mmc"
		            elif (.n | test("^mtdblock")) then "mtd"
		            elif (.t == "usb")            then "usb"
		            elif (.t == "sata" or .t == "ata") then "sata"
		            else "disk" end )
		| [ .n, .role, (.sz|tostring), (.ps|tostring), .t, (.ro|tostring), .md ]
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
	local dest="$1" exclude="$2" pfd="${3:-1}"
	[[ -d "$dest" ]] || { install_log ERR "transfer: '$dest' is not a directory"; return "$INSTALL_EX_TRANSFER"; }
	[[ -f "$exclude" ]] || { install_log ERR "transfer: exclude file '$exclude' missing"; return "$INSTALL_EX_TRANSFER"; }

	local todo
	todo=$(rsync -anx --delete --stats --exclude-from="$exclude" / "$dest" 2>/dev/null \
		| awk '/Number of files:/ {gsub(/[.,]/,"",$4); print $4; exit}')
	[[ "$todo" =~ ^[0-9]+$ && "$todo" -gt 0 ]] || todo=1

	local rc_file; rc_file="$(mktemp)"
	{
		rsync -avx --delete --exclude-from="$exclude" / "$dest" \
			| stdbuf -oL awk -v todo="$todo" '{ p=int(100*NR/todo); if(p>100)p=100; print p; fflush() }' >&"$pfd"
		echo "${PIPESTATUS[0]}" >"$rc_file"
	}
	local rc; rc="$(cat "$rc_file")"; rm -f "$rc_file"
	[[ "$rc" == "0" ]] || { install_log ERR "transfer: rsync exit $rc"; return "$INSTALL_EX_TRANSFER"; }

	# Second, quiet pass to catch files that changed during the first copy.
	rsync -ax --delete --exclude-from="$exclude" / "$dest" >>"$INSTALL_LOG" 2>&1 || true
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
	# install_populate_boot <target_rootfs_mount> [target_boot_mount]
	# Ensure the target has a non-empty /boot. When a separate boot partition is
	# mounted, copy the running /boot into it; otherwise ensure /boot exists in
	# the rootfs. This is the guard against build#10099 (empty /boot).
	local rootfs="$1" bootmnt="${2:-}"
	[[ -d "$rootfs" ]] || { install_log ERR "populate_boot: rootfs '$rootfs' missing"; return "$INSTALL_EX_BOOTCFG"; }
	if [[ -n "$bootmnt" ]]; then
		# Separate boot partition: copy the running /boot onto it.
		[[ -d "$bootmnt" ]] || { install_log ERR "populate_boot: '$bootmnt' missing"; return "$INSTALL_EX_BOOTCFG"; }
		rsync -aqx /boot/ "$bootmnt"/ >>"$INSTALL_LOG" 2>&1 \
			|| { install_log ERR "populate_boot: copy to $bootmnt failed"; return "$INSTALL_EX_BOOTCFG"; }
	else
		# No separate boot partition: /boot rides inside the rootfs. The rsync of
		# / already carried it (unless the exclude list dropped it), so just make
		# sure the mount point exists for the bind/verify steps.
		mkdir -p "$rootfs/boot"
	fi
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

install_write_bootloader() {
	# install_write_bootloader <boot_mode> <target_disk> <rootfs_mount> [uboot_dir] [mtd_list] [ufs_boot_lun]
	# Dispatches to the board-provided u-boot hooks (sourced at runtime from
	# /usr/lib/u-boot/platform_install.sh) or GRUB for UEFI. Returns
	# INSTALL_EX_BOOTLOADER on failure.
	local boot_mode="$1" disk="$2" rootfs="$3" uboot_dir="${4:-${DIR:-}}" mtd_list="${5:-}" ufs_boot="${6:-}"
	case "$boot_mode" in
		uefi)
			install_grub_install "$rootfs" ;;
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
	# install_grub_install <rootfs_mount>
	# Bind-mount /dev,/proc,/sys and run grub-install + grub-mkconfig in the
	# target. The ESP must already be mounted at <rootfs>/boot/efi.
	local rootfs="$1" arch_target
	mountpoint -q "$rootfs/boot/efi" || { install_log ERR "grub: ESP not mounted at $rootfs/boot/efi"; return "$INSTALL_EX_BOOTLOADER"; }
	mkdir -p "$rootfs"/{dev,proc,sys}
	mount --bind /dev "$rootfs/dev"
	mount --make-rslave --bind /dev/pts "$rootfs/dev/pts"
	mount --bind /proc "$rootfs/proc"
	mount --make-rslave --rbind /sys "$rootfs/sys"
	arch_target=$([[ "$(arch)" == x86_64 ]] && echo "x86_64-efi" || echo "arm64-efi")
	local rc=0
	chroot "$rootfs" /bin/bash -c "grub-install --target=$arch_target --efi-directory=/boot/efi --bootloader-id=Armbian --removable" >>"$INSTALL_LOG" 2>&1 || rc=1
	chroot "$rootfs" /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" >>"$INSTALL_LOG" 2>&1 || rc=1
	# Unwind the API mounts regardless of outcome.
	awk -v r="$rootfs/sys" '$2 ~ "^"r {print $2}' /proc/mounts | sort -r | xargs -r umount -n 2>/dev/null
	umount "$rootfs/proc" 2>/dev/null
	umount "$rootfs/dev/pts" 2>/dev/null
	umount "$rootfs/dev" 2>/dev/null
	[[ "$rc" == 0 ]] || { install_log ERR "grub: install failed"; return "$INSTALL_EX_BOOTLOADER"; }
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

	# Mount the freshly-formatted target.
	local mp; mp="$(mktemp -d /mnt/armbian-install.XXXXXX)" || return "$INSTALL_EX_TRANSFER"
	mount "$root_dev" "$mp" || { install_log ERR "scenario: mount root failed"; rmdir "$mp"; return "$INSTALL_EX_TRANSFER"; }
	if [[ -n "$boot_dev" ]]; then mkdir -p "$mp/boot"; mount "$boot_dev" "$mp/boot"; fi
	if [[ -n "$esp_dev" ]]; then mkdir -p "$mp/boot/efi"; fi

	# One-shot loop so a failing step can `break` straight to teardown.
	local rc=0
	while :; do
		install_transfer_rootfs "$mp" "$exclude" || { rc=$INSTALL_EX_TRANSFER; break; }
		install_populate_boot "$mp" "${boot_dev:+$mp/boot}" || { rc=$INSTALL_EX_BOOTCFG; break; }

		# fstab from the real, freshly-created UUIDs.
		local root_uuid boot_uuid="" esp_uuid=""
		root_uuid="$(install_uuid "$root_dev")"
		[[ -n "$boot_dev" ]] && boot_uuid="$(install_uuid "$boot_dev")"
		[[ -n "$esp_dev" ]]  && esp_uuid="$(install_uuid "$esp_dev")"
		install_gen_fstab "$root_uuid" "$fs" "$boot_uuid" ext4 "$esp_uuid" >"$mp/etc/fstab" \
			|| { rc=$INSTALL_EX_BOOTCFG; break; }
		grep -q '^tmpfs.*swap' /etc/fstab 2>/dev/null && grep swap /etc/fstab >>"$mp/etc/fstab"

		# Point the board's boot env at the new root (u-boot scenarios only).
		if [[ "$boot_mode" != uefi ]]; then
			local env_file="$mp/boot/armbianEnv.txt"
			[[ -f "$env_file" ]] && install_rewrite_bootenv "$env_file" "$root_uuid" "$fs"
		fi

		# ESP must be mounted before GRUB runs.
		[[ -n "$esp_dev" ]] && { mount "$esp_dev" "$mp/boot/efi" || { rc=$INSTALL_EX_BOOTLOADER; break; }; }
		install_write_bootloader "$boot_mode" "$disk" "$mp" "$uboot_dir" "${INSTALL_MTD_LIST:-}" "${INSTALL_UFS_BOOT_LUN:-}" \
			|| { rc=$INSTALL_EX_BOOTLOADER; break; }

		# Refuse to declare success on an unbootable result.
		install_verify_boot_dir "$mp/boot" || { rc=$INSTALL_EX_VERIFY; break; }
		install_verify_fstab "$mp/etc/fstab" || { rc=$INSTALL_EX_VERIFY; break; }
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
