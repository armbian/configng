#!/usr/bin/env bats
#
# Unit tests for the pure Windows dual-boot planner (install_dualboot_plan):
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
