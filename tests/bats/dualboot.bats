#!/usr/bin/env bats
#
# Unit tests for the Windows dual-boot planner (install_dualboot_plan), the
# free-space and Linux-partition parsers, and the dual-boot space choice:
# how far Windows must shrink to free the requested space, with a safety margin,
# and refusal when it will not fit.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null
	GIB=$(( 1024 * 1024 * 1024 ))
}

@test "dualboot plan: shrinks Windows to free the requested space" {
	# 500G Windows, 120G used-minimum, no free tail, want 100G for Armbian.
	run install_dualboot_plan $((500*GIB)) $((120*GIB)) 0 $((100*GIB))
	[ "$status" -eq 0 ]
	# Windows should become 500G - 100G = 400G.
	[ "$output" = "shrink_to=$((400*GIB))" ]
}

@test "dualboot plan: uses an existing free tail before shrinking Windows" {
	# 40G free tail already; want 30G -> no shrink needed, Windows unchanged.
	run install_dualboot_plan $((500*GIB)) $((120*GIB)) $((40*GIB)) $((30*GIB))
	[ "$status" -eq 0 ]
	[ "$output" = "shrink_to=$((500*GIB))" ]
}

@test "dualboot plan: tail partially covers, shrink only the remainder" {
	# 40G tail, want 100G -> take 60G from Windows.
	run install_dualboot_plan $((500*GIB)) $((120*GIB)) $((40*GIB)) $((100*GIB))
	[ "$status" -eq 0 ]
	[ "$output" = "shrink_to=$((440*GIB))" ]
}

@test "dualboot plan: refuses when the request exceeds shrinkable space" {
	# 130G Windows, 120G minimum -> only ~2G shrinkable after the 8G margin,
	# so a 100G request must fail.
	run install_dualboot_plan $((130*GIB)) $((120*GIB)) 0 $((100*GIB))
	[ "$status" -eq 66 ]   # INSTALL_EX_NOSPACE
}

@test "dualboot plan: keeps an 8GiB margin above the NTFS minimum" {
	# 200G Windows, 100G minimum. Max Armbian = 200 - (100+8) = 92G.
	run install_dualboot_plan $((200*GIB)) $((100*GIB)) 0 $((92*GIB))
	[ "$status" -eq 0 ]
	run install_dualboot_plan $((200*GIB)) $((100*GIB)) 0 $((93*GIB))
	[ "$status" -eq 66 ]
}

@test "dualboot: refuses a disk with mounted filesystems before looking for Windows" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { [[ "$1" == "$dev" ]]; }
	install_detect_windows() { : >"$BATS_TEST_TMPDIR/detected"; return 1; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" "$GIB"
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	[ ! -e "$BATS_TEST_TMPDIR/detected" ]
	grep -q "'$dev' is in use" "$INSTALL_LOG"
}

@test "free regions: parses parted output, rounds to whole MiB, drops slivers" {
	run _install_free_regions <<-'PARTED'
	BYT;
	/dev/nvme0n1:488386MiB:nvme:512:512:gpt:SAMSUNG:;
	1:0.02MiB:1.00MiB:0.98MiB:free;
	1:1.00MiB:101MiB:100MiB:fat32:Basic data partition:boot, esp;
	3:117MiB:282714MiB:282597MiB:ntfs:Basic data partition:msftdata;
	1:282714MiB:487498MiB:204784MiB:free;
	4:487498MiB:488385MiB:887MiB:ntfs::hidden, diag;
	1:488385MiB:488386MiB:1.32MiB:free;
	PARTED
	[ "$status" -eq 0 ]
	[ "$output" = "282714 487498 204784" ]
}

@test "linux parts: finds another Linux install, never Windows or the ESP" {
	local json='{"blockdevices":[{"name":"/dev/nvme0n1","children":[
		{"name":"/dev/nvme0n1p1","fstype":"vfat","parttypename":"EFI System","size":104857600,"label":null},
		{"name":"/dev/nvme0n1p2","fstype":null,"parttypename":"Microsoft reserved","size":16777216,"label":null},
		{"name":"/dev/nvme0n1p3","fstype":"ntfs","parttypename":"Microsoft basic data","size":296352743424,"label":null},
		{"name":"/dev/nvme0n1p4","fstype":"ntfs","parttypename":"Windows recovery environment","size":930086912,"label":null},
		{"name":"/dev/nvme0n1p5","fstype":"btrfs","parttypename":"Linux filesystem","size":214748364800,"label":"armbi_root"},
		{"name":"/dev/nvme0n1p6","fstype":"crypto_LUKS","parttypename":"Linux filesystem","size":1073741824,"label":null},
		{"name":"/dev/nvme0n1p7","fstype":"BitLocker","parttypename":"Microsoft basic data","size":1073741824,"label":null}]}]}'
	run _install_linux_parts "$json"
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "/dev/nvme0n1p5	214748364800	btrfs	armbi_root" ]
	[ "${lines[1]}" = "/dev/nvme0n1p6	1073741824	crypto_LUKS	" ]
	[ "${#lines[@]}" -eq 2 ]
}

