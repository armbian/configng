#!/usr/bin/env bats
#
# Unit tests for the boot modes the installer offers per target disk.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	source "${BATS_TEST_DIRNAME}/../../tools/modules/system/module_partitioner.sh"
	INSTALL_LOG=/dev/null
	write_uboot_platform() { :; }
	partitioner_mtd_list() { :; }
	partitioner_emmc_device() { echo /dev/mmcblk0; }
	unset BOOTLOADER_BOOTS_FROM
}

@test "modes: nvme without BOOTLOADER_BOOTS_FROM keeps boot on current media" {
	run partitioner_modes_for nvme nvme0n1
	[ "$status" -eq 0 ]
	[[ " $output " == *" sd split-emmc "* ]]
	[[ " $output " != *" standalone "* ]]
}

@test "modes: standalone is offered first for a role the bootloader boots from" {
	BOOTLOADER_BOOTS_FROM="nvme usb"
	run partitioner_modes_for nvme nvme0n1
	[[ " $output " == *" standalone sd split-emmc "* ]]
	run partitioner_modes_for usb sda
	[[ " $output " == *" standalone sd "* ]]
}

@test "modes: standalone is not offered for a role missing from the list" {
	BOOTLOADER_BOOTS_FROM="nvme"
	run partitioner_modes_for sata sda
	[[ " $output " != *" standalone "* ]]
}

@test "cli: standalone refuses a target the bootloader does not boot from" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point --target at"
	partitioner_root_disk() { echo none; }
	install_detect_targets() { printf '%s\tsata\t0\t512\tsata\t0\tdisk\n' "${dev#/dev/}"; }
	partitioner_ensure_fs_tool() { return 1; }
	install_run_scenario() { echo "scenario ran"; return 99; }
	INSTALL_EXCLUDE="$BATS_TEST_TMPDIR/exclude"
	: >"$INSTALL_EXCLUDE"
	BOOTLOADER_BOOTS_FROM="nvme"
	run partitioner_cli_install --target "$dev" --boot standalone --fs ext4 --yes
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	[[ "$output" == *"--boot standalone needs a disk"* ]]
	[[ "$output" != *"scenario ran"* ]]
}

@test "cli: standalone passes the gate for a target the bootloader boots from" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point --target at"
	partitioner_root_disk() { echo none; }
	install_detect_targets() { printf '%s\tnvme\t0\t512\tnvme\t0\tdisk\n' "${dev#/dev/}"; }
	partitioner_ensure_fs_tool() { return 1; }
	install_run_scenario() { echo "scenario ran"; return 99; }
	INSTALL_EXCLUDE="$BATS_TEST_TMPDIR/exclude"
	: >"$INSTALL_EXCLUDE"
	BOOTLOADER_BOOTS_FROM="nvme usb"
	run partitioner_cli_install --target "$dev" --boot standalone --fs ext4 --yes
	[ "$status" -eq "$INSTALL_EX_TOOL" ]
	[[ "$output" != *"--boot standalone needs a disk"* ]]
}
