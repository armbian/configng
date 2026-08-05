#!/usr/bin/env bats
#
# Unit tests for install_detect_targets - the storage inventory. The headline
# guarantee is build#8738: one record per device, never space-joined.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	FIX="${BATS_TEST_DIRNAME}/fixtures"
}

@test "detect: one TSV record per disk, no concatenation (build#8738)" {
	run install_detect_targets "" "$(cat "$FIX/lsblk_multidisk.json")"
	[ "$status" -eq 0 ]
	# Six entries in the fixture, but zram0/zram1/loop0 are filtered out -> three.
	[ "${#lines[@]}" -eq 3 ]
	# No line may contain two device names glued together.
	for line in "${lines[@]}"; do
		name="${line%%$'\t'*}"
		[[ "$name" != *" "* ]]
	done
}

@test "detect: excludes zram / loop / ram pseudo-devices" {
	run install_detect_targets "" "$(cat "$FIX/lsblk_multidisk.json")"
	[ "$status" -eq 0 ]
	[[ "$output" != *"zram"* ]]
	[[ "$output" != *"loop"* ]]
}

@test "detect: emits a '-' placeholder for an absent bus so fields never shift" {
	# mmcblk0 has tran=null; the bus column must be "-", not empty, and the row
	# must still parse into 7 tab-separated fields with role=mmc.
	run install_detect_targets "" "$(cat "$FIX/lsblk_multidisk.json")"
	local row; row=$(printf '%s\n' "${lines[@]}" | grep '^mmcblk0')
	IFS=$'\t' read -r n role sz sec bus rota model <<<"$row"
	[ "$role" = "mmc" ]
	[ "$bus" = "-" ]
	[ "$rota" = "false" ]
}

@test "detect: excludes the running-root disk" {
	run install_detect_targets "mmcblk0" "$(cat "$FIX/lsblk_multidisk.json")"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "$output" != *"mmcblk0"* ]]
	[[ "$output" == *"nvme0n1"* ]]
	[[ "$output" == *"sda"* ]]
}

@test "detect: classifies roles from name and bus" {
	run install_detect_targets "" "$(cat "$FIX/lsblk_multidisk.json")"
	# fields: name role size sector bus rota model
	echo "$output" | grep -qP '^mmcblk0\tmmc\t'
	echo "$output" | grep -qP '^nvme0n1\tnvme\t'
	echo "$output" | grep -qP '^sda\tusb\t'
}

@test "detect: excludes eMMC boot0/boot1/rpmb hardware partitions" {
	# An eMMC exposes read-only boot areas and an RPMB partition as their own
	# TYPE=disk devices (see the installer's destination menu). Only the main
	# mmcblk0 user-data device may be offered as an install target.
	run install_detect_targets "" "$(cat "$FIX/lsblk_emmc.json")"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 1 ]
	echo "$output" | grep -qP '^mmcblk0\tmmc\t'
	[[ "$output" != *"boot0"* ]]
	[[ "$output" != *"boot1"* ]]
	[[ "$output" != *"rpmb"* ]]
}

@test "detect: surfaces sector size and model" {
	run install_detect_targets "" "$(cat "$FIX/lsblk_4kn_large.json")"
	# 4Kn NVMe reports phy-sec 4096 in field 4.
	echo "$output" | grep -qP '^nvme0n1\tnvme\t4000787030016\t4096\t'
	[[ "$output" == *"WD Black SN850 4TB"* ]]
}