@test "dualboot: an encrypted root is allowed" {
	install_crypt_mode_ok uefi-dualboot
}

@test "dualboot: refuses to replace a partition that is not a Linux install" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { return 1; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	command() { [[ "$1 $2" == "-v grub-install" ]] && return 0; builtin command "$@"; }
	install_detect_windows() { printf 'esp=%s1\nwindows=%s3\n' "$dev" "$dev"; }
	install_linux_parts() { printf '%s5\t1\tbtrfs\t\n' "$dev"; }
	install_remove_partition() { : >"$BATS_TEST_TMPDIR/removed"; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" 0 "${dev}3"
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	[ ! -e "$BATS_TEST_TMPDIR/removed" ]
	grep -q "not a Linux partition" "$INSTALL_LOG"
}

@test "dualboot: free space that holds the request does not shrink Windows" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { return 1; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	command() { [[ "$1 $2" == "-v grub-install" ]] && return 0; builtin command "$@"; }
	install_detect_windows() { printf 'esp=%s1\nwindows=%s3\n' "$dev" "$dev"; }
	install_free_regions() { echo "282714 487498 204784"; }
	install_shrink_windows() { : >"$BATS_TEST_TMPDIR/shrunk"; }
	install_dualboot_blocker() { : >"$BATS_TEST_TMPDIR/shrunk"; }
	install_create_dualboot_parts() { echo "$2 $3" >"$BATS_TEST_TMPDIR/region"; return "$INSTALL_EX_PARTITION"; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" $((32 * GIB))
	[ "$status" -eq "$INSTALL_EX_PARTITION" ]
	[ ! -e "$BATS_TEST_TMPDIR/shrunk" ]
	# Only the requested 32 GiB of the 200 GiB region.
	[ "$(cat "$BATS_TEST_TMPDIR/region")" = "282714 $((282714 + 32768))" ]
}

@test "linux groups: adjacent partitions are one group, a gap starts a new one" {
	run _install_group_adjacent <<-'SPANS'
	282714 284762 /dev/nvme0n1p5 2147483648 ext4
	284762 487498 /dev/nvme0n1p6 212583104512 crypto_LUKS
	487600 488000 /dev/nvme0n1p7 419430400 -
	SPANS
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "/dev/nvme0n1p5,/dev/nvme0n1p6	214730588160	ext4+crypto_LUKS" ]
	[ "${lines[1]}" = "/dev/nvme0n1p7	419430400	-" ]
}

@test "free region over: the region that holds a point, also from its middle" {
	install_free_regions() { printf '%s\n' "1000 2000 1000" "282714 487498 204784"; }
	run install_free_region_over /dev/null 284762
	[ "$output" = "282714 487498" ]
	run install_free_region_over /dev/null 282714
	[ "$output" = "282714 487498" ]
	run install_free_region_over /dev/null 2500
	[ "$status" -ne 0 ]
}

@test "replace region: joins free space, refuses a partition between the choices" {
	local out='BYT;
/dev/x:500000MiB:nvme:512:512:gpt:X:;
1:0.02MiB:1.00MiB:0.98MiB:free;
1:1.00MiB:101MiB:100MiB:fat32::boot, esp;
2:101MiB:200000MiB:199899MiB:ntfs::msftdata;
1:200000MiB:200100MiB:100MiB:free;
5:200100MiB:202148MiB:2048MiB:ext4::;
6:202148MiB:300000MiB:97852MiB:btrfs::;
3:300000MiB:301000MiB:1000MiB:ntfs::hidden, diag;
7:301000MiB:302000MiB:1000MiB:btrfs::;'
	run _install_replace_region 5,6 <<<"$out"
	[ "$status" -eq 0 ]
	[ "$output" = "200000 300000" ]
	run _install_replace_region 6,7 <<<"$out"
	[ "$status" -ne 0 ]
	run _install_replace_region 5,9 <<<"$out"
	[ "$status" -ne 0 ]
	# A 1 MiB partition between the choices also blocks.
	run _install_replace_region 5,6 <<<"${out/6:202148MiB/8:202148MiB:202149MiB:1MiB:ext4::;
6:202149MiB}"
	[ "$status" -ne 0 ]
	# A partition under 1 MiB between the choices also blocks.
	run _install_replace_region 1,2 <<-'PARTED'
	1:100MiB:200MiB:100MiB:ext4::;
	3:200MiB:200.5MiB:0.5MiB:ext4::;
	2:200.5MiB:201MiB:0.5MiB:btrfs::;
	PARTED
	[ "$status" -ne 0 ]
}

