module_options+=(
	["module_steam,author"]="@HeyMeco"
	["module_steam,maintainer"]="@HeyMeco"
	["module_steam,feature"]="module_steam"
	["module_steam,example"]="install update remove purge status help"
	["module_steam,desc"]="Native ARM64 Steam client with Proton-CachyOS and Proton-GE"
	["module_steam,status"]="Active"
	["module_steam,doc_link"]="https://github.com/armbian/configng/issues/941"
	["module_steam,group"]="Games"
	["module_steam,arch"]="arm64"
	["module_steam,steam_manifest_url"]="https://client-update.fastly.steamstatic.com/steam_client_publicbeta_linuxarm64"
	["module_steam,steam_cdn"]="https://client-update.steamstatic.com"
	["module_steam,help_install"]="Install the public-beta ARM64 Steam client, the latest Proton-CachyOS and Proton-GE, and an extracted FEX Arch rootfs"
	["module_steam,help_update"]="Update Proton-CachyOS and Proton-GE to the latest release, and refresh the extracted FEX Arch rootfs"
	["module_steam,help_remove"]="Remove the Steam client and Proton trees; keep games, userdata, and the FEX rootfs"
	["module_steam,help_purge"]="Remove Steam, games, userdata, the extracted FEX rootfs, and the libvpx shim if this module created it"
	["module_steam,help_status"]="Return success when the ARM64 Steam client is installed for its user"
)

# Marker written only when this module creates the libvpx.so.6 compatibility link.
module_steam_libvpx_marker="/var/lib/armbian/module_steam-libvpx"

# The user Steam was installed for, so status does not depend on who runs sudo.
module_steam_user_marker="/var/lib/armbian/module_steam-user"

# Extracted Arch rootfs, the same layout FEXRootFSFetcher -x writes. The FEX
# binary comes from Steam, which always reads the rootfs from the guest path.
module_steam_fex_links="https://rootfs.fex-emu.gg/RootFS_links.json"
module_steam_fex_guest_path="/usr/share/guestos/fex-mesa"

module_steam_require_arm64() {
	local arch
	arch=$(dpkg --print-architecture)
	[[ "$arch" == "arm64" ]] && return 0
	echo "Steam ARM64 requires arm64. Detected architecture: ${arch}." >&2
	return 1
}

#
# Return success when managed state remains: the Steam directory, the FEX
# rootfs this module extracted, or the libvpx shim this module created.
# Used to gate Purge so it stays visible after Remove.
#
module_steam_has_state() {
	local user home
	[[ -f "$module_steam_libvpx_marker" ]] && return 0
	user=$(module_steam_installed_user 2>/dev/null) || return 1
	home=$(module_steam_user_home "$user" 2>/dev/null) || true
	[[ -n "$home" && "$home" != "/" ]] || return 1
	module_steam_paths "$home"
	[[ -d "$STEAM_ROOT" ]] || [[ -f "$(module_steam_fex_root "$home")/ArchLinux.hash" ]]
}

#
# Print the user Steam was installed for, falling back to the desktop user.
# Errors are suppressed so menu status checks stay silent.
#
module_steam_installed_user() {
	local user=""
	if [[ -f "$module_steam_user_marker" ]]; then
		user=$(<"$module_steam_user_marker")
		if [[ -n "$user" ]] && id "$user" >/dev/null 2>&1; then
			printf '%s\n' "$user"
			return 0
		fi
	fi
	module_desktop_getuser 2>/dev/null
}

module_steam_user_home() {
	local user="$1"
	getent passwd "$user" | awk -F: '{print $6}'
}

module_steam_paths() {
	local home="$1"
	STEAM_ROOT="${home}/.local/share/Steam"
	STEAM_DOT="${home}/.steam"
	STEAM_COMPAT="${STEAM_ROOT}/compatibilitytools.d"
	STEAM_CLIENT="${STEAM_ROOT}/steamrtarm64/steam"
	STEAM_DESKTOP="${home}/.local/share/applications/steam.desktop"
}

module_steam_fetch() {
	local user="$1"
	local url="$2"
	local dest="$3"
	echo "Downloading ${url}"
	runuser -u "$user" -- curl -fL --retry 5 --retry-delay 2 -o "$dest" "$url"
}

