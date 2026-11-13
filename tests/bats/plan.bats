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

@test "plan ufs: reserves 16MiB, u-boot.itb lives at 8MiB of the UFS general LUN" {
	run install_plan_layout ufs ext4 0 $(( 250 * GIB )) 4096 0
	grep -qx 'start=16' <<< "$output"
}

@test "plan: BOOTLOADER_RESERVED_MIB raises the reserve for on-device u-boot modes" {
	BOOTLOADER_RESERVED_MIB=32
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0
	grep -qx 'start=32' <<< "$output"
	run install_plan_layout emmc-boot ext4 0 $(( 58 * GIB )) 512 0 gpt
	grep -qx 'start=32' <<< "$output"
	run install_plan_layout ufs ext4 0 $(( 250 * GIB )) 4096 0
	grep -qx 'start=32' <<< "$output"
	# modes without u-boot on the target are not affected
	run install_plan_layout sd ext4 0 $(( 500 * GIB )) 512 0
	grep -qx 'start=1' <<< "$output"
}

@test "plan: BOOTLOADER_RESERVED_MIB never lowers the 16MiB floor, junk is ignored" {
	BOOTLOADER_RESERVED_MIB=4
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0
	grep -qx 'start=16' <<< "$output"
	BOOTLOADER_RESERVED_MIB=abc
	run install_plan_layout ufs ext4 0 $(( 250 * GIB )) 4096 0
	grep -qx 'start=16' <<< "$output"
}

