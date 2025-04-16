#!/bin/bash
# Unit tests for interface_checklist.sh functions

# Define test directory and set source directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$TEST_DIR/../functions"
# Import functions from interface_checklist.sh for testing
source "$SOURCE_DIR/interface_checklist.sh"

# Define mocks and global variables
declare -A module_options
DIALOG=""
OUTPUTS_DIR="$TEST_DIR/outputs"
RUN_COUNT=0
MOCK_OUTPUT=""
MOCK_EXIT_CODE=0

# Create an outputs directory for logging mock calls
mkdir -p "$OUTPUTS_DIR"

# Define helper functions for test setup, assertions, and cleanup

setup_test() {
    RUN_COUNT=$((RUN_COUNT + 1))
    MOCK_OUTPUT=""
    MOCK_EXIT_CODE=0
    > "$OUTPUTS_DIR/whiptail_calls_${RUN_COUNT}.log"
    > "$OUTPUTS_DIR/dialog_calls_${RUN_COUNT}.log"
    > "$OUTPUTS_DIR/pkg_install_calls_${RUN_COUNT}.log"
    > "$OUTPUTS_DIR/pkg_remove_calls_${RUN_COUNT}.log"
    > "$OUTPUTS_DIR/test_output_${RUN_COUNT}.log"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: $message"
        return 1
    else
        echo "PASS: Values match: $expected"
        return 0
    fi
}

assert_contains() {
    local pattern="$1"
    local file="$2"
    local message="${3:-Expected pattern '$pattern' in file $file}"
    if grep -q "$pattern" "$file"; then
        echo "PASS: File contains '$pattern'"
        return 0
    else
        echo "FAIL: $message"
        return 1
    fi
}

run_all_tests() {
    local failures=0
    for test_func in $(declare -F | awk '{print $3}' | grep "^test_"); do
        echo "Running $test_func"
        setup_test
        if ! $test_func; then
            failures=$((failures + 1))
        fi
        echo "------------------"
    done
    echo "Test Summary: $failures failures"
    return $failures
}

cleanup() {
    echo "Cleaning up test artifacts..."
    # Optionally remove test output files: rm -rf "$OUTPUTS_DIR"
}
trap cleanup EXIT

# Unit tests for interface_checklist function

test_interface_checklist_whiptail() {
    DIALOG="whiptail"
    MOCK_OUTPUT='"option1" "option3"'
    MOCK_EXIT_CODE=0
    local checklist_options=("option1" "Description 1" "ON" "option2" "Description 2" "OFF" "option3" "Description 3" "ON")
    local result
    result=$(interface_checklist "Test Title" "Select options:" checklist_options)
    
    # Verify that whiptail was invoked correctly
    assert_contains "whiptail --title \"Test Title\" --checklist" "$OUTPUTS_DIR/whiptail_calls_${RUN_COUNT}.log"
    # Verify that the function output matches expected options
    assert_equals '"option1" "option3"' "$result"
}

test_interface_checklist_dialog() {
    DIALOG="dialog"
    MOCK_OUTPUT="option1 option3"
    MOCK_EXIT_CODE=0
    local checklist_options=("option1" "Description 1" "ON" "option2" "Description 2" "OFF" "option3" "Description 3" "ON")
    local result
    result=$(interface_checklist "Test Title" "Select options:" checklist_options)
    
    # Verify that dialog was invoked correctly
    assert_contains "dialog --title \"Test Title\" --checklist" "$OUTPUTS_DIR/dialog_calls_${RUN_COUNT}.log"
    # Verify that the function output matches expected options
    assert_equals "option1 option3" "$result"
}

test_interface_checklist_read() {
    DIALOG="read"
    # Temporarily override the read command within this test
    function read() { echo "1 3"; }
    local checklist_options=("option1" "Description 1" "ON" "option2" "Description 2" "OFF" "option3" "Description 3" "ON")
    local result
    result=$(interface_checklist "Test Title" "Select options:" checklist_options)
    # For the read interface, the output is expected to be " option1 option3"
    assert_equals " option1 option3" "$result"
}

test_interface_checklist_cancel() {
    DIALOG="whiptail"
    MOCK_OUTPUT=""
    MOCK_EXIT_CODE=1
    local checklist_options=("option1" "Description 1" "ON" "option2" "Description 2" "OFF")
    local result
    result=$(interface_checklist "Test Title" "Select options:" checklist_options)
    # Verify that cancellation is handled as expected
    assert_equals "Checklist canceled." "$result"
    [[ $? -ne 0 ]] && echo "PASS: Function returned non-zero exit code" || echo "FAIL: Function did not return non-zero exit code"
}

# Unit tests for process_package_selection function

test_process_package_selection_install() {
    DIALOG="whiptail"
    MOCK_OUTPUT='"package1" "package3"'
    MOCK_EXIT_CODE=0
    local checklist_options=("package1" "Description 1" "OFF" "package2" "Description 2" "ON" "package3" "Description 3" "OFF")
    process_package_selection "Test" "Select packages:" checklist_options 2>&1 | tee "$OUTPUTS_DIR/test_output_${RUN_COUNT}.log"
    
    # Verify that pkg_install was called for packages selected for installation
    assert_contains "Called pkg_install with: package1" "$OUTPUTS_DIR/pkg_install_calls_${RUN_COUNT}.log"
    assert_contains "Called pkg_install with: package3" "$OUTPUTS_DIR/pkg_install_calls_${RUN_COUNT}.log"
}

test_process_package_selection_remove() {
    DIALOG="dialog"
    MOCK_OUTPUT="package1"
    MOCK_EXIT_CODE=0
    local checklist_options=("package1" "Description 1" "OFF" "package2" "Description 2" "ON" "package3" "Description 3" "ON")
    process_package_selection "Test" "Select packages:" checklist_options 2>&1 | tee "$OUTPUTS_DIR/test_output_${RUN_COUNT}.log"
    
    # Verify that pkg_install was called for removal scenario where package status changes
    assert_contains "Called pkg_install with: package1" "$OUTPUTS_DIR/pkg_install_calls_${RUN_COUNT}.log"
    # Verify that pkg_remove was invoked for the unselected package
    assert_contains "Called pkg_remove with: package3" "$OUTPUTS_DIR/pkg_remove_calls_${RUN_COUNT}.log"
}

test_process_package_selection_cancel() {
    DIALOG="whiptail"
    MOCK_OUTPUT=""
    MOCK_EXIT_CODE=1
    local checklist_options=("package1" "Description 1" "ON" "package2" "Description 2" "OFF")
    process_package_selection "Test" "Select packages:" checklist_options 2>&1 | tee "$OUTPUTS_DIR/test_output_${RUN_COUNT}.log"
    
    # Verify that no installation or removal occurred when cancelled
    if [[ ! -s "$OUTPUTS_DIR/pkg_install_calls_${RUN_COUNT}.log" ]]; then
        echo "PASS: pkg_install not called"
    else
        echo "FAIL: pkg_install was called despite cancellation"
    fi
    if [[ ! -s "$OUTPUTS_DIR/pkg_remove_calls_${RUN_COUNT}.log" ]]; then
        echo "PASS: pkg_remove not called"
    else
        echo "FAIL: pkg_remove was called despite cancellation"
    fi
    assert_contains "No changes made" "$OUTPUTS_DIR/test_output_${RUN_COUNT}.log"
}

# Execute all tests if this file is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi
