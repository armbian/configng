#!/usr/bin/env bats
#
# Integration tests for the side-effecting engine primitives against a real
# (loop-backed) block device: partitioning, mkfs and fstab generation. These
# need root + losetup, so they run under sudo in CI and skip locally otherwise.
#
# They exercise the exact chain the installer uses, minus the rootfs rsync and
# bootloader write, and assert with sfdisk/blkid/lsblk that the on-disk result
# matches the plan - proving the GPT/MBR/flag/blocksize fixes end to end.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null

	if [[ "$(id -u)" -ne 0 ]]; then skip "needs root for losetup"; fi
	command -v losetup >/dev/null || skip "losetup not available"
	command -v parted  >/dev/null || skip "parted not available"
	command -v sfdisk  >/dev/null || skip "sfdisk not available"

	IMG="$BATS_TEST_TMPDIR/disk.img"
	truncate -s 8G "$IMG"
	LOOP="$(losetup -f --show -P "$IMG")"
}

teardown() {
	local d
	# Unmount first, or losetup -d leaves a busy loop.
	for d in nr/boot nr/media/boot-media cur/boot old cur top; do
		mountpoint -q "$BATS_TEST_TMPDIR/$d" 2>/dev/null && umount "$BATS_TEST_TMPDIR/$d"
	done
	[[ -n "${LOOP:-}" ]] && losetup -d "$LOOP" 2>/dev/null || true
}

# Partition-table assertions read `sfdisk -d`, which opens the disk read-only.
# parted opens it read-write even for `print`, and closing that handle makes udev
# re-probe the disk; `[ -b ]` node checks right after a parted call flaked on that.
_ptable() { sfdisk -d "$LOOP" 2>/dev/null; }

@test "loopback: uefi plan yields GPT with an ESP-flagged first partition" {
	local plan; plan="$(install_plan_layout uefi ext4 1 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	# Label type and the ESP partition type GUID, straight from the on-disk table.
	_ptable | grep -q '^label: gpt'
	_ptable | grep -q "^${LOOP}p1 : .*type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
	# Two partition nodes exist.
	[ -b "${LOOP}p1" ]
	[ -b "${LOOP}p2" ]
}

@test "loopback: emmc plan keeps the Rockchip reserved window, clears the loaders" {
	# Sectors 7168-16383 hold vendor storage (MACs, serial) and secure storage
	# (HDCP/DRM keys), provisioned per unit and never recreated. The loader areas
	# either side of them must still be cleared. Markers sit on both edges so an
	# off-by-one cannot pass.
	printf 'IDB'   | dd of="$LOOP" bs=512 seek=64    conv=notrunc status=none
	printf 'LDR0'  | dd of="$LOOP" bs=512 seek=7167  conv=notrunc status=none
	printf 'DVKR'  | dd of="$LOOP" bs=512 seek=7168  conv=notrunc status=none
	printf 'SSKR'  | dd of="$LOOP" bs=512 seek=8192  conv=notrunc status=none
	printf 'RVEN'  | dd of="$LOOP" bs=512 seek=16383 conv=notrunc status=none
	printf 'UBOOT' | dd of="$LOOP" bs=512 seek=16384 conv=notrunc status=none
	printf 'TAIL'  | dd of="$LOOP" bs=512 seek=20479 conv=notrunc status=none
	printf 'NEXT'  | dd of="$LOOP" bs=512 seek=20480 conv=notrunc status=none

	local plan; plan="$(install_plan_layout emmc ext4 0 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	[ -b "${LOOP}p1" ]

	# preserved: the window, both edges included
	[ "$(dd if="$LOOP" bs=1 skip=$((7168*512))  count=4 status=none)" = "DVKR" ]
	[ "$(dd if="$LOOP" bs=1 skip=$((8192*512))  count=4 status=none)" = "SSKR" ]
	[ "$(dd if="$LOOP" bs=1 skip=$((16383*512)) count=4 status=none)" = "RVEN" ]
	# cleared: the loader areas, up to the last sector the old wipe reached
	[ -z "$(dd if="$LOOP" bs=1 skip=$((64*512))    count=3 status=none | tr -d '\0')" ]
	[ -z "$(dd if="$LOOP" bs=1 skip=$((7167*512))  count=4 status=none | tr -d '\0')" ]
	[ -z "$(dd if="$LOOP" bs=1 skip=$((16384*512)) count=5 status=none | tr -d '\0')" ]
	[ -z "$(dd if="$LOOP" bs=1 skip=$((20479*512)) count=4 status=none | tr -d '\0')" ]
	# untouched: beyond the wiped region
	[ "$(dd if="$LOOP" bs=1 skip=$((20480*512)) count=4 status=none)" = "NEXT" ]
}

