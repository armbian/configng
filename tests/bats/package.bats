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
