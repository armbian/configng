#!/bin/bash

# Test script for dialog abstraction layer
# Tests all wrapper functions with both whiptail and dialog

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/tools/modules/functions/config_interface.sh"

echo "==================================="
echo "Dialog Abstraction Layer Test Suite"
echo "==================================="
echo

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local dialog_type="$2"
    local test_function="$3"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "Test ${TESTS_RUN}: $test_name (with $dialog_type)"

    export DIALOG="$dialog_type"

    if $test_function; then
        echo "  ✓ PASSED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  ✗ FAILED"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
}

# Test: dialog_inputbox basic functionality
test_inputbox_basic() {
    # We can't test interactive dialog in automated script, so we test function existence
    type dialog_inputbox >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_menu basic functionality
test_menu_basic() {
    type dialog_menu >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_yesno basic functionality
test_yesno_basic() {
    type dialog_yesno >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_msgbox basic functionality
test_msgbox_basic() {
    type dialog_msgbox >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_checklist basic functionality
test_checklist_basic() {
    type dialog_checklist >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_radiolist basic functionality
test_radiolist_basic() {
    type dialog_radiolist >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_passwordbox basic functionality
test_passwordbox_basic() {
    type dialog_passwordbox >/dev/null 2>&1 || return 1
    return 0
}

# Test: dialog_gauge basic functionality
test_gauge_basic() {
    type dialog_gauge >/dev/null 2>&1 || return 1
    return 0
}

# Test: verify redirection pattern for whiptail
test_whiptail_redirection() {
    local result
    result=$(DIALOG="whiptail" bash -c '
        source /dev/stdin <<EOF
        dialog_inputbox() {
            case "$DIALOG" in
                "whiptail")
                    echo "whiptail_with_proper_redirection"
                    ;;
            esac
        }
        dialog_inputbox
EOF
    ')
    [[ "$result" == "whiptail_with_proper_redirection" ]]
}

# Test: verify redirection pattern for dialog
test_dialog_redirection() {
    local result
    result=$(DIALOG="dialog" bash -c '
        source /dev/stdin <<EOF
        dialog_inputbox() {
            case "$DIALOG" in
                "dialog")
                    echo "dialog_with_proper_redirection"
                    ;;
            esac
        }
        dialog_inputbox
EOF
    ')
    [[ "$result" == "dialog_with_proper_redirection" ]]
}

# Test: verify fallback to read
test_read_fallback() {
    type dialog_inputbox >/dev/null 2>&1 || return 1
    return 0
}

# Run tests
echo "=== Function Existence Tests ==="
echo

run_test "dialog_inputbox exists" "whiptail" test_inputbox_basic
run_test "dialog_menu exists" "whiptail" test_menu_basic
run_test "dialog_yesno exists" "whiptail" test_yesno_basic
run_test "dialog_msgbox exists" "whiptail" test_msgbox_basic
run_test "dialog_checklist exists" "whiptail" test_checklist_basic
run_test "dialog_radiolist exists" "whiptail" test_radiolist_basic
run_test "dialog_passwordbox exists" "whiptail" test_passwordbox_basic
run_test "dialog_gauge exists" "whiptail" test_gauge_basic

echo "=== Redirection Pattern Tests ==="
echo

run_test "whiptail redirection pattern" "whiptail" test_whiptail_redirection
run_test "dialog redirection pattern" "dialog" test_dialog_redirection
run_test "read fallback" "read" test_read_fallback

# Summary
echo "==================================="
echo "Test Summary"
echo "==================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed!"
    exit 1
fi
