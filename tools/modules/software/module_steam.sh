module_options+=(
	["module_steam,author"]="@HeyMeco"
	["module_steam,maintainer"]="@HeyMeco"
	["module_steam,feature"]="module_steam"
	["module_steam,example"]="install update remove purge status help proton-cachyos proton-ge proton-cachyos-remove proton-ge-remove proton-cachyos-status proton-ge-status"
	["module_steam,desc"]="Steam for arm64 and amd64, with optional Proton-CachyOS and Proton-GE"
	["module_steam,status"]="Active"
	["module_steam,doc_link"]="https://github.com/armbian/configng/issues/941"
	["module_steam,group"]="Gaming"
	["module_steam,arch"]="x86-64 arm64"
	["module_steam,steam_manifest_url"]="https://client-update.fastly.steamstatic.com/steam_client_publicbeta_linuxarm64"
	["module_steam,steam_cdn"]="https://client-update.steamstatic.com"
	["module_steam,help_install"]="On arm64, install the public-beta client and an extracted FEX Arch rootfs. On amd64, install Valve's steam-launcher package"
	["module_steam,help_update"]="On arm64, refresh the FEX rootfs and installed Proton tools. On amd64, upgrade the steam-launcher package and installed Proton tools"
	["module_steam,help_remove"]="Remove the Steam client or steam-launcher package; keep games and userdata"
	["module_steam,help_proton-cachyos"]="Install or update the latest Proton-CachyOS build for this machine under compatibilitytools.d"
	["module_steam,help_proton-ge"]="Install or update the latest Proton-GE build for this machine under compatibilitytools.d"
	["module_steam,help_proton-cachyos-remove"]="Remove Proton-CachyOS from compatibilitytools.d; keep games and the Steam client"
	["module_steam,help_proton-ge-remove"]="Remove Proton-GE from compatibilitytools.d; keep games and the Steam client"
	["module_steam,help_proton-cachyos-status"]="Return success when Proton-CachyOS is installed"
	["module_steam,help_proton-ge-status"]="Return success when Proton-GE is installed"
	["module_steam,help_purge"]="Remove Steam, games, and userdata. On arm64 also the FEX rootfs and libvpx shim; on amd64 also Valve's apt repository"
	["module_steam,help_status"]="Return success when Steam is installed for this machine"
)

# Marker written only when this module creates the libvpx.so.6 compatibility link.
module_steam_libvpx_marker="/var/lib/armbian/module_steam-libvpx"

# The user Steam was installed for, so status does not depend on who runs sudo.
module_steam_user_marker="/var/lib/armbian/module_steam-user"

# Extracted Arch rootfs, the same layout FEXRootFSFetcher -x writes. The FEX
# binary comes from Steam, which always reads the rootfs from the guest path.
module_steam_fex_links="https://rootfs.fex-emu.gg/RootFS_links.json"
module_steam_fex_guest_path="/usr/share/guestos/fex-mesa"

# The linuxarm64 client zip has no launcher icon. The store favicon is 38KB
# and its 256px entry is the same artwork as the 20MB steam.deb hicolor set.
module_steam_icon_url="https://store.steampowered.com/favicon.ico"

# Valve's apt repository. steam.gpg holds the 2012 repository key and the
# 2025 steam-launcher key. Both fingerprints are checked before the file is
# trusted. apt then verifies the steam-launcher .deb against the signed index.
module_steam_deb_key="/usr/share/keyrings/steam.gpg"
module_steam_deb_list="/etc/apt/sources.list.d/steam-stable.list"
module_steam_deb_key_url="https://repo.steampowered.com/steam/archive/stable/steam.gpg"
module_steam_deb_fingerprints="BA1816EF8E75005FCF5E27A1F24AEA9FB05498B7 DB23C56BF0F377FD02970A2A84706F31879D59CB"

module_steam_arch() {
	dpkg --print-architecture
}

module_steam_require_supported() {
	local arch
	arch=$(module_steam_arch)
	case "$arch" in
		arm64|amd64) return 0 ;;
	esac
	echo "Steam requires arm64 or amd64. Detected architecture: ${arch}." >&2
	return 1
}

module_steam_require_arm64() {
	local arch
	arch=$(module_steam_arch)
	[[ "$arch" == "arm64" ]] && return 0
	echo "This Steam action requires arm64. Detected architecture: ${arch}." >&2
	return 1
}

#
# Return success when managed state remains: the Steam directory, the FEX
# rootfs this module extracted, the libvpx shim this module created, or an
# installed steam-launcher package. Used to gate Purge so it stays visible
# after Remove.
#
module_steam_has_state() {
	local user home
	[[ -f "$module_steam_libvpx_marker" ]] && return 0
	if module_steam_deb_present; then
		return 0
	fi
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

#
# Turn curl's --progress-bar stream into dialog gauge updates. The bar stays
# below 100 until curl exits, so the dialog does not say the download finished
# while bytes are still arriving.
#
module_steam_curl_gauge() {
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

module_steam_fetch() {
	local user="$1"
	local url="$2"
	local dest="$3"
	local label rc_file curl_rc errexit=0

	label=$(basename "$url")
	if [[ "${DIALOG:-read}" == "read" ]]; then
		echo "Downloading ${url}"
		runuser -u "$user" -- curl -fL --retry 5 --retry-delay 2 -o "$dest" "$url"
		return
	fi

	rc_file=$(mktemp)
	# Curl's meter must feed the gauge. Left on the terminal, it keeps painting
	# the download after the package step has already shown "install complete".
	[[ $- == *e* ]] && errexit=1
	set +e
	(
		printf 'XXX\n0\nDownloading %s\nXXX\n' "$label"
		set +e
		runuser -u "$user" -- curl -fL --retry 5 --retry-delay 2 --progress-bar -o "$dest" "$url" 2>&1 \
			| module_steam_curl_gauge "$label"
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
# Fill repo, suffix, glob, and label for one optional Proton command.
# suffix matches the release asset for this machine. CachyOS also publishes
# an x86_64_v3 archive; the plain x86_64 asset is the one every amd64 CPU can run.
# glob matches every installed copy of that tool on this architecture.
#
module_steam_proton_spec() {
	local name="$1"
	local -n _repo="$2"
	local -n _suffix="$3"
	local -n _glob="$4"
	local -n _label="$5"
	local arch

	arch=$(module_steam_arch)
	case "$arch" in
		arm64|amd64) ;;
		*)
			echo "Proton builds are published for arm64 and amd64. Detected architecture: ${arch}." >&2
			return 1
			;;
	esac

	case "$name" in
		proton-cachyos)
			_repo="CachyOS/proton-cachyos"
			_label="Proton-CachyOS"
			if [[ "$arch" == "arm64" ]]; then
				_suffix="-arm64.tar.xz"
				_glob="proton-cachyos-*-arm64"
			else
				_suffix="-x86_64.tar.xz"
				_glob="proton-cachyos-*-x86_64"
			fi
			;;
		proton-ge)
			_repo="GloriousEggroll/proton-ge-custom"
			_label="Proton-GE"
			if [[ "$arch" == "arm64" ]]; then
				_suffix="-aarch64.tar.gz"
				_glob="GE-Proton*-aarch64"
			else
				_suffix="-x86_64.tar.gz"
				_glob="GE-Proton*-x86_64"
			fi
			;;
		*)
			echo "Unknown Proton tool: ${name}." >&2
			return 1
			;;
	esac
}

#
# Return success when compatibilitytools.d already has a directory for glob.
#
module_steam_proton_present() {
	local glob="$1"
	local found

	[[ -d "$STEAM_COMPAT" ]] || return 1
	found=$(find "$STEAM_COMPAT" -mindepth 1 -maxdepth 1 -type d -name "$glob" -print -quit 2>/dev/null)
	[[ -n "$found" ]]
}

#
# Install or replace the latest release of one Proton tool for this machine.
#
module_steam_install_named_proton() {
	local user="$1"
	local work="$2"
	local name="$3"
	local repo suffix glob label url

	module_steam_proton_spec "$name" repo suffix glob label || return 1
	url=$(module_steam_latest_asset "$repo" "$suffix") || return 1
	module_steam_install_tool "$user" "$url" "$glob" "$work"
}

#
# Delete every compatibilitytools.d directory that matches glob.
#
module_steam_remove_proton_glob() {
	local glob="$1"
	local old

	[[ -d "$STEAM_COMPAT" ]] || return 0
	while IFS= read -r -d '' old; do
		rm -rf "$old"
	done < <(find "$STEAM_COMPAT" -mindepth 1 -maxdepth 1 -type d -name "$glob" -print0 2>/dev/null)
}

#
# Remove one Proton tool. Games and the Steam client stay.
#
module_steam_remove_named_proton() {
	local name="$1"
	local repo suffix glob label

	module_steam_proton_spec "$name" repo suffix glob label || return 1
	if ! module_steam_proton_present "$glob"; then
		echo "${label} is not installed." >&2
		return 1
	fi
	module_steam_remove_proton_glob "$glob"
	echo "${label} removed. Installed games were kept."
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
	sum=$(xxhsum -H3 < "$file" | awk '{print ($1 ~ /^XXH3_/) ? $1 : $NF}')
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
	local path node magic
	for path in /proc/sys/fs/binfmt_misc/*; do
		node="${path##*/}"
		[[ "$node" == "register" || "$node" == "status" ]] && continue
		[[ "$(head -n 1 "$path" 2>/dev/null)" == "enabled" ]] || continue
		magic=$(awk '$1 == "magic" {print $2}' "$path" 2>/dev/null)
		# ELF magic ending in e_type + e_machine. e_type is ET_EXEC (0200) or
		# ET_DYN (0300); e_machine is x86_64 (3e00) or i386 (0300).
		case "$magic" in
			7f454c46*02003e00|7f454c46*03003e00|7f454c46*02000300|7f454c46*03000300) ;;
			*) continue ;;
		esac
		echo 0 > "$path" && printf '%s\n' "$node"
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

#
# Copy the 256px PNG out of a Windows icon. That entry is stored as PNG;
# width 0 in the directory means 256.
#
module_steam_extract_icon() {
	local ico="$1"
	local dest="$2"
	local count i base width height bytes img_off magic

	count=$(od -An -t u2 -j 4 -N 2 "$ico" | tr -d ' ')
	[[ "$count" =~ ^[0-9]+$ ]] || return 1
	for ((i = 0; i < count; i++)); do
		base=$((6 + i * 16))
		width=$(od -An -t u1 -j "$base" -N 1 "$ico" | tr -d ' ')
		height=$(od -An -t u1 -j $((base + 1)) -N 1 "$ico" | tr -d ' ')
		bytes=$(od -An -t u4 -j $((base + 8)) -N 4 "$ico" | tr -d ' ')
		img_off=$(od -An -t u4 -j $((base + 12)) -N 4 "$ico" | tr -d ' ')
		[[ "$width" == "0" ]] && width=256
		[[ "$height" == "0" ]] && height=256
		[[ "$width" == "256" && "$height" == "256" ]] || continue
		dd if="$ico" of="$dest" bs=1 skip="$img_off" count="$bytes" status=none
		magic=$(od -An -t x1 -N 8 "$dest" | tr -d ' ')
		[[ "$magic" == "89504e470d0a1a0a" ]] || return 1
		return 0
	done
	return 1
}

