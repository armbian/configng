#!/usr/bin/env bats
#
# Unit tests for boot-config generation and verification: fstab, armbianEnv
# rewriting, and the empty-/boot guard (build#10099/#10064) plus the
# not-bootable guard (build#6905).

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	TMP="$BATS_TEST_TMPDIR"
	INSTALL_LOG=/dev/null
}

# --- fstab -------------------------------------------------------------------

@test "fstab: root-only ext4 has tmpfs + root, no boot line" {
	run install_gen_fstab "UUID=aaaa" ext4
	[ "$status" -eq 0 ]
	[[ "$output" == *"tmpfs	/tmp	tmpfs"* ]]
	[[ "$output" == *"UUID=aaaa	/	ext4"* ]]
	[[ "$output" != *"	/boot	"* ]]
}

@test "fstab: separate boot + ESP produce /boot and /boot/efi lines" {
	run install_gen_fstab "UUID=root1" btrfs "UUID=boot1" ext4 "UUID=efi1"
	[ "$status" -eq 0 ]
	[[ "$output" == *"UUID=root1	/	btrfs"* ]]
	[[ "$output" == *"UUID=boot1	/boot	ext4"* ]]
	[[ "$output" == *"UUID=efi1	/boot/efi	vfat"* ]]
}

@test "fstab: btrfs root carries subvol=@ option" {
	run install_gen_fstab "UUID=root1" btrfs
	[ "$status" -eq 0 ]
	[[ "$output" == *"subvol=@"* ]]
}

@test "fstab: a swap partition UUID produces a swap entry" {
	run install_gen_fstab "UUID=root1" btrfs "UUID=boot1" ext4 "" "UUID=swap1"
	[[ "$output" == *"UUID=swap1	none	swap	sw"* ]]
}

@test "fstab: no swap UUID emits no swap entry" {
	run install_gen_fstab "UUID=root1" ext4
	[ "$status" -eq 0 ]
	[[ "$output" != *"	swap	"* ]]
}

# --- armbianEnv rewrite ------------------------------------------------------

@test "bootenv: existing rootdev/rootfstype are replaced in place" {
	f="$TMP/armbianEnv.txt"
	printf 'verbosity=1\nrootdev=UUID=old\nrootfstype=ext4\n' >"$f"
	run install_rewrite_bootenv "$f" "UUID=new" btrfs
	[ "$status" -eq 0 ]
	grep -q '^rootdev=UUID=new$' "$f"
	grep -q '^rootfstype=btrfs$' "$f"
	# no duplicate keys
	[ "$(grep -c '^rootdev=' "$f")" -eq 1 ]
}

@test "bootenv: missing keys are appended" {
	f="$TMP/armbianEnv.txt"
	printf 'verbosity=1\n' >"$f"
	run install_rewrite_bootenv "$f" "UUID=new" ext4
	[ "$status" -eq 0 ]
	grep -q '^rootdev=UUID=new$' "$f"
	grep -q '^rootfstype=ext4$' "$f"
}

@test "bootenv: missing file returns bootcfg error" {
	run install_rewrite_bootenv "$TMP/nope.txt" "UUID=new" ext4
	[ "$status" -eq 71 ]
}

# --- verify: bootable /boot --------------------------------------------------

@test "verify boot dir: kernel + boot script passes" {
	d="$TMP/boot"; mkdir -p "$d"
	: >"$d/vmlinuz-6.6.0"; : >"$d/boot.scr"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 0 ]
}

@test "verify boot dir: empty /boot fails (build#10099)" {
	d="$TMP/boot"; mkdir -p "$d"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 73 ]
}

@test "verify boot dir: kernel but no boot script fails (build#6905)" {
	d="$TMP/boot"; mkdir -p "$d"
	: >"$d/Image"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 73 ]
}

@test "verify boot dir: extlinux config counts as a boot script" {
	d="$TMP/boot"; mkdir -p "$d/extlinux"
	: >"$d/Image"; : >"$d/extlinux/extlinux.conf"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 0 ]
}

@test "verify boot dir: uEnv.txt counts as a boot script (k3/BeaglePlay)" {
	d="$TMP/boot"; mkdir -p "$d"
	: >"$d/Image"; : >"$d/uEnv.txt"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 0 ]
}

@test "verify boot dir: boot.ini counts as a boot script (amlogic/odroid)" {
	d="$TMP/boot"; mkdir -p "$d"
	: >"$d/Image"; : >"$d/boot.ini"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 0 ]
}

# --- populate /boot (synced separately from the main rootfs rsync) -----------

@test "populate_boot: copies the kernel into the target /boot and verifies" {
	src="$TMP/srcboot"; mkdir -p "$src"; : >"$src/vmlinuz-test"; : >"$src/boot.scr"
	rootfs="$TMP/rootfs"; mkdir -p "$rootfs"
	run install_populate_boot "$rootfs" 1 "$src"
	[ "$status" -eq 0 ]
	[ -f "$rootfs/boot/vmlinuz-test" ]
	# The populated /boot must pass the bootable check (regression for the empty
	# /boot that produced verify code 73 on the x86 BIOS install).
	run install_verify_boot_dir "$rootfs/boot"
	[ "$status" -eq 0 ]
}

@test "populate_boot: copy=0 leaves /boot empty (sd mode, boot on removable)" {
	src="$TMP/srcboot"; mkdir -p "$src"; : >"$src/vmlinuz-test"
	rootfs="$TMP/rootfs"; mkdir -p "$rootfs"
	run install_populate_boot "$rootfs" 0 "$src"
	[ "$status" -eq 0 ]
	[ -d "$rootfs/boot" ]
	[ ! -f "$rootfs/boot/vmlinuz-test" ]
}

