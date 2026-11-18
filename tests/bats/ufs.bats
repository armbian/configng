#!/usr/bin/env bats
#
# Unit tests for UFS logical unit detection, fed a fake sysfs tree.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	FIX="${BATS_TEST_DIRNAME}/fixtures"
	export INSTALL_SYSFS="$BATS_TEST_TMPDIR/sys"
	HBA="$INSTALL_SYSFS/devices/platform/2a2d0000.ufs"
	mkdir -p "$HBA/host0" "$HBA/attributes" "$INSTALL_SYSFS/class/scsi_host" "$INSTALL_SYSFS/class/scsi_device"
	echo ufshcd >"$HBA/host0/proc_name"
	ln -s "$HBA/host0" "$INSTALL_SYSFS/class/scsi_host/host0"
	ln -s "$HBA/host0" "$HBA/host0/device"
}

# fake_lu <lun> <blk> <bytes> [boot_lun_id] [lun_memory_type]
fake_lu() {
	local d="$INSTALL_SYSFS/class/scsi_device/0:0:0:$1"
	mkdir -p "$d/device/block/$2" "$INSTALL_SYSFS/block/$2"
	echo $(($3 / 512)) >"$INSTALL_SYSFS/block/$2/size"
	if [[ -n "${4:-}" ]]; then
		mkdir -p "$d/device/unit_descriptor"
		echo "$4" >"$d/device/unit_descriptor/boot_lun_id"
		echo "${5:-0x00}" >"$d/device/unit_descriptor/lun_memory_type"
	fi
}

nanopi_m5_luns() {
	fake_lu 0 sda 255894487040 0x00 0x00
	fake_lu 1 sdb 4194304 0x01 0x03
	fake_lu 2 sdc 4194304 0x02 0x03
	fake_lu 3 sdd 8388608 0x00 0x03
	# Well-known LU (REPORT LUNS), no block device.
	mkdir -p "$INSTALL_SYSFS/class/scsi_device/0:0:0:49476/device"
}

