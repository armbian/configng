#!/usr/bin/env bats
#
# Integration test for the Windows dual-boot primitives against a real,
# loop-backed "Windows" disk (GPT + ESP + NTFS). It exercises the risky part -
# NTFS detection, shrink, and carving an Armbian partition out of the freed tail
# - and asserts Windows survives intact. Needs root + ntfsprogs; skips otherwise.

setup() {
	# Run under pipefail so a masked-exit-code bug (e.g. `yes | ntfsresize`
	# reporting failure on SIGPIPE) is caught, mirroring a strict caller.
	set -o pipefail
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

	# Fabricate a real Windows/UEFI layout: GPT, ESP (vfat) + big NTFS (C:) + a
	# trailing NTFS "recovery" partition at the disk END. The trailing partition
	# is what tripped up "return the highest-numbered partition" - the free space
	# after shrinking C: sits BEFORE it.
	parted -s "$LOOP" mklabel gpt
	parted -s "$LOOP" mkpart primary fat32 1MiB 301MiB
	parted -s "$LOOP" set 1 esp on
	parted -s "$LOOP" mkpart primary ntfs 301MiB 10GiB
	parted -s "$LOOP" mkpart primary ntfs 10GiB 100%
	partprobe "$LOOP"; udevadm settle
	mkfs.vfat -F 32 "${LOOP}p1" >/dev/null 2>&1
	mkfs.ntfs -Q -F "${LOOP}p2" >/dev/null 2>&1
	mkfs.ntfs -Q -F "${LOOP}p3" >/dev/null 2>&1
	# Re-probe the freshly-made filesystems into the udev/blkid db. `udevadm
	# settle` alone does not re-probe, so lsblk (used by install_detect_windows)
	# can otherwise report empty FSTYPE for these loop partitions on newer
	# runner images. blkid warms the cache and `udevadm trigger` re-reads it.
	blkid "${LOOP}p1" "${LOOP}p2" "${LOOP}p3" >/dev/null 2>&1 || true
	udevadm trigger --settle "${LOOP}p1" "${LOOP}p2" "${LOOP}p3" >/dev/null 2>&1 \
		|| udevadm trigger --settle >/dev/null 2>&1 || true

	# Marker files: Windows boot manager in the ESP, payload in C:, marker in the
	# trailing recovery partition (must survive untouched).
	local m="$BATS_TEST_TMPDIR/mnt"; mkdir -p "$m"
	mount "${LOOP}p1" "$m"; mkdir -p "$m/EFI/Microsoft/Boot"; echo bootmgr >"$m/EFI/Microsoft/Boot/bootmgfw.efi"; umount "$m"
	mount -t ntfs-3g "${LOOP}p2" "$m"; head -c 5000000 /dev/urandom >"$m/payload.bin"; PAYSUM="$(sha256sum "$m/payload.bin" | cut -d' ' -f1)"; umount "$m"
	mount -t ntfs-3g "${LOOP}p3" "$m"; echo winre >"$m/RECOVERY.marker"; RECSUM="$(sha256sum "$m/RECOVERY.marker" | cut -d' ' -f1)"; umount "$m"
	udevadm settle
}

teardown() {
	# A failed assertion can abort a test before its own umount runs, leaving a
	# partition mounted and the loop device busy. Unmount everything we create
	# first, then detach - and don't silently swallow a still-busy device.
	local m
	for m in "$BATS_TEST_TMPDIR/verify" "$BATS_TEST_TMPDIR/rec" "$BATS_TEST_TMPDIR/mnt"; do
		mountpoint -q "$m" && umount "$m"
	done
	[[ -n "${LOOP:-}" ]] && losetup -d "$LOOP"
}

@test "dualboot: detect_windows finds the ESP and the NTFS volume" {
	run install_detect_windows "$LOOP"
	if [ "$status" -ne 0 ]; then
		echo "# detect_windows FAILED status=$status output=[$output]" >&3
		echo "# lsblk: $(lsblk -b -po NAME,FSTYPE,PARTTYPENAME,SIZE --json "$LOOP" 2>&1 | tr '\n' ' ')" >&3
		echo "# parted: $(parted -sm "$LOOP" print 2>&1 | tr '\n' '|')" >&3
		echo "# blkid: p1=[$(blkid "${LOOP}p1" 2>&1)] p2=[$(blkid "${LOOP}p2" 2>&1)]" >&3
	fi
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

	# Create + format the Armbian partition in the freed GAP (between C: and the
	# trailing recovery). It must be the NEW partition, never the recovery one.
	local root; root="$(install_create_free_partition "$LOOP" ext4)"
	[ -b "$root" ]
	[ "$root" != "${LOOP}p3" ]          # regression: not the trailing recovery part
	run install_make_filesystems "root $root ext4"
	[ "$status" -eq 0 ]
	[ "$(blkid -s TYPE -o value "$root")" = "ext4" ]

	# The trailing recovery partition is untouched: still NTFS, marker intact.
	[ "$(blkid -s TYPE -o value "${LOOP}p3")" = "ntfs" ]
	local mr="$BATS_TEST_TMPDIR/rec"; mkdir -p "$mr"
	mount -t ntfs-3g "${LOOP}p3" "$mr"
	[ "$(sha256sum "$mr/RECOVERY.marker" | cut -d' ' -f1)" = "$RECSUM" ]
	umount "$mr"

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
