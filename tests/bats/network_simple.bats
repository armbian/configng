#!/usr/bin/env bats
#
# Regression test for configng#414: cancelling one of the static-IP dialogs
# (address / route / gateway / DNS) during "Basic Network Setup -> static"
# fed dialog_inputbox's empty/cancelled output straight into `netplan set`
# unchecked, producing a malformed netplan yaml and crashing armbian-config
# (GLib-GIO-CRITICAL / "invalid IP family '-1'").
#
# Note: dialog_inputbox is always invoked via `$(...)` command substitution,
# which forks a subshell - a plain shell-variable counter would silently
# reset to 0 on every call. Counters below use a tmpfile instead.

setup() {
	# -g: bats' setup() is itself a shell function, so a plain `declare -A`
	# here would scope module_options to setup() and vanish once it returns,
	# leaving the sourced module_simple_network() reading an empty array.
	declare -g -A module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/network/module_network_simple.sh"

	adapter="eth0"
	NETWORK_RENDERER="networkd"

	NETPLAN_LOG="${BATS_TEST_TMPDIR}/netplan.log"
	MSGBOX_LOG="${BATS_TEST_TMPDIR}/msgbox.log"
	INPUTBOX_COUNTER="${BATS_TEST_TMPDIR}/inputbox.count"
	: > "$NETPLAN_LOG"
	: > "$MSGBOX_LOG"
	echo 0 > "$INPUTBOX_COUNTER"

	netplan() { echo "$*" >> "$NETPLAN_LOG"; }
	# Mirrors the real signature (title prompt height width [extra...]): the
	# real dialog/whiptail exit 255 without showing anything if height/width
	# are not numbers.
	dialog_msgbox() {
		[[ "$3" =~ ^[0-9]+$ && "$4" =~ ^[0-9]+$ ]] || return 255
		echo "$*" >> "$MSGBOX_LOG"
	}

	# No real network stack in the test environment; every caller of `ip`
	# in the static-IP path only uses its output as a dialog *default*
	# value, which the dialog_inputbox stub below ignores.
	ip() { :; }

	dialog_menu() { echo "static"; return 0; }

	# Prompts in order: 1 spoof MAC, 2 address, 3 route, 4 gateway, 5 DNS.
	# CANCEL_AT=n: prompt n returns non-zero (Cancel/Esc). EMPTY_AT=n: prompt
	# n returns success with an empty value (OK pressed on a blank field).
	dialog_inputbox() {
		local n
		n=$(<"$INPUTBOX_COUNTER")
		n=$((n + 1))
		echo "$n" > "$INPUTBOX_COUNTER"
		[[ "$n" == "${CANCEL_AT:-}" ]] && return 1
		[[ "$n" == "${EMPTY_AT:-}" ]] && return 0
		case $n in
			1) echo "aa:bb:cc:dd:ee:ff" ;;
			2) echo "192.168.1.12/24" ;;
			3) echo "0.0.0.0/0" ;;
			4) echo "192.168.1.2" ;;
			5) echo "9.9.9.9,1.1.1.1" ;;
		esac
	}
}

assert_aborted_cleanly() {
	[ "$(wc -l < "$NETPLAN_LOG")" -eq 0 ]
	[ "$(wc -l < "$MSGBOX_LOG")" -eq 1 ]
}

# `run`, not a direct call: dialog_inputbox intentionally returns non-zero to
# simulate Cancel, which would abort the whole test body under bats' errexit.

@test "cancelling the address prompt aborts instead of calling netplan (configng#414)" {
	CANCEL_AT=2 run module_simple_network type "eth0" "ethernets"
	assert_aborted_cleanly
}

@test "cancelling the route prompt aborts instead of calling netplan (configng#414)" {
	CANCEL_AT=3 run module_simple_network type "eth0" "ethernets"
	assert_aborted_cleanly
}

@test "cancelling the gateway prompt aborts instead of calling netplan (configng#414)" {
	CANCEL_AT=4 run module_simple_network type "eth0" "ethernets"
	assert_aborted_cleanly
}

@test "cancelling the DNS-server prompt aborts instead of calling netplan (configng#414)" {
	CANCEL_AT=5 run module_simple_network type "eth0" "ethernets"
	assert_aborted_cleanly
}

@test "confirming an empty gateway aborts instead of calling netplan (configng#414)" {
	EMPTY_AT=4 run module_simple_network type "eth0" "ethernets"
	assert_aborted_cleanly
}

@test "confirming an empty DNS field is still allowed (netplan accepts an empty nameserver list)" {
	EMPTY_AT=5 run module_simple_network type "eth0" "ethernets"

	[ "$status" -eq 0 ]
	grep -q 'nameservers.addresses=\[\]' "$NETPLAN_LOG"
	[ "$(wc -l < "$MSGBOX_LOG")" -eq 0 ]
}

@test "completing all static IP prompts still reaches netplan" {
	run module_simple_network type "eth0" "ethernets"

	[ "$status" -eq 0 ]
	grep -q 'addresses=\[192.168.1.12/24\]' "$NETPLAN_LOG"
	grep -q 'nameservers.addresses=\[9.9.9.9,1.1.1.1\]' "$NETPLAN_LOG"
	[ "$(wc -l < "$MSGBOX_LOG")" -eq 0 ]
}