@test "grub firstboot: installs a self-removing one-shot update-grub unit" {
	r="$TMP/rootfs"; mkdir -p "$r/etc/systemd/system"
	install_setup_grub_firstboot "$r"
	[ -f "$r/etc/systemd/system/armbian-grub-update.service" ]
	grep -q "update-grub" "$r/etc/systemd/system/armbian-grub-update.service"
	# enabled via a wants symlink so it runs on first boot
	[ -L "$r/etc/systemd/system/multi-user.target.wants/armbian-grub-update.service" ]
}

# --- bootloader capability pre-flight ----------------------------------------

@test "bootloader available: u-boot modes need write_uboot_platform (x86 has none)" {
	# No write_uboot_platform defined -> u-boot modes must report unavailable, so
	# the installer refuses before wiping (the code-72-after-wipe scenario).
	unset -f write_uboot_platform 2>/dev/null || true
	run install_bootloader_available sd
	[ "$status" -ne 0 ]
	run install_bootloader_available emmc
	[ "$status" -ne 0 ]
}

@test "bootloader available: u-boot modes ok once the hook exists" {
	write_uboot_platform() { :; }
	run install_bootloader_available sd
	[ "$status" -eq 0 ]
	unset -f write_uboot_platform
}

@test "fs tools: ext4 always available; missing fs reports its package" {
	# ext4 tools are part of the base system.
	run install_check_fs_tools ext4
	[ "$status" -eq 0 ]
	# For a filesystem whose tool is absent, the package name is reported so the
	# pre-flight can refuse before wiping (the mkfs.f2fs-missing scenario).
	if ! command -v mkfs.f2fs >/dev/null 2>&1; then
		run install_check_fs_tools f2fs
		[ "$status" -ne 0 ]
		[ "$output" = "f2fs-tools" ]
	fi
}

@test "update_initramfs: built-in fs is a no-op, module fs gets listed" {
	rootfs="$TMP/rootfs"; mkdir -p "$rootfs/etc/initramfs-tools" "$rootfs/usr/sbin"
	: >"$rootfs/etc/initramfs-tools/modules"
	# Fake update-initramfs so no real chroot/mount happens; ext4 must not even
	# reach it (built-in), f2fs must add itself to the module list first.
	printf '#!/bin/sh\nexit 0\n' >"$rootfs/usr/sbin/update-initramfs"; chmod +x "$rootfs/usr/sbin/update-initramfs"

	run install_update_initramfs "$rootfs" ext4
	[ "$status" -eq 0 ]
	[ ! -s "$rootfs/etc/initramfs-tools/modules" ]   # ext4 added nothing
}

@test "update_initramfs: a module fs (f2fs) is added to the module list" {
	rootfs="$TMP/rootfs-mod"; mkdir -p "$rootfs/etc/initramfs-tools" "$rootfs/usr/sbin"
	: >"$rootfs/etc/initramfs-tools/modules"
	printf '#!/bin/sh\nexit 0\n' >"$rootfs/usr/sbin/update-initramfs"; chmod +x "$rootfs/usr/sbin/update-initramfs"
	# f2fs is a module root fs: it must be added to the initramfs module list.
	# That add happens before the chroot step, which may fail unprivileged on
	# the mount --bind, so assert on the module list rather than the exit status.
	install_update_initramfs "$rootfs" f2fs || true
	grep -qxF f2fs "$rootfs/etc/initramfs-tools/modules"
}

@test "fs kernel support: ext4 always supported; a bogus fs is not" {
	run install_fs_kernel_supported ext4
	[ "$status" -eq 0 ]
	run install_fs_kernel_supported notafs_zzz
	[ "$status" -ne 0 ]
}

@test "bootloader available: grub modes depend on grub-install presence" {
	if command -v grub-install >/dev/null 2>&1; then
		run install_bootloader_available bios; [ "$status" -eq 0 ]
		run install_bootloader_available uefi; [ "$status" -eq 0 ]
	else
		run install_bootloader_available bios; [ "$status" -ne 0 ]
	fi
}

# --- sd mode: map current /boot into the target (mount + bind) ---------------

@test "map current boot: dedicated /boot partition mounts straight at /boot" {
	findmnt() { case "$3" in /boot) case "$2" in SOURCE) echo /dev/mmcblk1p1 ;; FSTYPE) echo vfat ;; esac ;; esac; }
	install_uuid() { echo "UUID=bootpart"; }
	f="$TMP/fstab"; : >"$f"; mp="$TMP/target"; mkdir -p "$mp"
	run install_map_current_boot "$f" "$mp"
	[ "$status" -eq 0 ]
	grep -qE '^UUID=bootpart	/boot	vfat	defaults,nofail' "$f"
	# straight mount, no bind indirection
	! grep -q 'boot-media' "$f"
}

@test "map current boot: /boot dir on root partition uses mount + bind" {
	findmnt() { case "$3" in /boot) return 1 ;; /) case "$2" in SOURCE) echo /dev/mmcblk1p1 ;; FSTYPE) echo ext4 ;; esac ;; esac; }
	install_uuid() { echo "UUID=rootpart"; }
	f="$TMP/fstab"; : >"$f"; mp="$TMP/target"; mkdir -p "$mp"
	run install_map_current_boot "$f" "$mp"
	[ "$status" -eq 0 ]
	grep -qE '^UUID=rootpart	/media/boot-media	ext4	defaults,nofail' "$f"
	grep -qE '^/media/boot-media/boot	/boot	none	bind,nofail' "$f"
	[ -d "$mp/media/boot-media" ]
}
