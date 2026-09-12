#!/usr/bin/env bats
#
# Unit tests for the self-hosted runner module: parameter parsing, label
# fallback, and the runner listing that broke on a GitHub error object
# (jq: Cannot iterate over null).

setup() {
	declare -gA module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/system/module_armbian_runners.sh"
	TMP="$BATS_TEST_TMPDIR"
	DELETED="$TMP/deleted"
	: >"$DELETED"
}

# A curl stub: $LIST_FIXTURE is served for the runner listing, DELETEs are
# recorded, and $LIST_CODE / $DELETE_CODE drive the HTTP status.
_stub_curl() {
	curl() {
		local out="" is_delete=0 url="" prev=""
		for a in "$@"; do
			case "$prev" in -o) out="$a" ;; esac
			case "$a" in DELETE) is_delete=1 ;; https://*) url="$a" ;; esac
			prev="$a"
		done
		if (( is_delete )); then
			echo "${url##*/}" >>"$DELETED"
			[[ -n "$out" ]] && printf '' >"$out"
			printf '%s' "${DELETE_CODE:-204}"
		else
			[[ -n "$out" ]] && printf '%s' "$LIST_FIXTURE" >"$out"
			printf '%s' "${LIST_CODE:-200}"
		fi
	}
}

@test "remove_online: a GitHub error object fails cleanly, no jq crash" {
	# Bad credentials => {"message":...} with no .runners. Piping that into
	# .runners[] produced 'Cannot iterate over null (null)' and then carried
	# on as though the org had no runners.
	_stub_curl
	LIST_CODE=401
	LIST_FIXTURE='{"message":"Bad credentials","documentation_url":"https://docs.github.com"}'
	run module_armbian_runners remove_online armbian-01 gh_token=xxx
	[ "$status" -ne 0 ]
	[[ "$output" != *"Cannot iterate over null"* ]]
	[[ "$output" == *"Bad credentials"* ]]
	[ ! -s "$DELETED" ]
}

@test "remove_online: refuses to run without a token" {
	run module_armbian_runners remove_online armbian-01
	[ "$status" -ne 0 ]
	[[ "$output" == *"token is mandatory"* ]]
}

@test "remove_online: deletes only the exactly matching runner" {
	_stub_curl
	LIST_FIXTURE='{"total_count":3,"runners":[{"id":11,"name":"armbian-01"},{"id":22,"name":"armbian-02"},{"id":33,"name":"other-01"}]}'
	run module_armbian_runners remove_online armbian-02 gh_token=xxx
	[ "$status" -eq 0 ]
	[ "$(cat "$DELETED")" = "22" ]
}

@test "remove_online: a runner name with a glob does not delete the fleet" {
	# [[ $name == $DELETE ]] with an unquoted right-hand side is a pattern
	# match, so '*' matched - and deleted - every runner in the org.
	_stub_curl
	LIST_FIXTURE='{"total_count":2,"runners":[{"id":11,"name":"armbian-01"},{"id":22,"name":"armbian-02"}]}'
	run module_armbian_runners remove_online '*' gh_token=xxx
	[ ! -s "$DELETED" ]
}

@test "remove_online: an empty runner list is not an error" {
	_stub_curl
	LIST_FIXTURE='{"total_count":0,"runners":[]}'
	run module_armbian_runners remove_online armbian-01 gh_token=xxx
	[ "$status" -eq 0 ]
	[ ! -s "$DELETED" ]
}

@test "remove_online: a busy runner (422) is reported, not swallowed" {
	_stub_curl
	LIST_FIXTURE='{"total_count":1,"runners":[{"id":11,"name":"armbian-01"}]}'
	DELETE_CODE=422
	run module_armbian_runners remove_online armbian-01 gh_token=xxx
	[ "$status" -ne 0 ]
	[[ "$output" == *"422"* ]]
}

@test "params: a value containing '=' survives parsing" {
	# IFS='=' read -a split kept only the first field, truncating such a value.
	_stub_curl
	LIST_FIXTURE='{"total_count":1,"runners":[{"id":11,"name":"a=b"}]}'
	run module_armbian_runners remove_online 'a=b' gh_token=xx=yy
	[ "$status" -eq 0 ]
	[ "$(cat "$DELETED")" = "11" ]
}

@test "params: a value is never executed as code" {
	# The old parser ran eval "$feature=$value" on whatever came off the
	# command line. No spaces in the payload: the old parser word-split on
	# those before eval saw them, which would mask the injection.
	# Stubbed like the rest: without it this reaches the real api.github.com,
	# making a parser test depend on the network.
	_stub_curl
	LIST_FIXTURE='{"total_count":0,"runners":[]}'
	run module_armbian_runners remove_online armbian-01 "gh_token=\$(id>$TMP/pwned)"
	[ ! -e "$TMP/pwned" ]
}

# `remove` does local teardown (userdel, sudoers edits). Neutralise it so these
# tests never touch the host, while letting the module's own temp-file cleanup
# work. rm passes through only for paths under the test tmpdir or /tmp.
_stub_local_teardown() {
	getent()   { return 1; }
	userdel()  { echo "userdel $*" >>"$TMP/teardown"; }
	groupdel() { :; }
	sed()      { :; }
	rm() {
		local a last=""
		for a in "$@"; do [[ "$a" == -* ]] || last="$a"; done
		case "$last" in /tmp/*|"$BATS_TEST_TMPDIR"/*) command rm "$@" ;; *) : ;; esac
	}
}

@test "remove_online: a name that matches nothing says so instead of looking deleted" {
	# The caller prints "Removing runner X on GitHub" before this runs, so a
	# silent zero-match read as a successful delete — which is how a stale
	# registration survived a "successful" remove.
	_stub_curl
	LIST_FIXTURE='{"total_count":2,"runners":[{"id":11,"name":"armbian-01"},{"id":22,"name":"armbian-02"}]}'
	run module_armbian_runners remove_online xxx gh_token=xxx
	[ "$status" -eq 0 ]
	[[ "$output" == *"No runner named 'xxx'"* ]]
	[[ "$output" == *"2 runner(s) listed"* ]]
	[ ! -s "$DELETED" ]
}

@test "remove: start/stop default to 01, so a bare runner_name hits <name>-01" {
	# Without the default, rm_indices was empty and the bare name "xxx" was
	# looked up — runners are registered as "<name>-NN", so it matched nothing.
	_stub_curl
	_stub_local_teardown
	: >"$TMP/teardown"
	LIST_FIXTURE='{"total_count":1,"runners":[{"id":77,"name":"xxx-01"}]}'
	run module_armbian_runners remove runner_name=xxx gh_token=xxx organisation=armbian
	[ "$status" -eq 0 ]
	[[ "$output" == *"Removing runner xxx-01 on GitHub"* ]]
	[[ "$output" == *"Delete existing: xxx-01"* ]]
	[ "$(cat "$DELETED")" = "77" ]
}

@test "help: documents the label fallback" {
	run module_armbian_runners help
	[ "$status" -eq 0 ]
	[[ "$output" == *"self-hosted"* ]]
	[[ "$output" == *"same as label_primary"* ]]
}
