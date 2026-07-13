#!/usr/bin/env bats
#
# Integration test for the Windows dual-boot primitives against a real,
# loop-backed "Windows" disk (GPT + ESP + NTFS). It exercises the risky part -
# NTFS detection, shrink, and carving an Armbian partition out of the freed tail
# - and asserts Windows survives intact. Needs root + ntfsprogs; skips otherwise.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null
	export LC_ALL=C LANG=C

	[[ "$(id -u)" -eq 0 ]] || skip "needs root for losetup"
	command -v mkfs.ntfs  >/dev/null || skip "mkfs.ntfs (ntfs-3g) not available"
	command -v ntfsresize >/dev/null || skip "ntfsresize not available"
	command -v parted     >/dev/null || skip "parted not available"

	IMG="$BATS_TEST_TMPDIR/win.img"
	truncate -s 12G "$IMG"
	LOOP="$(losetup -f --show -P "$IMG")"

	# Fabricate a Windows/UEFI layout: GPT, ESP (vfat) + one big NTFS volume.
	parted -s "$LOOP" mklabel gpt
	parted -s "$LOOP" mkpart primary fat32 1MiB 301MiB
	parted -s "$LOOP" set 1 esp on
	parted -s "$LOOP" mkpart primary ntfs 301MiB 100%
	partprobe "$LOOP"; udevadm settle
	mkfs.vfat -F 32 "${LOOP}p1" >/dev/null 2>&1
	mkfs.ntfs -Q -F "${LOOP}p2" >/dev/null 2>&1

	# Drop marker files: a Windows boot manager in the ESP and payload in NTFS.
	local m="$BATS_TEST_TMPDIR/mnt"; mkdir -p "$m"
	mount "${LOOP}p1" "$m"; mkdir -p "$m/EFI/Microsoft/Boot"; echo bootmgr >"$m/EFI/Microsoft/Boot/bootmgfw.efi"; umount "$m"
	mount -t ntfs-3g "${LOOP}p2" "$m"; head -c 5000000 /dev/urandom >"$m/payload.bin"; PAYSUM="$(sha256sum "$m/payload.bin" | cut -d' ' -f1)"; umount "$m"
	udevadm settle
}

teardown() {
	[[ -n "${LOOP:-}" ]] && losetup -d "$LOOP" 2>/dev/null || true
}

@test "dualboot: detect_windows finds the ESP and the NTFS volume" {
	run install_detect_windows "$LOOP"
	[ "$status" -eq 0 ]
	[[ "$output" == *"esp=${LOOP}p1"* ]]
	[[ "$output" == *"windows=${LOOP}p2"* ]]
}

@test "dualboot: windows_min_bytes reports a plausible NTFS minimum" {
	run install_windows_min_bytes "${LOOP}p2"
	[ "$status" -eq 0 ]
	[ "$output" -gt 0 ]
	# Minimum must be smaller than the ~11.7G volume.
	[ "$output" -lt $((11 * 1024 * 1024 * 1024)) ]
}

@test "dualboot: shrink Windows, carve Armbian partition, Windows survives" {
	local win="${LOOP}p2"
	local before; before="$(blockdev --getsize64 "$win")"

	# Shrink the NTFS volume to 4 GiB.
	run install_shrink_windows "$LOOP" "$win" $((4 * 1024 * 1024 * 1024))
	[ "$status" -eq 0 ]

	# The partition actually got smaller...
	local after; after="$(blockdev --getsize64 "$win")"
	[ "$after" -lt "$before" ]
	# ...and there is now free space to carve into.
	partprobe "$LOOP"; udevadm settle

	# Create + format the Armbian partition in the freed tail.
	local root; root="$(install_create_free_partition "$LOOP" ext4)"
	[ -b "$root" ]
	run install_make_filesystems "root $root ext4"
	[ "$status" -eq 0 ]
	[ "$(blkid -s TYPE -o value "$root")" = "ext4" ]

	# Windows is intact: still NTFS, still consistent, payload unchanged, and the
	# ESP still holds the Windows boot manager.
	[ "$(blkid -s TYPE -o value "$win")" = "ntfs" ]
	ntfsresize -f --info "$win" >/dev/null 2>&1
	local m="$BATS_TEST_TMPDIR/verify"; mkdir -p "$m"
	mount -t ntfs-3g "$win" "$m"
	[ "$(sha256sum "$m/payload.bin" | cut -d' ' -f1)" = "$PAYSUM" ]
	umount "$m"
	mount "${LOOP}p1" "$m"
	[ -f "$m/EFI/Microsoft/Boot/bootmgfw.efi" ]
	umount "$m"
}