#
# Install the Steam launcher icon into the user's hicolor theme. Set the
# nameref to the 256px path. Icon=steam stays generic without this file.
#
module_steam_install_icons() {
	local user="$1"
	local -n icon_path_ref="$2"
	local home icons work dest group icon

	home=$(module_steam_user_home "$user")
	[[ -n "$home" && "$home" != "/" ]] || return 1
	icons="${home}/.local/share/icons/hicolor"
	icon="${icons}/256x256/apps/steam.png"
	if [[ -f "$icon" ]]; then
		icon_path_ref="$icon"
		return 0
	fi

	group=$(id -gn "$user")
	work=$(mktemp -d)
	chown "$user:$group" "$work"
	if ! module_steam_fetch "$user" "$module_steam_icon_url" "${work}/favicon.ico"; then
		rm -rf "$work"
		echo "Warning: could not download the Steam launcher icon." >&2
		return 1
	fi
	if ! module_steam_extract_icon "${work}/favicon.ico" "${work}/steam.png"; then
		rm -rf "$work"
		echo "Warning: the Steam favicon did not contain a 256px icon." >&2
		return 1
	fi
	dest=$(dirname "$icon")
	runuser -u "$user" -- mkdir -p "$dest"
	install -o "$user" -g "$group" -m 644 "${work}/steam.png" "$icon"
	rm -rf "$work"
	icon_path_ref="$icon"
}

module_steam_remove_icons() {
	local home="$1"
	local icon

	[[ -n "$home" && "$home" != "/" ]] || return 0
	[[ -d "${home}/.local/share/icons/hicolor" ]] || return 0
	while IFS= read -r -d '' icon; do
		rm -f "$icon"
	done < <(find "${home}/.local/share/icons/hicolor" -type f -path '*/apps/steam.png' -print0 2>/dev/null)
}

module_steam_write_desktop() {
	local user="$1"
	local client="$2"
	local desktop="$3"
	local apps home provider exec_line icon_value icon_path

	apps=$(dirname "$desktop")
	home=$(module_steam_user_home "$user")
	if provider=$(module_steam_fex_provider "$home"); then
		exec_line="env STEAM_COMPAT_GRAPHICS_PROVIDER=\"${provider}\" \"${client}\""
	else
		exec_line="\"${client}\""
	fi
	icon_value="steam"
	icon_path=""
	if module_steam_install_icons "$user" icon_path; then
		icon_value="$icon_path"
	fi
	runuser -u "$user" -- mkdir -p "$apps"
	runuser -u "$user" -- tee "$desktop" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam
Comment=Native ARM64 Steam client
Exec=${exec_line} %U
Icon=${icon_value}
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
	local home link
	local -a links=()

	[[ -n "$user" ]] || return 0
	home=$(module_steam_user_home "$user")
	[[ -n "$home" && "$home" != "/" ]] || return 0
	module_steam_paths "$home"

	rm -rf "${STEAM_ROOT}/steamrtarm64" "${STEAM_ROOT}/linuxarm64"
	rm -f "${STEAM_ROOT}/package/beta" "${STEAM_ROOT}/.steam-enable-steamrt64-client"
	rmdir "${STEAM_ROOT}/package" 2>/dev/null || true

	local name repo suffix glob label
	for name in proton-cachyos proton-ge; do
		module_steam_proton_spec "$name" repo suffix glob label || return 1
		module_steam_remove_proton_glob "$glob"
	done

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
	module_steam_remove_icons "$home"
}

#
# Print the primary-key fingerprints in a keyring. Subkey fingerprints are
# skipped so the check matches the keys Valve publishes, not their encryption
# subkeys.
#
module_steam_deb_fingerprints_of() {
	local file="$1"
	gpg --batch --show-keys --with-colons "$file" 2>/dev/null | awk -F: '
		$1 == "pub" { primary = 1; next }
		$1 == "sub" { primary = 0; next }
		$1 == "fpr" && primary { print $10; primary = 0 }
	'
}