@test "dualboot fits: an encrypted layout needs more than 4096 MiB" {
	install_dualboot_fits 0 1
	run install_dualboot_fits 1 4096
	[ "$status" -ne 0 ]
	install_dualboot_fits 1 4097
}

@test "dualboot: refuses non-adjacent or small replacements before any removal" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { return 1; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	install_crypt_check() { return 0; }
	command() { [[ "$1 $2" == "-v grub-install" ]] && return 0; builtin command "$@"; }
	install_detect_windows() { printf 'esp=%s1\nwindows=%s2\n' "$dev" "$dev"; }
	install_linux_parts() { printf '%s5\t1\tbtrfs\t\n%s7\t1\tbtrfs\t\n' "$dev" "$dev"; }
	install_part_span() { case "$2" in *5) echo "200000 203072" ;; *7) echo "204000 205000" ;; esac; }
	parted() { printf '%s\n' '5:200000MiB:203072MiB:3072MiB:btrfs::;' '3:203072MiB:204000MiB:928MiB:ntfs::;' '7:204000MiB:205000MiB:1000MiB:btrfs::;'; }
	install_remove_partition() { : >"$BATS_TEST_TMPDIR/removed"; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" 0 "${dev}5,${dev}7"
	[ "$status" -eq "$INSTALL_EX_USAGE" ]
	grep -q "not adjacent" "$INSTALL_LOG"
	# 3072 MiB does not hold an encrypted /boot and root.
	CRYPTROOT_ENABLE=yes run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" 0 "${dev}5"
	[ "$status" -eq "$INSTALL_EX_NOSPACE" ]
	grep -q "too small" "$INSTALL_LOG"
	[ ! -e "$BATS_TEST_TMPDIR/removed" ]
}

@test "dualboot: refuses a small encrypted request before Windows shrinks" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { return 1; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	install_crypt_check() { return 0; }
	command() { [[ "$1 $2" == "-v grub-install" ]] && return 0; builtin command "$@"; }
	install_detect_windows() { printf 'esp=%s1\nwindows=%s2\n' "$dev" "$dev"; }
	install_shrink_windows() { : >"$BATS_TEST_TMPDIR/shrunk"; }
	install_dualboot_needs_shrink() { : >"$BATS_TEST_TMPDIR/shrunk"; return 0; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	CRYPTROOT_ENABLE=yes run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" $((3 * GIB))
	[ "$status" -eq "$INSTALL_EX_NOSPACE" ]
	[ ! -e "$BATS_TEST_TMPDIR/shrunk" ]
}

@test "dualboot: a shrink frees the slack of install_shrink_windows too" {
	local dev
	for dev in /dev/loop0 /dev/sda /dev/vda /dev/nvme0n1 /dev/mmcblk0 ""; do [[ -b "$dev" ]] && break; done
	[[ -n "$dev" ]] || skip "no block device to point the install at"
	install_disk_in_use() { return 1; }
	install_check_fs_tools() { return 0; }
	install_fs_kernel_supported() { return 0; }
	install_crypt_check() { return 0; }
	command() { [[ "$1 $2" == "-v grub-install" || "$1 $2" == "-v ntfsresize" ]] && return 0; builtin command "$@"; }
	install_detect_windows() { printf 'esp=%s1\nwindows=%s2\n' "$dev" "$dev"; }
	install_dualboot_needs_shrink() { return 0; }
	install_dualboot_blocker() { return 0; }
	blockdev() { echo $((200 * GIB)); }
	install_windows_min_bytes() { echo $((50 * GIB)); }
	install_part_span() { echo "100 204900"; }
	install_free_region_at() { return 1; }
	install_shrink_windows() { echo "$3" >"$BATS_TEST_TMPDIR/new_win"; return "$INSTALL_EX_PARTITION"; }
	INSTALL_LOG="$BATS_TEST_TMPDIR/log"
	: >"$BATS_TEST_TMPDIR/exclude"
	CRYPTROOT_ENABLE=yes run install_run_dualboot "$dev" ext4 "$BATS_TEST_TMPDIR/exclude" $((4097 * 1048576))
	[ "$status" -eq "$INSTALL_EX_PARTITION" ]
	[ "$(cat "$BATS_TEST_TMPDIR/new_win")" -eq $((200 * GIB - (4097 + 18) * 1048576)) ]
}
