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
	[[ "$output" == *"UUID=root1	/	btrfs"* ]]
	[[ "$output" == *"UUID=boot1	/boot	ext4"* ]]
	[[ "$output" == *"UUID=efi1	/boot/efi	vfat"* ]]
}

@test "fstab: btrfs root carries subvol=@ option" {
	run install_gen_fstab "UUID=root1" btrfs
	[[ "$output" == *"subvol=@"* ]]
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