#
# Return success when the keyring contains exactly Valve's published keys.
#
module_steam_deb_key_ok() {
	local file="$1"
	local -A want=()
	local fp have
	local count=0

	for fp in $module_steam_deb_fingerprints; do
		want["$fp"]=1
	done
	while IFS= read -r have; do
		have="${have^^}"
		[[ -n "$have" ]] || continue
		[[ -n "${want[$have]+x}" ]] || return 1
		unset "want[$have]"
		count=$((count + 1))
	done < <(module_steam_deb_fingerprints_of "$file")
	[[ "$count" -gt 0 && ${#want[@]} -eq 0 ]]
}

module_steam_deb_install_key() {
	local tmp
	pkg_install ca-certificates curl gnupg || return 1
	install -d -m 0755 /usr/share/keyrings
	tmp=$(mktemp)
	if ! curl -fsSL --retry 5 --retry-delay 2 -o "$tmp" "$module_steam_deb_key_url"; then
		rm -f "$tmp"
		echo "Failed to download the Steam repository key." >&2
		return 1
	fi
	if ! module_steam_deb_key_ok "$tmp"; then
		rm -f "$tmp"
		echo "The Steam repository key did not match Valve's published fingerprints." >&2
		return 1
	fi
	install -m 0644 "$tmp" "$module_steam_deb_key"
	rm -f "$tmp"
}

module_steam_deb_write_list() {
	cat > "$module_steam_deb_list" <<EOF
deb [arch=amd64,i386 signed-by=${module_steam_deb_key}] https://repo.steampowered.com/steam/ stable steam
EOF
}

#
# 32-bit games and steam-libs-i386 need the i386 architecture. Leave it enabled
# after remove; other packages may depend on it.
#
module_steam_deb_enable_i386() {
	dpkg --print-foreign-architectures | grep -qx i386 && return 0
	dpkg --add-architecture i386
}

module_steam_deb_prepare_repo() {
	module_steam_deb_install_key || return 1
	module_steam_deb_write_list || return 1
	module_steam_deb_enable_i386 || return 1
	pkg_update
}

module_steam_deb_present() {
	local pkg
	for pkg in steam-launcher steam-libs-amd64 steam-libs-i386; do
		pkg_installed "$pkg" && return 0
	done
	return 1
}

module_steam_deb_install_packages() {
	pkg_install steam-launcher steam-libs-amd64 steam-libs-i386
}

module_steam_deb_remove_packages() {
	local pkg
	local -a remove=()
	for pkg in steam-launcher steam-libs-amd64 steam-libs-i386; do
		pkg_installed "$pkg" && remove+=("$pkg")
	done
	[[ ${#remove[@]} -eq 0 ]] && return 0
	pkg_remove "${remove[@]}"
}

module_steam_deb_remember_user() {
	local steam_user
	steam_user=$(module_desktop_getuser 2>/dev/null || true)
	[[ -n "$steam_user" ]] && id "$steam_user" >/dev/null 2>&1 || return 0
	mkdir -p "$(dirname "$module_steam_user_marker")"
	printf '%s\n' "$steam_user" > "$module_steam_user_marker"
}

#
# Install Valve's official amd64 steam-launcher .deb from repo.steampowered.com.
# The signed apt index checks the package. The client downloads the rest of
# itself on first launch.
#
module_steam_deb_install() {
	module_steam_deb_prepare_repo || return 1
	module_steam_deb_install_packages || return 1
	module_steam_deb_remember_user
	echo "Steam launcher installed. Launch Steam from the menu and sign in."
	echo "The client downloads the rest of Steam on first launch."
	echo "Windows games can use Proton-CachyOS or Proton-GE. Install either from the menu."
}

module_steam_deb_update() {
	if ! pkg_installed steam-launcher; then
		echo "Steam is not installed. Install it before updating." >&2
		return 1
	fi
	module_steam_deb_prepare_repo || return 1
	module_steam_deb_install_packages || return 1
	echo "Steam launcher is up to date."
}

#
# Install Steam. arm64 uses Valve's public-beta client. amd64 uses the official
# steam-launcher package. Proton-CachyOS and Proton-GE are separate commands.
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

			if ! module_steam_require_supported; then
				if [[ -t 1 ]]; then
					dialog_msgbox "${title} not supported" \
						"Steam installs on arm64 and amd64.\n\nDetected architecture: $(module_steam_arch)." 8 60
				fi
				return 1
			fi
			if [[ "$(module_steam_arch)" == "amd64" ]]; then
				module_steam_deb_install
				return
			fi

			steam_user=$(module_desktop_getuser) || return 1
			home=$(module_steam_user_home "$steam_user")
			if [[ -z "$home" || "$home" == "/" ]]; then
				echo "Could not resolve a home directory for ${steam_user}." >&2
				return 1
			fi
			module_steam_paths "$home"

			pkg_update || return 1
			pkg_install ca-certificates curl jq libarchive-tools xz-utils libibus-1.0-5 libva2 libopenal1 steam-devices || return 1
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
			runuser -u "$steam_user" -- bsdtar -xf "$zip_path" -C "$STEAM_ROOT" -s ',\\,/,g' || return 1
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

			module_steam_fex_install "$steam_user" "$home" || return 1

			module_steam_write_desktop "$steam_user" "$STEAM_CLIENT" "$STEAM_DESKTOP"
			module_steam_deckard "$steam_user" "$STEAM_CLIENT"
			echo "Steam installed for ${steam_user}. Launch it from the desktop menu and sign in."
			echo "The first game launch lets Steam download Steam Linux Runtime 4.0 (arm64)."
			echo "Windows games need Proton-CachyOS or Proton-GE. Install either from the menu."
			;;
		"${commands[1]}")
			local steam_user home work name repo suffix glob label
			local -a proton_labels=()

			if [[ "$(module_steam_arch)" == "amd64" ]]; then
				module_steam_deb_update || return
				steam_user=$(module_steam_installed_user 2>/dev/null || true)
				if [[ -n "$steam_user" ]]; then
					home=$(module_steam_user_home "$steam_user")
					if [[ -n "$home" && "$home" != "/" ]]; then
						module_steam_paths "$home"
						pkg_install ca-certificates curl jq xz-utils || return 1
						work=$(mktemp -d)
						chown "$steam_user" "$work"
						trap 'rm -rf "$work"; trap - RETURN' RETURN
						for name in "${commands[6]}" "${commands[7]}"; do
							module_steam_proton_spec "$name" repo suffix glob label || return 1
							module_steam_proton_present "$glob" || continue
							proton_labels+=("$label")
							module_steam_install_named_proton "$steam_user" "$work" "$name" || return 1
						done
						if ((${#proton_labels[@]} == 1)); then
							echo "${proton_labels[0]} is up to date for ${steam_user}."
							echo "Restart Steam, then pick the compatibility tool per game."
						elif ((${#proton_labels[@]} > 1)); then
							echo "${proton_labels[0]} and ${proton_labels[1]} are up to date for ${steam_user}."
							echo "Restart Steam, then pick the compatibility tool per game."
						fi
					fi
				fi
				return
			fi
			module_steam_require_arm64 || return 1
			if ! ${module_options["module_steam,feature"]} "${commands[4]}"; then
				echo "Steam is not installed. Install it before updating." >&2
				return 1
			fi

			steam_user=$(module_steam_installed_user) || return 1
			home=$(module_steam_user_home "$steam_user")
			module_steam_paths "$home"
			pkg_install ca-certificates curl jq xz-utils || return 1

			work=$(mktemp -d)
			chown "$steam_user" "$work"
			trap 'rm -rf "$work"; trap - RETURN' RETURN
			for name in "${commands[6]}" "${commands[7]}"; do
				module_steam_proton_spec "$name" repo suffix glob label || return 1
				module_steam_proton_present "$glob" || continue
				proton_labels+=("$label")
				module_steam_install_named_proton "$steam_user" "$work" "$name" || return 1
			done
			module_steam_fex_install "$steam_user" "$home" || return 1
			module_steam_write_desktop "$steam_user" "$STEAM_CLIENT" "$STEAM_DESKTOP"
			if ((${#proton_labels[@]} == 0)); then
				echo "FEX rootfs is up to date for ${steam_user}."
			elif ((${#proton_labels[@]} == 1)); then
				echo "${proton_labels[0]} and the FEX rootfs are up to date for ${steam_user}."
				echo "Restart Steam, then pick the compatibility tool per game."
			else
				echo "${proton_labels[0]}, ${proton_labels[1]}, and the FEX rootfs are up to date for ${steam_user}."
				echo "Restart Steam, then pick the compatibility tool per game."
			fi
			;;
		"${commands[2]}")
			local steam_user home name repo suffix glob label
			if [[ "$(module_steam_arch)" == "amd64" ]]; then
				if ! module_steam_deb_present; then
					echo "Steam is not installed." >&2
					return 1
				fi
				steam_user=$(module_steam_installed_user || true)
				if [[ -n "$steam_user" ]]; then
					home=$(module_steam_user_home "$steam_user")
					if [[ -n "$home" && "$home" != "/" ]]; then
						module_steam_paths "$home"
						for name in proton-cachyos proton-ge; do
							module_steam_proton_spec "$name" repo suffix glob label || return 1
							module_steam_remove_proton_glob "$glob"
						done
					fi
				fi
				module_steam_deb_remove_packages || return 1
				echo "Steam launcher removed. Games and userdata were kept."
				return
			fi
			steam_user=$(module_steam_installed_user || true)
			module_steam_remove_client "$steam_user"
			echo "Steam client removed. Games and userdata were kept."
			;;
		"${commands[3]}")
			local steam_user home
			if [[ "$(module_steam_arch)" == "amd64" ]]; then
				module_steam_deb_remove_packages || return 1
				rm -f "$module_steam_deb_list" "$module_steam_deb_key"
			fi
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
			if [[ "$(module_steam_arch)" == "amd64" ]]; then
				pkg_installed steam-launcher
				return
			fi
			steam_user=$(module_steam_installed_user) || return 1
			home=$(module_steam_user_home "$steam_user")
			[[ -n "$home" && "$home" != "/" ]] || return 1
			module_steam_paths "$home"
			[[ -x "$STEAM_CLIENT" ]]
			;;
		"${commands[5]}")
			show_module_help "module_steam" "$title" \
				"arm64: public-beta client and an extracted FEX Arch rootfs\namd64: steam-launcher from https://repo.steampowered.com/steam/\nProton-CachyOS and Proton-GE: optional, latest build for this machine" \
				"native"
			;;
		"${commands[6]}" | "${commands[7]}")
			local steam_user home work repo suffix glob label

			module_steam_require_supported || return 1
			module_steam_proton_spec "$1" repo suffix glob label || return 1
			if ! ${module_options["module_steam,feature"]} "${commands[4]}"; then
				echo "Steam is not installed. Install it before adding ${label}." >&2
				return 1
			fi

			steam_user=$(module_steam_installed_user) || return 1
			home=$(module_steam_user_home "$steam_user")
			module_steam_paths "$home"
			pkg_install ca-certificates curl jq xz-utils || return 1

			work=$(mktemp -d)
			chown "$steam_user" "$work"
			trap 'rm -rf "$work"; trap - RETURN' RETURN
			module_steam_install_named_proton "$steam_user" "$work" "$1" || return 1
			echo "${label} is installed for ${steam_user}."
			echo "Restart Steam, then pick it as the compatibility tool per game."
			;;
		"${commands[8]}" | "${commands[9]}")
			local steam_user home repo suffix glob label tool

			tool="${1%-remove}"
			module_steam_proton_spec "$tool" repo suffix glob label || return 1
			steam_user=$(module_steam_installed_user) || {
				echo "Could not find the Steam user. ${label} was not removed." >&2
				return 1
			}
			home=$(module_steam_user_home "$steam_user")
			[[ -n "$home" && "$home" != "/" ]] || return 1
			module_steam_paths "$home"
			module_steam_remove_named_proton "$tool"
			;;
		"${commands[10]}" | "${commands[11]}")
			local steam_user home repo suffix glob label tool

			tool="${1%-status}"
			steam_user=$(module_steam_installed_user 2>/dev/null) || return 1
			home=$(module_steam_user_home "$steam_user" 2>/dev/null) || return 1
			[[ -n "$home" && "$home" != "/" ]] || return 1
			module_steam_paths "$home"
			module_steam_proton_spec "$tool" repo suffix glob label >/dev/null || return 1
			module_steam_proton_present "$glob"
			;;
		has_state)
			module_steam_has_state
			;;
		*)
			${module_options["module_steam,feature"]} "${commands[5]}"
			;;
	esac
}
