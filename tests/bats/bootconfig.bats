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

# --- extlinux rewrite --------------------------------------------------------
#
# Distro-boot boards (spacemit/riscv and other vendor kernels) ship no
# armbianEnv.txt; root= lives on the extlinux "append" line instead.

# A real /boot/extlinux/extlinux.conf as written for a SpacemiT MUSE Book.
_extlinux_fixture() {
	cat >"$1" <<-'EOF'
		label Armbian
		  kernel /boot/Image
		  initrd /boot/uInitrd
		  fdt /boot/dtb/spacemit/k1-musebook.dtb
		  append root=UUID=old-uuid console=ttyS0,115200 loglevel=1 rw splash
	EOF
}

@test "extlinux: root= on the append line is repointed" {
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"
	run install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	[ "$status" -eq 0 ]
	grep -q 'root=UUID=new-uuid' "$f"
	! grep -q 'old-uuid' "$f"
	# every other kernel arg survives, in place
	grep -q 'console=ttyS0,115200' "$f"
	grep -q 'splash' "$f"
}

@test "extlinux: label/kernel/initrd/fdt lines are left alone" {
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	grep -q '^label Armbian$' "$f"
	grep -q '^  kernel /boot/Image$' "$f"
	grep -q '^  fdt /boot/dtb/spacemit/k1-musebook.dtb$' "$f"
	[ "$(grep -c 'root=' "$f")" -eq 1 ]
}

@test "extlinux: rootfstype is added when absent and replaced when present" {
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	grep -q 'rootfstype=ext4' "$f"
	# second pass with a different fs must not duplicate the token
	install_rewrite_extlinux "$f" "UUID=new-uuid" f2fs
	grep -q 'rootfstype=f2fs' "$f"
	[ "$(grep -o 'rootfstype=' "$f" | wc -l)" -eq 1 ]
}

@test "extlinux: btrfs root also gets rootflags=subvol=@" {
	# armbianEnv boards get this from boot.cmd; extlinux boards never run it, so
	# without it a btrfs install mounts the wrong subvolume.
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" btrfs
	grep -q 'rootflags=subvol=@' "$f"
	run install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	[ "$status" -eq 0 ]
	# ...and rewriting back to a non-btrfs root must take subvol=@ away again:
	# a non-btrfs kernel rejects it and fails to mount the root filesystem.
	! grep -q 'subvol=@' "$f"
	grep -q 'rootfstype=ext4' "$f"
}

@test "extlinux: a non-btrfs rewrite keeps rootflags the board ships" {
	# aml-s9xx-box and the RISC-V boards ship rootflags=data=writeback on an
	# ext4 root; only the btrfs subvol= component may be removed.
	f="$TMP/flags.conf"
	printf 'label Armbian\n  append root=UUID=old rootflags=data=writeback console=tty0 rw\n' >"$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	grep -q 'rootflags=data=writeback' "$f"
	grep -q 'root=UUID=new-uuid' "$f"
	grep -q 'console=tty0' "$f"
}

@test "extlinux: subvol= is removed from a compound rootflags, the rest kept" {
	f="$TMP/mixed.conf"
	printf 'label Armbian\n  append root=UUID=old rootflags=data=writeback,subvol=@ console=tty0 rw\n' >"$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	grep -q 'rootflags=data=writeback' "$f"
	! grep -q 'subvol=' "$f"
	grep -q 'console=tty0' "$f"
}

@test "extlinux: dropping a lone subvol= leaves no stray whitespace or token" {
	f="$TMP/lone.conf"
	printf 'label Armbian\n  append root=UUID=old rootflags=subvol=@ console=tty0 rw\n' >"$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	! grep -q 'rootflags' "$f"
	grep -q 'root=UUID=new-uuid console=tty0 rw' "$f"
}

@test "extlinux: rewriting twice is a no-op (idempotent)" {
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	cp "$f" "$TMP/once"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	diff -q "$TMP/once" "$f"
}

@test "extlinux: an append line with no root= gets one" {
	f="$TMP/extlinux.conf"
	printf 'label Armbian\n  kernel /boot/Image\n  append console=ttyS0,115200 rw\n' >"$f"
	run install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	[ "$status" -eq 0 ]
	grep -q 'root=UUID=new-uuid' "$f"
	grep -q 'console=ttyS0,115200' "$f"
}