@test "ufs: classifies the NanoPi M5 LUs from the unit descriptors" {
	nanopi_m5_luns
	run install_ufs_luns
	[ "$status" -eq 0 ]
	[ "$output" = "sda general
sdb boot-a
sdc boot-b
sdd aux" ]
}

@test "ufs: falls back to the LUN number without unit descriptors" {
	fake_lu 0 sda 255894487040
	fake_lu 1 sdb 4194304
	fake_lu 2 sdc 4194304
	fake_lu 3 sdd 8388608
	run install_ufs_luns
	[[ "$output" == *"sda general"* ]]
	[[ "$output" == *"sdb boot-a"* ]]
	[[ "$output" == *"sdc boot-b"* ]]
	[[ "$output" == *"sdd aux"* ]]
}

@test "ufs: Qualcomm firmware LUs are aux, the largest normal LU is the target" {
	fake_lu 0 sda $((120 * 1024 * 1024 * 1024)) 0x00 0x00
	fake_lu 1 sdb $((8 * 1024 * 1024)) 0x01 0x00
	fake_lu 2 sdc $((8 * 1024 * 1024)) 0x02 0x00
	fake_lu 3 sdd $((8 * 1024 * 1024)) 0x00 0x00
	fake_lu 4 sde $((2 * 1024 * 1024 * 1024)) 0x00 0x00
	fake_lu 5 sdf $((64 * 1024 * 1024)) 0x00 0x00
	run install_ufs_luns
	[ "$(grep -c ' general$' <<<"$output")" -eq 1 ]
	[[ "$output" == *"sda general"* ]]
	[[ "$output" == *"sde aux"* ]]
}

@test "ufs: no ufshcd host means no LUs" {
	echo ahci >"$HBA/host0/proc_name"
	nanopi_m5_luns
	run install_ufs_luns
	[ -z "$output" ]
	run install_ufs_boot_lun
	[ -z "$output" ]
}

@test "ufs: boot LU follows bBootLunEn, A by default" {
	nanopi_m5_luns
	run install_ufs_boot_lun
	[ "$output" = /dev/sdb ]
	echo 0x00000001 >"$HBA/attributes/boot_lun_enabled"
	run install_ufs_boot_lun
	[ "$output" = /dev/sdb ]
	echo 0x00000002 >"$HBA/attributes/boot_lun_enabled"
	run install_ufs_boot_lun
	[ "$output" = /dev/sdc ]
}

@test "ufs: no boot LU when bBootLunEn disables boot" {
	nanopi_m5_luns
	echo 0x00000000 >"$HBA/attributes/boot_lun_enabled"
	run install_ufs_boot_lun sda
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "ufs detect: general LU gets role ufs, boot and vendor LUs are dropped" {
	nanopi_m5_luns
	run install_detect_targets mmcblk0 "$(cat "$FIX/lsblk_ufs.json")"
	[ "$status" -eq 0 ]
	[ "$output" = "sda	ufs	255894487040	4096	-	false	BWU3AKC46C256G" ]
}

@test "ufs detect: explicit empty LU map keeps the plain disk roles" {
	run install_detect_targets mmcblk0 "$(cat "$FIX/lsblk_ufs.json")" ""
	echo "$output" | grep -qP '^sda\tdisk\t'
	echo "$output" | grep -qP '^sdb\tdisk\t'
}

@test "ufs: a blank module (no general LU) is reported unprovisioned" {
	run install_ufs_unprovisioned
	[ "$status" -eq 0 ]
	# Unprovisioned LU 0 that exposes no capacity yet.
	fake_lu 0 sda 0 0x00 0x00
	run install_ufs_unprovisioned
	[ "$status" -eq 0 ]
	run install_ufs_luns
	[[ "$output" != *general* ]]
}

@test "ufs: a provisioned module or no UFS at all is not reported" {
	nanopi_m5_luns
	run install_ufs_unprovisioned
	[ "$status" -ne 0 ]
	echo ahci >"$HBA/host0/proc_name"
	run install_ufs_unprovisioned
	[ "$status" -ne 0 ]
}

# fake_part <blk> <n> <start_sectors_512>
fake_part() {
	mkdir -p "$INSTALL_SYSFS/block/$1/$1$2"
	echo "$3" >"$INSTALL_SYSFS/block/$1/$1$2/start"
}

@test "ufs room: partitions at 16MiB leave room for u-boot.itb" {
	nanopi_m5_luns
	fake_part sda 1 32768
	run install_ufs_uboot_room sda
	[ "$status" -eq 0 ]
	# An unpartitioned LU has room too.
	wipefs() { :; }
	run install_ufs_uboot_room sdb
	[ "$status" -eq 0 ]
}

@test "ufs room: a filesystem on the whole LU is refused" {
	nanopi_m5_luns
	wipefs() { echo ext4; }
	run install_ufs_uboot_room sda
	[ "$status" -ne 0 ]
	# ext4 plus a stale vfat boot sector: blkid -p sees nothing, wipefs both.
	wipefs() { printf 'vfat\nvfat\next4\n'; }
	run install_ufs_uboot_room sda
	[ "$status" -ne 0 ]
}

@test "ufs room: a bare partition table passes, a failed probe is refused" {
	nanopi_m5_luns
	wipefs() { printf 'gpt\nPMBR\n'; }
	run install_ufs_uboot_room sda
	[ "$status" -eq 0 ]
	wipefs() { return 1; }
	run install_ufs_uboot_room sda
	[ "$status" -ne 0 ]
}

@test "ufs room: a 1MiB partition start is refused" {
	nanopi_m5_luns
	fake_part sda 1 2048
	run install_ufs_uboot_room sda
	[ "$status" -ne 0 ]
}

@test "ufs room: a larger BOOTLOADER_RESERVED_MIB raises the floor" {
	nanopi_m5_luns
	fake_part sda 1 32768
	BOOTLOADER_RESERVED_MIB=32
	run install_ufs_uboot_room sda
	[ "$status" -ne 0 ]
}

@test "ufs: with two UFS hosts the boot LU comes from the target's host" {
	nanopi_m5_luns
	echo 0x00000001 >"$HBA/attributes/boot_lun_enabled"
	local hba1="$INSTALL_SYSFS/devices/platform/2a2e0000.ufs"
	mkdir -p "$hba1/host1" "$hba1/attributes"
	echo ufshcd >"$hba1/host1/proc_name"
	echo 0x00000002 >"$hba1/attributes/boot_lun_enabled"
	ln -s "$hba1/host1" "$INSTALL_SYSFS/class/scsi_host/host1"
	ln -s "$hba1/host1" "$hba1/host1/device"
	local lu
	for lu in "0 sde $((64 * 1024 * 1024 * 1024)) 0x00" "1 sdf 4194304 0x01" "2 sdg 4194304 0x02"; do
		set -- $lu
		mkdir -p "$INSTALL_SYSFS/class/scsi_device/1:0:0:$1/device/block/$2" \
			"$INSTALL_SYSFS/class/scsi_device/1:0:0:$1/device/unit_descriptor" "$INSTALL_SYSFS/block/$2"
		echo $(($3 / 512)) >"$INSTALL_SYSFS/block/$2/size"
		echo "$4" >"$INSTALL_SYSFS/class/scsi_device/1:0:0:$1/device/unit_descriptor/boot_lun_id"
		echo 0x00 >"$INSTALL_SYSFS/class/scsi_device/1:0:0:$1/device/unit_descriptor/lun_memory_type"
	done
	run install_ufs_boot_lun sda
	[ "$output" = /dev/sdb ]
	run install_ufs_boot_lun sde
	[ "$output" = /dev/sdg ]
	run install_ufs_luns 1
	[ "$output" = "sde general
sdf boot-a
sdg boot-b" ]
	# A disk on no UFS host has no boot LU.
	run install_ufs_boot_lun nvme0n1
	[ -z "$output" ]
	# One blank host is enough to report it.
	rm -rf "$INSTALL_SYSFS/class/scsi_device/1:0:0:0"
	run install_ufs_unprovisioned
	[ "$status" -eq 0 ]
}
