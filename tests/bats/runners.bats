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

@test "help: documents the label fallback" {
	run module_armbian_runners help
	[ "$status" -eq 0 ]
	[[ "$output" == *"self-hosted"* ]]
	[[ "$output" == *"same as label_primary"* ]]
}
