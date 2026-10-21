module_options+=(
	["module_heroic,author"]="@HeyMeco"
	["module_heroic,maintainer"]="@HeyMeco"
	["module_heroic,feature"]="module_heroic"
	["module_heroic,example"]="install update remove status help"
	["module_heroic,desc"]="Heroic Games Launcher for amd64 and arm64"
	["module_heroic,status"]="Active"
	["module_heroic,doc_link"]="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher"
	["module_heroic,group"]="Gaming"
	["module_heroic,arch"]="x86-64 arm64"
	["module_heroic,release_api"]="https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest"
	["module_heroic,help_install"]="Install the latest Heroic .deb for this machine's architecture"
	["module_heroic,help_update"]="Install a newer Heroic release when GitHub has one"
	["module_heroic,help_remove"]="Remove the Heroic package; keep games and login data in the home directory"
	["module_heroic,help_status"]="Return success when the heroic package is installed"
)

# Debian package name produced by Heroic's electron-builder config.
module_heroic_package="heroic"

#
# Print the .deb suffix and electron-builder yml name for one dpkg architecture.
# amd64 is the x86_64 build. Heroic does not publish a 32-bit x86 package.
#
module_heroic_arch_spec() {
	local arch="${1:-$(dpkg --print-architecture)}"
	case "$arch" in
		amd64)
			printf '%s\n' linux-amd64.deb latest-linux.yml
			;;
		arm64)
			printf '%s\n' linux-arm64.deb latest-linux-arm64.yml
			;;
		*)
			echo "Heroic requires amd64 or arm64. Detected architecture: ${arch}." >&2
			return 1
			;;
	esac
}