@test "extlinux: uppercase APPEND is handled" {
	f="$TMP/extlinux.conf"
	printf 'LABEL Armbian\n  APPEND root=/dev/mmcblk0p1 rw\n' >"$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	grep -q 'root=UUID=new-uuid' "$f"
	! grep -q 'mmcblk0p1' "$f"
}

@test "extlinux: file mode is preserved" {
	f="$TMP/extlinux.conf"; _extlinux_fixture "$f"; chmod 600 "$f"
	install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	[ "$(stat -c '%a' "$f")" = "600" ]
	[ ! -e "$f.new" ]
}

@test "extlinux: a file with no append line is an error, not a silent no-op" {
	# Nothing to repoint means root= was never set; succeeding here would let
	# the install continue and report success on an unbootable target.
	f="$TMP/no-append.conf"
	printf 'label Armbian\n  kernel /boot/Image\n  initrd /boot/uInitrd\n' >"$f"
	cp "$f" "$TMP/before"
	run install_rewrite_extlinux "$f" "UUID=new-uuid" ext4
	[ "$status" -ne 0 ]
	# and the original must be left exactly as it was
	diff -q "$TMP/before" "$f"
	[ ! -e "$f.new" ]
}

@test "extlinux: missing file returns bootcfg error" {
	run install_rewrite_extlinux "$TMP/nope.conf" "UUID=new" ext4
	[ "$status" -eq 71 ]
}

# --- boot config discovery / dispatch ----------------------------------------

@test "boot cfg: armbianEnv.txt wins when both exist" {
	d="$TMP/boot1"; mkdir -p "$d/extlinux"
	: >"$d/armbianEnv.txt"; : >"$d/extlinux/extlinux.conf"
	run install_boot_cfg_file "$d"
	[ "$status" -eq 0 ]
	[ "$output" = "$d/armbianEnv.txt" ]
}

@test "boot cfg: extlinux.conf is found when there is no armbianEnv.txt" {
	d="$TMP/boot2"; mkdir -p "$d/extlinux"
	: >"$d/extlinux/extlinux.conf"
	run install_boot_cfg_file "$d"
	[ "$status" -eq 0 ]
	[ "$output" = "$d/extlinux/extlinux.conf" ]
}

@test "boot cfg: neither present reports failure and prints nothing" {
	d="$TMP/boot3"; mkdir -p "$d"
	run install_boot_cfg_file "$d"
	[ "$status" -ne 0 ]
	[ -z "$output" ]
}

@test "boot cfg: dispatch rewrites each format in its own syntax" {
	d="$TMP/boot4"; mkdir -p "$d/extlinux"
	printf 'verbosity=1\nrootdev=UUID=old\n' >"$d/armbianEnv.txt"
	_extlinux_fixture "$d/extlinux/extlinux.conf"

	install_rewrite_bootcfg "$d/armbianEnv.txt" "UUID=new" ext4
	grep -q '^rootdev=UUID=new$' "$d/armbianEnv.txt"

	install_rewrite_bootcfg "$d/extlinux/extlinux.conf" "UUID=new" ext4
	grep -q 'root=UUID=new' "$d/extlinux/extlinux.conf"
	# the extlinux file must not have grown armbianEnv-style keys
	! grep -q '^rootdev=' "$d/extlinux/extlinux.conf"
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

@test "verify boot dir: nested firmware/config.txt+cmdline.txt counts (native mode)" {
	d="$TMP/boot"; mkdir -p "$d/firmware"
	: >"$d/vmlinuz-test"; : >"$d/firmware/config.txt"; : >"$d/firmware/cmdline.txt"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 0 ]
}

