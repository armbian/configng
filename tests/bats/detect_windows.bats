#!/usr/bin/env bats
#
# Unit tests for Windows dual-boot detection (_install_windows_parts /
# install_detect_windows). The headline guarantee: pick the Windows *system*
# NTFS volume (C:), never the tiny WinRE recovery partition, and sort by numeric
# size (lsblk may emit size as a string).

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null
	FIX="${BATS_TEST_DIRNAME}/fixtures"
}

@test "detect_windows: picks C: (Microsoft basic data), not the WinRE recovery part" {
	run install_detect_windows /dev/sda "$(cat "$FIX/lsblk_windows.json")"
	[ "$status" -eq 0 ]
	[[ "$output" == *"esp=/dev/sda1"* ]]
	[[ "$output" == *"windows=/dev/sda3"* ]]
	[[ "$output" != *"windows=/dev/sda4"* ]]
}

@test "detect_windows: numeric size sort (string sort would wrongly pick 781MB WinRE)" {
	# Only the pure helper, exercising the sort directly.
	run _install_windows_parts "$(cat "$FIX/lsblk_windows.json")"
	[[ "$output" == *"windows=/dev/sda3"* ]]
}

@test "detect_windows: a BitLocker C: yields no target and a clear hint" {
	# sda3 is Microsoft basic data but NOT ntfs (BitLocker); only WinRE is ntfs.
	local json; json="$(jq '(.blockdevices[0].children[2].fstype)="BitLocker"' "$FIX/lsblk_windows.json")"
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	run install_detect_windows /dev/sda "$json"
	[ "$status" -eq 65 ]                      # INSTALL_EX_NODEV
	grep -qi "BitLocker" "$BATS_TEST_TMPDIR/log"
}

@test "has_bitlocker: true when a BitLocker volume is present, false otherwise" {
	local bl; bl="$(jq '(.blockdevices[0].children[2].fstype)="BitLocker"' "$FIX/lsblk_windows.json")"
	run install_disk_has_bitlocker /dev/sda "$bl"
	[ "$status" -eq 0 ]
	# Plain NTFS Windows -> not BitLocker.
	run install_disk_has_bitlocker /dev/sda "$(cat "$FIX/lsblk_windows.json")"
	[ "$status" -ne 0 ]
}

@test "detect_windows: no NTFS at all is reported as no ESP+NTFS pair" {
	# No NTFS and no "basic data" partition -> the generic message, not the
	# BitLocker hint.
	local json; json="$(jq '
		(.blockdevices[0].children[2].fstype)="ext4"
		| (.blockdevices[0].children[2].parttypename)="Linux filesystem"
		| (.blockdevices[0].children[3].fstype)="ext4"
		| (.blockdevices[0].children[3].parttypename)="Linux filesystem"' "$FIX/lsblk_windows.json")"
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	run install_detect_windows /dev/sda "$json"
	[ "$status" -eq 65 ]
	grep -qi "no ESP+NTFS pair" "$BATS_TEST_TMPDIR/log"
}
