#!/usr/bin/env bats
#
# Raspberry Pi overlay filters and config.txt writes, using synthetic boards
# and boot files. The resolver and dialog stubs keep all I/O in the fixture.

setup() {
	declare -gA module_options
	source "${BATS_TEST_DIRNAME}/../../tools/modules/system/module_devicetree_overlays.sh"
	config="$BATS_TEST_TMPDIR/config.txt"
	model="$BATS_TEST_TMPDIR/model"
	overlays="$BATS_TEST_TMPDIR/overlays"
	mkdir "$overlays"
	touch "$overlays"/{dwc2,spi0-1cs}.dtbo

	_dt_overlays_resolve_paths() {
		overlayconf="$config"
		overlaydir="$overlays"
		overlay_prefix=""
		overlay_prefixes=()
		is_pi=true
		pi_model_file="$model"
	}
}

write_config() {
	cat > "$BATS_TEST_TMPDIR/outside" <<'EOF'
dtoverlay=gpio-fan,gpiopin=14
[cm5]
dtoverlay=dwc2,dr_mode=host
dtparam=audio=on
[pi5]
dtoverlay=uart0
[pi4]
dtoverlay=i2c1
[all]
dtoverlay=pwm
EOF
	cat "$BATS_TEST_TMPDIR/outside" > "$config"
	printf '%s\n' '# Armbian config' '[all]' 'dtoverlay=spi0-1cs,cs0_pin=7' >> "$config"
}

assert_outside_preserved() {
	sed '/^# Armbian config$/,$d' "$config" > "$BATS_TEST_TMPDIR/after"
	cmp "$BATS_TEST_TMPDIR/outside" "$BATS_TEST_TMPDIR/after"
}

@test "show: CM5 matches cm5 and inherits pi5 but skips pi4" {
	write_config
	printf 'Raspberry Pi Compute Module 5 Rev 1.0\0' > "$model"
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[[ "$output" == *'dwc2,dr_mode=host (set above'* ]]
	[[ "$output" == *'uart0 (set above'* ]]
	[[ "$output" != *'i2c1'* ]]
	[[ "$output" == *'gpio-fan,gpiopin=14 (set above'* ]]
	[[ "$output" == *'pwm (set above'* ]]
	[[ "$output" == *'spi0-1cs,cs0_pin=7'* ]]
}

@test "show: Pi 4 and Pi 5 do not match cm5" {
	write_config
	printf 'Raspberry Pi 4 Model B Rev 1.5\0' > "$model"
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[[ "$output" == *'i2c1 (set above'* ]]
	[[ "$output" != *'dwc2'* && "$output" != *'uart0'* ]]

	printf 'Raspberry Pi 5 Model B Rev 1.0\0' > "$model"
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[[ "$output" == *'uart0 (set above'* ]]
	[[ "$output" != *'dwc2'* && "$output" != *'i2c1'* ]]
}

@test "show: model changes replace model filters and all clears combined filters" {
	printf 'Raspberry Pi Compute Module 4S Rev 1.0\0' > "$model"
	cat > "$config" <<'EOF'
[pi5]
dtoverlay=other-model
[pi4]
dtoverlay=inherited
[cm4]
dtoverlay=other-module
[cm4s]
dtoverlay=matching
[gpio4=1]
dtoverlay=conditional
[pi4]
dtoverlay=still-conditional
[all]
dtoverlay=after-reset
[none]
dtoverlay=disabled
[cm4s]
dtoverlay=still-disabled
[all]
dtoverlay=final
EOF
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 4 ]
	[[ "${lines[0]}" == 'inherited (set above'* ]]
	[[ "${lines[1]}" == 'matching (set above'* ]]
	[[ "${lines[2]}" == 'after-reset (set above'* ]]
	[[ "${lines[3]}" == 'final (set above'* ]]
}

@test "show: missing or unknown model only confirms unconditional overlays" {
	write_config
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 3 ]
	[[ "${lines[1]}" == 'gpio-fan,gpiopin=14 (set above'* ]]
	[[ "${lines[2]}" == 'pwm (set above'* ]]
	expected="$output"

	printf 'Raspberry Pi 50 Model B Rev 1.0\0' > "$model"
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[ "$output" = "$expected" ]
}

@test "show: CM0 inherits pi02 and skips pi0 and pi0w" {
	printf 'Raspberry Pi Compute Module 0 Rev 1.0\0' > "$model"
	cat > "$config" <<'EOF'
[pi0]
dtoverlay=zero-only
[pi0w]
dtoverlay=zero-w-only
[pi02]
dtoverlay=zero2-parent
[cm0]
dtoverlay=cm0-only
EOF
	run module_devicetree_overlays show
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[0]}" == 'zero2-parent (set above'* ]]
	[[ "${lines[1]}" == 'cm0-only (set above'* ]]
}