@test "loopback: without the Rockchip tags the full 10MiB is still cleared" {
	# No DVKR/SSKR present, so this must behave exactly as before the reserved
	# window existed - nothing in the first 10MiB survives.
	printf 'AAAA' | dd of="$LOOP" bs=512 seek=7168  conv=notrunc status=none
	printf 'BBBB' | dd of="$LOOP" bs=512 seek=8192  conv=notrunc status=none
	printf 'CCCC' | dd of="$LOOP" bs=512 seek=12000 conv=notrunc status=none
	printf 'NEXT' | dd of="$LOOP" bs=512 seek=20480 conv=notrunc status=none

	local plan; plan="$(install_plan_layout emmc ext4 0 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]

	[ -z "$(dd if="$LOOP" bs=1 skip=$((7168*512))  count=4 status=none | tr -d '\0')" ]
	[ -z "$(dd if="$LOOP" bs=1 skip=$((8192*512))  count=4 status=none | tr -d '\0')" ]
	[ -z "$(dd if="$LOOP" bs=1 skip=$((12000*512)) count=4 status=none | tr -d '\0')" ]
	[ "$(dd if="$LOOP" bs=1 skip=$((20480*512)) count=4 status=none)" = "NEXT" ]
}

@test "loopback: either Rockchip tag alone keeps the reserved window" {
	# The gate is an OR, so each tag must work on its own. A marker inside the
	# window that is not itself a tag shows the whole range survived.
	for tag_sector in "DVKR 7168" "SSKR 8192"; do
		set -- $tag_sector
		dd if=/dev/zero of="$LOOP" bs=1M count=10 conv=notrunc status=none
		printf '%s' "$1" | dd of="$LOOP" bs=512 seek="$2"  conv=notrunc status=none
		printf 'MARK'    | dd of="$LOOP" bs=512 seek=12000 conv=notrunc status=none

		local plan; plan="$(install_plan_layout emmc ext4 0 $((8*1024*1024*1024)) 512 0)"
		run install_apply_partitions "$LOOP" "$plan"
		[ "$status" -eq 0 ]
		[ "$(dd if="$LOOP" bs=1 skip=$((12000*512)) count=4 status=none)" = "MARK" ]
	done
}

@test "loopback: emmc ext4 plan yields a single MBR boot-flagged partition" {
	local plan; plan="$(install_plan_layout emmc ext4 0 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	_ptable | grep -q '^label: dos'
	_ptable | grep -q "^${LOOP}p1 : .*bootable"
	[ -b "${LOOP}p1" ]
	[ ! -b "${LOOP}p2" ]
	# p1 must start at 16MiB (sector 32768) so it clears the on-device u-boot region
	# (idbloader@32KiB + u-boot.itb@8MiB); starting at 1MiB corrupts boot.
	_ptable | grep -qE "^${LOOP}p1 : start= *32768,"
}

