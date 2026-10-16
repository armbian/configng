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