@test "verify boot dir: firmware/ with only one of the two files does not count" {
	d="$TMP/boot"; mkdir -p "$d/firmware"
	: >"$d/vmlinuz-test"; : >"$d/firmware/config.txt"
	run install_verify_boot_dir "$d"
	[ "$status" -eq 73 ]
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

@test "bootloader available: emmc needs write_uboot_platform (x86 has none)" {
	# No write_uboot_platform defined -> emmc must report unavailable, so the
	# installer refuses before wiping (the code-72-after-wipe scenario).
	unset -f write_uboot_platform 2>/dev/null || true
	run install_bootloader_available emmc
	[ "$status" -ne 0 ]
}

@test "bootloader available: sd needs no capability - it never writes a bootloader" {
	# sd mode only moves root and leaves the current boot media untouched
	# (install_run_scenario skips install_write_bootloader for it), so unlike
	# emmc it must be available even with no write_uboot_platform hook at all -
	# that is what makes it usable on Raspberry Pi (no u-boot whatsoever).
	unset -f write_uboot_platform 2>/dev/null || true
	run install_bootloader_available sd
	[ "$status" -eq 0 ]
}

@test "bootloader available: emmc ok once the write_uboot_platform hook exists" {
	write_uboot_platform() { :; }
	run install_bootloader_available emmc
	[ "$status" -eq 0 ]
	unset -f write_uboot_platform
}

@test "bootloader available: native needs Raspberry Pi-style firmware" {
	# native writes a plain FAT32 boot partition only the board's own firmware
	# reads; on anything else the target would never boot, so it must report
	# unavailable unless install_rpi_style_boot detects raspi firmware.
	unset -f write_uboot_platform 2>/dev/null || true
	d="$TMP/fw-none"; mkdir -p "$d"
	install_boot_firmware_dir() { echo "$d"; }
	run install_bootloader_available native
	[ "$status" -ne 0 ]
	: >"$d/config.txt"; : >"$d/cmdline.txt"
	run install_bootloader_available native
	[ "$status" -eq 0 ]
}

# --- sd capability (current boot config must be rewirable) ---------------------

@test "sd capable: true with a u-boot armbianEnv.txt, no raspi firmware" {
	d="$TMP/fw-none"; mkdir -p "$d"
	install_boot_firmware_dir() { echo "$d"; }
	envf="$TMP/armbianEnv.txt"; : >"$envf"
	install_sd_env_file() { echo "$envf"; }
	run install_sd_capable
	[ "$status" -eq 0 ]
}

@test "sd capable: true with Raspberry Pi-style firmware, no armbianEnv.txt" {
	d="$TMP/fw"; mkdir -p "$d"; : >"$d/config.txt"; : >"$d/cmdline.txt"
	install_boot_firmware_dir() { echo "$d"; }
	install_sd_env_file() { echo "$TMP/no-such-armbianEnv.txt"; }
	run install_sd_capable
	[ "$status" -eq 0 ]
}

@test "sd capable: false when neither boot config exists (bare firmware)" {
	d="$TMP/fw-none2"; mkdir -p "$d"
	install_boot_firmware_dir() { echo "$d"; }
	install_sd_env_file() { echo "$TMP/no-such-armbianEnv.txt"; }
	run install_sd_capable
	[ "$status" -ne 0 ]
}

@test "sd capable: true on an extlinux board (no armbianEnv.txt)" {
	# Distro-boot boards carry extlinux/extlinux.conf instead of armbianEnv.txt;
	# without this sd mode would be hidden from them entirely.
	d="$TMP/fw-none3"; mkdir -p "$d"
	install_boot_firmware_dir() { echo "$d"; }
	b="$TMP/sdboot"; mkdir -p "$b/extlinux"; _extlinux_fixture "$b/extlinux/extlinux.conf"
	install_sd_boot_dir() { echo "$b"; }
	run install_sd_capable
	[ "$status" -eq 0 ]
}

@test "sd env file: prefers armbianEnv.txt, falls back to extlinux.conf" {
	b="$TMP/sdboot2"; mkdir -p "$b/extlinux"
	_extlinux_fixture "$b/extlinux/extlinux.conf"
	install_sd_boot_dir() { echo "$b"; }
	run install_sd_env_file
	[ "$status" -eq 0 ]
	[ "$output" = "$b/extlinux/extlinux.conf" ]
	: >"$b/armbianEnv.txt"
	run install_sd_env_file
	[ "$status" -eq 0 ]
	[ "$output" = "$b/armbianEnv.txt" ]
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

@test "update_initramfs: a failed run is fatal, not silently swallowed (build report)" {
	# Previously this always returned 0 even when the chroot update-initramfs
	# run failed - a btrfs/f2fs install "succeeded" then never actually booted
	# (dropped to an (initramfs) shell: "mount ... failed: Invalid argument",
	# the module missing from the initrd that was really booted). Whether it's
	# this fake script failing or chroot itself refusing unprivileged, either
	# way the function must report failure.
	rootfs="$TMP/rootfs-fail"; mkdir -p "$rootfs/etc/initramfs-tools" "$rootfs/usr/sbin"
	: >"$rootfs/etc/initramfs-tools/modules"
	printf '#!/bin/sh\nexit 1\n' >"$rootfs/usr/sbin/update-initramfs"; chmod +x "$rootfs/usr/sbin/update-initramfs"
	run install_update_initramfs "$rootfs" btrfs
	[ "$status" -ne 0 ]
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

# --- Raspberry Pi-style boot (native firmware, static cmdline.txt) -----------

@test "boot firmware dir: separately-mounted /boot/firmware wins" {
	findmnt() { [ "$3" = /boot/firmware ]; }
	[ "$(install_boot_firmware_dir)" = /boot/firmware ]
}

@test "boot firmware dir: falls back to /boot when not separately mounted" {
	findmnt() { return 1; }
	[ "$(install_boot_firmware_dir)" = /boot ]
}

@test "rpi style boot: true when config.txt + cmdline.txt are both present" {
	d="$TMP/fw"; mkdir -p "$d"; : >"$d/config.txt"; : >"$d/cmdline.txt"
	install_boot_firmware_dir() { echo "$d"; }
	run install_rpi_style_boot
	[ "$status" -eq 0 ]
}

@test "rpi style boot: false when only one of the two files exists (u-boot board)" {
	d="$TMP/fw"; mkdir -p "$d"; : >"$d/config.txt"
	install_boot_firmware_dir() { echo "$d"; }
	run install_rpi_style_boot
	[ "$status" -ne 0 ]
}

@test "rewrite rpi cmdline: replaces root= (LABEL/UUID/PARTUUID), leaves the rest" {
	f="$TMP/cmdline.txt"
	printf 'console=serial0,115200 root=LABEL=armbi_root rootfstype=ext4 rootwait\n' >"$f"
	run install_rewrite_rpi_cmdline "$f" "UUID=1234-5678"
	[ "$status" -eq 0 ]
	grep -q 'root=UUID=1234-5678' "$f"
	grep -q 'console=serial0,115200' "$f"
	grep -q 'rootfstype=ext4 rootwait' "$f"
	# no leftover LABEL=
	! grep -q 'armbi_root' "$f"
}

@test "rewrite rpi cmdline: given a fs, also replaces a stale rootfstype=" {
	# initramfs-tools mounts root with `mount -t "$ROOTFSTYPE"` whenever
	# rootfstype= is set to anything but empty/auto - a stale rootfstype=ext4
	# on a btrfs/f2fs root fails that mount with "Invalid argument" even once
	# root= is correct and the module is present in the initrd (build report).
	f="$TMP/cmdline.txt"
	printf 'console=serial0,115200 root=LABEL=armbi_root rootfstype=ext4 rootwait\n' >"$f"
	run install_rewrite_rpi_cmdline "$f" "UUID=1234-5678" btrfs
	[ "$status" -eq 0 ]
	grep -q 'root=UUID=1234-5678' "$f"
	grep -q 'rootfstype=btrfs' "$f"
	! grep -q 'rootfstype=ext4' "$f"
}

@test "rewrite rpi cmdline: given a fs, appends rootfstype= when absent" {
	f="$TMP/cmdline.txt"
	printf 'console=serial0,115200 root=LABEL=armbi_root rootwait\n' >"$f"
	run install_rewrite_rpi_cmdline "$f" "UUID=1234-5678" f2fs
	[ "$status" -eq 0 ]
	grep -q 'rootfstype=f2fs' "$f"
}

@test "rewrite rpi cmdline: no fs argument leaves rootfstype= untouched" {
	f="$TMP/cmdline.txt"
	printf 'console=serial0,115200 root=LABEL=armbi_root rootfstype=ext4 rootwait\n' >"$f"
	run install_rewrite_rpi_cmdline "$f" "UUID=1234-5678"
	[ "$status" -eq 0 ]
	grep -q 'rootfstype=ext4' "$f"
}

@test "rewrite rpi cmdline: missing file returns bootcfg error" {
	run install_rewrite_rpi_cmdline "$TMP/nope-cmdline.txt" "UUID=x"
	[ "$status" -eq 71 ]
}

@test "rewrite rpi cmdline: no root= in file returns bootcfg error" {
	f="$TMP/cmdline.txt"; printf 'console=serial0,115200 rootwait\n' >"$f"
	run install_rewrite_rpi_cmdline "$f" "UUID=x"
	[ "$status" -eq 71 ]
}