@test "loopback: emmc-boot plan yields /boot + /emmc_storage, p1 at 16MiB" {
	local plan; plan="$(install_plan_layout emmc-boot ext4 0 $((8*1024*1024*1024)) 512 0 gpt)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	[[ "$output" == *"boot ${LOOP}p1"* ]]
	[[ "$output" == *"storage ${LOOP}p2"* ]]
	[ -b "${LOOP}p1" ]
	[ -b "${LOOP}p2" ]
	# boot partition clears the u-boot region (starts at sector 32768 = 16MiB) and is
	# 512MiB (1048576 sectors); storage fills the rest
	_ptable | grep -qE "^${LOOP}p1 : start= *32768, size= *1048576,"
}

@test "loopback: apply_partitions echoes role->device for each partition" {
	local plan; plan="$(install_plan_layout uefi ext4 1 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[[ "$output" == *"esp ${LOOP}p1"* ]]
	[[ "$output" == *"root ${LOOP}p2"* ]]
}

@test "loopback: make_filesystems creates the requested filesystems with UUIDs" {
	local plan map; plan="$(install_plan_layout uefi ext4 1 $((8*1024*1024*1024)) 512 0)"
	install_apply_partitions "$LOOP" "$plan" >/dev/null
	# Explicit fs map: esp->vfat, root->ext4 (real newline between rows).
	map="esp ${LOOP}p1 vfat
root ${LOOP}p2 ext4"
	run install_make_filesystems "$map"
	[ "$status" -eq 0 ]
	[ "$(blkid -s TYPE -o value "${LOOP}p1")" = "vfat" ]
	[ "$(blkid -s TYPE -o value "${LOOP}p2")" = "ext4" ]
	# A generated fstab from these real UUIDs must verify.
	local ru; ru="$(install_uuid "${LOOP}p2")"
	local fstab="$BATS_TEST_TMPDIR/fstab"
	install_gen_fstab "$ru" ext4 >"$fstab"
	run install_verify_fstab "$fstab"
	[ "$status" -eq 0 ]
}

@test "loopback: bios msdos plan yields a single boot-flagged partition" {
	local plan; plan="$(install_plan_layout bios ext4 0 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	_ptable | grep -q '^label: dos'
	_ptable | grep -q "^${LOOP}p1 : .*bootable"
	[ -b "${LOOP}p1" ]
	[ ! -b "${LOOP}p2" ]
}

@test "loopback: bios gpt plan yields a bios_grub-flagged partition + root" {
	# Force GPT via a >2TiB capacity in the plan (applied to the small loop dev).
	local plan; plan="$(install_plan_layout bios ext4 0 $((3*1024*1024*1024*1024)) 512 0)"
	[[ "$plan" == *"table=gpt"* ]]
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	_ptable | grep -q "^${LOOP}p1 : .*type=21686148-6449-6E6F-744E-656564454649"
	[[ "$output" == *"biosboot ${LOOP}p1"* ]]
	[[ "$output" == *"root ${LOOP}p2"* ]]
}

@test "loopback: >2TiB capacity forces GPT even in a non-uefi plan (build#9794)" {
	# We cannot allocate 2TiB, but the planner decision is capacity-driven, so
	# feed the large capacity to the plan and apply it to the small loop dev.
	local plan; plan="$(install_plan_layout sd ext4 0 $((3*1024*1024*1024*1024)) 512 0)"
	[[ "$plan" == *"table=gpt"* ]]
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	_ptable | grep -q '^label: gpt'
}