@test "install and remove: applicable fixed overlay blocks duplication and removal" {
	write_config
	printf 'Raspberry Pi Compute Module 5\0' > "$model"
	cp "$config" "$BATS_TEST_TMPDIR/before"

	run module_devicetree_overlays install overlays=dwc2
	[ "$status" -eq 0 ]
	[[ "$output" == *'already enabled'* ]]
	run module_devicetree_overlays remove overlays=dwc2,spi0-1cs
	[ "$status" -eq 1 ]
	[[ "$output" == *'dwc2 set above'* ]]
	cmp "$BATS_TEST_TMPDIR/before" "$config"
	[ ! -e "$config.bak" ]
}

@test "install and remove: CM5-only overlay can be managed separately on Pi 5" {
	write_config
	printf 'Raspberry Pi 5 Model B Rev 1.0\0' > "$model"
	cp "$config" "$BATS_TEST_TMPDIR/before"

	run module_devicetree_overlays install overlays=dwc2
	[ "$status" -eq 0 ]
	grep -qx 'dtoverlay=dwc2' "$config"
	assert_outside_preserved
	cmp "$BATS_TEST_TMPDIR/before" "$config.bak"

	run module_devicetree_overlays remove overlays=dwc2
	[ "$status" -eq 0 ]
	cmp "$BATS_TEST_TMPDIR/before" "$config"
}

@test "edit: fixed overlay is hidden only on the matching model" {
	write_config
	printf 'Raspberry Pi Compute Module 5\0' > "$model"
	printf '%s\n' 'dtoverlay=dwc2,dr_mode=peripheral' >> "$config"
	cp "$config" "$BATS_TEST_TMPDIR/before"
	_dt_overlays_scenario() { echo "00"; }
	dialog_yesno() { return 1; }
	systemctl() { touch "$BATS_TEST_TMPDIR/unexpected-reboot"; }
	dialog_checklist() {
		[[ -f "$BATS_TEST_TMPDIR/checklist" ]] && return 1
		printf '%s\n' "$@" > "$BATS_TEST_TMPDIR/checklist"
		echo '"spi0-1cs"'
	}

	run module_devicetree_overlays edit
	[ "$status" -eq 0 ]
	grep -q 'dwc2,dr_mode=host' "$BATS_TEST_TMPDIR/checklist"
	run grep -qx 'dwc2' "$BATS_TEST_TMPDIR/checklist"
	[ "$status" -eq 1 ]
	grep -qx 'spi0-1cs' "$BATS_TEST_TMPDIR/checklist"
	grep -qx 'dtoverlay=dwc2,dr_mode=peripheral' "$config"
	grep -qx 'dtoverlay=spi0-1cs,cs0_pin=7' "$config"
	assert_outside_preserved
	cmp "$BATS_TEST_TMPDIR/before" "$config.bak"

	# On Pi 5 the managed dwc2 entry is selectable, so leaving it
	# unticked removes only that entry.
	rm "$BATS_TEST_TMPDIR/checklist"
	printf 'Raspberry Pi 5 Model B\0' > "$model"
	run module_devicetree_overlays edit
	[ "$status" -eq 0 ]
	grep -qx 'dwc2' "$BATS_TEST_TMPDIR/checklist"
	run grep -qx 'dtoverlay=dwc2,dr_mode=peripheral' "$config"
	[ "$status" -eq 1 ]
	assert_outside_preserved
	[ ! -e "$BATS_TEST_TMPDIR/unexpected-reboot" ]
}

@test "install: a CRLF managed marker keeps the outside bytes on rewrite" {
	printf 'Raspberry Pi 5 Model B\0' > "$model"
	printf '[cm5]\r\ndtoverlay=dwc2,dr_mode=host\r\n' > "$BATS_TEST_TMPDIR/outside"
	cat "$BATS_TEST_TMPDIR/outside" > "$config"
	printf '# Armbian config\r\n[all]\r\ndtoverlay=spi0-1cs,cs0_pin=7\r\n' >> "$config"

	run module_devicetree_overlays install overlays=dwc2
	[ "$status" -eq 0 ]
	assert_outside_preserved
	grep -qx 'dtoverlay=spi0-1cs,cs0_pin=7' "$config"
	grep -qx 'dtoverlay=dwc2' "$config"
}

@test "install: appending a managed block preserves an unterminated directive" {
	printf 'Raspberry Pi 5 Model B\0' > "$model"
	printf '[cm5]\ndtoverlay=dwc2,dr_mode=host' > "$config"

	run module_devicetree_overlays install overlays=dwc2
	[ "$status" -eq 0 ]
	printf '%s\n' '[cm5]' 'dtoverlay=dwc2,dr_mode=host' '# Armbian config' '[all]' 'dtoverlay=dwc2' > "$BATS_TEST_TMPDIR/expected"
	cmp "$BATS_TEST_TMPDIR/expected" "$config"
}
