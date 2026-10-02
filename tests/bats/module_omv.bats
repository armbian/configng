#!/usr/bin/env bats
#
# Regression tests for module_omv's Raspberry Pi 5 i2c/gpio/spi group fix.
#
# Armbian (unlike Raspberry Pi OS) never creates the i2c/gpio/spi groups
# referenced by stock udev rules (60-i2c-aliases.rules, 99-com.rules). Missing
# groups make every udev/systemd reload during the OMV install log
# "Unknown group ..., ignoring" and stall for ~90s, which eventually times
# salt-minion out and breaks the install (armbian/configng#694). The fix
# creates the groups defensively, before any apt work, and reloads udev only
# when udevd is actually reachable.
#
# These tests exercise the install case's SCRIPT LOGIC only (ordering,
# idempotent flags, the udevd-reachability guard) via stubbed commands - they
# cannot reproduce the real multi-hour systemd freeze, which needs actual
# Raspberry Pi 5 hardware.

setup() {
	# -g: a plain `declare -A` inside a function is local to that function and
	# would vanish before the @test body runs, silently turning `module_omv`
	# into a no-op via its `*)` fallback case (mirrors runners.bats).
	declare -gA module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/software/module_omv.sh"

	CALL_LOG="$BATS_TEST_TMPDIR/calls.log"
	: > "$CALL_LOG"

	# Never installed, so the install case always proceeds past the early return.
	pkg_installed() { return 1; }

	# Neutralise the desktop/Docker/LXC/arch/codename preflight checks so the
	# install case reaches the group-creation code deterministically.
	dpkg() {
		if [[ "$1" == "--print-architecture" ]]; then
			echo "arm64"
			return 0
		fi
		return 1
	}
	lsb_release() { echo "bookworm"; }

	groupadd() {
		echo "groupadd $*" >> "$CALL_LOG"
		return 0
	}
	udevadm() {
		echo "udevadm $*" >> "$CALL_LOG"
		return 0
	}

	# Abort right after the group-creation step (before any real apt/network
	# work) by making pkg_update fail; keeps the test hermetic.
	pkg_update() {
		echo "pkg_update" >> "$CALL_LOG"
		return 1
	}
}

@test "module_omv install: creates i2c/gpio/spi groups with --system --force before pkg_update" {
	run module_omv install
	[ "$status" -ne 0 ]

	grep -qx "groupadd --system --force i2c" "$CALL_LOG"
	grep -qx "groupadd --system --force gpio" "$CALL_LOG"
	grep -qx "groupadd --system --force spi" "$CALL_LOG"

	local group_line pkg_update_line
	group_line="$(grep -n "^groupadd --system --force spi$" "$CALL_LOG" | cut -d: -f1)"
	pkg_update_line="$(grep -n "^pkg_update$" "$CALL_LOG" | cut -d: -f1)"
	[ -n "$group_line" ]
	[ -n "$pkg_update_line" ]
	[ "$group_line" -lt "$pkg_update_line" ]
}

@test "module_omv install: does not call udevadm when udevd is unreachable (no /run/udev/control socket)" {
	# The bats sandbox never has a real udevd socket, so this exercises the
	# same "absent in CI containers" guard used by module_jellyfin.sh.
	run module_omv install
	run grep -q "^udevadm " "$CALL_LOG"
	[ "$status" -ne 0 ]
}