# sd scenario with a failing /boot mapping. Only the [ -b ] checks need the loop
# device: every disk-touching step is stubbed.
_sd_scenario_map_fails() {
	install_sd_capable() { return 0; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	install_source_table_type() { echo msdos; }
	install_apply_partitions() { echo "root $LOOP"; }
	install_make_filesystems() { return 0; }
	mktemp() { mkdir -p "$BATS_TEST_TMPDIR/mp"; echo "$BATS_TEST_TMPDIR/mp"; }
	mount() { return 0; }
	umount() { return 0; }
	install_transfer_rootfs() { mkdir -p "$1/etc"; }
	install_uuid() { echo UUID=new; }
	install_map_current_boot() { return 1; }
	: >"$BATS_TEST_TMPDIR/exclude.txt"
	run install_run_scenario sd "$LOOP" ext4 "$BATS_TEST_TMPDIR/exclude.txt"
}

@test "loopback: sd scenario leaves the current boot env alone when mapping /boot fails" {
	local env="$BATS_TEST_TMPDIR/armbianEnv.txt"
	printf 'rootdev=UUID=old\n' >"$env"
	install_rpi_style_boot() { return 1; }
	install_sd_env_file() { echo "$env"; }
	_sd_scenario_map_fails
	[ "$status" -eq "$INSTALL_EX_BOOTCFG" ]
	[ "$(cat "$env")" = "rootdev=UUID=old" ]
}

@test "loopback: sd scenario leaves the current cmdline.txt alone when mapping /boot fails" {
	local fw="$BATS_TEST_TMPDIR/fw"
	mkdir -p "$fw"; printf 'console=tty1 root=UUID=old rootwait\n' >"$fw/cmdline.txt"
	install_rpi_style_boot() { return 0; }
	install_boot_firmware_dir() { echo "$fw"; }
	_sd_scenario_map_fails
	[ "$status" -eq "$INSTALL_EX_BOOTCFG" ]
	[ "$(cat "$fw/cmdline.txt")" = "console=tty1 root=UUID=old rootwait" ]
}

# btrfs on $LOOP with subvolumes @, @boot and the default @decoy. Each tree,
# the top level too, has zImage and boot/zImage holding its name.
_btrfs_layout() {
	command -v mkfs.btrfs >/dev/null || skip "btrfs-progs not available"
	install_fs_kernel_supported btrfs || skip "kernel has no btrfs"
	local top="$BATS_TEST_TMPDIR/top" sv
	mkfs.btrfs -q -f "$LOOP"
	mkdir -p "$top"; mount "$LOOP" "$top"
	mkdir -p "$top/boot"; echo top >"$top/boot/zImage"
	for sv in @ @boot @decoy; do
		btrfs subvolume create "$top/$sv"
		mkdir -p "$top/$sv/boot"; echo "$sv" >"$top/$sv/zImage"; echo "$sv" >"$top/$sv/boot/zImage"
	done
	# A mount without subvol= now gives @decoy.
	btrfs subvolume set-default "$top/@decoy"
	umount "$top"
}

# Map /boot with real findmnt, btrfs and blkid, / and /boot redirected to $cur.
# Then mount the generated lines under $nr, as the new root would at boot.
_map_and_mount() {
	cur="$BATS_TEST_TMPDIR/cur" nr="$BATS_TEST_TMPDIR/nr" fstab="$BATS_TEST_TMPDIR/fstab"
	findmnt() { local t="${*: -1}"; case "$t" in /) t="$cur" ;; /boot) t="$cur/boot" ;; esac; command findmnt "${@:1:$#-1}" "$t"; }
	btrfs() { local t="${*: -1}"; case "$t" in /) t="$cur" ;; /boot) t="$cur/boot" ;; esac; command btrfs "${@:1:$#-1}" "$t"; }
	mkdir -p "$nr/boot"; : >"$fstab"
	run install_map_current_boot "$fstab" "$nr"
	[ "$status" -eq 0 ]
	install_verify_fstab "$fstab"
	# By device path, as loop devices may lack by-uuid links. Bind source under $nr.
	sed -i -e "s|^UUID=[^[:space:]]*|$LOOP|" -e "s|^/media/boot-media/boot|$nr&|" "$fstab"
	_mount_fstab
}

_mount_fstab() {
	local tgt
	while read -r _ tgt _; do
		mount --fstab "$fstab" --target-prefix "$nr" "$tgt"
	done <"$fstab"
}

# Options column of the generated line for <mount point>.
_opts() { awk -v t="$1" '$2 == t {print $4}' "$fstab"; }

