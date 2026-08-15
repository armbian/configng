#!/usr/bin/env bats
#
# Integration tests for the side-effecting engine primitives against a real
# (loop-backed) block device: partitioning, mkfs and fstab generation. These
# need root + losetup, so they run under sudo in CI and skip locally otherwise.
#
# They exercise the exact chain the installer uses, minus the rootfs rsync and
# bootloader write, and assert with parted/blkid/lsblk that the on-disk result
# matches the plan - proving the GPT/MBR/flag/blocksize fixes end to end.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null

	if [[ "$(id -u)" -ne 0 ]]; then skip "needs root for losetup"; fi
	command -v losetup >/dev/null || skip "losetup not available"
	command -v parted  >/dev/null || skip "parted not available"

	IMG="$BATS_TEST_TMPDIR/disk.img"
	truncate -s 8G "$IMG"
	LOOP="$(losetup -f --show -P "$IMG")"
}

teardown() {
	[[ -n "${LOOP:-}" ]] && losetup -d "$LOOP" 2>/dev/null || true
}

@test "loopback: uefi plan yields GPT with an ESP-flagged first partition" {
	local plan; plan="$(install_plan_layout uefi ext4 1 $((8*1024*1024*1024)) 512 0)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	# parted reports the label type and the esp flag (force C locale - parted
	# translates flag names, e.g. "boot" -> "zagon" under a Slovenian locale).
	LC_ALL=C parted -sm "$LOOP" print | grep -q '^/dev/.*:gpt:'
	LC_ALL=C parted -sm "$LOOP" print | head -3 | grep -q 'esp'
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
	LC_ALL=C parted -sm "$LOOP" print | grep -q '^/dev/.*:msdos:'
	LC_ALL=C parted -sm "$LOOP" print | grep -q 'boot'
	[ -b "${LOOP}p1" ]
	[ ! -b "${LOOP}p2" ]
	# p1 must start at 16MiB so it clears the on-device u-boot region
	# (idbloader@32KiB + u-boot.itb@8MiB); starting at 1MiB corrupts boot.
	LC_ALL=C parted -sm "$LOOP" unit MiB print | grep -qE '^1:16\.0MiB:'
}

@test "loopback: emmc-boot plan yields /boot + /emmc_storage, p1 at 16MiB" {
	local plan; plan="$(install_plan_layout emmc-boot ext4 0 $((8*1024*1024*1024)) 512 0 gpt)"
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	[[ "$output" == *"boot ${LOOP}p1"* ]]
	[[ "$output" == *"storage ${LOOP}p2"* ]]
	[ -b "${LOOP}p1" ]
	[ -b "${LOOP}p2" ]
	# boot partition clears the u-boot region and is ~512MiB; storage fills the rest
	LC_ALL=C parted -sm "$LOOP" unit MiB print | grep -qE '^1:16\.0MiB:528'
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
	LC_ALL=C parted -sm "$LOOP" print | grep -q '^/dev/.*:msdos:'
	LC_ALL=C parted -sm "$LOOP" print | grep -q 'boot'
	[ -b "${LOOP}p1" ]
	[ ! -b "${LOOP}p2" ]
}

@test "loopback: bios gpt plan yields a bios_grub-flagged partition + root" {
	# Force GPT via a >2TiB capacity in the plan (applied to the small loop dev).
	local plan; plan="$(install_plan_layout bios ext4 0 $((3*1024*1024*1024*1024)) 512 0)"
	[[ "$plan" == *"table=gpt"* ]]
	run install_apply_partitions "$LOOP" "$plan"
	[ "$status" -eq 0 ]
	LC_ALL=C parted -sm "$LOOP" print | grep -q 'bios_grub'
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
	LC_ALL=C parted -sm "$LOOP" print | grep -q '^/dev/.*:gpt:'
}
