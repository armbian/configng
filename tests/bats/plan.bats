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

@test "table: honours a gpt preference when nothing forces the choice" {
	# eMMC/SD installs replicate the running image's table so the board's u-boot
	# can read it - Rockchip vendor u-boot (2017.09) parses GPT only.
	run install_table_type 0 $(( 16 * GIB )) 512 gpt
	[ "$output" = "gpt" ]
}

@test "table: honours an msdos preference (Allwinner: SPL at 8KiB clashes with GPT)" {
	run install_table_type 0 $(( 16 * GIB )) 512 msdos
	[ "$output" = "msdos" ]
}

@test "table: hard requirements override the preference (4Kn / >2TiB still gpt)" {
	run install_table_type 0 $(( 16 * GIB )) 4096 msdos
	[ "$output" = "gpt" ]
	run install_table_type 0 $(( 4 * TIB )) 512 msdos
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

# --- bios (x86 legacy) layout ------------------------------------------------

@test "plan bios: msdos disk -> single boot-flagged root, no bios boot partition" {
	run install_plan_layout bios ext4 0 $(( 20 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"table=msdos"* ]]
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
	[[ "$output" != *"biosboot"* ]]
}

@test "plan bios: gpt disk (>2TiB) -> 1MiB bios_grub partition + root" {
	run install_plan_layout bios ext4 0 $(( 4 * TIB )) 512 0
	[[ "$output" == *"table=gpt"* ]]
	[[ "$output" == *"part=biosboot:1MiB::bios_grub"* ]]
	[[ "$output" == *"part=root:100%:ext4:"* ]]
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

@test "plan emmc: replicates a gpt source table so Rockchip vendor u-boot can read it" {
	# Regression: an MBR eMMC made the RK3588 vendor u-boot loop on
	# "Invalid GPT" and never find the kernel. Passing the source's gpt through
	# must yield a gpt target.
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0 gpt
	[[ "$output" == *"table=gpt"* ]]
}

@test "plan emmc: an msdos source stays msdos (Allwinner)" {
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0 msdos
	[[ "$output" == *"table=msdos"* ]]
}

@test "plan emmc: reserves 16MiB before the first partition for on-device u-boot" {
	# emmc dd's idbloader (32KiB) + u-boot.itb (8MiB) to raw sectors of this same
	# device, so the first partition must start at 16MiB (classic FIRSTSECTOR=32768)
	# or the filesystem and the bootloader clobber each other and the board won't boot.
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0
	[[ "$output" == *"start=16"* ]]
}

@test "plan: non-emmc modes keep the 1MiB start (u-boot lives off this device)" {
	run install_plan_layout uefi ext4 1 $(( 16 * GIB )) 512 0
	[[ "$output" == *"start=1"* ]]
	run install_plan_layout sd ext4 0 $(( 500 * GIB )) 512 0
	[[ "$output" == *"start=1"* ]]
	run install_plan_layout bios ext4 0 $(( 20 * GIB )) 512 0
	[[ "$output" == *"start=1"* ]]
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

# --- split install: eMMC boot device (root lives on NVMe/SATA/USB) -----------

@test "plan emmc-boot: u-boot gap + ext4 /boot + /emmc_storage data partition" {
	run install_plan_layout emmc-boot ext4 0 $(( 58 * GIB )) 512 0 gpt
	[ "$status" -eq 0 ]
	# 16MiB reserve so u-boot (raw sectors) clears the first partition
	[[ "$output" == *"start=16"* ]]
	# a small boot-flagged ext4 /boot the board's u-boot can read...
	[[ "$output" == *"part=boot:512MiB:ext4:boot"* ]]
	# ...and the rest as an ext4 data partition (mounted at /emmc_storage)
	[[ "$output" == *"part=storage:100%:ext4:"* ]]
	# root does NOT live on the eMMC in this mode
	[[ "$output" != *"part=root:"* ]]
}

@test "plan emmc-boot: replicates the source table type (gpt for Rockchip vendor u-boot)" {
	run install_plan_layout emmc-boot ext4 0 $(( 58 * GIB )) 512 0 gpt
	[[ "$output" == *"table=gpt"* ]]
	run install_plan_layout emmc-boot ext4 0 $(( 58 * GIB )) 512 0 msdos
	[[ "$output" == *"table=msdos"* ]]
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
