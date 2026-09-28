#!/usr/bin/env bats
#
# Regression tests for apt_operation_progress() exit-code propagation.
#
# The dialog/whiptail progress path runs apt inside `( ... ) | dialog_gauge`, so
# a naive `exit_code=$?` captures dialog_gauge (which succeeds) and masks a
# failed apt operation - pkg_install then treats a failed install as success and
# appends to ACTUALLY_INSTALLED. These lock the real apt rc down.

setup() {
	declare -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/functions/module_package.sh"

	# apt-get stub on PATH; its exit code is driven by FAKE_APT_RC.
	STUB="$BATS_TEST_TMPDIR/bin"
	mkdir -p "$STUB"
	cat > "$STUB/apt-get" <<-'STUBEOF'
		#!/usr/bin/env bash
		echo "E: stub apt-get $*"
		exit "${FAKE_APT_RC:-0}"
	STUBEOF
	chmod +x "$STUB/apt-get"
	PATH="$STUB:$PATH"

	# A non-"read" DIALOG exercises the dialog_gauge progress pipeline.
	DIALOG="dialog"

	# Neutralise the UI + preflight so the test is deterministic and unprivileged.
	# dialog_gauge MUST succeed - the whole point is that its success must not be
	# mistaken for apt's result.
	dialog_gauge()  { cat > /dev/null; return 0; }
	dialog_msgbox() { return 0; }
	dpkg()          { return 0; }
}

@test "apt_operation_progress: progress path propagates an apt failure" {
	export FAKE_APT_RC=100
	run apt_operation_progress install stub-pkg
	[ "$status" -ne 0 ]
}

@test "apt_operation_progress: progress path reports apt success" {
	export FAKE_APT_RC=0
	run apt_operation_progress install stub-pkg
	[ "$status" -eq 0 ]
}

# Regression test for #712: disabling automatic updates (module_armbian_upgrades.sh
# -> `pkg_remove unattended-upgrades`) used to run `apt-get -y autopurge
# unattended-upgrades`. autopurge cascade-removes every OTHER package apt
# currently considers "automatically installed and now unneeded" - on a
# system where those marks are wrong (e.g. an OMV-modified image, per the
# issue) that took out base-system packages along with unattended-upgrades.
# pkg_remove must issue a scoped `purge` of only the named package(s), never
# the cascading `autopurge`.
@test "pkg_remove: removes only the named package, never autopurge" {
	local log="$BATS_TEST_TMPDIR/apt-invocations.log"
	cat > "$STUB/apt-get" <<-STUBEOF
		#!/usr/bin/env bash
		echo "\$*" >> "$log"
		exit 0
	STUBEOF
	chmod +x "$STUB/apt-get"

	run pkg_remove unattended-upgrades
	[ "$status" -eq 0 ]

	# Confirm what apt-get was actually asked to do.
	run cat "$log"
	[[ "$output" == *"purge"*"unattended-upgrades"* ]]
	# The dangerous cascading operation must never be invoked by pkg_remove.
	[[ "$output" != *"autopurge"* ]]
}

@test "pkg_remove: a package with corrupted auto-install marks does not take other packages with it" {
	# Simulate an apt state (like the OMV-modified image in #712) where
	# unrelated base-system packages are wrongly marked "automatically
	# installed" and would be swept up by a real autopurge. Our stub apt-get
	# only removes what it was explicitly told to remove/purge - exactly
	# what `purge` (not `autopurge`) guarantees on a real system too.
	local removed_log="$BATS_TEST_TMPDIR/removed.log"
	cat > "$STUB/apt-get" <<-STUBEOF
		#!/usr/bin/env bash
		if [[ "\$1" == "-y" && "\$2" == "autopurge" ]]; then
			# Real autopurge would also remove these orphaned-looking base packages.
			printf '%s\n' "\${@:3}" coreutils libc6 dpkg >> "$removed_log"
		elif [[ "\$1" == "-y" && "\$2" == "purge" ]]; then
			printf '%s\n' "\${@:3}" >> "$removed_log"
		fi
		exit 0
	STUBEOF
	chmod +x "$STUB/apt-get"

	run pkg_remove unattended-upgrades
	[ "$status" -eq 0 ]

	run cat "$removed_log"
	[[ "$output" == *"unattended-upgrades"* ]]
	[[ "$output" != *"coreutils"* ]]
	[[ "$output" != *"libc6"* ]]
	[[ "$output" != *"dpkg"* ]]
}