#
# Print version, download URL, and base64 sha512 for the latest matching .deb.
#
module_heroic_resolve() {
	local suffix yml release name url version sums sum api

	{ read -r suffix; read -r yml; } < <(module_heroic_arch_spec) || return 1
	api="${module_options["module_heroic,release_api"]}"
	release=$(curl -fsSL --retry 5 --retry-delay 2 "$api") || {
		echo "Failed to read the latest Heroic release." >&2
		return 1
	}
	url=$(jq -r --arg suffix "$suffix" '[.assets[].browser_download_url | select(endswith($suffix))][0] // empty' <<< "$release")
	if [[ -z "$url" ]]; then
		echo "The latest Heroic release has no ${suffix} package." >&2
		return 1
	fi
	name=$(basename "$url")
	sums=$(curl -fsSL --retry 5 --retry-delay 2 "${url%/*}/${yml}") || {
		echo "Failed to read the Heroic checksum file." >&2
		return 1
	}
	version=$(awk '$1 == "version:" { print $2; exit }' <<< "$sums")
	sum=$(awk -v name="$name" '
		$1 == "-" && $2 == "url:" && $3 == name { grab = 1; next }
		grab && $1 == "sha512:" { print $2; exit }
	' <<< "$sums")
	if [[ -z "$version" || -z "$sum" ]]; then
		echo "Could not read the version or checksum for ${name}." >&2
		return 1
	fi
	printf '%s\n' "$version" "$url" "$sum"
}

module_heroic_installed_version() {
	local version
	pkg_installed "$module_heroic_package" || return 1
	version=$(dpkg-query -W -f='${Version}' "$module_heroic_package" 2>/dev/null) || return 1
	printf '%s\n' "${version%%-*}"
}

#
# Hold the dialog gauge below 100 until curl exits.
#
module_heroic_curl_gauge() {
	local label="$1"
	local line pct

	while IFS= read -r -d $'\r' line; do
		[[ "$line" =~ ([0-9]{1,3})(\.[0-9]+)?% ]] || continue
		pct="${BASH_REMATCH[1]}"
		if (( pct > 99 )); then
			pct=99
		fi
		printf 'XXX\n%s\nDownloading %s\nXXX\n' "$pct" "$label"
	done
}

module_heroic_fetch() {
	local url="$1"
	local dest="$2"
	local label rc_file curl_rc errexit=0

	label=$(basename "$url")
	if [[ "${DIALOG:-read}" == "read" ]]; then
		echo "Downloading ${url}"
		curl -fL --retry 5 --retry-delay 2 -o "$dest" "$url"
		return
	fi

	rc_file=$(mktemp)
	[[ $- == *e* ]] && errexit=1
	set +e
	(
		printf 'XXX\n0\nDownloading %s\nXXX\n' "$label"
		set +e
		curl -fL --retry 5 --retry-delay 2 --progress-bar -o "$dest" "$url" 2>&1 \
			| module_heroic_curl_gauge "$label"
		echo "${PIPESTATUS[0]}" > "$rc_file"
		curl_rc=$(<"$rc_file")
		if [[ "$curl_rc" == "0" ]]; then
			printf 'XXX\n100\nDownloaded %s\nXXX\n' "$label"
		fi
	) | dialog_gauge "Download" "Downloading ${label}" 8 80
	(( errexit )) && set -e
	curl_rc=$(<"$rc_file")
	rm -f "$rc_file"
	if [[ "$curl_rc" != "0" ]]; then
		echo "Failed to download ${url}." >&2
		return 1
	fi
}

module_heroic_verify() {
	local file="$1"
	local expected="$2"
	local have

	have=$(openssl dgst -sha512 -binary "$file" | base64 -w0)
	if [[ -z "$have" || "$have" != "$expected" ]]; then
		echo "Checksum mismatch for $(basename "$file")." >&2
		return 1
	fi
}

#
# Download the latest .deb for this architecture and install it.
# A matching installed version is left in place.
#
module_heroic_install_release() {
	local version url sum have work deb

	pkg_update || return 1
	pkg_install ca-certificates curl jq openssl || return 1
	{ read -r version; read -r url; read -r sum; } < <(module_heroic_resolve) || return 1
	if have=$(module_heroic_installed_version) && [[ "$have" == "$version" ]]; then
		echo "Heroic ${version} is already installed."
		return 0
	fi

	work=$(mktemp -d)
	trap 'rm -rf "$work"; trap - RETURN' RETURN
	deb="${work}/$(basename "$url")"
	module_heroic_fetch "$url" "$deb" || return 1
	module_heroic_verify "$deb" "$sum" || return 1
	apt_operation_progress install "$deb" || return 1
	echo "Heroic ${version} installed. Launch Heroic Games Launcher from the menu."
}

#
# Install or update the Heroic Games Launcher .deb that matches this machine.
#
function module_heroic() {
	local title="Heroic Launcher"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_heroic,example"]}"

	case "$1" in
		"${commands[0]}" | "${commands[1]}")
			if ! module_heroic_arch_spec >/dev/null; then
				if [[ -t 1 ]]; then
					dialog_msgbox "${title} not supported" \
						"Heroic publishes amd64 and arm64 packages.\n\nDetected architecture: $(dpkg --print-architecture)." 8 60
				fi
				return 1
			fi
			module_heroic_install_release
			;;
		"${commands[2]}")
			if ! pkg_installed "$module_heroic_package"; then
				echo "Heroic is not installed." >&2
				return 1
			fi
			pkg_remove "$module_heroic_package" || return 1
			echo "Heroic removed. Games and login data in the home directory were kept."
			;;
		"${commands[3]}")
			pkg_installed "$module_heroic_package"
			;;
		supported)
			module_heroic_arch_spec >/dev/null 2>&1
			;;
		"${commands[4]}")
			show_module_help "module_heroic" "$title" \
				"Package: heroic\nArchitectures: amd64 (x86_64) and arm64\nSource: latest GitHub release .deb" \
				"native"
			;;
		*)
			${module_options["module_heroic,feature"]} "${commands[4]}"
			;;
	esac
}