@test "loopback: sd map of a btrfs root in @ mounts @, not the default subvolume" {
	_btrfs_layout
	mkdir -p "$BATS_TEST_TMPDIR/cur"; mount -o subvol=@ "$LOOP" "$BATS_TEST_TMPDIR/cur"
	_map_and_mount
	[ "$(_opts /media/boot-media)" = "defaults,nofail,subvol=/@" ]
	[ "$(cat "$nr/boot/zImage")" = "@" ]
}

@test "loopback: sd map of a btrfs root in the default subvolume follows a later set-default" {
	_btrfs_layout
	local top="$BATS_TEST_TMPDIR/top"
	mkdir -p "$BATS_TEST_TMPDIR/cur" "$top"; mount -o subvol=@ "$LOOP" "$BATS_TEST_TMPDIR/cur"
	mount -o subvolid=5 "$LOOP" "$top"
	btrfs subvolume set-default "$top/@"
	_map_and_mount
	[ "$(_opts /media/boot-media)" = "defaults,nofail" ]
	[ "$(cat "$nr/boot/zImage")" = "@" ]
	# Like U-Boot, the new root then reads /boot from the new default.
	umount "$nr/boot" "$nr/media/boot-media"
	btrfs subvolume set-default "$top/@decoy"
	_mount_fstab
	[ "$(cat "$nr/boot/zImage")" = "@decoy" ]
}

@test "loopback: sd map of a top-level btrfs root mounts subvol=/" {
	_btrfs_layout
	mkdir -p "$BATS_TEST_TMPDIR/cur"; mount -o subvolid=5 "$LOOP" "$BATS_TEST_TMPDIR/cur"
	_map_and_mount
	[ "$(_opts /media/boot-media)" = "defaults,nofail,subvol=/" ]
	[ "$(cat "$nr/boot/zImage")" = "top" ]
}

@test "loopback: sd map of a btrfs /boot subvolume mounts it at /boot" {
	_btrfs_layout
	mkdir -p "$BATS_TEST_TMPDIR/cur"; mount -o subvol=@ "$LOOP" "$BATS_TEST_TMPDIR/cur"
	mount -o subvol=@boot "$LOOP" "$BATS_TEST_TMPDIR/cur/boot"
	_map_and_mount
	[ "$(_opts /boot)" = "defaults,nofail,subvol=/@boot" ]
	[ "$(wc -l <"$fstab")" -eq 1 ]
	[ "$(cat "$nr/boot/zImage")" = "@boot" ]
}

@test "loopback: sd map refuses a /boot bound from the old root, as a second sd install sees it" {
	_btrfs_layout
	cur="$BATS_TEST_TMPDIR/cur" fstab="$BATS_TEST_TMPDIR/fstab"
	mkdir -p "$BATS_TEST_TMPDIR/old" "$cur/boot"; mount -o subvol=@ "$LOOP" "$BATS_TEST_TMPDIR/old"
	mount --bind "$BATS_TEST_TMPDIR/old/boot" "$cur/boot"
	findmnt() { local t="${*: -1}"; case "$t" in /) t="$cur" ;; /boot) t="$cur/boot" ;; esac; command findmnt "${@:1:$#-1}" "$t"; }
	: >"$fstab"
	run install_map_current_boot "$fstab" "$BATS_TEST_TMPDIR/nr"
	[ "$status" -eq "$INSTALL_EX_BOOTCFG" ]
	[ ! -s "$fstab" ]
}

@test "loopback: sd map of an ext4 root binds its /boot without subvol=" {
	mkfs.ext4 -qF "$LOOP"
	mkdir -p "$BATS_TEST_TMPDIR/cur"; mount "$LOOP" "$BATS_TEST_TMPDIR/cur"
	mkdir -p "$BATS_TEST_TMPDIR/cur/boot"; echo ext4 >"$BATS_TEST_TMPDIR/cur/boot/zImage"
	_map_and_mount
	[ "$(_opts /media/boot-media)" = "defaults,nofail" ]
	[ "$(cat "$nr/boot/zImage")" = "ext4" ]
}