@test "plan: BOOTLOADER_RESERVED_MIB with leading zeros is read as decimal" {
	BOOTLOADER_RESERVED_MIB=020
	run install_plan_layout emmc ext4 0 $(( 16 * GIB )) 512 0
	grep -qx 'start=20' <<< "$output"
	BOOTLOADER_RESERVED_MIB=018
	run install_plan_layout ufs ext4 0 $(( 250 * GIB )) 4096 0
	[ "$status" -eq 0 ]
	grep -qx 'start=18' <<< "$output"
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

# --- spi: self-contained target, u-boot pre-flashed in on-board SPI/NOR ------
# The SoC boots from SPI and its boot script scans this disk for /boot, so the
# layout is fully self-contained like emmc (local /boot the board reads), but
# u-boot is NOT on this device, so - unlike emmc - there is no 16MiB reserve.

@test "plan spi ext4: single boot-flagged root, like emmc" {
	run install_plan_layout spi ext4 0 $(( 250 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
}

@test "plan spi btrfs: separate ext4 boot + btrfs root (u-boot can't read btrfs)" {
	run install_plan_layout spi btrfs 0 $(( 250 * GIB )) 512 0
	[[ "$output" == *"part=boot:512MiB:ext4:boot"* ]]
	[[ "$output" == *"part=root:100%:btrfs:"* ]]
}

@test "plan spi: no 16MiB reserve (u-boot lives in SPI, not on this disk)" {
	run install_plan_layout spi ext4 0 $(( 250 * GIB )) 512 0
	[[ "$output" == *"start=1"* ]]
}

@test "plan spi: replicates the source table type, same as emmc/sd/mtd" {
	run install_plan_layout spi ext4 0 $(( 250 * GIB )) 512 0 msdos
	[[ "$output" == *"table=msdos"* ]]
	run install_plan_layout spi ext4 0 $(( 250 * GIB )) 512 0 gpt
	[[ "$output" == *"table=gpt"* ]]
}

# --- standalone: self-contained target, u-boot stays on the current SD/eMMC --

@test "plan standalone: same self-contained layout as spi, no 16MiB reserve" {
	run install_plan_layout standalone ext4 0 $(( 250 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"start=1"* ]]
	[[ "$output" == *"part=root:100%:ext4:boot"* ]]
	run install_plan_layout standalone btrfs 0 $(( 250 * GIB )) 512 0
	[[ "$output" == *"part=boot:512MiB:ext4:boot"* ]]
}

# --- native: full install on a board with no u-boot/EFI/GRUB (Raspberry Pi) --

@test "plan native: FAT32 firmware partition first, plain root second" {
	run install_plan_layout native ext4 0 $(( 16 * GIB )) 512 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"part=firmware:512MiB:vfat:boot"* ]]
	[[ "$output" == *"part=root:100%:ext4:"* ]]
	# unlike emmc, root carries no "boot" flag - the firmware partition owns it
	[[ "$output" != *"part=root:100%:ext4:boot"* ]]
}

@test "plan native: no 16MiB reserve (nothing is written to raw sectors)" {
	run install_plan_layout native ext4 0 $(( 16 * GIB )) 512 0
	[[ "$output" == *"start=1"* ]]
}

@test "plan native: replicates the source table type, same as emmc/sd/mtd" {
	run install_plan_layout native ext4 0 $(( 16 * GIB )) 512 0 msdos
	[[ "$output" == *"table=msdos"* ]]
	run install_plan_layout native ext4 0 $(( 16 * GIB )) 512 0 gpt
	[[ "$output" == *"table=gpt"* ]]
}

@test "plan native: firmware partition is always vfat regardless of root fs" {
	run install_plan_layout native btrfs 0 $(( 16 * GIB )) 512 0
	[[ "$output" == *"part=firmware:512MiB:vfat:boot"* ]]
	[[ "$output" == *"part=root:100%:btrfs:"* ]]
}

# --- errors ------------------------------------------------------------------

@test "plan: unknown boot mode fails with usage code" {
	run install_plan_layout bogus ext4 0 $(( 16 * GIB )) 512 0
	[ "$status" -eq 64 ]
}

# --- encrypted root (LUKS) ---------------------------------------------------

@test "crypt plan: uefi gets an ext4 /boot between the ESP and the root" {
	run install_plan_layout uefi ext4 1 $(( 32 * GIB )) 512 0 "" 1
	[ "$status" -eq 0 ]
	[ "$(grep '^part=' <<<"$output" | tr '\n' ' ')" = "part=esp:512MiB:vfat:esp,boot part=boot:1024MiB:ext4: part=root:100%:ext4: " ]
}

@test "crypt plan: emmc ext4 gets a /boot partition, as btrfs does" {
	run install_plan_layout emmc ext4 0 $(( 32 * GIB )) 512 0 "" 1
	[ "$(grep '^part=' <<<"$output" | tr '\n' ' ')" = "part=boot:512MiB:ext4:boot part=root:100%:ext4: " ]
}

@test "crypt plan: bios msdos puts the boot flag on /boot" {
	run install_plan_layout bios ext4 0 $(( 32 * GIB )) 512 0 "" 1
	grep -qx 'table=msdos' <<<"$output"
	[ "$(grep '^part=' <<<"$output" | tr '\n' ' ')" = "part=boot:1024MiB:ext4:boot part=root:100%:ext4: " ]
}

@test "crypt plan: bios gpt keeps bios_grub first, then /boot" {
	run install_plan_layout bios ext4 0 $(( 32 * GIB )) 512 0 gpt 1
	[ "$(grep '^part=' <<<"$output" | tr '\n' ' ')" = "part=biosboot:1MiB::bios_grub part=boot:1024MiB:ext4: part=root:100%:ext4: " ]
}

@test "crypt plan: mtd and ufs get /boot on the target, sd does not" {
	run install_plan_layout mtd ext4 0 $(( 32 * GIB )) 512 0 "" 1
	[ "$(grep -c '^part=' <<<"$output")" -eq 2 ]
	run install_plan_layout ufs ext4 0 $(( 32 * GIB )) 4096 0 "" 1
	[ "$(grep -c '^part=' <<<"$output")" -eq 2 ]
	run install_plan_layout sd ext4 0 $(( 32 * GIB )) 512 0 "" 1
	[ "$(grep -c '^part=' <<<"$output")" -eq 1 ]
}

@test "crypt plan: no crypt argument keeps the old layouts" {
	run install_plan_layout uefi ext4 1 $(( 32 * GIB )) 512 0
	[ "$(grep -c '^part=' <<<"$output")" -eq 2 ]
	run install_plan_layout emmc ext4 0 $(( 32 * GIB )) 512 0
	[ "$(grep '^part=' <<<"$output")" = "part=root:100%:ext4:boot" ]
}

@test "crypt: sd and uefi-dualboot cannot boot an encrypted root" {
	run install_crypt_mode_ok sd
	[ "$status" -ne 0 ]
	run install_crypt_mode_ok uefi-dualboot
	[ "$status" -ne 0 ]
	for m in uefi bios emmc spi standalone mtd ufs native split-emmc; do
		install_crypt_mode_ok "$m"
	done
}

@test "crypt: armbianEnv.txt gets cryptdevice=, other configs only the mapper" {
	CRYPTROOT_MAPPER=armbian-root
	run install_crypt_bootarg /x/boot/armbianEnv.txt 1234-abcd
	[ "$output" = "/dev/mapper/armbian-root cryptdevice=UUID=1234-abcd:armbian-root" ]
	run install_crypt_bootarg /x/boot/extlinux/extlinux.conf 1234-abcd
	[ "$output" = "/dev/mapper/armbian-root" ]
	run install_crypt_bootarg /x/boot/firmware/cmdline.txt ""
	[ "$output" = "/dev/mapper/armbian-root" ]
}

# Each check test starts clean and asserts the logged reason, so a failure
# for another reason cannot pass.
_crypt_check_env() {
	unset CRYPTROOT_PASSPHRASE CRYPTROOT_AUTOUNLOCK CRYPTROOT_SSH_UNLOCK CRYPTROOT_SSH_UNLOCK_KEYS CRYPTROOT_SSH_UNLOCK_PORT CRYPTROOT_PARAMETERS
	CRYPTROOT_ENABLE=yes CRYPTROOT_MAPPER=bats-crypt-unused
	INSTALL_LOG="$BATS_TEST_TMPDIR/install.log"; : >"$INSTALL_LOG"
	install_crypt_packages() { :; }
	cryptsetup() { :; }   # the check only asks that the tool exists
	_install_dm_crypt_ok() { :; }
}

@test "crypt check: asks for a reboot when the running kernel has no modules" {
	_crypt_check_env
	CRYPTROOT_AUTOUNLOCK=yes
	_install_dm_crypt_ok() { return 1; }
	uname() { echo bats-no-such-kernel; }
	run install_crypt_check uefi
	[ "$status" -eq "$INSTALL_EX_TOOL" ]
	grep -q 'no modules for the running kernel bats-no-such-kernel; reboot first' "$INSTALL_LOG"
}

@test "crypt check: refuses without a passphrase or autounlock" {
	_crypt_check_env
	run install_crypt_check uefi
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	grep -q 'set a passphrase or the autounlock' "$INSTALL_LOG"
}

@test "crypt check: autounlock needs no passphrase" {
	_crypt_check_env
	CRYPTROOT_AUTOUNLOCK=yes
	run install_crypt_check uefi
	[ "$status" -eq 0 ]
}

@test "crypt check: refuses the sd boot mode" {
	_crypt_check_env
	CRYPTROOT_AUTOUNLOCK=yes
	run install_crypt_check sd
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	grep -q "boot mode 'sd' cannot boot an encrypted root" "$INSTALL_LOG"
}

@test "crypt check: refuses a bad mapper name" {
	_crypt_check_env
	CRYPTROOT_PASSPHRASE=x CRYPTROOT_MAPPER='a b'
	run install_crypt_check uefi
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	grep -q "bad mapper name 'a b'" "$INSTALL_LOG"
}

@test "crypt check: refuses SSH unlock without public keys" {
	_crypt_check_env
	CRYPTROOT_PASSPHRASE=x CRYPTROOT_SSH_UNLOCK=yes CRYPTROOT_SSH_UNLOCK_KEYS=/nonexistent
	run install_crypt_check uefi
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	grep -q 'SSH unlock needs public keys in /nonexistent' "$INSTALL_LOG"
}

@test "crypt check: names the missing packages" {
	_crypt_check_env
	install_crypt_packages() { echo cryptsetup-initramfs; }
	CRYPTROOT_PASSPHRASE=x
	run install_crypt_check emmc
	[ "$status" -eq "$INSTALL_EX_TOOL" ]
	grep -q 'install cryptsetup-initramfs first' "$INSTALL_LOG"
}

@test "crypt defaults: a held armbian-root gives the next free name" {
	unset CRYPTROOT_MAPPER
	local held="$BATS_TEST_TMPDIR/mapper"
	mkdir -p "$held"
	# Point the /dev/mapper test at a fixture with -e wrapped in a function.
	_crypt_defaults_in() { sed "s|/dev/mapper/|$held/|g" <<<"$(declare -f install_crypt_defaults)"; }
	eval "$(_crypt_defaults_in)"
	install_crypt_defaults
	[ "$CRYPTROOT_MAPPER" = armbian-root ]
	touch "$held/armbian-root" "$held/armbian-root-2"
	unset CRYPTROOT_MAPPER
	install_crypt_defaults
	[ "$CRYPTROOT_MAPPER" = armbian-root-3 ]
	CRYPTROOT_MAPPER=mine
	install_crypt_defaults
	[ "$CRYPTROOT_MAPPER" = mine ]
}
