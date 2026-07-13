#!/usr/bin/env bats
#
# Unit tests for the pure partition planner. These lock down the partitioning
# bug classes: MBR-only tables (build#9454), MBR on >2TiB / 4Kn (build#9794),
# and missing boot/ESP flags (build#6905).

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	GIB=$(( 1024 * 1024 * 1024 ))
	TIB=$(( 1024 * GIB ))
}

# --- table type decision -----------------------------------------------------

@test "table: small 512b non-uefi disk -> msdos" {
	run install_table_type 0 $(( 32 * GIB )) 512
	[ "$output" = "msdos" ]
}

@test "table: uefi always -> gpt" {
	run install_table_type 1 $(( 32 * GIB )) 512
	[ "$output" = "gpt" ]
}

@test "table: >2TiB disk -> gpt even without uefi (build#9794)" {
	run install_table_type 0 $(( 4 * TIB )) 512
	[ "$output" = "gpt" ]
}

@test "table: 4Kn disk -> gpt (build#9454)" {
	run install_table_type 0 $(( 32 * GIB )) 4096
	[ "$output" = "gpt" ]
}

# --- uefi layout -------------------------------------------------------------

@test "plan uefi: gpt, ESP first with esp+boot flags, root fills rest" {
	run install_plan_layout uefi ext4 1 $(( 256 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"table=gpt"* ]]
	[[ "$output" == *"part=esp:512MiB:vfat:esp,boot"* ]]
	[[ "$output" == *"part=root:100%:ext4:"* ]]
}

@test "plan uefi: table stays gpt even for a tiny 512b disk" {
	run install_plan_layout uefi ext4 1 $(( 8 * GIB )) 512 0
	[[ "$output" == *"table=gpt"* ]]
}

# --- emmc full install -------------------------------------------------------

@test "plan emmc ext4: single boot-flagged root partition" {
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"table=msdos"* ]]
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
	# ext4 keeps /boot as a directory: no separate boot partition.
	[[ "$output" != *"part=boot:"* ]]
}

@test "plan emmc btrfs: separate ext4 boot + btrfs root (u-boot can't read btrfs)" {
	run install_plan_layout emmc btrfs 0 $(( 16 * GIB )) 512 0
	[[ "$output" == *"part=boot:512MiB:ext4:boot"* ]]
	[[ "$output" == *"part=root:100%:btrfs:"* ]]
}

@test "plan emmc btrfs with swap: boot + swap + root" {
	run install_plan_layout emmc btrfs 0 $(( 16 * GIB )) 512 1
	[[ "$output" == *"part=boot:512MiB:ext4:boot"* ]]
	[[ "$output" == *"part=swap:256MiB:swap:"* ]]
	[[ "$output" == *"part=root:100%:btrfs:"* ]]
}

@test "plan emmc ext4 has no swap partition (swapfile stays on ext4)" {
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 1
	[[ "$output" != *"part=swap:"* ]]
}

# --- rootfs-only layouts (boot lives elsewhere) ------------------------------

@test "plan sd: single boot-flagged root partition" {
	run install_plan_layout sd ext4 0 $(( 500 * GIB )) 512 0
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
}

@test "plan sd on >2TiB disk: upgrades to gpt (build#9794)" {
	run install_plan_layout sd ext4 0 $(( 4 * TIB )) 512 0
	[[ "$output" == *"table=gpt"* ]]
}

@test "plan mtd/ufs: rootfs-only, boot flag set" {
	run install_plan_layout mtd ext4 0 $(( 250 * GIB )) 512 0
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
	run install_plan_layout ufs f2fs 0 $(( 250 * GIB )) 512 0
	[[ "$output" == *"part=root:100%:f2fs:boot"* ]]
}

# --- errors ------------------------------------------------------------------

@test "plan: unknown boot mode fails with usage code" {
	run install_plan_layout bogus ext4 0 $(( 16 * GIB )) 512 0
	[ "$status" -eq 64 ]
}
