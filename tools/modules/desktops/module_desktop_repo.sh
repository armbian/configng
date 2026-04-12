module_options+=(
	["module_desktop_repo,author"]="@igorpecovnik"
	["module_desktop_repo,feature"]="module_desktop_repo"
	["module_desktop_repo,desc"]="Set up custom APT repository for desktop environments"
	["module_desktop_repo,example"]="module_desktop_repo kde-neon"
	["module_desktop_repo,status"]="Active"
	["module_desktop_repo,arch"]="arm64 amd64 armhf riscv64"
)

#
# Set up custom APT repo if desktop requires one
# Usage: module_desktop_repo <de_name>
# Requires DESKTOP_REPO_URL, DESKTOP_REPO_KEY_URL, DESKTOP_REPO_KEYRING
# to be set (via module_desktop_yamlparse)
#
function module_desktop_repo() {
	local de="$1"

	case "$de" in
		help|"")
			echo "Usage: module_desktop_repo <de_name>"
			echo ""
			echo "Set up a custom APT repository for a desktop that requires one."
			echo "Must be called after module_desktop_yamlparse to set repo variables."
			echo ""
			echo "Examples:"
			echo "  module_desktop_yamlparse kde-neon"
			echo "  module_desktop_repo kde-neon"
			return 0
		;;
		*)
			# sanitize de name for safe use in file paths
			if [[ ! "$de" =~ ^[a-zA-Z0-9._-]+$ ]]; then
				echo "Error: invalid desktop name '${de}'" >&2
				return 1
			fi

			if [[ -n "$DESKTOP_REPO_URL" && -n "$DESKTOP_REPO_KEY_URL" && -n "$DESKTOP_REPO_KEYRING" ]]; then
				echo "Setting up repository for ${de}..." >&2

				# download and verify GPG key
				if ! (set -o pipefail; curl -fsSL --retry 3 --retry-connrefused --connect-timeout 10 --max-time 30 "$DESKTOP_REPO_KEY_URL" | gpg --yes --dearmor -o "$DESKTOP_REPO_KEYRING" 2>/dev/null); then
					echo "Error: failed to download GPG key from $DESKTOP_REPO_KEY_URL" >&2
					return 1
				fi

				if [[ ! -s "$DESKTOP_REPO_KEYRING" ]]; then
					echo "Error: GPG keyring is empty at $DESKTOP_REPO_KEYRING" >&2
					rm -f "$DESKTOP_REPO_KEYRING"
					return 1
				fi

				# Emit one `deb ...` line per suite. Components are shared
				# across all lines. Written via temp + mv so a mid-write
				# failure never leaves apt with a partial source list.
				# Falls back to ${DISTROID} / "main" when the parser did
				# not supply values (DE YAMLs without the optional fields).
				local repo_components="${DESKTOP_REPO_COMPONENTS:-main}"
				local sources_count="${DESKTOP_REPO_SUITES_COUNT:-1}"
				local sources_file="/etc/apt/sources.list.d/${de}.list"
				local sources_tmp="${sources_file}.tmp"
				local i suite_var suite

				if ! : > "$sources_tmp"; then
					echo "Error: cannot create ${sources_tmp}" >&2
					return 1
				fi

				for (( i=0; i < sources_count; i++ )); do
					suite_var="DESKTOP_REPO_SUITE_${i}"
					suite="${!suite_var:-${DISTROID}}"
					if ! printf 'deb [signed-by=%s] %s %s %s\n' \
						"$DESKTOP_REPO_KEYRING" "$DESKTOP_REPO_URL" \
						"$suite" "$repo_components" >> "$sources_tmp"; then
						echo "Error: failed to write sources list for ${de}" >&2
						rm -f "$sources_tmp"
						return 1
					fi
				done

				if ! mv "$sources_tmp" "$sources_file"; then
					echo "Error: failed to install ${sources_file}" >&2
					rm -f "$sources_tmp"
					return 1
				fi

				# Optional: APT pin preferences. Gated on the repo guard
				# above so prefs can only land when the matching archive
				# was actually configured. Written via temp + mv so a
				# mid-write failure never leaves a truncated stanza that
				# apt would misparse. Only fields emitted by
				# parse_desktop_yaml.py are interpolated.
				local pref_file="/etc/apt/preferences.d/${de}"
				if [[ -n "${DESKTOP_REPO_PREFS_COUNT}" && "${DESKTOP_REPO_PREFS_COUNT}" -gt 0 ]]; then
					local pref_tmp="${pref_file}.tmp"
					local i origin_var suite_var prio_var origin suite prio

					if ! : > "$pref_tmp"; then
						echo "Error: cannot create ${pref_tmp}" >&2
						return 1
					fi

					for (( i=0; i < DESKTOP_REPO_PREFS_COUNT; i++ )); do
						origin_var="DESKTOP_REPO_PREFS_${i}_ORIGIN"
						suite_var="DESKTOP_REPO_PREFS_${i}_SUITE"
						prio_var="DESKTOP_REPO_PREFS_${i}_PRIORITY"
						origin="${!origin_var}"
						suite="${!suite_var}"
						prio="${!prio_var}"
						if ! printf 'Package: *\nPin: release o=%s, n=%s\nPin-Priority: %s\n\n' \
							"$origin" "$suite" "$prio" >> "$pref_tmp"; then
							echo "Error: failed to write preferences for ${de}" >&2
							rm -f "$pref_tmp"
							return 1
						fi
					done

					if ! mv "$pref_tmp" "$pref_file"; then
						echo "Error: failed to install ${pref_file}" >&2
						rm -f "$pref_tmp"
						return 1
					fi
				else
					# No pins in the current YAML: drop any stale pref
					# file left by an earlier install whose YAML carried
					# preferences. Install is declarative — post-state
					# must match the YAML, whether pins are present or not.
					rm -f "$pref_file"
				fi
			fi
		;;
	esac
}
