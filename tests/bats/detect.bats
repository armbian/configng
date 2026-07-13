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
	# Three disks in the fixture -> exactly three lines.
	[ "${#lines[@]}" -eq 3 ]
	# No line may contain two device names glued together.
	for line in "${lines[@]}"; do
		name="${line%%$'\t'*}"
		[[ "$name" != *" "* ]]
	done
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

@test "detect: surfaces sector size and model" {
	run install_detect_targets "" "$(cat "$FIX/lsblk_4kn_large.json")"
	# 4Kn NVMe reports phy-sec 4096 in field 4.
	echo "$output" | grep -qP '^nvme0n1\tnvme\t4000787030016\t4096\t'
	[[ "$output" == *"WD Black SN850 4TB"* ]]
}
