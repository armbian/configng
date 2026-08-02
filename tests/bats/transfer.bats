#!/usr/bin/env bats
#
# Tests for install_transfer_rootfs progress reporting. The gauge tracks rsync's
# real file-count progress (to-chk=REMAIN/TOTAL from --info=progress2, monotonic
# 0..100, reaching 100). No privileges needed - it rsyncs a temp tree.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_install_engine.sh"
	INSTALL_LOG=/dev/null
	SRC="$BATS_TEST_TMPDIR/src"; DEST="$BATS_TEST_TMPDIR/dest"
	EX="$BATS_TEST_TMPDIR/exclude"
	mkdir -p "$SRC/sub" "$DEST"
	: >"$EX"
	local i
	for i in $(seq 1 24); do head -c 1048576 /dev/urandom >"$SRC/f$i"; done
	for i in $(seq 1 8);  do head -c 1048576 /dev/urandom >"$SRC/sub/g$i"; done
}

@test "transfer: progress is monotonic non-decreasing and reaches 100" {
	install_transfer_rootfs "$DEST" "$EX" 1 "$SRC/" >"$BATS_TEST_TMPDIR/prog"
	[ -s "$BATS_TEST_TMPDIR/prog" ]
	# every value is an integer 0..100
	run awk '$1!~/^[0-9]+$/ || $1<0 || $1>100 {exit 1}' "$BATS_TEST_TMPDIR/prog"
	[ "$status" -eq 0 ]
	# non-decreasing
	run awk 'NR>1 && $1<prev {exit 1} {prev=$1}' "$BATS_TEST_TMPDIR/prog"
	[ "$status" -eq 0 ]
	# actually reaches completion
	grep -qx 100 "$BATS_TEST_TMPDIR/prog"
}

@test "transfer: actually copies the tree and returns success" {
	run install_transfer_rootfs "$DEST" "$EX" 1 "$SRC/"
	[ "$status" -eq 0 ]
	[ "$(find "$DEST" -type f | wc -l)" -eq 32 ]
}

@test "transfer: missing destination fails cleanly" {
	run install_transfer_rootfs "$BATS_TEST_TMPDIR/nope" "$EX" 1 "$SRC/"
	[ "$status" -eq 70 ]   # INSTALL_EX_TRANSFER
}