#
# Compare a file against an expected digest. algo is sha256 or sha512.
#
module_steam_verify() {
	local file="$1"
	local algo="$2"
	local expected="${3,,}"
	local actual

	actual=$("${algo}sum" "$file" | awk '{print $1}')
	if [[ -z "$expected" || "$actual" != "$expected" ]]; then
		echo "Checksum mismatch for $(basename "$file")." >&2
		return 1
	fi
}

#
# Print the file name and sha2 of one entry in a Steam client manifest (VDF).
#
module_steam_manifest_entry() {
	local manifest="$1"
	local key="$2"
	awk -v key="\"${key}\"" '
		$1 == key { inside = 1; next }
		inside && $1 == "}" { exit }
		inside && $1 == "\"file\"" { gsub(/"/, "", $2); file = $2 }
		inside && $1 == "\"sha2\"" { gsub(/"/, "", $2); sha = $2 }
		END { if (file == "" || sha == "") exit 1; print file; print sha }
	' <<< "$manifest"
}

#
# Print the download URL of the first asset in the latest release of repo
# whose name ends with suffix.
#
module_steam_latest_asset() {
	local repo="$1"
	local suffix="$2"
	local url

	url=$(curl -fsSL --retry 5 --retry-delay 2 "https://api.github.com/repos/${repo}/releases/latest" |
		jq -r --arg suffix "$suffix" '[.assets[].browser_download_url | select(endswith($suffix))][0] // empty')
	if [[ -z "$url" ]]; then
		echo "Could not find a ${suffix} release asset in ${repo}." >&2
		return 1
	fi
	printf '%s\n' "$url"
}

#
# Install a Proton archive into compatibilitytools.d, then drop sibling
# directories that match cleanup_glob. The archive must extract to a directory
# named after itself and have a .sha512sum published next to it.
#
module_steam_install_tool() {
	local user="$1"
	local url="$2"
	local cleanup_glob="$3"
	local work="$4"
	local archive_name dir dest_dir archive sums expected old

	archive_name=$(basename "$url")
	dir="${archive_name%.tar.*}"
	dest_dir="${STEAM_COMPAT}/${dir}"
	runuser -u "$user" -- mkdir -p "$STEAM_COMPAT"

	if [[ -d "$dest_dir" ]]; then
		echo "${dir} already installed."
	else
		archive="${work}/${archive_name}"
		sums="${work}/${dir}.sha512sum"
		module_steam_fetch "$user" "$url" "$archive" || return 1
		module_steam_fetch "$user" "${url%.tar.*}.sha512sum" "$sums" || return 1
		expected=$(awk 'NR == 1 {print $1}' "$sums")
		module_steam_verify "$archive" sha512 "$expected" || return 1
		runuser -u "$user" -- tar -xf "$archive" -C "$STEAM_COMPAT" || return 1
		if [[ ! -d "$dest_dir" ]]; then
			echo "Expected ${dest_dir} after extracting ${archive_name}." >&2
			return 1
		fi
		echo "Installed ${dir}."
	fi

	while IFS= read -r -d '' old; do
		[[ "$old" == "$dest_dir" ]] && continue
		echo "Removing old $(basename "$old")"
		rm -rf "$old"
	done < <(find "$STEAM_COMPAT" -mindepth 1 -maxdepth 1 -type d -name "$cleanup_glob" -print0 2>/dev/null)
}

#
# Install or replace the latest arm64 Proton-CachyOS and Proton-GE under
# compatibilitytools.d.
#
module_steam_install_protons() {
	local user="$1"
	local work="$2"
	local url

	url=$(module_steam_latest_asset CachyOS/proton-cachyos '-arm64.tar.xz') || return 1
	module_steam_install_tool "$user" "$url" 'proton-cachyos-*-arm64' "$work" || return 1

	url=$(module_steam_latest_asset GloriousEggroll/proton-ge-custom '-aarch64.tar.gz') || return 1
	module_steam_install_tool "$user" "$url" 'GE-Proton*-aarch64' "$work"
}

#
# The public-beta client looks for libvpx.so.6. Link the newest installed
# libvpx if that soname is absent, and remember the link so purge can undo it.
#
module_steam_libvpx_candidate() {
	local libdir="$1"
	find "$libdir" -maxdepth 1 -name 'libvpx.so.*' ! -name 'libvpx.so.6' -printf '%f\n' 2>/dev/null | sort -V | tail -n 1
}

module_steam_libvpx_shim() {
	local libdir="/usr/lib/aarch64-linux-gnu"
	local link="${libdir}/libvpx.so.6"
	local candidate="" pkg

	[[ -e "$link" ]] && return 0
	if [[ -L "$link" ]]; then
		if [[ -f "$module_steam_libvpx_marker" && "$(<"$module_steam_libvpx_marker")" == "$link" ]]; then
			rm -f "$link"
		else
			echo "Warning: ${link} is a dangling link not created by this module." >&2
			return 0
		fi
	fi

	candidate=$(module_steam_libvpx_candidate "$libdir")
	if [[ -z "$candidate" ]]; then
		for pkg in libvpx11 libvpx9 libvpx8 libvpx7; do
			if apt-cache show "$pkg" >/dev/null 2>&1; then
				pkg_install "$pkg" || return 1
				break
			fi
		done
		[[ -e "$link" ]] && return 0
		candidate=$(module_steam_libvpx_candidate "$libdir")
	fi

	if [[ -z "$candidate" ]]; then
		echo "Warning: libvpx.so.6 is missing and no libvpx library was found. Steam may fail to start." >&2
		return 0
	fi

	ln -s "$candidate" "$link" || return 1
	mkdir -p "$(dirname "$module_steam_libvpx_marker")"
	printf '%s\n' "$link" > "$module_steam_libvpx_marker"
}

module_steam_remove_libvpx_shim() {
	local link
	[[ -f "$module_steam_libvpx_marker" ]] || return 0
	link=$(<"$module_steam_libvpx_marker")
	if [[ -n "$link" && -L "$link" ]]; then
		rm -f "$link"
	fi
	rm -f "$module_steam_libvpx_marker"
}

#
# Left-pad a hex digest to 16 characters so a short xxHash matches the
# 64-bit value FEX publishes in RootFS_links.json.
#
module_steam_fex_pad_hash() {
	local hex="${1,,}"
	hex="${hex#0x}"
	printf '%016s\n' "$hex" | tr ' ' '0'
}

#
# FEXRootFSFetcher hashes with XXH3-64 and seed 0. xxh64sum is a different algorithm.
#
module_steam_fex_xxh3() {
	local file="$1" sum
	sum=$(xxhsum -H3 "$file" | awk '{print $1}')
	sum="${sum#XXH3_}"
	[[ -n "$sum" ]] || return 1
	module_steam_fex_pad_hash "$sum"
}

module_steam_fex_root() {
	printf '%s\n' "$1/.local/share/fex-emu/RootFS"
}

#
# Print the graphics_provider.json Steam should use, preferring the guest path.
#
module_steam_fex_provider() {
	local home="$1"
	local path
	for path in "${module_steam_fex_guest_path}/graphics_provider.json" \
		"$(module_steam_fex_root "$home")/ArchLinux/graphics_provider.json"; do
		if [[ -f "$path" ]]; then
			printf '%s\n' "$path"
			return 0
		fi
	done
	return 1
}

#
# Print the current Arch squashfs URL and xxHash, one per line.
#
module_steam_fex_resolve() {
	curl -fsSL --retry 5 --retry-delay 2 "$module_steam_fex_links" |
		jq -r '.v1["ArchLinux (SquashFS)"] | select(.Type == "squashfs") | .URL, .Hash'
}

#
# Steam's FEX tool ignores the environment and always uses the guest path.
# Point that path at the extracted tree. Only one user per system can own it.
#
module_steam_fex_link() {
	local home="$1"
	local dest

	dest="$(module_steam_fex_root "$home")/ArchLinux"
	[[ -f "${dest}/graphics_provider.json" ]] || return 1
	mkdir -p "$(dirname "$module_steam_fex_guest_path")"
	if [[ -e "$module_steam_fex_guest_path" && ! -L "$module_steam_fex_guest_path" ]]; then
		if ! rmdir "$module_steam_fex_guest_path" 2>/dev/null; then
			echo "Refusing to replace ${module_steam_fex_guest_path}." >&2
			return 1
		fi
	fi
	ln -sfn "$dest" "$module_steam_fex_guest_path"
}

module_steam_fex_write_env() {
	local user="$1"
	local home="$2"
	local provider env_dir env_file

	provider=$(module_steam_fex_provider "$home") || return 0
	env_dir="${home}/.config/environment.d"
	env_file="${env_dir}/steam-fex.conf"
	runuser -u "$user" -- mkdir -p "$env_dir"
	printf 'STEAM_COMPAT_GRAPHICS_PROVIDER=%s\n' "$provider" | runuser -u "$user" -- tee "$env_file" >/dev/null
}

module_steam_fex_publish() {
	local user="$1"
	local home="$2"

	module_steam_fex_link "$home" || return 1
	module_steam_fex_write_env "$user" "$home"
}

#
# Download FEX's Arch squashfs, extract it, and delete the image.
# An existing graphics_provider.json that this module did not create is left alone.
#
module_steam_fex_install() {
	local user="$1"
	local home="$2"
	local spec url hash padded have root dest marker staging partial extract_status

	root=$(module_steam_fex_root "$home")
	dest="${root}/ArchLinux"
	marker="${root}/ArchLinux.hash"
	staging="${root}/ArchLinux.extracting"
	partial="${root}/ArchLinux.sqsh.partial"

	pkg_install curl jq squashfs-tools xxhash || return 1
	spec=$(module_steam_fex_resolve)
	{ read -r url; read -r hash; } <<< "$spec"
	if [[ -z "$url" || -z "$hash" ]]; then
		echo "Failed to resolve the FEX Arch rootfs." >&2
		return 1
	fi
	padded=$(module_steam_fex_pad_hash "$hash")

	if [[ -f "${dest}/graphics_provider.json" && ! -f "$marker" ]]; then
		echo "FEX rootfs already present at ${dest}."
		module_steam_fex_publish "$user" "$home"
		return 0
	fi
	if [[ -f "${dest}/graphics_provider.json" && "$(<"$marker")" == "$padded" ]]; then
		echo "FEX Arch rootfs already extracted."
		module_steam_fex_publish "$user" "$home"
		return 0
	fi

	runuser -u "$user" -- mkdir -p "$root"
	echo "Downloading FEX Arch rootfs."
	if ! module_steam_fetch "$user" "$url" "$partial"; then
		rm -f "$partial"
		return 1
	fi
	have=$(module_steam_fex_xxh3 "$partial") || have=""
	if [[ "$have" != "$padded" ]]; then
		rm -f "$partial"
		echo "FEX rootfs hash ${have:-unknown} does not match ${padded}." >&2
		return 1
	fi
	if ! (set -o pipefail; unsquashfs -cat "$partial" graphics_provider.json | jq -e . >/dev/null); then
		rm -f "$partial"
		echo "FEX rootfs is missing graphics_provider.json." >&2
		return 1
	fi

	echo "Extracting FEX Arch rootfs."
	rm -rf "$staging"
	# Exit 2 means unsquashfs kept going after a non-fatal error. Device nodes
	# and some permissions cannot be created as the desktop user; the tree is
	# still the one FEX uses. Exit 1 is a fatal extract and must fail.
	extract_status=0
	runuser -u "$user" -- unsquashfs -no-xattrs -d "$staging" "$partial" || extract_status=$?
	if [[ "$extract_status" -ne 0 && "$extract_status" -ne 2 ]] || [[ ! -f "${staging}/graphics_provider.json" ]]; then
		rm -rf "$staging" "$partial"
		echo "Failed to extract the FEX Arch rootfs." >&2
		return 1
	fi
	rm -f "$partial"
	rm -rf "$dest"
	runuser -u "$user" -- mv "$staging" "$dest" || return 1
	printf '%s\n' "$padded" | runuser -u "$user" -- tee "$marker" >/dev/null
	module_steam_fex_publish "$user" "$home"
	echo "FEX Arch rootfs extracted to ${dest}."
}

module_steam_fex_remove() {
	local home="$1"
	local root dest marker

	[[ -n "$home" && "$home" != "/" ]] || return 0
	root=$(module_steam_fex_root "$home")
	dest="${root}/ArchLinux"
	marker="${root}/ArchLinux.hash"
	[[ -f "$marker" ]] || return 0
	if [[ -L "$module_steam_fex_guest_path" && "$(readlink -f "$module_steam_fex_guest_path")" == "$(readlink -f "$dest")" ]]; then
		rm -f "$module_steam_fex_guest_path"
		rmdir "$(dirname "$module_steam_fex_guest_path")" 2>/dev/null || true
	fi
	rm -rf "$dest" "$marker" "${root}/ArchLinux.sqsh.partial" "${root}/ArchLinux.extracting"
	rm -f "${home}/.config/environment.d/steam-fex.conf"
	rmdir "$root" "${home}/.local/share/fex-emu" 2>/dev/null || true
}

#
# KEY=VALUE lines for the desktop user's graphical session, or failure when
# Steam would have no display to bootstrap against.
#
module_steam_session_env() {
	local user="$1"
	local uid runtime id session="" sess_user sess_type sess_state display wl=""

	command -v loginctl >/dev/null 2>&1 || return 1
	uid=$(id -u "$user") || return 1
	runtime="/run/user/${uid}"
	[[ -d "$runtime" ]] || return 1

	while read -r id _; do
		[[ -z "$id" || "$id" == "SESSION" ]] && continue
		sess_user=$(loginctl show-session "$id" -p Name --value 2>/dev/null || true)
		[[ "$sess_user" == "$user" ]] || continue
		sess_type=$(loginctl show-session "$id" -p Type --value 2>/dev/null || true)
		sess_state=$(loginctl show-session "$id" -p State --value 2>/dev/null || true)
		case "$sess_type" in
			wayland|x11) ;;
			*) continue ;;
		esac
		case "$sess_state" in
			active|online) ;;
			*) continue ;;
		esac
		session="$id"
		break
	done < <(loginctl list-sessions --no-legend 2>/dev/null || true)

	[[ -n "$session" ]] || return 1

	printf 'XDG_RUNTIME_DIR=%s\n' "$runtime"
	if [[ -S "${runtime}/bus" ]]; then
		printf 'DBUS_SESSION_BUS_ADDRESS=unix:path=%s/bus\n' "$runtime"
	fi
	display=$(loginctl show-session "$session" -p Display --value 2>/dev/null || true)
	if [[ -n "$display" ]]; then
		printf 'DISPLAY=%s\n' "$display"
	fi
	if [[ -S "${runtime}/wayland-0" ]]; then
		wl="wayland-0"
	else
		wl=$(find "$runtime" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' 2>/dev/null | head -n 1 || true)
	fi
	if [[ -n "$wl" ]]; then
		printf 'WAYLAND_DISPLAY=%s\n' "$wl"
	fi
	[[ -n "$display" || -n "$wl" ]]
}

#
# Disable the x86 binfmt handlers that are currently enabled and print their
# names, so the bootstrap uses Steam's own FEX.
#
module_steam_binfmt_disable() {
	local node
	for node in x86 box32 box64; do
		[[ "$(head -n 1 "/proc/sys/fs/binfmt_misc/${node}" 2>/dev/null)" == "enabled" ]] || continue
		echo 0 > "/proc/sys/fs/binfmt_misc/${node}" && printf '%s\n' "$node"
	done
}

module_steam_binfmt_enable() {
	local node
	for node in "$@"; do
		echo 1 > "/proc/sys/fs/binfmt_misc/${node}" || true
	done
}

#
# One-shot Frame-mode bootstrap. The desktop launcher does not use -deckard.
# A missing display skips the pass; a non-zero Steam exit is only a warning.
#
module_steam_deckard() {
	local user="$1"
	local client="$2"
	local session_text line home provider prev_int prev_term prev_hup
	local -a env_args=() disabled=()

	if ! session_text=$(module_steam_session_env "$user"); then
		echo "No graphical session for ${user}. Launch Steam once from the desktop menu to finish setup."
		return 0
	fi

	while IFS= read -r line; do
		[[ -n "$line" ]] && env_args+=("$line")
	done <<< "$session_text"
	home=$(module_steam_user_home "$user")
	if provider=$(module_steam_fex_provider "$home"); then
		env_args+=("STEAM_COMPAT_GRAPHICS_PROVIDER=${provider}")
	fi

	prev_int=$(trap -p INT)
	prev_term=$(trap -p TERM)
	prev_hup=$(trap -p HUP)
	mapfile -t disabled < <(module_steam_binfmt_disable)
	trap 'module_steam_binfmt_enable "${disabled[@]}"; exit 130' INT TERM HUP

	echo "Running Steam bootstrap (steam -deckard -exitsteam). This can take several minutes."
	if ! timeout 600 runuser -u "$user" -- env "${env_args[@]}" "$client" -deckard -exitsteam; then
		echo "Warning: Steam bootstrap did not finish cleanly. Launch Steam from the desktop menu." >&2
	fi

	module_steam_binfmt_enable "${disabled[@]}"
	trap - INT TERM HUP
	eval "$prev_int"
	eval "$prev_term"
	eval "$prev_hup"
}

module_steam_write_desktop() {
	local user="$1"
	local client="$2"
	local desktop="$3"
	local apps home provider exec_line

	apps=$(dirname "$desktop")
	home=$(module_steam_user_home "$user")
	if provider=$(module_steam_fex_provider "$home"); then
		exec_line="env STEAM_COMPAT_GRAPHICS_PROVIDER=\"${provider}\" \"${client}\""
	else
		exec_line="\"${client}\""
	fi
	runuser -u "$user" -- mkdir -p "$apps"
	runuser -u "$user" -- tee "$desktop" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam
Comment=Native ARM64 Steam client
Exec=${exec_line} %U
Icon=steam
Terminal=false
Categories=Game;
MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
EOF
	if command -v update-desktop-database >/dev/null 2>&1; then
		runuser -u "$user" -- update-desktop-database "$apps" || true
	fi
}

module_steam_remove_client() {
	local user="$1"
	local home old link
	local -a links=()

	[[ -n "$user" ]] || return 0
	home=$(module_steam_user_home "$user")
	[[ -n "$home" && "$home" != "/" ]] || return 0
	module_steam_paths "$home"

	rm -rf "${STEAM_ROOT}/steamrtarm64" "${STEAM_ROOT}/linuxarm64"
	rm -f "${STEAM_ROOT}/package/beta" "${STEAM_ROOT}/.steam-enable-steamrt64-client"
	rmdir "${STEAM_ROOT}/package" 2>/dev/null || true

	if [[ -d "$STEAM_COMPAT" ]]; then
		while IFS= read -r -d '' old; do
			rm -rf "$old"
		done < <(find "$STEAM_COMPAT" -mindepth 1 -maxdepth 1 -type d \( -name 'proton-cachyos-*-arm64' -o -name 'GE-Proton*-aarch64' \) -print0 2>/dev/null)
	fi

	links=(
		"${STEAM_DOT}/steam"
		"${STEAM_DOT}/root"
		"${STEAM_DOT}/sdkarm64"
		"${STEAM_ROOT}/steamrt64"
	)
	for link in "${links[@]}"; do
		[[ -L "$link" ]] && rm -f "$link"
	done
	rm -f "$STEAM_DESKTOP"
}

#
# Install Valve's public-beta ARM64 Steam client plus Proton-CachyOS and Proton-GE.
#
function module_steam() {
	local title="Steam"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_steam,example"]}"

	local manifest_url="${module_options["module_steam,steam_manifest_url"]}"
	local steam_cdn="${module_options["module_steam,steam_cdn"]}"

	case "$1" in
		"${commands[0]}")
			local steam_user home work manifest entry target_file target_sha zip_path

			if ! module_steam_require_arm64; then
				if [[ -t 1 ]]; then
					dialog_msgbox "${title} not supported" \
						"The native Steam client install is arm64 only.\n\nDetected architecture: $(dpkg --print-architecture)." 8 60
				fi
				return 1
			fi

			steam_user=$(module_desktop_getuser) || return 1
			home=$(module_steam_user_home "$steam_user")
			if [[ -z "$home" || "$home" == "/" ]]; then
				echo "Could not resolve a home directory for ${steam_user}." >&2
				return 1
			fi
			module_steam_paths "$home"

			pkg_update || return 1
			pkg_install ca-certificates curl jq unzip xz-utils libibus-1.0-5 libva2 || return 1
			module_steam_libvpx_shim || return 1

			work=$(mktemp -d)
			chown "$steam_user" "$work"
			trap 'rm -rf "$work"; trap - RETURN' RETURN

			echo "Fetching Steam client manifest."
			manifest=$(curl -fsSL --retry 5 --retry-delay 2 "$manifest_url") || {
				echo "Failed to fetch the Steam client manifest." >&2
				return 1
			}
			entry=$(module_steam_manifest_entry "$manifest" bins_linuxarm64_linuxarm64) || {
				echo "Failed to parse the Steam client archive from the manifest." >&2
				return 1
			}
			{ read -r target_file; read -r target_sha; } <<< "$entry"
			echo "Steam client archive: ${target_file}"

			runuser -u "$steam_user" -- mkdir -p "$STEAM_ROOT"
			zip_path="${work}/linuxarm64.zip"
			module_steam_fetch "$steam_user" "${steam_cdn}/${target_file}" "$zip_path" || return 1
			module_steam_verify "$zip_path" sha256 "$target_sha" || return 1
			runuser -u "$steam_user" -- unzip -o "$zip_path" -d "$STEAM_ROOT" || return 1
			if [[ ! -f "$STEAM_CLIENT" ]]; then
				echo "Steam client binary missing after extract." >&2
				return 1
			fi
			runuser -u "$steam_user" -- chmod +x "$STEAM_CLIENT"
			runuser -u "$steam_user" -- mkdir -p "${STEAM_ROOT}/package" "$STEAM_DOT" "$STEAM_COMPAT"
			printf 'publicbeta\n' | runuser -u "$steam_user" -- tee "${STEAM_ROOT}/package/beta" >/dev/null
			runuser -u "$steam_user" -- ln -sfn "$STEAM_ROOT" "${STEAM_DOT}/steam"
			runuser -u "$steam_user" -- ln -sfn "$STEAM_ROOT" "${STEAM_DOT}/root"
			runuser -u "$steam_user" -- ln -sfn "${STEAM_ROOT}/linuxarm64" "${STEAM_DOT}/sdkarm64"
			# steamrt64 is the x86_64 client directory. Pointing it at steamrtarm64
			# makes the updater verify the ARM64 files against the wrong tree, show
			# the update window, and exit.
			mkdir -p "$(dirname "$module_steam_user_marker")"
			printf '%s\n' "$steam_user" > "$module_steam_user_marker"

			module_steam_install_protons "$steam_user" "$work" || return 1
			module_steam_fex_install "$steam_user" "$home" || return 1

			module_steam_write_desktop "$steam_user" "$STEAM_CLIENT" "$STEAM_DESKTOP"
			module_steam_deckard "$steam_user" "$STEAM_CLIENT"
			echo "Steam installed for ${steam_user}. Launch it from the desktop menu and sign in."
			echo "The first game launch lets Steam download Steam Linux Runtime 4.0 (arm64)."
			;;
		"${commands[1]}")
			local steam_user home work

			module_steam_require_arm64 || return 1
			if ! ${module_options["module_steam,feature"]} "${commands[4]}"; then
				echo "Steam is not installed. Install it before updating Proton." >&2
				return 1
			fi

			steam_user=$(module_steam_installed_user) || return 1
			home=$(module_steam_user_home "$steam_user")
			module_steam_paths "$home"
			pkg_install ca-certificates curl jq xz-utils || return 1

			work=$(mktemp -d)
			chown "$steam_user" "$work"
			trap 'rm -rf "$work"; trap - RETURN' RETURN
			module_steam_install_protons "$steam_user" "$work" || return 1
			module_steam_fex_install "$steam_user" "$home" || return 1
			module_steam_write_desktop "$steam_user" "$STEAM_CLIENT" "$STEAM_DESKTOP"
			echo "Proton-CachyOS, Proton-GE, and the FEX rootfs are up to date for ${steam_user}."
			echo "Restart Steam, then pick the new compatibility tool per game."
			;;
		"${commands[2]}")
			local steam_user
			steam_user=$(module_steam_installed_user || true)
			module_steam_remove_client "$steam_user"
			echo "Steam client removed. Games and userdata were kept."
			;;
		"${commands[3]}")
			local steam_user home
			steam_user=$(module_steam_installed_user || true)
			if [[ -n "$steam_user" ]]; then
				module_steam_remove_client "$steam_user"
				home=$(module_steam_user_home "$steam_user")
				if [[ -n "$home" && "$home" != "/" ]]; then
					module_steam_paths "$home"
					rm -rf "$STEAM_ROOT" "$STEAM_DOT"
					module_steam_fex_remove "$home"
				fi
			fi
			module_steam_remove_libvpx_shim
			rm -f "$module_steam_user_marker"
			echo "Steam purged."
			;;
		"${commands[4]}")
			local steam_user home
			steam_user=$(module_steam_installed_user) || return 1
			home=$(module_steam_user_home "$steam_user")
			[[ -n "$home" && "$home" != "/" ]] || return 1
			module_steam_paths "$home"
			[[ -x "$STEAM_CLIENT" ]]
			;;
		"${commands[5]}")
			show_module_help "module_steam" "$title" \
				"Architecture: arm64 public beta\nProton-CachyOS and Proton-GE: latest arm64 release\nFEX Arch rootfs: ~/.local/share/fex-emu/RootFS/ArchLinux" \
				"native"
			;;
		has_state)
			module_steam_has_state
			;;
		*)
			${module_options["module_steam,feature"]} "${commands[5]}"
			;;
	esac
}
