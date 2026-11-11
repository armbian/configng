module_options+=(
	["module_nextcloud,author"]="@igorpecovnik"
	["module_nextcloud,maintainer"]="@igorpecovnik"
	["module_nextcloud,feature"]="module_nextcloud"
	["module_nextcloud,example"]="install remove purge status help"
	["module_nextcloud,desc"]="Install nextcloud container"
	["module_nextcloud,status"]="Active"
	["module_nextcloud,doc_link"]="https://nextcloud.com/support/"
	["module_nextcloud,group"]="Downloaders"
	["module_nextcloud,port"]="1443"
	["module_nextcloud,arch"]="x86-64 arm64"
	["module_nextcloud,dockerimage"]="lscr.io/linuxserver/nextcloud:latest"
	["module_nextcloud,dockername"]="nextcloud"
)
#
# Module nextcloud
#
function module_nextcloud () {
	local title="Nextcloud"
	local dockerimage="${module_options["module_nextcloud,dockerimage"]}"
	local dockername="${module_options["module_nextcloud,dockername"]}"
	local port="${module_options["module_nextcloud,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nextcloud,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/data"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:443" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data:/data" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_nextcloud,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_nextcloud" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_nextcloud,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="2080 2443 5007 9123"
	["module_openhab,arch"]="x86-64 arm64 armhf"
	["module_openhab,dockerimage"]="openhab/openhab:latest"
	["module_openhab,dockername"]="openhab"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {
	local title="openHAB"
	local dockerimage="${module_options["module_openhab,dockerimage"]}"
	local dockername="${module_options["module_openhab,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	# Parse ports
	local ports_array=(${module_options[module_openhab,port]})
	local port_http="${ports_array[0]}"
	local port_https="${ports_array[1]}"
	local port_l="${ports_array[2]}"
	local port_rest="${ports_array[3]}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/conf" "${base_dir}/userdata" "${base_dir}/addons"

			# Run container with multiple ports
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port_http}:8080" \
				-p "${port_https}:8443" \
				-p "${port_l}:5007" \
				-p "${port_rest}:9123" \
				-v /etc/localtime:/etc/localtime:ro \
				-v /etc/timezone:/etc/timezone:ro \
				-v "${base_dir}/conf:/openhab/conf" \
				-v "${base_dir}/userdata:/openhab/userdata" \
				-v "${base_dir}/addons:/openhab/addons" \
				-e USER_ID="${DOCKER_USERUID}" \
				-e GROUP_ID="${DOCKER_GROUPUID}" \
				-e CRYPTO_POLICY=unlimited \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_openhab,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_openhab" "$title" \
				"Docker Image: $dockerimage\nPorts: $port_http (HTTP), $port_https (HTTPS), $port_l, $port_rest"
		;;
		*)
			${module_options["module_openhab,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_octoprint,author"]="@armbian"
	["module_octoprint,maintainer"]="@igorpecovnik"
	["module_octoprint,feature"]="module_octoprint"
	["module_octoprint,example"]="install remove purge status help"
	["module_octoprint,desc"]="Install octoprint container"
	["module_octoprint,status"]="Active"
	["module_octoprint,doc_link"]="https://transmissionbt.com/"
	["module_octoprint,group"]="Printing"
	["module_octoprint,port"]="7981"
	["module_octoprint,arch"]="x86-64 arm64"
	["module_octoprint,dockerimage"]="octoprint/octoprint:latest"
	["module_octoprint,dockername"]="octoprint"
)
#
# Module octoprint
#
function module_octoprint () {
	local title="OctoPrint"
	local dockerimage="${module_options["module_octoprint,dockerimage"]}"
	local dockername="${module_options["module_octoprint,dockername"]}"
	local port="${module_options["module_octoprint,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_octoprint,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Check if camera device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/video0 ]]; then
				device_params="--device /dev/video0:/dev/video0"
			else
				echo "Warning: /dev/video0 not found. Camera support will not be available."
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-v "${base_dir}:/octoprint/octoprint" \
				$device_params \
				-e TZ="$(cat /etc/timezone)" \
				-e ENABLE_MJPG_STREAMER=true \
				-p "${port}:80" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_octoprint,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_octoprint" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nNote: Camera support requires /dev/video0 device."
		;;
		*)
			${module_options["module_octoprint,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_dozzle,author"]="@armbian"
	["module_dozzle,maintainer"]="@armbian"
	["module_dozzle,feature"]="module_dozzle"
	["module_dozzle,example"]="install remove purge status help"
	["module_dozzle,desc"]="Install Dozzle container (real-time Docker log viewer)"
	["module_dozzle,status"]="Active"
	["module_dozzle,doc_link"]="https://dozzle.dev/"
	["module_dozzle,group"]="Productivity"
	["module_dozzle,port"]="8888"
	["module_dozzle,arch"]="x86-64 arm64"
	["module_dozzle,dockerimage"]="amir20/dozzle:latest"
	["module_dozzle,dockername"]="dozzle"
)

#
# Module Dozzle
#
function module_dozzle () {
	local title="Dozzle"
	local dockerimage="${module_options["module_dozzle,dockerimage"]}"
	local dockername="${module_options["module_dozzle,dockername"]}"
	local port="${module_options["module_dozzle,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_dozzle,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				return 0
			fi

			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Run Dozzle container with Docker socket mount
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net lsio \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-p "${port}:8080" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for container to be ready
			wait_for_container_ready "$dockername" 30 3 "running"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_dozzle,feature"]} ${commands[1]}; then
				return 1
			fi
			# No data directory to clean up for Dozzle
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_dozzle" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nDozzle is a lightweight, real-time Docker log viewer."
		;;
		*)
			${module_options["module_dozzle,feature"]} ${commands[4]}
		;;
	esac
}

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

module_options+=(
	["module_netdata,author"]="@armbian"
	["module_netdata,maintainer"]="@igorpecovnik"
	["module_netdata,feature"]="module_netdata"
	["module_netdata,example"]="install remove purge status help"
	["module_netdata,desc"]="Install netdata container"
	["module_netdata,status"]="Active"
	["module_netdata,doc_link"]="https://learn.netdata.cloud/"
	["module_netdata,group"]="Monitoring"
	["module_netdata,port"]="19999"
	["module_netdata,arch"]="x86-64 arm64 armhf"
	["module_netdata,dockerimage"]="netdata/netdata:latest"
	["module_netdata,dockername"]="netdata"
)
#
# Module Netdata
#
function module_netdata () {
	local title="Netdata"
	local dockerimage="${module_options["module_netdata,dockerimage"]}"
	local dockername="${module_options["module_netdata,dockername"]}"
	local port="${module_options["module_netdata,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netdata,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/netdata"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--pid=host \
				--network=host \
				-v "${base_dir}/netdataconfig:/etc/netdata" \
				-v "${base_dir}/netdatalib:/var/lib/netdata" \
				-v "${base_dir}/netdatacache:/var/cache/netdata" \
				-v /:/host/root:ro,rslave \
				-v /etc/passwd:/host/etc/passwd:ro \
				-v /etc/group:/host/etc/group:ro \
				-v /etc/localtime:/etc/localtime:ro \
				-v /proc:/host/proc:ro \
				-v /sys:/host/sys:ro \
				-v /etc/os-release:/host/etc/os-release:ro \
				-v /var/log:/host/var/log:ro \
				-v /var/run/docker.sock:/var/run/docker.sock:ro \
				--restart=always \
				--cap-add SYS_PTRACE \
				--cap-add SYS_ADMIN \
				--security-opt apparmor=unconfined \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_netdata,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_netdata" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage\n\nUses host networking for system monitoring"
		;;
		*)
			${module_options["module_netdata,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_embyserver,author"]="@schwar3kat"
	["module_embyserver,maintainer"]="@schwar3kat"
	["module_embyserver,feature"]="module_embyserver"
	["module_embyserver,example"]="install remove purge status help"
	["module_embyserver,desc"]="Install embyserver container"
	["module_embyserver,status"]="Active"
	["module_embyserver,doc_link"]="https://emby.media"
	["module_embyserver,group"]="Media"
	["module_embyserver,port"]="8091"
	["module_embyserver,arch"]="x86-64 arm64"
	["module_embyserver,dockerimage"]="lscr.io/linuxserver/emby:latest"
	["module_embyserver,dockername"]="emby"
)
#
# Module Emby server
#
function module_embyserver () {
	local title="Emby"
	local dockerimage="${module_options["module_embyserver,dockerimage"]}"
	local dockername="${module_options["module_embyserver,dockername"]}"
	local port="${module_options["module_embyserver,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_embyserver,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/emby/library" "${base_dir}/movies" "${base_dir}/tvshows"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8096" \
				-v "${base_dir}/emby/library:/config" \
				-v "${base_dir}/movies:/movies" \
				-v "${base_dir}/tvshows:/tvshows" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_embyserver,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_embyserver" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_embyserver,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_aptcacherng,author"]="@igorpecovnik"
	["module_aptcacherng,maintainer"]="@igorpecovnik"
	["module_aptcacherng,feature"]="module_aptcacherng"
	["module_aptcacherng,example"]="install remove purge status help"
	["module_aptcacherng,desc"]="Install apt-cacher-ng container (caching proxy for Debian/Ubuntu apt repos)"
	["module_aptcacherng,status"]="Active"
	["module_aptcacherng,doc_link"]="https://www.unix-ag.uni-kl.de/~bloch/acng/"
	["module_aptcacherng,group"]="Utilities"
	["module_aptcacherng,port"]="3142"
	["module_aptcacherng,arch"]="x86-64 arm64"
	["module_aptcacherng,dockerimage"]="ghcr.io/armbian/apt-cacher-ng:latest"
	["module_aptcacherng,dockername"]="apt-cacher-ng"
)
#
# Module apt-cacher-ng
#
function module_aptcacherng () {
	local title="apt-cacher-ng"
	local dockerimage="${module_options["module_aptcacherng,dockerimage"]}"
	local dockername="${module_options["module_aptcacherng,dockername"]}"
	local port="${module_options["module_aptcacherng,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_aptcacherng,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/${dockername}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the cache bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			# No authentication: publish for this host and its containers only.
			local -a publish
			docker_publish_local publish "$port" 3142
			local listen="$(docker_publish_describe publish)"

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--init \
				--net=lsio \
				--restart=always \
				"${publish[@]}" \
				--volume "${base_dir}/cache:/var/cache/apt-cacher-ng" \
				"$dockerimage"

			local install_msg="apt-cacher-ng is listening on ${listen}\n\nPoint clients at it by adding the following line to\n/etc/apt/apt.conf.d/00aptproxy on each consumer:\n\n  Acquire::http::Proxy \"http://<address>:${port}\";\n\nStatus page: http://<address>:${port}/acng-report.html\n\nBy default only this host and its Docker containers can reach it; reinstall\nwith BIND_ADDRESS=<address> (e.g. the LAN address, or 0.0.0.0) to serve\nother hosts."

			if [[ -t 1 ]]; then
				dialog_msgbox "apt-cacher-ng installed" "$install_msg" 16 70
			else
				echo -e "\n${install_msg}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_aptcacherng,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove cache directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_aptcacherng" "$title" \
				"Caching proxy for Debian / Ubuntu apt repositories.\n\nProxy port: ${port}\nDocker Image: ${dockerimage}\nCache directory: ${base_dir}/cache\nStatus page: http://localhost:${port}/acng-report.html\nListens on 127.0.0.1 and the Docker bridge gateway (host and local containers) only; set BIND_ADDRESS (e.g. a LAN address, or 0.0.0.0) at install to serve other hosts\n\nClient configuration — on each apt host:\n  echo 'Acquire::http::Proxy \"http://<server>:${port}\";' \\\\\n    | sudo tee /etc/apt/apt.conf.d/00aptproxy"
		;;
		*)
			${module_options["module_aptcacherng,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_navidrome,author"]="@armbian"
	["module_navidrome,maintainer"]="@igorpecovnik"
	["module_navidrome,feature"]="module_navidrome"
	["module_navidrome,example"]="install remove purge status help"
	["module_navidrome,desc"]="Install navidrome container"
	["module_navidrome,status"]="Active"
	["module_navidrome,doc_link"]="https://github.com/pynavidrome/navidrome/wiki"
	["module_navidrome,group"]="Downloaders"
	["module_navidrome,port"]="4533"
	["module_navidrome,arch"]="x86-64 arm64"
	["module_navidrome,dockerimage"]="deluan/navidrome:latest"
	["module_navidrome,dockername"]="navidrome"
)
#
# Install Module navidrome
#
function module_navidrome () {
	local title="Navidrome"
	local dockerimage="${module_options["module_navidrome,dockerimage"]}"
	local dockername="${module_options["module_navidrome,dockername"]}"
	local port="${module_options["module_navidrome,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_navidrome,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory and subdirectories
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/music" "${base_dir}/data"

			# Set ownership (navidrome requires specific UID)
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir/"

			# Run container with explicit user
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				--user "${DOCKER_USERUID}:${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:4533" \
				-v "${base_dir}/music:/music" \
				-v "${base_dir}/data:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_navidrome,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_navidrome" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_navidrome,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_samba,author"]="@Tearran"
	["module_samba,maintainer"]="@Tearran"
	["module_samba,feature"]="module_samba"
	["module_samba,example"]="help install remove start stop enable disable configure default status"
	["module_samba,desc"]="Samba setup and service setting."
	["module_samba,status"]="Active"
	["module_samba,doc_link"]="https://www.samba.org/samba/docs/"
	["module_samba,group"]="Networking"
	["module_samba,port"]="445"
	["module_samba,protocol"]="smb"
	["module_samba,arch"]="x86-64 arm64 armhf"
)

function module_samba() {
	local title="samba"
	local condition
	condition=$(command -v smbd)

	# Set the interface for dialog tools
	set_interface

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_samba,example"]}"

	case "$1" in
		"${commands[0]}"|"")
		## help/menu options for the module
		echo -e "\nUsage: ${module_options["module_samba,feature"]} <command>"
		# Full list of commands to referance is printed
		echo -e "Commands: ${module_options["module_samba,example"]}"
		echo "Available commands:"
		# Unlike the for mentioned `echo -e "Commands: ${module_options["module_samba,example"]}"``
		# comprehenive referance the Avalible commands are commands considered useable in UI/UX
		# intened use below.
		if [[ -z "$condition" ]]; then
			echo -e "\t${commands[1]}\t- ${commands[1]} $title."
		else
			if srv_active smbd; then
			echo -e "\t${commands[2]}\t- ${commands[2]} $title service."
			echo -e "\t${commands[3]}\t- ${commands[3]} $title from starting on boot."
			else
			echo -e "\t${commands[4]}\t- ${commands[4]} $title to start on boot."
			echo -e "\t${commands[5]}\t- ${commands[5]} $title. service."
			fi
			echo -e "\t${commands[6]}\t- ${commands[6]} $title. $title."
			# Note: Comment to hide advanced option from menu
			# while remaining avalible for advance options --api flag
			echo -e "\t${commands[8]}\t- $title ${commands[8]} conf"
			echo -e "\t${commands[9]}\t- $title ${commands[9]}."
		fi
		echo
		;;
		"${commands[1]}")
		# install samba
		pkg_install samba
		# Check if /etc/samba/smb.conf exists
		if [[ ! -f "/etc/samba/smb.conf" ]]; then
			if [[ -f "/usr/share/samba/smb.conf" ]]; then
				cp "/usr/share/samba/smb.conf" "/etc/samba/smb.conf"
			else
				echo "Warning: Missing configuration file. Use the <configure> option."
			fi
		fi

		echo "Samba installed successfully."
		;;
		"${commands[2]}")
		## added subshell to prevent srv_disable exiting befor removing is complete.
		srv_disable smbd
		pkg_remove samba
		echo "$title remove complete."
		;;
		"${commands[3]}")
		srv_start smbd
		echo "Samba service started."
		;;
		"${commands[4]}")
		srv_stop smbd
		echo "Samba service stopped."
		;;
		"${commands[5]}")
		srv_enable smbd
		echo "Samba service enabled."
		;;
		"${commands[6]}")
		srv_disable smbd
		echo "Samba service disabled."
		;;
		"${commands[7]}"|"${commands[8]}")
		echo "Using package default configuration..."

		# Check if the default Samba configuration file and directory exist
		if [[ -f "/usr/share/samba/smb.conf" && -d "/etc/samba" ]]; then
			echo "Found default configuration and target directory."
			cp /usr/share/samba/smb.conf /etc/samba/smb.conf
			echo "Default configuration copied to /etc/samba/smb.conf."
		else
			# Provide more specific error messages
			if [[ ! -f "/usr/share/samba/smb.conf" ]]; then
			echo "Error: Default configuration file /usr/share/samba/smb.conf not found."
			fi
			if [[ ! -d "/etc/samba" ]]; then
			echo "Error: Target directory /etc/samba does not exist."
			fi
			return 1
		fi
		;;
		"${commands[9]}")
		## check samba status
		if srv_active smbd; then
			echo "active."
			return 0
		elif ! srv_enabled smbd; then
			echo "inactive"
			return 1
		else
			echo "Samba service is in an unknown state."
			return 1
		fi
		;;
		*)
		# Full list of commands to referance is printed
		echo "Invalid command. Try: '${module_options["module_samba,example"]}'"
		;;
	esac
}

module_options+=(
	["module_hastebin,author"]="@armbian"
	["module_hastebin,maintainer"]="@efectn"
	["module_hastebin,feature"]="module_hastebin"
	["module_hastebin,example"]="install remove purge status help"
	["module_hastebin,desc"]="Install hastebin container"
	["module_hastebin,status"]="Active"
	["module_hastebin,doc_link"]="https://github.com/rpardini/ansi-hastebin"
	["module_hastebin,group"]="Media"
	["module_hastebin,port"]="7777"
	["module_hastebin,arch"]="x86-64 arm64"
	["module_hastebin,dockerimage"]="ghcr.io/armbian/ansi-hastebin:latest"
	["module_hastebin,dockername"]="hastebin"
)
#
# Module hastebin
#
function module_hastebin () {
	local title="HasteBin"
	local dockerimage="${module_options["module_hastebin,dockerimage"]}"
	local dockername="${module_options["module_hastebin,dockername"]}"
	local port="${module_options["module_hastebin,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hastebin,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories and download about file
			mkdir -p "${base_dir}/pastes"
			wget -qO- https://raw.githubusercontent.com/armbian/hastebin-ansi/refs/heads/main/about.md > "$base_dir/about.md"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e STORAGE_TYPE=file \
				-e STORAGE_FILE_PATH="/app/pastes" \
				-e RATE_LIMITING_ENABLE=true \
				-e RATE_LIMITING_LIMIT=100 \
				-e RATE_LIMITING_WINDOW=300 \
				-p "${port}:7777" \
				-v "${base_dir}:/app:rw" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_hastebin,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_hastebin" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_hastebin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_duplicati,author"]="@armbian"
	["module_duplicati,maintainer"]="@igorpecovnik"
	["module_duplicati,feature"]="module_duplicati"
	["module_duplicati,example"]="install remove purge status help"
	["module_duplicati,desc"]="Install duplicati container"
	["module_duplicati,status"]="Active"
	["module_duplicati,doc_link"]="https://prev-docs.duplicati.com/en/latest/"
	["module_duplicati,group"]="Backup"
	["module_duplicati,port"]="8200"
	["module_duplicati,arch"]="x86-64 arm64"
	["module_duplicati,dockerimage"]="lscr.io/linuxserver/duplicati:latest"
	["module_duplicati,dockername"]="duplicati"
)
#
# Module duplicati
#
function module_duplicati () {
	local title="Duplicati"
	local dockerimage="${module_options["module_duplicati,dockerimage"]}"
	local dockername="${module_options["module_duplicati,dockername"]}"
	local port="${module_options["module_duplicati,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_duplicati,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			shift
			# Accept encryption key and WebUI password from parameters if provided
			local encryption_key="$1"
			local webui_password="$2"

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/config" "${base_dir}/backups"

			# If no encryption key provided, prompt for it
			if [[ -z "${encryption_key}" ]]; then
				encryption_key=$(dialog_inputbox "Duplicati Encryption Key" "\nEnter an encryption key for Duplicati (at least 8 characters):" "" 9 60)
			fi

			# Check encryption key length
			if [[ -z "${encryption_key}" || ${#encryption_key} -lt 8 ]]; then
				echo -e "\nError: Encryption key must be at least 8 characters long!"
				exit 1
			fi

			# If no WebUI password provided, prompt for it
			if [[ -z "${webui_password}" ]]; then
				webui_password=$(dialog_inputbox "Duplicati WebUI Password" "\nEnter a password for Duplicati WebUI (at least 8 characters):" "" 9 60)
			fi

			# Check WebUI password length
			if [[ -z "${webui_password}" || ${#webui_password} -lt 8 ]]; then
				echo -e "\nError: WebUI password must be at least 8 characters long!"
				exit 1
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e SETTINGS_ENCRYPTION_KEY="${encryption_key}" \
				-e DUPLICATI__WEBSERVICE_PASSWORD="${webui_password}" \
				-p "${port}:8200" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/backups:/backups" \
				-v /:/source:ro \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_duplicati,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_duplicati" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nOptional arguments for install:\n  encryption_key webui_password"
		;;
		*)
			${module_options["module_duplicati,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_syncthing,author"]="@igorpecovnik"
	["module_syncthing,maintainer"]="@igorpecovnik"
	["module_syncthing,feature"]="module_syncthing"
	["module_syncthing,example"]="install remove purge status help"
	["module_syncthing,desc"]="Install syncthing container"
	["module_syncthing,status"]="Active"
	["module_syncthing,doc_link"]="https://docs.syncthing.net/"
	["module_syncthing,group"]="Media"
	["module_syncthing,port"]="8884 22000 21027"
	["module_syncthing,arch"]="x86-64 arm64"
	["module_syncthing,dockerimage"]="lscr.io/linuxserver/syncthing:latest"
	["module_syncthing,dockername"]="syncthing"
)
#
# Module syncthing
#
function module_syncthing () {
	local title="Syncthing"
	local dockerimage="${module_options["module_syncthing,dockerimage"]}"
	local dockername="${module_options["module_syncthing,dockername"]}"
	local port="${module_options["module_syncthing,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_syncthing,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories for data
			mkdir -p "${base_dir}/config" "${base_dir}/data1" "${base_dir}/data2"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--hostname="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p 8884:8384 \
				-p 22000:22000/tcp \
				-p 22000:22000/udp \
				-p 21027:21027/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data1:/data1" \
				-v "${base_dir}/data2:/data2" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_syncthing,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_syncthing" "$title" \
				"Docker Image: $dockerimage\nPorts: 8884 (Web UI), 22000 (TCP/UDP), 21027 (UDP)"
		;;
		*)
			${module_options["module_syncthing,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_actualbudget,author"]="@armbian"
	["module_actualbudget,maintainer"]="@igorpecovnik"
	["module_actualbudget,feature"]="module_actualbudget"
	["module_actualbudget,example"]="install remove purge status help"
	["module_actualbudget,desc"]="Install actualbudget container"
	["module_actualbudget,status"]="Active"
	["module_actualbudget,doc_link"]="https://actualbudget.org/docs"
	["module_actualbudget,group"]="Finances"
	["module_actualbudget,port"]="5443"
	["module_actualbudget,arch"]="x86-64 arm64"
	["module_actualbudget,dockerimage"]="actualbudget/actual-server:latest"
	["module_actualbudget,dockername"]="my_actual_budget"
)
#
# Module ActualBudget
#
function module_actualbudget () {
	local title="ActualBudget"
	local dockerimage="${module_options["module_actualbudget,dockerimage"]}"
	local dockername="${module_options["module_actualbudget,dockername"]}"
	local port="${module_options["module_actualbudget,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_actualbudget,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/actualbudget"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				--name "$dockername" \
				-v "${base_dir}/data:/data" \
				-p 5006:5006 \
				-p "${port}:443" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_actualbudget,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_actualbudget" "$title" \
				"Web Interface: http://localhost:${port}\nData Port: 5006\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_actualbudget,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_watchtower,author"]="@armbian"
	["module_watchtower,maintainer"]="@igorpecovnik"
	["module_watchtower,feature"]="module_watchtower"
	["module_watchtower,example"]="remove purge status help"
	["module_watchtower,desc"]="Remove watchtower container (install no longer offered)"
	["module_watchtower,status"]="Active"
	["module_watchtower,doc_link"]="https://containrrr.dev/watchtower/"
	["module_watchtower,group"]="Updates"
	["module_watchtower,port"]=""
	["module_watchtower,arch"]="x86-64 arm64"
	["module_watchtower,dockerimage"]="containrrr/watchtower:latest"
	["module_watchtower,dockername"]="watchtower"
)
#
# Module watchtower
#
function module_watchtower () {
	local title="Watchtower"
	local dockerimage="${module_options["module_watchtower,dockerimage"]}"
	local dockername="${module_options["module_watchtower,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_watchtower,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[1]}") # purge
			# Remove container and image first
			if ! ${module_options["module_watchtower,feature"]} ${commands[0]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[2]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[3]}") # help
			show_module_help "module_watchtower" "$title" \
				"Docker Image: $dockerimage\nPorts: None\n\nNote: upstream is archived; install is no longer offered"
		;;
		*)
			${module_options["module_watchtower,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_git_cdn,author"]="@igorpecovnik"
	["module_git_cdn,maintainer"]="@igorpecovnik"
	["module_git_cdn,feature"]="module_git_cdn"
	["module_git_cdn,example"]="install remove purge status help"
	["module_git_cdn,desc"]="Install git_cdn container (caching git+http proxy for GitHub clones)"
	["module_git_cdn,status"]="Active"
	["module_git_cdn,doc_link"]="https://gitlab.com/grouperenault/git_cdn"
	["module_git_cdn,group"]="Utilities"
	["module_git_cdn,port"]="8000"
	["module_git_cdn,arch"]="x86-64 arm64"
	["module_git_cdn,dockerimage"]="ghcr.io/armbian/git_cdn:latest"
	["module_git_cdn,dockername"]="git_cdn"
	["module_git_cdn,upstream"]="https://github.com/"
	["module_git_cdn,cache_size_gb"]="20"
	["module_git_cdn,workers"]="12"
)
#
# Module git_cdn — git+http(s) caching proxy / CDN (Groupe Renault)
#
function module_git_cdn () {
	local title="git_cdn"
	local dockerimage="${module_options["module_git_cdn,dockerimage"]}"
	local dockername="${module_options["module_git_cdn,dockername"]}"
	local port="${module_options["module_git_cdn,port"]}"
	local upstream="${module_options["module_git_cdn,upstream"]}"
	local cache_size_gb="${module_options["module_git_cdn,cache_size_gb"]}"
	local workers="${module_options["module_git_cdn,workers"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_git_cdn,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/${dockername}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the cache bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			# No authentication: publish for this host and its containers only.
			local -a publish
			docker_publish_local publish "$port" 8000
			local listen="$(docker_publish_describe publish)"

			# git_cdn mirrors a single upstream git server (GITSERVER_UPSTREAM)
			# and caches it under WORKING_DIRECTORY, served over http on :8000.
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--init \
				--net=lsio \
				--restart=always \
				"${publish[@]}" \
				--env GITSERVER_UPSTREAM="$upstream" \
				--env WORKING_DIRECTORY="/git-data" \
				--env GUNICORN_WORKER="$workers" \
				--env PACK_CACHE_SIZE_GB="$cache_size_gb" \
				--env PACK_CACHE_DEPTH="true" \
				--env CDN_BUNDLE_URL="" \
				--volume "${base_dir}/cache:/git-data" \
				"$dockerimage"; then
				echo -e "\nFailed to start ${dockername} (${dockerimage})\n" >&2
				return 1
			fi

			local install_msg="git_cdn is proxying ${upstream} on ${listen}\n\nPoint git at it on each consumer:\n\n  git config --global url.\"http://<address>:${port}/\".insteadOf ${upstream}\n\nThen clone GitHub repos as usual — fetches are served from the local cache:\n\n  git clone ${upstream}<owner>/<repo>.git\n\nBy default only this host and its Docker containers can reach it; reinstall\nwith BIND_ADDRESS=<address> (e.g. the LAN address, or 0.0.0.0) to serve\nother hosts."

			if [[ -t 1 ]]; then
				dialog_msgbox "git_cdn installed" "$install_msg" 16 70
			else
				echo -e "\n${install_msg}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_git_cdn,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove cache directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_git_cdn" "$title" \
				"Caching git+http(s) proxy / CDN that mirrors one upstream git server near your CI workers, reducing WAN usage on repeated clones.\n\nUpstream: ${upstream}\nProxy port: ${port}\nDocker Image: ${dockerimage}\nCache directory: ${base_dir}/cache\nPack cache size: ${cache_size_gb} GB\nWorkers: ${workers}\nListens on 127.0.0.1 and the Docker bridge gateway (host and local containers) only; set BIND_ADDRESS (e.g. a LAN address, or 0.0.0.0) at install to serve other hosts\n\nClient configuration — on each git host:\n  git config --global url.\"http://<server>:${port}/\".insteadOf ${upstream}\n\nThen clone normally:\n  git clone ${upstream}<owner>/<repo>.git"
		;;
		*)
			${module_options["module_git_cdn,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_owncloud,author"]="@armbian"
	["module_owncloud,maintainer"]="@igorpecovnik"
	["module_owncloud,feature"]="module_owncloud"
	["module_owncloud,example"]="install remove purge status help"
	["module_owncloud,desc"]="Install owncloud container"
	["module_owncloud,status"]="Active"
	["module_owncloud,doc_link"]="https://doc.owncloud.com/"
	["module_owncloud,group"]="Database"
	["module_owncloud,port"]="7787"
	["module_owncloud,arch"]="x86-64 arm64"
	["module_owncloud,dockerimage"]="owncloud/server:10.16.1"
	["module_owncloud,dockername"]="owncloud"
)
#
# Module owncloud
#
function module_owncloud () {
	local title="ownCloud"
	local dockerimage="${module_options["module_owncloud,dockerimage"]}"
	local dockername="${module_options["module_owncloud,dockername"]}"
	local port="${module_options["module_owncloud,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_owncloud,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/data"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e "OWNCLOUD_TRUSTED_DOMAINS=${LOCALIPADD}" \
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/data:/mnt/data" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_owncloud,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_owncloud" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_owncloud,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_sonarr,author"]="@armbian"
	["module_sonarr,maintainer"]="@igorpecovnik"
	["module_sonarr,feature"]="module_sonarr"
	["module_sonarr,example"]="install remove purge status help"
	["module_sonarr,desc"]="Install sonarr container"
	["module_sonarr,status"]="Active"
	["module_sonarr,doc_link"]="https://wiki.servarr.com/sonarr"
	["module_sonarr,group"]="Downloaders"
	["module_sonarr,port"]="8989"
	["module_sonarr,arch"]="x86-64 arm64"
	["module_sonarr,dockerimage"]="lscr.io/linuxserver/sonarr:latest"
	["module_sonarr,dockername"]="sonarr"
)
#
# Module Sonarr
#
function module_sonarr () {
	local title="Sonarr"
	local dockerimage="${module_options["module_sonarr,dockerimage"]}"
	local dockername="${module_options["module_sonarr,dockername"]}"
	local port="${module_options["module_sonarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sonarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/sonarr"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8989" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/tvseries:/tv" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_sonarr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_sonarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_sonarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_netalertx,author"]="@jokob-sk"
	["module_netalertx,maintainer"]="@igorpecovnik"
	["module_netalertx,feature"]="module_netalertx"
	["module_netalertx,example"]="install remove purge status help"
	["module_netalertx,desc"]="Install netalertx container"
	["module_netalertx,status"]="Preview"
	["module_netalertx,doc_link"]="https://netalertx.com"
	["module_netalertx,group"]="Monitoring"
	["module_netalertx,port"]="20211"
	["module_netalertx,arch"]="x86-64 arm64 armhf"
	["module_netalertx,dockerimage"]="ghcr.io/jokob-sk/netalertx:latest"
	["module_netalertx,dockername"]="netalertx"
)
#
# Module netalertx
#
function module_netalertx () {
	local title="NetAlertX"
	local dockerimage="${module_options["module_netalertx,dockerimage"]}"
	local dockername="${module_options["module_netalertx,dockername"]}"
	local port="${module_options["module_netalertx,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netalertx,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	NETALERTX_NO_TMPFS=1

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/db"

			# Check if we should use tmpfs for /app/api (requires sufficient RAM)
			local mount_params=""
			if [[ "${NETALERTX_NO_TMPFS}" != "1" ]]; then
				# Get available memory in MB
				local available_mem=$(free -m | awk '/^Mem:/{print $7}')
				# Only use tmpfs if we have at least 512MB available RAM
				if [[ $available_mem -ge 512 ]]; then
					mount_params="--mount type=tmpfs,tmpfs-size=512m,target=/app/api"
				else
					echo "Warning: Insufficient RAM for tmpfs mount. /app/api will use disk storage."
				fi
			fi

			# Run container with special security options
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--network=host \
				--cap-drop=ALL \
				--cap-add=CHOWN \
				--cap-add=SETGID \
				--cap-add=SETUID \
				--cap-add=NET_RAW \
				--cap-add=NET_ADMIN \
				--cap-add=NET_BIND_SERVICE \
				--read-only \
				--tmpfs /tmp \
				--tmpfs /tmp/run:rw,noexec,nosuid,size=128m \
				--tmpfs /tmp/log:rw,noexec,nosuid,size=64m \
				--tmpfs /tmp/nginx:rw,noexec,nosuid,size=32m \
				-e PUID=200 \
				-e PGID=300 \
				-e TZ="$(cat /etc/timezone)" \
				-e PORT="${port}" \
				-v "${base_dir}/config:/data/config:rw" \
				-v "${base_dir}/db:/data/db:rw" \
				$mount_params \
				--restart unless-stopped \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_netalertx,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_netalertx" "$title" \
				"Docker Image: $dockerimage\nPort: $port (uses host network)\n\nNote: Uses custom PUID=200, PGID=300 for security"
		;;
		*)
			${module_options["module_netalertx,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_domoticz,author"]="@armbian"
	["module_domoticz,maintainer"]="@igorpecovnik"
	["module_domoticz,feature"]="module_domoticz"
	["module_domoticz,example"]="install remove purge status help"
	["module_domoticz,desc"]="Install domoticz container"
	["module_domoticz,status"]="Active"
	["module_domoticz,doc_link"]="https://wiki.domoticz.com"
	["module_domoticz,group"]="Monitoring"
	["module_domoticz,port"]="8780"
	["module_domoticz,arch"]=""
	["module_domoticz,dockerimage"]="domoticz/domoticz:stable"
	["module_domoticz,dockername"]="domoticz"
)
#
# Module domoticz
#
function module_domoticz () {
	local title="Domoticz"
	local dockerimage="${module_options["module_domoticz,dockerimage"]}"
	local dockername="${module_options["module_domoticz,dockername"]}"
	local port="${module_options["module_domoticz,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_domoticz,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Check if USB serial device exists, only add --device if it does
			local device_params=""
			if [[ -e /dev/ttyUSB0 ]]; then
				device_params="--device /dev/ttyUSB0:/dev/ttyUSB0"
			else
				echo "Warning: /dev/ttyUSB0 not found. USB serial device support will not be available."
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--pid=host \
				--net=lsio \
				$device_params \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8080" \
				-p 8443:443 \
				-v "${base_dir}:/opt/domoticz/userdata" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_domoticz,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_domoticz" "$title" \
				"Docker Image: $dockerimage\nPorts: $port (HTTP), 8443 (HTTPS)\n\nNote: USB serial support requires /dev/ttyUSB0 device."
		;;
		*)
			${module_options["module_domoticz,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_prowlarr,author"]="@Prowlarr"
	["module_prowlarr,maintainer"]="@armbian"
	["module_prowlarr,feature"]="module_prowlarr"
	["module_prowlarr,example"]="install remove purge status help"
	["module_prowlarr,desc"]="Install prowlarr container"
	["module_prowlarr,status"]="Active"
	["module_prowlarr,doc_link"]="https://prowlarr.com/"
	["module_prowlarr,group"]="Database"
	["module_prowlarr,port"]="9696"
	["module_prowlarr,arch"]="x86-64 arm64"
	["module_prowlarr,dockerimage"]="lscr.io/linuxserver/prowlarr:latest"
	["module_prowlarr,dockername"]="prowlarr"
)
#
# Module prowlarr
#
function module_prowlarr () {
	local title="Prowlarr"
	local dockerimage="${module_options["module_prowlarr,dockerimage"]}"
	local dockername="${module_options["module_prowlarr,dockername"]}"
	local port="${module_options["module_prowlarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prowlarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:9696" \
				-v "${base_dir}/config:/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_prowlarr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_prowlarr" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_prowlarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_armbianrouter,author"]="@armbian"
	["module_armbianrouter,maintainer"]="@efectn"
	["module_armbianrouter,feature"]="module_armbianrouter"
	["module_armbianrouter,example"]="install remove purge status help"
	["module_armbianrouter,desc"]="Install armbian router container"
	["module_armbianrouter,status"]="Active"
	["module_armbianrouter,doc_link"]="https://github.com/armbian/armbian-router"
	["module_armbianrouter,group"]="Armbian"
	["module_armbianrouter,port"]="8080 8081 8082 8083 8084 8100"
	["module_armbianrouter,arch"]="x86-64 arm64"
	["module_armbianrouter,dockerimage"]="ghcr.io/armbian/armbian-router:latest"
	["module_armbianrouter,dockername"]="armbianrouter"
)

function download_all_images() {
	wget -qO- https://github.armbian.com/armbian-images.json > "${1}/all-images.json"
}

#
# Module armbianrouter
#
function module_armbianrouter () {
	local title="Armbian Router"
	local dockerimage="${module_options["module_armbianrouter,dockerimage"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbianrouter,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/armbian_router"

	# Define router containers
	declare -A routers
	routers["8080"]="dlrouter-debs"
	routers["8081"]="dlrouter-images"
	routers["8082"]="dlrouter-archive"
	routers["8083"]="dlrouter-debs-beta"
	routers["8084"]="dlrouter-cache"
	routers["8100"]="dlrouter-content"

	case "$1" in
		"${commands[0]}") # install
			# Pull image once
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Download all config yaml files
			for port in "${!routers[@]}"; do
				wget -qO- https://github.armbian.com/${routers[$port]}.yaml > "${base_dir}/${routers[$port]}.yaml"
				sed -i "s|/scripts/redirect-config|/app|g" "${base_dir}/${routers[$port]}.yaml"
			done

			# Download geoip database
			wget -qO- https://github.armbian.com/GeoLite2-ASN.mmdb > "${base_dir}/GeoLite2-ASN.mmdb"
			wget -qO- https://github.armbian.com/GeoLite2-City.mmdb > "${base_dir}/GeoLite2-City.mmdb"

			# Download all images json
			download_all_images "${base_dir}"

			# Run all router containers
			for port in "${!routers[@]}"; do
				local container_name="armbianrouter-${routers[$port]}"
				docker_operation_progress run "$container_name" \
					-d \
					--name="$container_name" \
					--net=lsio \
					-p "${port}:${port}" \
					-v "${base_dir}:/app" \
					--restart=always \
					"$dockerimage" /bin/dlrouter --config /app/${routers[$port]}.yaml
			done
		;;
		"${commands[1]}") # remove
			# Remove all router containers
			for port in "${!routers[@]}"; do
				local container_name="armbianrouter-${routers[$port]}"
				docker_operation_progress rm "$container_name"
			done
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_armbianrouter,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Check if at least one container exists
			local container_name="armbianrouter-dlrouter-debs"
			docker_is_installed "$container_name" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_armbianrouter" "$title" \
				"Docker Image: $dockerimage\nPorts: 8080, 8081, 8082, 8083, 8084, 8100\n\nNote: This installs 6 router containers"
		;;
		*)
			${module_options["module_armbianrouter,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_prometheus,author"]="@armbian"
	["module_prometheus,maintainer"]="@efectn"
	["module_prometheus,feature"]="module_prometheus"
	["module_prometheus,example"]="install remove purge status help"
	["module_prometheus,desc"]="Install prometheus container"
	["module_prometheus,status"]="Active"
	["module_prometheus,doc_link"]="https://prometheus.io/docs/"
	["module_prometheus,group"]="Monitoring"
	["module_prometheus,port"]="9191"
	["module_prometheus,arch"]="x86-64 arm64"
	["module_prometheus,dockerimage"]="prom/prometheus:latest"
	["module_prometheus,dockername"]="prometheus"
)
#
# Module prometheus
#
function module_prometheus () {
	local title="Prometheus"
	local dockerimage="${module_options["module_prometheus,dockerimage"]}"
	local dockername="${module_options["module_prometheus,dockername"]}"
	local port="${module_options["module_prometheus,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prometheus,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create prometheus config file if it doesn't exist
			if [[ ! -f "$base_dir/prometheus.yml" ]]; then
				printf '%s\n' \
					"global:" \
					"  scrape_interval: 15s" \
					"  evaluation_interval: 15s" \
					"" \
					"scrape_configs:" \
					"  - job_name: 'prometheus'" \
					"    static_configs:" \
					"      - targets: ['localhost:9090']" \
					> "$base_dir/prometheus.yml"
			fi

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port}:9090" \
				-v "${base_dir}:/etc/prometheus" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_prometheus,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_prometheus" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_prometheus,feature"]} ${commands[4]}
		;;
	esac
}


module_options+=(
	["see_monitoring,author"]="@Tearran"
	["see_monitoring,ref_link"]=""
	["see_monitoring,feature"]="see_monitoring"
	["see_monitoring,desc"]="Menu for armbianmonitor features"
	["see_monitoring,example"]="see_monitoring"
	["see_monitoring,status"]="review"
	["see_monitoring,doc_link"]=""
)
#
# @decrition generate a menu for armbianmonitor
#
function see_monitoring() {
	if [ -f /usr/bin/htop ]; then
		choice=$(armbianmonitor -h | grep -Ev '^\s*-c\s|^\s*-M\s' | show_menu)

		armbianmonitor -$choice

	else
		echo "htop is not installed"
	fi
}

module_options+=(
	["module_git-cli,author"]="@armbian"
	["module_git-cli,maintainer"]="@igorpecovnik"
	["module_git-cli,feature"]="module_git-cli"
	["module_git-cli,example"]="install remove status help"
	["module_git-cli,desc"]="Install git command-line tools"
	["module_git-cli,status"]="Stable"
	["module_git-cli,doc_link"]="https://git-scm.com/doc"
	["module_git-cli,group"]="DevTools"
	["module_git-cli,arch"]="x86-64 arm64 armhf riscv64"
)
#
# Module Git CLI
#
# Installs the git command-line tools (distributed version control) from the
# distribution repositories. Native package - no container.
#
function module_git-cli() {
	local title="git"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_git-cli,example"]}"

	case "$1" in

		"${commands[0]}") # install
			pkg_update
			pkg_install git
		;;

		"${commands[1]}") # remove
			pkg_remove git
		;;

		"${commands[2]}") # status
			if pkg_installed git; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # help
			echo -e "\nUsage: ${module_options["module_git-cli,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_git-cli,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;

		*)
			${module_options["module_git-cli,feature"]} ${commands[3]}
		;;

	esac
}

module_options+=(
	["module_bazarr,author"]="@igorpecovnik"
	["module_bazarr,maintainer"]="@igorpecovnik"
	["module_bazarr,feature"]="module_bazarr"
	["module_bazarr,example"]="install remove purge status help"
	["module_bazarr,desc"]="Install bazarr container"
	["module_bazarr,status"]="Active"
	["module_bazarr,doc_link"]="https://wiki.bazarr.media/"
	["module_bazarr,group"]="Downloaders"
	["module_bazarr,port"]="6767"
	["module_bazarr,arch"]="x86-64 arm64"
	["module_bazarr,dockerimage"]="lscr.io/linuxserver/bazarr:latest"
	["module_bazarr,dockername"]="bazarr"
)
#
# Module Bazarr
#
function module_bazarr () {
	local title="Bazarr"
	local dockerimage="${module_options["module_bazarr,dockerimage"]}"
	local dockername="${module_options["module_bazarr,dockername"]}"
	local port="${module_options["module_bazarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_bazarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/bazarr"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:6767" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/movies:/movies" \
				-v "${base_dir}/tv:/tv" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_bazarr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_bazarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_bazarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_code-server,author"]="@igorpecovnik"
	["module_code-server,maintainer"]="@igorpecovnik"
	["module_code-server,feature"]="module_code-server"
	["module_code-server,example"]="install remove purge status help"
	["module_code-server,desc"]="Install VS Code in browser container"
	["module_code-server,status"]="Active"
	["module_code-server,doc_link"]="https://github.com/linuxserver/docker-code-server"
	["module_code-server,group"]="Development"
	["module_code-server,port"]="8443"
	["module_code-server,arch"]="x86-64 arm64"
	["module_code-server,dockerimage"]="lscr.io/linuxserver/code-server:latest"
	["module_code-server,dockername"]="code-server"
)
#
# Module Code-server
#
# Code-server is VS Code running on a remote server, accessible through
# the browser. This module manages the Docker container deployment with
# persistent storage for configuration and workspace data.
#
# Environment variables:
#   PASSWORD          - Optional password for web UI (not recommended)
#   HASHED_PASSWORD   - Optional hashed password for web UI
#   SUDO_PASSWORD     - Optional password for sudo access
#   PROXY_DOMAIN      - Optional proxy domain for reverse proxy
#   DEFAULT_WORKSPACE - Optional default workspace directory
#   PWA_APPNAME       - Optional PWA app name
#
function module_code-server () {
	local title="Code-server"
	local dockerimage="${module_options["module_code-server,dockerimage"]}"
	local dockername="${module_options["module_code-server,dockername"]}"
	local port="${module_options["module_code-server,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_code-server,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local config_dir="${base_dir}/config"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config directory
			mkdir -p "$config_dir" || {
				dialog_msgbox "Directory Creation Failed" \
					"Failed to create required directories.\n\nCheck permissions and try again." 8 50
				return 1
			}

			# Run container with LinuxServer.io recommended settings
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8443" \
				-v "${config_dir}:/config" \
				--restart=unless-stopped \
				"$dockerimage"

		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_code-server,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_code-server" "$title" \
				"Web Interface: http://localhost:${port}\n\nDocker Image: $dockerimage\n\nConfig Directory: ${config_dir}\n\nOptional Environment Variables:\n  PASSWORD - Set web UI password (not recommended)\n  HASHED_PASSWORD - Set hashed password\n  SUDO_PASSWORD - Set sudo password\n  PROXY_DOMAIN - Proxy domain for reverse proxy\n  DEFAULT_WORKSPACE - Default workspace directory\n  PWA_APPNAME - PWA application name"
		;;
		*)
			${module_options["module_code-server,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_mysql,author"]="@igorpecovnik"
	["module_mysql,maintainer"]="@igorpecovnik"
	["module_mysql,feature"]="module_mysql"
	["module_mysql,example"]="install remove purge status help"
	["module_mysql,desc"]="Install mysql container"
	["module_mysql,status"]="Active"
	["module_mysql,doc_link"]="https://hub.docker.com/_/mysql"
	["module_mysql,group"]="Database"
	["module_mysql,port"]="3306"
	["module_mysql,protocol"]="mysql"
	["module_mysql,arch"]="x86-64 arm64"
	["module_mysql,dockerimage"]="mysql:lts"
	["module_mysql,dockername"]="mysql"
)
#
# Module MySQL
#
function module_mysql () {
	local title="MySQL"
	local dockerimage="${module_options["module_mysql,dockerimage"]}"
	local dockername="${module_options["module_mysql,dockername"]}"
	local port="${module_options["module_mysql,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mysql,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/mysql"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Exit if already installed (check is done by pull, but we need to handle params)
			if docker_is_installed "$dockername" "$dockerimage" 2>/dev/null; then
				echo "MySQL container is already installed."
				return 0
			fi

			# Get parameters or use defaults
			local mysql_root_password="${2:-armbian}"
			local mysql_database="${3:-armbian}"
			local mysql_user="${4:-armbian}"
			local mysql_password="${5:-armbian}"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e MYSQL_ROOT_PASSWORD="${mysql_root_password}" \
				-e MYSQL_DATABASE="${mysql_database}" \
				-e MYSQL_USER="${mysql_user}" \
				-e MYSQL_PASSWORD="${mysql_password}" \
				-v "${base_dir}:/var/lib/mysql" \
				-p "${port}:3306" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for MySQL to be ready with dialog_gauge progress
			local max_wait=60
			local wait_count=0
			(
				while [[ $wait_count -lt $max_wait ]]; do
					if docker exec "$dockername" \
						env MYSQL_PWD="$mysql_root_password" \
						mysql -uroot -e "SELECT 1;" &>/dev/null; then
						echo "XXX"; echo "100"; echo "MySQL is ready!"; echo "XXX"
						exit 0
					fi

					echo "XXX"; echo "$((wait_count * 100 / max_wait))"; echo "Waiting for MySQL to accept connections..."; echo "XXX"
					sleep 2
					((wait_count++))
				done
				echo "XXX"; echo "100"; echo "Timed out waiting for MySQL"; echo "XXX"
			) | dialog_gauge "$title" "Initializing MySQL..." 8 60

			# Verify MySQL is ready
			if ! docker exec "$dockername" \
				env MYSQL_PWD="$mysql_root_password" \
				mysql -uroot -e "SELECT 1;" &>/dev/null; then
				dialog_msgbox "$title Installation Failed" \
					"MySQL container failed to start properly.\n\nCheck logs with: docker logs $dockername" \
					10 60
				return 1
			fi

			# Create additional databases
			local mysql_databases=("ghost")
			for db_name in "${mysql_databases[@]}"; do
				docker exec -i "$dockername" \
				env MYSQL_PWD="$mysql_root_password" \
				mysql -uroot <<-EOF
					CREATE DATABASE IF NOT EXISTS \`$db_name\`;
					GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '${mysql_user}'@'%';
					FLUSH PRIVILEGES;
				EOF
			done
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_mysql,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_mysql" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage\n\nOptionally accepts arguments:\n root_password database user user_password"
		;;
		*)
			${module_options["module_mysql,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_registry_cache,author"]="@igorpecovnik"
	["module_registry_cache,maintainer"]="@igorpecovnik"
	["module_registry_cache,feature"]="module_registry_cache"
	["module_registry_cache,example"]="install remove purge status help"
	["module_registry_cache,desc"]="Install OCI registry pull-through cache container (ghcr.io mirror)"
	["module_registry_cache,status"]="Active"
	["module_registry_cache,doc_link"]="https://distribution.github.io/distribution/recipes/mirror/"
	["module_registry_cache,group"]="Utilities"
	["module_registry_cache,port"]="5000"
	["module_registry_cache,arch"]="x86-64 arm64"
	["module_registry_cache,dockerimage"]="registry:3"
	["module_registry_cache,dockername"]="registry-cache"
	["module_registry_cache,upstream"]="https://ghcr.io"
	["module_registry_cache,ttl"]="168h"
)
#
# Module registry-cache — OCI registry in pull-through (proxy) mode
#
function module_registry_cache () {
	local title="registry-cache"
	local dockerimage="${module_options["module_registry_cache,dockerimage"]}"
	local dockername="${module_options["module_registry_cache,dockername"]}"
	local port="${module_options["module_registry_cache,port"]}"
	local upstream="${REGISTRY_CACHE_UPSTREAM:-${module_options["module_registry_cache,upstream"]}}"
	local ttl="${module_options["module_registry_cache,ttl"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_registry_cache,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/${dockername}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the cache bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			# No authentication: publish for this host and its containers only.
			local -a publish
			docker_publish_local publish "$port" 5000
			local listen="$(docker_publish_describe publish)"

			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--restart=always \
				"${publish[@]}" \
				--env REGISTRY_PROXY_REMOTEURL="$upstream" \
				--env REGISTRY_PROXY_TTL="$ttl" \
				--volume "${base_dir}/data:/var/lib/registry" \
				"$dockerimage"; then
				echo -e "\nFailed to start ${dockername} (${dockerimage})\n" >&2
				return 1
			fi

			local install_msg="registry-cache mirrors ${upstream} on ${listen}.\n\nFor Armbian builds, set OCI_PROXY=<address>:${port}.\n\nOnly this host and its Docker containers can connect.\nTo serve other hosts, reinstall with BIND_ADDRESS=<address>."

			if [[ -t 1 ]]; then
				dialog_msgbox "registry-cache installed" "$install_msg" 18 74
			else
				echo -e "\n${install_msg}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_registry_cache,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove cache directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_registry_cache" "$title" \
				"Read-only cache of one OCI registry (ghcr.io by default).\n\nUpstream: ${upstream} (REGISTRY_CACHE_UPSTREAM)\nPort: ${port}\nDocker Image: ${dockerimage}\nCache directory: ${base_dir}/data\nCache expiry: ${ttl}\nAccess: this host and its Docker containers (BIND_ADDRESS to change)\n\nArmbian builds: OCI_PROXY=<address>:${port}"
		;;
		*)
			${module_options["module_registry_cache,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,maintainer"]="@igorpecovnik"
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,example"]="install remove purge status help"
	["module_uptimekuma,desc"]="Install uptimekuma container"
	["module_uptimekuma,status"]="Active"
	["module_uptimekuma,doc_link"]="https://github.com/louislam/uptime-kuma/wiki"
	["module_uptimekuma,group"]="Downloaders"
	["module_uptimekuma,port"]="3001"
	["module_uptimekuma,arch"]="x86-64 arm64"
	["module_uptimekuma,dockerimage"]="louislam/uptime-kuma:2"
	["module_uptimekuma,dockername"]="uptime-kuma"
)
#
# Module uptimekuma
#
function module_uptimekuma () {
	local title="Uptime Kuma"
	local dockerimage="${module_options["module_uptimekuma,dockerimage"]}"
	local dockername="${module_options["module_uptimekuma,dockername"]}"
	local port="${module_options["module_uptimekuma,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_uptimekuma,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/uptimekuma"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=always \
				-p "${port}:3001" \
				-v "${base_dir}:/app/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_uptimekuma,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_uptimekuma" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_uptimekuma,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_mariadb,author"]="@igorpecovnik"
	["module_mariadb,maintainer"]="@igorpecovnik"
	["module_mariadb,feature"]="module_mariadb"
	["module_mariadb,example"]="install remove purge status help"
	["module_mariadb,desc"]="Install mariadb container"
	["module_mariadb,status"]="Active"
	["module_mariadb,doc_link"]="https://mariadb.org/documentation/"
	["module_mariadb,group"]="Database"
	["module_mariadb,port"]="3307"
	["module_mariadb,protocol"]="mariadb"
	["module_mariadb,arch"]="x86-64 arm64"
	["module_mariadb,dockerimage"]="lscr.io/linuxserver/mariadb:latest"
	["module_mariadb,dockername"]="mariadb"
)
#
# Module MariaDB
#
function module_mariadb () {
	local title="MariaDB"
	local dockerimage="${module_options["module_mariadb,dockerimage"]}"
	local dockername="${module_options["module_mariadb,dockername"]}"
	local port="${module_options["module_mariadb,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mariadb,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/mariadb"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--restart=always \
				-p "${port}:3306" \
				-v "${base_dir}:/config" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e MYSQL_ROOT_PASSWORD=armbian \
				-e MYSQL_DATABASE=armbian \
				-e MYSQL_USER=armbian \
				-e MYSQL_PASSWORD=armbian \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_mariadb,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_mariadb" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_mariadb,feature"]} ${commands[4]}
		;;
	esac
}

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

module_options+=(
	["module_wireguard,author"]="@armbian"
	["module_wireguard,maintainer"]="@igorpecovnik"
	["module_wireguard,feature"]="module_wireguard"
	["module_wireguard,example"]="install client server remove purge qrcode status help"
	["module_wireguard,desc"]="Install wireguard container"
	["module_wireguard,status"]="Active"
	["module_wireguard,doc_link"]="https://docs.linuxserver.io/images/docker-wireguard/#server-mode"
	["module_wireguard,group"]="Network"
	["module_wireguard,port"]="51820"
	["module_wireguard,arch"]="x86-64 arm64"
	["module_wireguard,dockerimage"]="lscr.io/linuxserver/wireguard:latest"
	["module_wireguard,dockername"]="wireguard"
)

#
# Module wireguard
#
function module_wireguard () {
	local title="WireGuard"
	local dockerimage="${module_options["module_wireguard,dockerimage"]}"
	local dockername="${module_options["module_wireguard,dockername"]}"
	local port="${module_options["module_wireguard,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wireguard,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}")
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create the base and config directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "$base_dir/config/wg_confs/" || { echo "Couldn't create config directory: $base_dir/config/wg_confs/"; exit 1; }
		;;
		"${commands[1]}")
			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			# Create temp file
			local TMP_FILE=$(mktemp)

			# Optional initial content
			if [[ -f "${base_dir}/config/wg_confs/client.conf" ]]; then
				cp "${base_dir}/config/wg_confs/client.conf" "$TMP_FILE"
			else
				echo "# WireGuard client configuration file" > "$TMP_FILE"
			fi

			# Ask user to edit content
			${EDITOR:-nano} "$TMP_FILE"

			# Use `install` to move the file with correct owner and permissions
			rm -f "${base_dir}/config/wg_confs/wg0.conf"
			install -m 600 -o "${DOCKER_USERUID}" -g "${DOCKER_GROUPUID}" "$TMP_FILE" "${base_dir}/config/wg_confs/client.conf"
			rm -f "$TMP_FILE"

			# Check if the container is running, if so, remove it
			${module_options["module_wireguard,feature"]} ${commands[6]}
			if [[ $? -eq 0 ]]; then
				docker_operation_progress rm "$dockername"
			fi

			# Get local subnets from user input or use default
			if [[ -z $2 ]]; then
			LOCAL_SUBNETS=$(dialog_inputbox "Enter comma delimited subnets for routing" "\n* delete if this is not your local subnet \n" "10.0.10.0/24" 9 70)
			else
				LOCAL_SUBNETS="$2"
			fi

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE \
				--privileged \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-v "${base_dir}/config:/config" \
				--restart unless-stopped \
				--sysctl net.ipv4.ip_forward=1 \
				"$dockerimage"

			wait_for_container_ready "$dockername" 20 3 "running" '[[ -f "${base_dir}/config/wg_confs/client.conf" ]]' || exit 1
			if [[ -n "${LOCAL_SUBNETS}" ]]; then
				# Create host-side route helper script for LAN routing via WireGuard container
				cat > "/usr/local/bin/add-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash

				docker exec "$dockername" iptables -t nat -A POSTROUTING -o client -j MASQUERADE

				# Get the IP address of the WireGuard container dynamically
				CONTAINER_IP=\$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$dockername")

				if [[ -z "\$CONTAINER_IP" ]]; then
					echo "WireGuard container not found or not running"
					exit 1
				fi

				echo "Adding LAN routes via container IP: \$CONTAINER_IP"

				# Add route for specific LAN subnets (customize as needed)
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route add $subnet via \"\$CONTAINER_IP\"" >> /usr/local/bin/add-vpn-lan-routes.sh
				done

				cat > "/usr/local/bin/remove-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash
				docker exec "$dockername" iptables -t nat -C POSTROUTING -o client -j MASQUERADE 2>/dev/null && \
				docker exec "$dockername" iptables -t nat -D POSTROUTING -o client -j MASQUERADE || true
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route show \"$subnet\" | grep -q \"$subnet\" && ip route del \"$subnet\" || true" >> /usr/local/bin/remove-vpn-lan-routes.sh
				done

				chmod +x /usr/local/bin/add-vpn-lan-routes.sh
				chmod +x /usr/local/bin/remove-vpn-lan-routes.sh

				cat > "/etc/systemd/system/add-vpn-lan-routes.service" <<- EOT
				[Unit]
				Description=Add routes for LAN via WireGuard Docker container
				After=network-online.target docker.service
				Wants=network-online.target

				[Service]
				Type=oneshot
				ExecStart=/usr/local/bin/add-vpn-lan-routes.sh
				RemainAfterExit=yes

				[Install]
				WantedBy=multi-user.target
				EOT

				# Remove routes just in case they were added before
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true

				systemctl daemon-reexec
				systemctl daemon-reload
				systemctl enable add-vpn-lan-routes.service
				systemctl restart add-vpn-lan-routes.service
			fi
		;;
		"${commands[2]}")
			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			local dialog_rc
			if [[ -z $2 ]]; then
				NUMBER_OF_PEERS=$(dialog_inputbox "Enter comma delimited peer keywords" "Valid characters: letters and numbers" "laptop" 9 70)
				dialog_rc=$?
			else
				NUMBER_OF_PEERS="$2"
				dialog_rc=0
			fi
			if [[ $dialog_rc -eq 0 ]]; then
				# Validate peer names - reject spaces, newlines, and special characters
				# First, remove all newlines, carriage returns, and extra spaces from the input
				NUMBER_OF_PEERS=$(echo "$NUMBER_OF_PEERS" | tr -d '\n\r' | tr -s ' ')

				# Check for common help text patterns that might have been accidentally captured
				if [[ "$NUMBER_OF_PEERS" =~ --help ]] || [[ "$NUMBER_OF_PEERS" =~ usage ]] || [[ "$NUMBER_OF_PEERS" =~ Usage ]]; then
					dialog_msgbox "Error" "Invalid input: Help text detected\n\nPlease enter only comma-separated peer names without any additional text or commands.\n\nExample: laptop,desktop,phone" 10 60
					exit 1
				fi

				# Split by comma and validate each peer name
				IFS=',' read -ra peers_array <<< "$NUMBER_OF_PEERS"
				for peer in "${peers_array[@]}"; do
					# Trim leading and trailing whitespace more safely
					peer="${peer#"${peer%%[![:space:]]*}"}"
					peer="${peer%"${peer##*[![:space:]]}"}"
					# Skip empty peer names
					[[ -z "$peer" ]] && continue
					# Check for invalid characters (spaces, special chars except hyphen and underscore)
					if [[ ! "$peer" =~ ^[a-zA-Z0-9]+$ ]]; then
						dialog_msgbox "Error" "Invalid peer name: '$peer'\n\nPeer names must contain only:\n  - Letters (a-z, A-Z)\n  - Numbers (0-9)\n\nSpaces, newlines, hyphens, underscores, and special characters are not allowed." 11 60
						exit 1
					fi
				done
				${module_options["module_wireguard,feature"]} ${commands[6]}
				if [[ $? -eq 0 ]]; then
					docker_operation_progress rm "$dockername"
				fi

				# Remove client config if any
				rm -f "${base_dir}/config/wg_confs/client.conf"

				docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e SERVERURL=auto \
				-e SERVERPORT=$port \
				-e PEERS="${NUMBER_OF_PEERS}" \
				-e PEERDNS=auto \
				-e INTERNAL_SUBNET=10.13.13.0 \
				-e ALLOWEDIPS=0.0.0.0/0 \
				-e PERSISTENTKEEPALIVE_PEERS= \
				-e LOG_CONFS=true \
				-p $port:51820/udp \
				-v "${base_dir}/config:/config" \
				--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
				--restart unless-stopped \
				"$dockerimage"

			wait_for_container_ready "$dockername" 20 3 "running" '[[ -f "${base_dir}/config/wg_confs/wg0.conf" ]]' || exit 1

				# Wait for peer configs to be created by the container
				local peer_wait_count=0
				local max_peer_wait=10
				while [[ $peer_wait_count -lt $max_peer_wait ]]; do
					peer_count=$(find "${base_dir}/config/" -name "peer_*.conf" -type f 2>/dev/null | wc -l)
					if [[ $peer_count -gt 0 ]]; then
						break
					fi
					sleep 1
					((peer_wait_count++))
				done

				${module_options["module_wireguard,feature"]} ${commands[5]}
			fi
		;;
		"${commands[3]}")
			if srv_active add-vpn-lan-routes; then
				srv_stop add-vpn-lan-routes.service
				srv_disable add-vpn-lan-routes.service
			fi
			# Run route removal script only if it exists, ignore errors
			if [[ -f "/usr/local/bin/remove-vpn-lan-routes.sh" ]]; then
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true
			fi
			# Remove files
			rm -f /usr/local/bin/add-vpn-lan-routes.sh
			rm -f /usr/local/bin/remove-vpn-lan-routes.sh
			rm -f /etc/systemd/system/add-vpn-lan-routes.service
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[4]}")
			${module_options["module_wireguard,feature"]} ${commands[3]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[5]}")
		if [[ -z $2 ]]; then
			local LIST=()
			# Find all peer config files recursively
			while IFS= read -r -d '' peer_conf; do
				peer="${peer_conf#peer_}"
				peer="${peer%.conf}"
				[[ -n "$peer" ]] && LIST+=("$peer" "$peer")
			done < <(find "${base_dir}/config/" -name "peer_*.conf" -type f -printf "%f\0")
			local LIST_LENGTH=$((${#LIST[@]} / 2))

				# Check if there are any peers to display
				if [[ $LIST_LENGTH -eq 0 ]]; then
					dialog_msgbox "No peers found" "No WireGuard peer configs found.\n\nPlease create a server configuration first:\n  ${module_options["module_wireguard,feature"]} server <peer_names>" 10 60
					return 0
				fi
			local SELECTED_PEER=$(dialog_menu "Select peer" "" $((${LIST_LENGTH} + 8)) 60 ${LIST_LENGTH} -- "${LIST[@]}")
		else
			local SELECTED_PEER="$2"
		fi
			if [[ -n ${SELECTED_PEER} ]]; then
				# Validate peer name to prevent command injection
				if [[ ! "${SELECTED_PEER}" =~ ^[a-zA-Z0-9]+$ ]]; then
					dialog_msgbox "Error" "Invalid peer name: '${SELECTED_PEER}'\n\nPeer names must contain only letters and numbers" 10 60
					return 1
				fi
				clear
				docker exec -it "$dockername" /app/show-peer "${SELECTED_PEER}"
				cat "${base_dir}/config/peer_${SELECTED_PEER}/peer_${SELECTED_PEER}.conf"
				read
			fi
		;;
		"${commands[6]}")
			if [[ "$2" == server && -f "${base_dir}/config/wg_confs/client.conf" ]]; then
				return 1
			fi
			docker_is_installed "wireguard" "lscr.io/linuxserver/wireguard"
		;;
		"${commands[7]}")
			show_module_help "module_wireguard" "$title" \
				"Port: $port (UDP)"
		;;
		*)
			${module_options["module_wireguard,feature"]} ${commands[7]}
		;;
	esac
}

module_options+=(
	["module_zerotier,author"]="@jnovos"
	["module_zerotier,maintainer"]="@jnovos"
	["module_zerotier,feature"]="module_zerotier"
	["module_zerotier,ref_link"]="https://github.com/jnovos/configng/"
	["module_zerotier,desc"]="Install Zerotier"
	["module_zerotier,example"]="help install remove start stop enable disable status check"
	["module_zerotier,doc_link"]="https://docs.zerotier.com/wat"
	["module_zerotier,status"]="Active"
	["module_zerotier,group"]="VPN"
	["module_zerotier,arch"]="x86-64 arm64 armhf"
)

function module_zerotier() {
	local title="zerotier-one"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zerotier,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_zerotier,feature"]} <command>"
			echo -e "Commands: ${module_options["module_zerotier,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else
				if srv_active zerotier-one; then
					echo -e "\tstop\t- Stop the $title service."
					echo -e "\tdisable\t- Disable $title from starting on boot."
				else
					echo -e "\tenable\t- Enable $title to start on boot."
					echo -e "\tstart\t- Start the $title service."
				fi
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."
			fi
			echo
		;;
		"${commands[1]}")
			## install zerotier-one
			pkg_update
			curl -fsSL http://download.zerotier.com/contact%40zerotier.com.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/zerotier.gpg > /dev/null
			echo "deb http://download.zerotier.com/debian/$DISTROID $DISTROID main" | sudo tee /etc/apt/sources.list.d/zerotier.list
			pkg_update
			pkg_install zerotier-one
			echo "Zerotier installed successfully."
		;;
		"${commands[2]}")
			## remove zerotier-one
			srv_disable zerotier-one
			pkg_remove zerotier-one
			rm -rf /var/lib/zerotier-one
			rm -f /etc/apt/trusted.gpg.d/zerotier.gpg
			rm -f /etc/apt/sources.list.d/zerotier.list
			pkg_update
			echo "Zerotier removed successfully."
		;;

		"${commands[3]}")
			srv_start zerotier-one
			echo "Zerotier service started."
		;;

		"${commands[4]}")
			srv_stop zerotier-one
			echo "Zerotier service stopped."
		;;

		"${commands[5]}")
			srv_enable zerotier-one
			echo "Zerotier service enabled."
		;;

		"${commands[6]}")
			srv_disable zerotier-one
			echo "Zerotier service disabled."
		;;

		"${commands[7]}")
			if srv_active zerotier-one ; then
				echo -e "\033[0;32m****** Active *****\033[0m"
			else
				echo -e "\033[0;31m****** Inactive *****\033[0m"
			fi
		;;

		"${commands[8]}")
			## check zerotier-one status
			if srv_active zerotier-one; then
				echo "Zerotier service is active."
				return 0
			elif ! srv_enabled zerotier-one; then
				echo "Zerotier service is disabled."
				return 1
			else
				echo "Zerotier service is in an unknown state."
				return 1
			fi
		;;
		*)
			echo "Invalid command.try: '${module_options["module_zerotier,example"]}'"
		;;
	esac
}

module_options+=(
	["module_transmission,author"]="@armbian"
	["module_transmission,maintainer"]="@igorpecovnik"
	["module_transmission,feature"]="module_transmission"
	["module_transmission,example"]="install remove purge status help"
	["module_transmission,desc"]="Install transmission container"
	["module_transmission,status"]="Active"
	["module_transmission,doc_link"]="https://transmissionbt.com/"
	["module_transmission,group"]="Downloaders"
	["module_transmission,port"]="9091"
	["module_transmission,arch"]="x86-64 arm64"
	["module_transmission,dockerimage"]="lscr.io/linuxserver/transmission:latest"
	["module_transmission,dockername"]="transmission"
)
#
# Module Transmission
#
function module_transmission () {
	local title="Transmission"
	local dockerimage="${module_options["module_transmission,dockerimage"]}"
	local dockername="${module_options["module_transmission,dockername"]}"
	local port="${module_options["module_transmission,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_transmission,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/transmission"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Get username and password
			local transmission_user
			local transmission_pass
			transmission_user=$(dialog_inputbox "Enter username for Transmission" "\nHit enter for default" "armbian" 9 50)
			transmission_pass=$(dialog_inputbox "Enter password for Transmission" "\nHit enter for default" "armbian" 9 50)

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e USER="${transmission_user}" \
				-e PASS="${transmission_pass}" \
				-e WHITELIST="${TRANSMISSION_WHITELIST}" \
				-p 9091:9091 \
				-p 51413:51413 \
				-p 51413:51413/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/watch:/watch" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_transmission,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_transmission" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_transmission,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_jellyseerr,author"]="@armbian"
	["module_jellyseerr,maintainer"]="@igorpecovnik"
	["module_jellyseerr,feature"]="module_jellyseerr"
	["module_jellyseerr,example"]="install remove purge status help"
	["module_jellyseerr,desc"]="Install jellyseerr container"
	["module_jellyseerr,status"]="Active"
	["module_jellyseerr,doc_link"]="https://docs.jellyseerr.dev/"
	["module_jellyseerr,group"]="Downloaders"
	["module_jellyseerr,port"]="5055"
	["module_jellyseerr,arch"]="x86-64 arm64"
	["module_jellyseerr,dockerimage"]="fallenbagel/jellyseerr:latest"
	["module_jellyseerr,dockername"]="jellyseerr"
)
#
# Module jellyseerr
#
function module_jellyseerr () {
	local title="Jellyseerr"
	local dockerimage="${module_options["module_jellyseerr,dockerimage"]}"
	local dockername="${module_options["module_jellyseerr,dockername"]}"
	local port="${module_options["module_jellyseerr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyseerr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e LOG_LEVEL=debug \
				-e TZ="$(cat /etc/timezone)" \
				-e PORT=5055 \
				-p "${port}:5055" \
				-v "${base_dir}/config:/app/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_jellyseerr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_jellyseerr" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_jellyseerr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_medusa,author"]="@armbian"
	["module_medusa,maintainer"]="@igorpecovnik"
	["module_medusa,feature"]="module_medusa"
	["module_medusa,example"]="install remove purge status help"
	["module_medusa,desc"]="Install medusa container"
	["module_medusa,status"]="Active"
	["module_medusa,doc_link"]="https://github.com/pymedusa/Medusa/wiki"
	["module_medusa,group"]="Downloaders"
	["module_medusa,port"]="8081"
	["module_medusa,arch"]="x86-64 arm64"
	["module_medusa,dockerimage"]="lscr.io/linuxserver/medusa:latest"
	["module_medusa,dockername"]="medusa"
)
#
# Install Module medusa
#
function module_medusa () {
	local title="Medusa"
	local dockerimage="${module_options["module_medusa,dockerimage"]}"
	local dockername="${module_options["module_medusa,dockername"]}"
	local port="${module_options["module_medusa,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_medusa,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/config" "${base_dir}/downloads" "${base_dir}/downloads/tv"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8081" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/downloads/tv:/tv" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_medusa,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_medusa" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_medusa,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_haos,author"]="@armbian"
	["module_haos,maintainer"]="@igorpecovnik"
	["module_haos,feature"]="module_haos"
	["module_haos,example"]="install remove purge status help"
	["module_haos,desc"]="Install HA supervised container"
	["module_haos,status"]="Active"
	["module_haos,doc_link"]="https://github.com/home-assistant/supervised-installer"
	["module_haos,group"]="HomeAutomation"
	["module_haos,port"]="8123"
	["module_haos,arch"]="x86-64 arm64 armhf"
)
#
# Install haos supervised
#
function module_haos() {

	local title="haos"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=home-assistant" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'home-assistant' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_haos,example"]}"

	HAOS_BASE="${SOFTWARE_FOLDER}/haos"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$HAOS_BASE" ]] || mkdir -p "$HAOS_BASE" || { echo "Couldn't create storage directory: $HAOS_BASE"; exit 1; }

			# we host packages at our repository and version for both is determined:
			# https://github.com/armbian/os/blob/main/external/haos-agent.conf
			# https://github.com/armbian/os/blob/main/external/haos-supervised-installer.conf

			pkg_install --download-only homeassistant-supervised os-agent

			# determine machine type
			case "${ARCH}" in
				arm | armhf) MACHINE="tinker";;
				x86_64) MACHINE="generic-x86-64";;
				arm64) MACHINE="odroid-n2";;
				*) exit 1;;
			esac

			# this we can't put behind wrapper
			DATA_SHARE="$HAOS_BASE" MACHINE="${MACHINE}" pkg_install homeassistant-supervised os-agent

			# Supervisor reads host internet state from NetworkManager. With the networkd
			# renderer, NetworkManager reports no connectivity and Supervisor blocks restores and updates.
			local yaml renderer_changed="no"
			for yaml in /etc/netplan/*.yaml; do
				[[ -f "$yaml" ]] && grep -qE '^[[:space:]]*renderer:[[:space:]]*networkd[[:space:]]*$' "$yaml" || continue
				sed -i -E 's/^([[:space:]]*renderer:[[:space:]]*)networkd[[:space:]]*$/\1NetworkManager/' "$yaml"
				renderer_changed="yes"
			done
			if [[ "$renderer_changed" == "yes" ]]; then
				echo "Switching network management to NetworkManager. The connection can drop for a moment."
				netplan apply
			fi

			# workarounding supervisor loosing healthy state https://github.com/home-assistant/supervisor/issues/4381
			cat <<- SUPERVISOR_FIX > "/usr/local/bin/supervisor_fix.sh"
			#!/bin/bash
			while true; do
			if ha supervisor info 2>&1 | grep -q "healthy: false"; then
				echo "Unhealthy detected, restarting" | systemd-cat -t $(basename "$0") -p debug
				systemctl restart hassio-supervisor
				sleep 600
			else
				sleep 5
			fi
			done
			SUPERVISOR_FIX

			# add executable bit
			chmod +x "/usr/local/bin/supervisor_fix.sh"

			# generate service file to run this script
			cat <<- SUPERVISOR_FIX_SERVICE > "/etc/systemd/system/supervisor-fix.service"
			[Unit]
			Description=Supervisor Unhealthy Fix

			[Service]
			StandardOutput=null
			StandardError=null
			ExecStart=/usr/local/bin/supervisor_fix.sh

			[Install]
			WantedBy=multi-user.target
			SUPERVISOR_FIX_SERVICE

			if [[ -f /boot/firmware/cmdline.txt ]]; then
				# Raspberry Pi
				sed -i '/./ s/$/ apparmor=1 security=apparmor/' /boot/firmware/cmdline.txt
			elif [[ -f /boot/armbianEnv.txt ]]; then
				echo "extraargs=apparmor=1 security=apparmor" >> "/boot/armbianEnv.txt"
			fi
			sleep 5

			if [[ -t 1 ]]; then
				# We have a terminal, use dialog
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_haos,port"]}/ > /dev/null; then
						break
					fi
				done | dialog_gauge "Home Assistant Supervised" "Preparing Home Assistant Supervised\n\nPlease wait! (can take a few minutes)"
			else
				# No terminal, fallback to echoing progress
				echo "Waiting for Home Assistant Supervised to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_haos,port"]}/ > /dev/null; then
						echo "✅ Home Assistant Supervised is responding."
						break
					fi
				done
			fi

			# enable service
			srv_enable supervisor-fix
			srv_start supervisor-fix

			# reboot related to apparmor install
			if [[ -t 1 ]]; then
if dialog_yesno "Reboot required" "A reboot is required to enable AppArmor. Shall we reboot now?" "Reboot" "Cancel" 7 68; then
					reboot
				fi
			fi

		;;
		"${commands[1]}")
			# disable service
			srv_disable supervisor-fix
			srv_stop supervisor-fix
			pkg_remove homeassistant-supervised os-agent
			echo "Removing Home Assistant containers."
			echo "Please wait, this may take a few minutes..."
			if [[ "${container}" ]]; then
				echo "Removing containers: $container"
				echo "${container}" | xargs docker stop 2>&1
				echo "${container}" | xargs docker container rm 2>&1
			fi
			if [[ "${image}" ]]; then
				echo "${image}" | xargs docker image rm 2>&1
			fi
			rm -f /usr/local/bin/supervisor_fix.sh
			rm -f /etc/systemd/system/supervisor-fix.service
			sed -i "s/ apparmor=1 security=apparmor//" /boot/armbianEnv.txt
			# Raspberry Pi
			sed -i "s/ apparmor=1 security=apparmor//" /boot/firmware/cmdline.txt
			srv_daemon_reload
		;;
		"${commands[2]}")
			${module_options["module_haos,feature"]} ${commands[1]}
			if [[ -n "${HAOS_BASE}" && "${HAOS_BASE}" != "/" ]]; then
				rm -rf "${HAOS_BASE}"
			fi
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_haos,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_haos,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
		${module_options["module_haos,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_proxmox,author"]="@igorpecovnik"
	["module_proxmox,maintainer"]="@igorpecovnik"
	["module_proxmox,feature"]="module_proxmox"
	["module_proxmox,example"]="install remove purge status help"
	["module_proxmox,desc"]="Proxmox VE on top of the Armbian kernel (Debian trixie)"
	["module_proxmox,status"]="Active"
	["module_proxmox,doc_link"]="https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie"
	["module_proxmox,group"]="Management"
	["module_proxmox,port"]="8006"
	["module_proxmox,arch"]="x86-64 arm64"
)

#
# Install Proxmox VE from the official repo, WITHOUT the Proxmox kernel.
#
# The proxmox-ve meta-package hard-depends on proxmox-default-kernel, so we
# install pve-manager instead: it pulls the full PVE userspace (pve-cluster,
# qemu-server, pve-container, ifupdown2, ...) but has no kernel dependency,
# leaving the running Armbian kernel (which already ships KVM) in place.
#
function module_proxmox() {
	local title="Proxmox VE"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_proxmox,example"]}"

	local key_url="https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg"
	local key_file="/usr/share/keyrings/proxmox-archive-keyring.gpg"
	local repo_file="/etc/apt/sources.list.d/pve-install-repo.sources"
	# Shipped enabled by pve-manager itself; 401s without a subscription.
	local enterprise_file="/etc/apt/sources.list.d/pve-enterprise.sources"
	local pin_file="/etc/apt/preferences.d/armbian-proxmox-no-kernel.pref"

	case "$1" in

		"${commands[0]}")
			## install

			# Proxmox VE 9 packages are built for Debian 13 (trixie) only.
			if [[ "${DISTROID}" != "trixie" ]]; then
				dialog_msgbox "${title} not supported" \
					"Proxmox VE 9 requires Debian 13 (trixie).\n\nDetected release: ${DISTROID:-unknown}.\nInstallation aborted." 9 60
				return 1
			fi

			# Official packages exist for amd64 and arm64 only.
			local host_arch
			host_arch=$(dpkg --print-architecture)
			case "${host_arch}" in
				amd64 | arm64) ;;
				*)
					dialog_msgbox "${title} not supported" \
						"Proxmox VE is available for amd64 and arm64 only.\n\nDetected architecture: ${host_arch}.\nInstallation aborted." 9 60
					return 1
					;;
			esac

			# PVE needs the hostname to resolve to a real (non-loopback) IP for its
			# cluster stack + web-UI cert. When it only resolves to loopback, offer
			# to fix the hostname right here: change_system_hostname sets a new name
			# that isn't pinned to a loopback line in /etc/hosts, so nss-myhostname
			# then resolves it to the LAN IP (which is what the user's manual
			# armbian-config hostname change did). Re-check after each attempt.
			local host_ip
			host_ip=$(hostname --ip-address 2>/dev/null | awk '{print $1}')
			while [[ -z "${host_ip}" || "${host_ip}" == 127.* || "${host_ip}" == "::1" ]]; do
				local hn_choice
				hn_choice=$(dialog_menu " Hostname check " \
					"The hostname does not resolve to a non-loopback IP (got: ${host_ip:-none}).\n\nProxmox needs the hostname to map to a LAN IP, otherwise the web UI and clustering may not work." \
					16 70 3 -- \
					"fix"      "Set the hostname now (recommended)" \
					"continue" "Continue anyway (fix it later)" \
					"cancel"   "Abort installation")
				case "${hn_choice}" in
					fix)
						change_system_hostname
						host_ip=$(hostname --ip-address 2>/dev/null | awk '{print $1}')
						;;
					continue)
						# A loopback address is useless for the web-UI URL; fall back to a placeholder.
						host_ip=""
						break
						;;
					*)
						return 1
						;;
				esac
			done

			# Add the Proxmox release key and verify its checksum. Stage to a temp
			# file first and only publish it to key_file once verified, so a failed
			# download or checksum mismatch can't clobber an already-valid keyring
			# that the repo config + pkg_update still rely on.
			pkg_install curl ca-certificates
			install -m 0755 -d /usr/share/keyrings
			local key_tmp
			key_tmp="$(mktemp)"
			if ! curl -fsSL "${key_url}" -o "${key_tmp}"; then
				rm -f "${key_tmp}"
				dialog_msgbox "Key download failed" \
					"The Proxmox release key could not be downloaded.\n\nInstallation aborted." 9 60
				return 1
			fi
			install -m 0644 "${key_tmp}" "${key_file}"
			rm -f "${key_tmp}"

			# no-subscription repository (DEB822 format).
			cat <<- EOF > "${repo_file}"
			Types: deb
			URIs: http://download.proxmox.com/debian/pve
			Suites: trixie
			Components: pve-no-subscription
			Signed-By: ${key_file}
			EOF

			# Keep the Proxmox kernel out. pve-manager depends on
			# pve-yew-mobile-gui, which *recommends* proxmox-ve, which depends
			# on proxmox-default-kernel -- so apt installs a whole second
			# kernel unless told otherwise. That recommendation is the only
			# link, so blocking proxmox-ve is enough; the kernel packages are
			# listed too in case a future release grows another path to them.
			cat <<- EOF > "${pin_file}"
			Package: proxmox-ve proxmox-default-kernel proxmox-kernel-* proxmox-headers-*
			Pin: release *
			Pin-Priority: -1
			EOF

			pkg_update
			pkg_full_upgrade

			# Preseed postfix so its install does not block on a debconf prompt.
			debconf-set-selections <<- EOF
			postfix postfix/main_mailer_type select Local only
			postfix postfix/mailname string $(hostname -f 2>/dev/null || hostname)
			EOF

			# Install the PVE userspace WITHOUT the Proxmox kernel (see header note).
			pkg_install pve-manager postfix open-iscsi chrony

			# pve-manager ships the enterprise repository enabled. Without a
			# subscription it answers 401 and every later apt update fails, so
			# turn it off -- the no-subscription repo written above is the one
			# we want. It is a conffile, hence edited rather than deleted.
			if [[ -f "${enterprise_file}" ]]; then
				if grep -q '^Enabled:' "${enterprise_file}"; then
					sed -i 's/^Enabled:.*/Enabled: false/' "${enterprise_file}"
				else
					echo "Enabled: false" >> "${enterprise_file}"
				fi
			fi

			# Proxmox's default storage stack expects ZFS. Provide it through the
			# Armbian ZFS module (kernel headers + zfs-dkms + tools, built against
			# the running kernel) when it is not already present.
			if ! module_zfs status >/dev/null 2>&1; then
				module_zfs install
			fi

			if pkg_installed pve-manager; then
				# Bracket IPv6 literals so host:port stays valid in the URL.
				local host_disp="${host_ip:-<board-ip>}"
				[[ "${host_disp}" == *:* ]] && host_disp="[${host_disp}]"
				dialog_msgbox "${title} installed" \
					"Proxmox VE is installed on the Armbian kernel.\n\nWeb UI: https://${host_disp}:${module_options["module_proxmox,port"]}\nLog in as 'root' with your system password." 10 66
			fi
		;;

		"${commands[1]}")
			## remove
			# proxmox-ve installs an apt hook that aborts any transaction
			# removing the meta-package until this marker exists. Only matters
			# on systems installed before the pin above; harmless otherwise.
			touch /please-remove-proxmox-ve
			pkg_installed pve-manager && pkg_remove pve-manager
			# Drop the rest of the stack pulled in by pve-manager, if present.
			for p in proxmox-ve qemu-server pve-container pve-qemu-kvm pve-cluster; do
				pkg_installed "$p" && pkg_remove "$p"
			done
			rm -f "${repo_file}" "${pin_file}" /please-remove-proxmox-ve
			pkg_update
		;;

		"${commands[2]}")
			## purge
			${module_options["module_proxmox,feature"]} "${commands[1]}"
			rm -f "${key_file}"
			rm -rf /etc/pve /var/lib/pve-cluster /var/lib/pve-manager /var/lib/rrdcached/db/pve2-*
			pkg_update
		;;

		"${commands[3]}")
			## status
			if pkg_installed pve-manager; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[4]}")
			show_module_help "module_proxmox" "${title}" \
				"Architecture: ${module_options["module_proxmox,arch"]} | OS: Debian trixie | Keeps the Armbian kernel" \
				"native"
		;;

		*)
			${module_options["module_proxmox,feature"]} "${commands[4]}"
		;;
	esac
}

module_options+=(
	["module_grafana,author"]="@armbian"
	["module_grafana,maintainer"]="@igorpecovnik"
	["module_grafana,feature"]="module_grafana"
	["module_grafana,example"]="install remove purge status help"
	["module_grafana,desc"]="Install grafana container"
	["module_grafana,status"]="Active"
	["module_grafana,doc_link"]="https://grafana.com/docs/"
	["module_grafana,group"]="Monitoring"
	["module_grafana,port"]="3022"
	["module_grafana,arch"]="x86-64 arm64"
	["module_grafana,dockerimage"]="grafana/grafana-enterprise:latest"
	["module_grafana,dockername"]="grafana"
)
#
# Module Grafana
#
function module_grafana () {
	local title="Grafana"
	local dockerimage="${module_options["module_grafana,dockerimage"]}"
	local dockername="${module_options["module_grafana,dockername"]}"
	local port="${module_options["module_grafana,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_grafana,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/grafana"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--pid=host \
				--net=lsio \
				--user 0 \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:3000" \
				-v "${base_dir}:/var/lib/grafana" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_grafana,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_grafana" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_grafana,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_deluge,author"]="@igorpecovnik"
	["module_deluge,maintainer"]="@igorpecovnik"
	["module_deluge,feature"]="module_deluge"
	["module_deluge,example"]="install remove purge status help"
	["module_deluge,desc"]="Install deluge container"
	["module_deluge,status"]="Active"
	["module_deluge,doc_link"]="https://deluge-torrent.org/userguide/"
	["module_deluge,group"]="Downloaders"
	["module_deluge,port"]="8112"
	["module_deluge,arch"]="x86-64 arm64"
	["module_deluge,dockerimage"]="lscr.io/linuxserver/deluge:latest"
	["module_deluge,dockername"]="deluge"
)
#
# Module Deluge
#
function module_deluge () {
	local title="Deluge"
	local dockerimage="${module_options["module_deluge,dockerimage"]}"
	local dockername="${module_options["module_deluge,dockername"]}"
	local port="${module_options["module_deluge,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_deluge,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/deluge"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e DELUGE_LOGLEVEL=error \
				-p 8112:8112 \
				-p 6181:6881 \
				-p 6181:6881/udp \
				-p 58846:58846 \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_deluge,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_deluge" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_deluge,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_wallos,author"]="@igorpecovnik"
	["module_wallos,maintainer"]="@igorpecovnik"
	["module_wallos,feature"]="module_wallos"
	["module_wallos,example"]="install remove purge status help"
	["module_wallos,desc"]="Install Wallos finance tracker container"
	["module_wallos,status"]="Active"
	["module_wallos,doc_link"]="https://github.com/Wallos-app/Wallos"
	["module_wallos,group"]="Finance"
	["module_wallos,port"]="8282"
	["module_wallos,arch"]="x86-64 arm64"
	["module_wallos,dockerimage"]="bellamy/wallos:latest"
	["module_wallos,dockername"]="wallos"
)
#
# Module Wallos
#
# Wallos is a self-hosted finance tracker application that helps you track
# subscriptions and recurring expenses. This module manages the Docker
# container deployment with persistent storage for database and logos.
#
function module_wallos () {
	local title="Wallos"
	local dockerimage="${module_options["module_wallos,dockerimage"]}"
	local dockername="${module_options["module_wallos,dockername"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wallos,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local config_dir="${base_dir}/config"
	local db_dir="${config_dir}/db"
	local logos_dir="${config_dir}/logos"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config directories
			mkdir -p "$db_dir" "$logos_dir" || {
				dialog_msgbox "Directory Creation Failed" \
					"Failed to create required directories.\n\nCheck permissions and try again." 8 50
				return 1
			}

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				-v "${db_dir}:/var/www/html/db" \
				-v "${logos_dir}:/var/www/html/images/uploads/logos" \
				-e TZ="${TZ:-Europe/Berlin}" \
				-p 8282:80 \
				--restart=unless-stopped \
				"$dockerimage"

		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_wallos,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_wallos" "$title" \
				"Docker Image: $dockerimage\nPort: 8282\nData directories:\n  Database: ${db_dir}\n  Logos: ${logos_dir}"
		;;
		*)
			${module_options["module_wallos,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_hedgedoc,author"]="@armbian"
	["module_hedgedoc,maintainer"]="@efectn"
	["module_hedgedoc,feature"]="module_hedgedoc"
	["module_hedgedoc,example"]="install remove purge status help"
	["module_hedgedoc,desc"]="Install HedgeDoc container (real-time collaborative markdown editor)"
	["module_hedgedoc,status"]="Active"
	["module_hedgedoc,doc_link"]="https://docs.hedgedoc.org/"
	["module_hedgedoc,group"]="WebHosting"
	["module_hedgedoc,port"]="3100"
	["module_hedgedoc,arch"]="x86-64 arm64"
	["module_hedgedoc,dockerimage"]="quay.io/hedgedoc/hedgedoc:latest"
	["module_hedgedoc,dockername"]="hedgedoc"
)

#
# Module hedgedoc
#
function module_hedgedoc () {
	local title="HedgeDoc"
	local dockerimage="${module_options["module_hedgedoc,dockerimage"]}"
	local dockername="${module_options["module_hedgedoc,dockername"]}"
	local port="${module_options["module_hedgedoc,port"]}"
	local DATABASE_HOST="hedgedoc-db"
	local DATABASE_USER="hedgedoc"
	local DATABASE_NAME="hedgedoc"
	local DATABASE_IMAGE="postgres"
	local DATABASE_TAG="16-alpine"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hedgedoc,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local DOMAIN="${2:-$LOCALIPADD}"
	local USE_SSL="${3:-false}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				return 0
			fi

			# Database configuration
			local DATABASE_PASSWORD
			local session_secret

			# Generate secure passwords and secrets
			DATABASE_PASSWORD=$(openssl rand -hex 16)
			session_secret=$(openssl rand -hex 32)

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/uploads"

			# Remove existing PostgreSQL container if present to ensure fresh installation
			if docker container ls -a --format '{{.Names}}' | grep -q "^${DATABASE_HOST}$"; then
				dialog_msgbox "Existing Database" \
					"Removing existing PostgreSQL container to ensure clean installation." 6 60
				module_postgres purge "$DATABASE_USER" "" "$DATABASE_NAME" \
					"$DATABASE_IMAGE" "$DATABASE_TAG" "$DATABASE_HOST"
			fi

			# Install PostgreSQL
			if ! module_postgres install "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" \
				"$DATABASE_IMAGE" "$DATABASE_TAG" "$DATABASE_HOST"; then
				dialog_msgbox "Database Error" \
					"Could not start the PostgreSQL container '${DATABASE_HOST}'." 6 60
				return 1
			fi

			# Wait for PostgreSQL to be ready with progress
			local max_wait=30
			local wait_count=0
			(
				while [[ $wait_count -lt $max_wait ]]; do
					if docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" -c '\q' &>/dev/null; then
						echo "XXX"; echo "100"; echo "PostgreSQL is ready!"; echo "XXX"
						exit 0
					fi
					echo "XXX"; echo "$((wait_count * 100 / max_wait))"; \
						echo "Waiting for PostgreSQL to be ready..."; echo "XXX"
					sleep 2
					((wait_count++))
				done
				echo "XXX"; echo "0"; echo "PostgreSQL ready timeout"; echo "XXX"
				exit 1
			) | dialog_gauge "$title" "Waiting for PostgreSQL..." 8 60
			# The gauge is the tail of the pipe, so its own status says nothing
			# about the wait; without this the timeout was ignored and the
			# install carried on to announce a database that never came up.
			if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
				dialog_msgbox "Database Error" \
					"PostgreSQL '${DATABASE_HOST}' did not become ready in time." 6 60
				return 1
			fi

			# Create database - drop if exists to ensure clean installation
			if docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" 2>/dev/null | grep -q 1; then
				# Database exists, drop it to ensure clean installation
				docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" <<-EOT
				DROP DATABASE $DATABASE_NAME;
				EOT
			fi

			# Create fresh database
			docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" <<-EOT
			CREATE DATABASE $DATABASE_NAME;
			GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
			EOT

			dialog_msgbox "Database Ready" \
				"Database '$DATABASE_NAME' is ready for use." 6 50


			# Pull HedgeDoc image with progress
			docker_operation_progress pull "$dockerimage"

			# Run HedgeDoc container
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net lsio \
				-e CMD_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:5432/${DATABASE_NAME}" \
				-e CMD_DOMAIN="${DOMAIN}" \
				-e CMD_PROTOCOL_USESSL="${USE_SSL}" \
				-e CMD_SESSION_SECRET="${session_secret}" \
				-e CMD_ALLOW_ANONYMOUS=true \
				-e CMD_URL_ADDPORT=false \
				-e CMD_ALLOW_EMAIL_REGISTER=true \
				-p "${port}:3000" \
				-v "${base_dir}/uploads:/hedgedoc/public/uploads" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for container to be ready
			wait_for_container_ready "$dockername" 30 3 "running"
		;;
		"${commands[1]}") # remove
			# Remove container and image
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_hedgedoc,feature"]} ${commands[1]}; then
				return 1
			fi
			# Purge PostgreSQL database
			module_postgres purge "$DATABASE_USER" "" "$DATABASE_NAME" \
				"$DATABASE_IMAGE" "$DATABASE_TAG" "$DATABASE_HOST"
			# Remove data directory
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_hedgedoc" "$title" \
				"Docker Image: $dockerimage\nPort: $port\nDatabase: PostgreSQL"
		;;
		*)
			${module_options["module_hedgedoc,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_shlink,author"]="@igorpecovnik"
	["module_shlink,maintainer"]="@igorpecovnik"
	["module_shlink,feature"]="module_shlink"
	["module_shlink,example"]="install remove purge status help"
	["module_shlink,desc"]="Install Shlink URL shortener container"
	["module_shlink,status"]="Active"
	["module_shlink,doc_link"]="https://shlink.io/documentation/"
	["module_shlink,group"]="WebHosting"
	["module_shlink,port"]="8085"
	["module_shlink,arch"]="x86-64 arm64"
	["module_shlink,dockerimage"]="shlinkio/shlink:stable"
	["module_shlink,dockername"]="shlink"
)
#
# Module Shlink
#
# Shlink is a self-hosted URL shortener with a REST API. Data is stored in
# SQLite. The short domain and the API key are kept in shlink.env, so a
# reinstall keeps them.
#
function module_shlink () {
	local title="Shlink"
	local dockerimage="${module_options["module_shlink,dockerimage"]}"
	local dockername="${module_options["module_shlink,dockername"]}"
	local port="${module_options["module_shlink,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_shlink,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/shlink"
	local data_dir="${base_dir}/data"
	local env_file="${base_dir}/shlink.env"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# The container runs as uid 1001
			mkdir -p "$data_dir" && chown 1001:1001 "$data_dir" || return 1

			if [[ ! -f "$env_file" ]]; then
				# SHLINK_DOMAIN skips the question in unattended installs
				local domain="${SHLINK_DOMAIN:-}"
				# Ask on a terminal only. Cancel stops the install.
				if [[ -z "$domain" && -t 0 ]]; then
					domain=$(dialog_inputbox "$title short domain" \
						"\nDomain of the short links, e.g. go.example.com.\nKeep the default to use it on the local network." \
						"${LOCALIPADD}:${port}" 11 70) || return 1
				fi
				# Accept host[:port] only. Empty means the local default.
				domain="${domain#*://}"
				domain="${domain%%/*}"
				domain="${domain:-${LOCALIPADD}:${port}}"
				if [[ ! "$domain" =~ ^[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
					echo "Invalid Shlink domain: ${domain}" >&2
					dialog_msgbox "$title" "\nInvalid domain: ${domain}\n\nUse host or host:port, e.g. go.example.com." 9 60
					return 1
				fi
				# A domain without a port is served over HTTPS by a reverse proxy
				local https="true"
				[[ "$domain" == *:* ]] && https="false"
				local api_key
				api_key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
				install -m 600 /dev/null "$env_file"
				cat > "$env_file" <<- EOT
				DEFAULT_DOMAIN=${domain}
				IS_HTTPS_ENABLED=${https}
				INITIAL_API_KEY=${api_key}
				EOT
			fi

			# Behind a reverse proxy (HTTPS), publish on localhost only.
			# SWAG reaches the container over the lsio network.
			local publish="${port}:8080"
			grep -q '^IS_HTTPS_ENABLED=true' "$env_file" && publish="127.0.0.1:${port}:8080"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=unless-stopped \
				--env-file "$env_file" \
				-e TZ="${TZ:-Etc/UTC}" \
				-p "$publish" \
				-v "${data_dir}:/etc/shlink/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername" || return 1
			docker_operation_progress rmi "$dockerimage" || return 1
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_shlink,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_shlink" "$title" \
				"Docker Image: $dockerimage\nPort: $port\nSettings and API key: ${env_file}\nData: ${data_dir}"
		;;
		*)
			${module_options["module_shlink,feature"]} ${commands[4]}
		;;
	esac
}

#
# Module options: images
#
module_options+=(
	["module_images,author"]=""
	["module_images,maintainer"]="@igorpecovnik"
	["module_images,feature"]="module_images"
	["module_images,example"]="install remove purge status help"
	["module_images,desc"]="Download and flash Armbian OS images for selected hardware"
	["module_images,status"]="Active"
	["module_images,doc_link"]=""
	["module_images,group"]="Management"
	["module_images,arch"]="x86-64 arm64 armhf"
)

#
# Module images
#
function module_images () {
	local title="images"
	local condition="ok"  # dummy, kept for consistency with other modules

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_images,example"]}"

	local ALL_IMAGES_JSON_URL="https://github.armbian.com/armbian-images.json"
	local IMAGES_BASE="${SOFTWARE_FOLDER}/images"
	local IMAGES_JSON_PATH="${IMAGES_BASE}/armbian-images.json"

	# $1 = command, $2 = board_slug override (optional)
	local CMD="$1"
	local BOARD_SLUG="${2:-${BOARD:-uefi-x86}}"

	# filters (set during install flow)
	PREAPP_FILTER=""
	DOWNLOAD_REPO_FILTER=""   # e.g. "archive" when STABLE is selected
	KERNEL_FILTER=""
	VARIANT_FILTER=""

	# Ensure base directory exists
	[[ -d "$IMAGES_BASE" ]] || mkdir -p "$IMAGES_BASE" || { echo "Couldn't create storage directory: $IMAGES_BASE"; return 1; }

	# Helper: ensure dependencies
	local -a DEPS=("curl" "jq")
	for dep in "${DEPS[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			pkg_install "$dep"
		fi
	done

	# Helper: ensure BOARD_SLUG is set, otherwise ask
	ensure_board_slug() {
		if [[ -z "$BOARD_SLUG" ]]; then
			if [[ -n "$DIALOG" ]]; then
				BOARD_SLUG=$(dialog_inputbox "Board slug" "Enter board slug (e.g. bananapi):" "" 8 50)
				[[ -z "$BOARD_SLUG" ]] && { echo "Board slug not provided."; return 1; }
			else
				read -rp "Enter board slug (e.g. bananapi): " BOARD_SLUG
				[[ -z "$BOARD_SLUG" ]] && { echo "Board slug not provided."; return 1; }
			fi
		fi
		return 0
	}

	# Helper: fetch/refresh JSON (simple cache, max age 1 day)
	refresh_images_json() {
		local max_age=$((24*60*60))  # 1 day
		local now epoch

		now=$(date +%s)

		if [[ -f "$IMAGES_JSON_PATH" ]]; then
			epoch=$(stat -c %Y "$IMAGES_JSON_PATH" 2>/dev/null || echo 0)
		else
			epoch=0
		fi

		if (( now - epoch > max_age )) || [[ ! -s "$IMAGES_JSON_PATH" ]]; then
			if [[ -n "$DIALOG" ]]; then
				dialog_infobox "" "Refreshing Armbian images index...\n\n$ALL_IMAGES_JSON_URL" 8 70
			else
				echo "Refreshing Armbian images index from $ALL_IMAGES_JSON_URL ..."
			fi

			if ! curl -fsSL "$ALL_IMAGES_JSON_URL" -o "$IMAGES_JSON_PATH"; then
				echo "Failed to download $ALL_IMAGES_JSON_URL"
				return 1
			fi
		fi
		return 0
	}

	# Helper: let user pick a board_slug from the index (unique list)
	# Only consider records with real flashable images (file_extension NOT .asc/.torrent/.sha*)
	choose_board_slug_from_index() {
		local -a options=()
		local temp_list slug

		temp_list=$(jq -r '
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
			| .board_slug
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			echo "No boards found in images index."
			return 1
		fi

		while IFS='|' read -r idx slug; do
			[[ -z "$idx" ]] && continue
			options+=("$idx" "$slug")
		done <<< "$temp_list"

		local selected_idx

		if [[ -n "$DIALOG" ]]; then
			selected_idx=$(dialog_menu "Select board" "\nNo images found for the current board.\n\nSelect a different board to flash:" 24 76 12 -- "${options[@]}")
		else
			echo "Boards available in index:"
			local i=0
			while [[ $i -lt ${#options[@]} ]]; do
				echo "  ${options[$i]}: ${options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter board index: " selected_idx
		fi

		[[ -z "$selected_idx" ]] && return 1

		BOARD_SLUG=$(jq -r --argjson i "$selected_idx" '
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
			| .board_slug
			]
			| unique
			| sort
			| .[$i]
		' "$IMAGES_JSON_PATH")

		[[ -z "$BOARD_SLUG" || "$BOARD_SLUG" == "null" ]] && return 1

		return 0
	}

	# Helper: confirm current BOARD_SLUG or choose another from index
	confirm_board_or_choose_other() {
		# If we don't have a board yet, nothing to confirm
		if [[ -z "$BOARD_SLUG" ]]; then
			return 0
		fi

		if [[ -n "$DIALOG" ]]; then
			local choice
			choice=$(dialog_menu "Confirm board" "\nDetected board: ${BOARD_SLUG}\n\nWhat would you like to do?" 15 76 3 -- "CURRENT" "Use this board" "OTHER" "Choose another board from images index")

			[[ -z "$choice" ]] && return 1

			case "$choice" in
				CURRENT)
					# keep BOARD_SLUG as-is
					return 0
					;;
				OTHER)
					# use JSON index and let user pick any board
					choose_board_slug_from_index || return 1
					return 0
					;;
			esac
		else
			echo "Current board slug: $BOARD_SLUG"
			echo "  1) Use this board"
			echo "  2) Choose another board from images index"
			echo "  3) Cancel"
			local ans
			read -rp "Select [1-3]: " ans
			case "$ans" in
				1|"")
					return 0
					;;
				2)
					choose_board_slug_from_index || return 1
					return 0
					;;
				*)
					return 1
					;;
			esac
		fi
	}

	# Helper: select preinstalled_application filter for board
	# PREAPP_FILTER:
	#   ""           -> all
	#   "__EMPTY__"  -> barebone (preinstalled_application == "")
	#   other        -> that exact preinstalled_application
	select_preapp_for_board() {
		local board="$1"
		local -a options=()
		local temp_list app
		local has_barebone=0
		local apps_list=""

		temp_list=$(jq -r --arg board "$board" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| .file_application // ""
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER=""
			return 0
		fi

		# Split into barebone flag + list of named apps
		while IFS='|' read -r _ app; do
			if [[ -z "$app" ]]; then
				has_barebone=1
			else
				apps_list+="${app}"$'\n'
			fi
		done <<< "$temp_list"

		# Build clean options list
		options=()
		options+=("ALL"    "All images (barebone + preinstalled)")
		options+=("STABLE" "Stable images only")

		if [[ $has_barebone -eq 1 ]]; then
			options+=("BAREBONE" "Barebone images only (no preinstalled apps)")
		fi

		while IFS= read -r app; do
			[[ -z "$app" ]] && continue
			local desc
			case "$app" in
				homeassistant)
					desc="Home Assistant smart home suite"
				;;
				kali)
					desc="Preinstalled security applications from Kali repository"
				;;
				omv|OMV)
					desc="Openmediavault NAS appliance"
				;;
				openhab|OpenHAB|openHAB)
					desc="Empowering the smart home"
				;;
				*)
					desc="$app"
				;;
			esac
			options+=("$app" "$desc")
		done <<< "$apps_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$(dialog_menu "Prebuild images" "\nSelect image type: stable, barebone, or with preinstalled apps." 22 76 12 --default-item STABLE -- "${options[@]}")
		else
			echo "Available application filters for $board:"
			local i=0
			while [[ $i -lt ${#options[@]} ]]; do
				echo "  ${options[$i]}: ${options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter filter (ALL/STABLE/BAREBONE or app name, empty=ALL): " selected
		fi
		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER=""
		elif [[ "$selected" == "STABLE" ]]; then
			# Only stable images: download_repository == "archive"
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER="archive"
		elif [[ "$selected" == "BAREBONE" ]]; then
			PREAPP_FILTER="__EMPTY__"
			DOWNLOAD_REPO_FILTER=""
		else
			PREAPP_FILTER="$selected"
			DOWNLOAD_REPO_FILTER=""
		fi

		return 0
	}

	# Helper: select kernel_branch filter for board
	select_kernel_branch_for_board() {
		local board="$1"
		local -a options=()
		local temp_list kbranch

		temp_list=$(jq -r --arg board "$board" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			def preapp_filter:
			if   $preapp == ""          then .
			elif $preapp == "__EMPTY__" then select((.file_application // "") == "")
			else select(.file_application == $preapp)
			end;
			def repo_filter:
			if $repo == "" then .
			else select(.download_repository == $repo)
			end;
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| preapp_filter
			| repo_filter
			| .branch // "unknown"
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			# No kernel information – just keep filter empty (all)
			KERNEL_FILTER=""
			return 0
		fi

		# "All" option
		options+=("ALL" "All kernel branches")
		while IFS='|' read -r _ kbranch; do
			[[ -z "$kbranch" ]] && continue
			options+=("$kbranch" "$kbranch")
		done <<< "$temp_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$(dialog_menu "Kernel branch" "\nSelect kernel branch to filter images (or choose All):" 14 70 4 -- "${options[@]}")
		else
			echo "Available kernel branches for $board (preinstalled=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}):"
			echo "  ALL  - All kernel branches"
			while IFS='|' read -r _ kbranch; do
				[[ -z "$kbranch" ]] && continue
				echo "  $kbranch"
			done <<< "$temp_list"
			read -rp "Enter kernel branch to filter (empty/ALL for all): " selected
		fi

		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			KERNEL_FILTER=""
		else
			KERNEL_FILTER="$selected"
		fi

		return 0
	}

	# Helper: select image_variant filter for board + kernel + preapp
	select_image_variant_for_board() {
		local board="$1"
		local -a options=()
		local temp_list variant

		temp_list=$(jq -r --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			def preapp_filter:
			if   $preapp == ""          then .
			elif $preapp == "__EMPTY__" then select((.file_application // "") == "")
			else select(.file_application == $preapp)
			end;
			def repo_filter:
			if $repo == "" then .
			else select(.download_repository == $repo)
			end;
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| preapp_filter
			| repo_filter
			| (if $kbranch != "" then select(.branch == $kbranch) else . end)
			| .variant // "unknown"
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			VARIANT_FILTER=""
			return 0
		fi

		options+=("ALL" "All image variants")
		while IFS='|' read -r _ variant; do
			[[ -z "$variant" ]] && continue
			options+=("$variant" "$variant")
		done <<< "$temp_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$(dialog_menu "Image variant" "\nSelect image variant to filter (or choose All):" 15 70 5 -- "${options[@]}")
		else
			echo "Available variants for $board (preinstalled=${PREAPP_FILTER:-ALL}, branch=${KERNEL_FILTER:-all}, repo=${DOWNLOAD_REPO_FILTER:-all}):"
			echo "  ALL  - All variants"
			while IFS='|' read -r _ variant; do
				[[ -z "$variant" ]] && continue
				echo "  $variant"
			done <<< "$temp_list"
			read -rp "Enter image variant to filter (empty/ALL for all): " selected
		fi

		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			VARIANT_FILTER=""
		else
			VARIANT_FILTER="$selected"
		fi

		return 0
	}

	# Helper: select image via menu (uses BOARD_SLUG + filters)
	select_image_for_board() {
		local board
		board="$1"

		while true; do
			local temp_list
			local -a options=()
			local idx desc

			temp_list=$(jq -r --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg variant "$VARIANT_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
				def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
				def preapp_filter:
					if   $preapp == ""          then .
					elif $preapp == "__EMPTY__" then select((.file_application // "") == "")
					else select(.file_application == $preapp)
					end;
				def repo_filter:
					if $repo == "" then .
					else select(.download_repository == $repo)
					end;

				def spaces(n): reduce range(0;n) as $i (""; . + " ");
				def pad(s; n):
					(s // "") as $s |
					($s | length) as $l |
					if $l >= n then $s else $s + spaces(n - $l) end;
				def pad_right(s; n):
					(s // "") as $s |
					($s | length) as $l |
					if $l >= n then $s else spaces(n - $l) + $s end;
				def size_mb(x):
					(
						(x.file_size // "0" | try tonumber // 0)
						/ (1024*1024)
						| if . < 1 then 1 else floor end
						| tostring + " MB"
					);
				def show_ver(v):
					(v // "") as $v |
					if ($v | test("-trunk\\.[0-9]+$")) then
						# Example: 26.2.0-trunk.33 -> T-33
						"DEV." + ($v | capture("trunk\\.(?<n>[0-9]+)$").n)
					else
						$v
					end;

				[
				.. | objects
				| select(.board_slug? != null)
				| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
				| select(.branch != "cloud")
				| select(norm(.board_slug) == norm($board))
				| preapp_filter
				| repo_filter
				| (if $kbranch != "" then select(.branch == $kbranch) else . end)
				| (if $variant != "" then select(.variant == $variant) else . end)
				]
				| sort_by([ (if .promoted=="true" then 0 else 1 end), .armbian_version ])
				| to_entries[]
				| (
					(.key|tostring) + "|" +
					(if .value.promoted=="true" then "\u2605 " else "  " end) +
					pad(show_ver(.value.armbian_version); 10) + " " +
					pad(.value.distro // ""; 9) + " " +
					pad(.value.branch // ""; 10) + " " +
					pad(.value.variant // ""; 12) + " " +
					pad_right(size_mb(.value); 7) + " " +
					pad_right((.value.file_application // ""); 15)
				)
			' "$IMAGES_JSON_PATH" 2>/dev/null)


			if [[ -z "$temp_list" ]]; then
				# No images even after filters – offer to adjust filters
				if [[ -n "$DIALOG" ]]; then
					if dialog_yesno "Adjust filters" "No images found for:\n\n  board:   ${board}\n  preapp:  ${PREAPP_FILTER:-ALL}\n  repo:    ${DOWNLOAD_REPO_FILTER:-all}\n  branch:  ${KERNEL_FILTER:-all}\n  variant: ${VARIANT_FILTER:-all}\n\nWould you like to adjust filters?" "Yes" "No" 17 72; then
						select_preapp_for_board         "$board" || return 1
						select_kernel_branch_for_board  "$board" || return 1
						select_image_variant_for_board  "$board" || return 1
						continue
					else
						echo "No images found for the selected filters."
						return 1
					fi
				else
					echo "No images found for board=$board, preapp=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}, branch=${KERNEL_FILTER:-all}, variant=${VARIANT_FILTER:-all}."
					read -rp "Adjust filters? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						select_preapp_for_board         "$board" || return 1
						select_kernel_branch_for_board  "$board" || return 1
						select_image_variant_for_board  "$board" || return 1
						continue
					fi
					return 1
				fi
				local dlg_exit=$?
				if [[ $dlg_exit -ne 0 ]]; then
					return 1
				fi
			fi

			while IFS='|' read -r idx desc; do
				[[ -z "$idx" ]] && continue
				options+=("$idx" "$desc")
			done <<< "$temp_list"

			local selected_index

			if [[ -n "$DIALOG" ]]; then
				selected_index=$(dialog_menu "Select Armbian image" "\nBoard: $board\nPreinstalled: ${PREAPP_FILTER:-ALL}\nRepo: ${DOWNLOAD_REPO_FILTER:-all}\nBranch: ${KERNEL_FILTER:-all}\nVariant: ${VARIANT_FILTER:-all}\n★ = promoted image\n\n  #   version    release   branch     variant    size (MB)  [preinstalled]" 26 80 8 -- "${options[@]}")
			else
				echo "Available images for $board (preapp=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}, branch=${KERNEL_FILTER:-all}, variant=${VARIANT_FILTER:-all}; ★ = promoted):"
				local i=0
				while [[ $i -lt ${#options[@]} ]]; do
					echo "  ${options[$i]}: ${options[$((i+1))]}"
					((i+=2))
				done
				read -rp "Enter index to flash: " selected_index
			fi

			[[ -z "$selected_index" ]] && return 1

			# Return the selected JSON object via global variable
			IMAGE_JSON=$(jq -c --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg variant "$VARIANT_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" --argjson idx "$selected_index" '
				def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
				def preapp_filter:
				if   $preapp == ""          then .
				elif $preapp == "__EMPTY__" then select((.file_application // "") == "")
				else select(.file_application == $preapp)
				end;
				def repo_filter:
				if $repo == "" then .
				else select(.download_repository == $repo)
				end;
				[
				.. | objects
				| select(.board_slug? != null)
				| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
				| select(.branch != "cloud")
				| select(norm(.board_slug) == norm($board))
				| preapp_filter
				| repo_filter
				| (if $kbranch != "" then select(.branch == $kbranch) else . end)
				| (if $variant != "" then select(.variant == $variant) else . end)
				]
				| sort_by([ (if .promoted=="true" then 0 else 1 end), .armbian_version ])
				| .[$idx]
			' "$IMAGES_JSON_PATH")

			if [[ -z "$IMAGE_JSON" || "$IMAGE_JSON" == "null" ]]; then
				echo "Failed to obtain image metadata."
				return 1
			fi

			# Update BOARD_SLUG to the final chosen board
			BOARD_SLUG="$board"
			return 0
		done
	}

	# Helper: select target block device
	select_block_device() {
		local -a dev_options=()
		local raw_devices
		local line dev size model bytes

		# Find devices backing /, /boot, /boot/efi
		local rootdev bootdev bootefidev
		local rootdisk="" bootdisk="" bootefidisk=""

		rootdev=$(findmnt -n -o SOURCE --nofsroot / 2>/dev/null || echo "")
		bootdev=$(findmnt -n -o SOURCE --nofsroot /boot 2>/dev/null || echo "")
		bootefidev=$(findmnt -n -o SOURCE --nofsroot /boot/efi 2>/dev/null || echo "")

		# Resolve to parent disks (PKNAME) where possible
		if [[ -n "$rootdev" ]]; then
			local rd
			rd=$(lsblk -no PKNAME "$rootdev" 2>/dev/null || true)
			if [[ -n "$rd" ]]; then
				rootdisk="/dev/$rd"
			else
				# fallback: maybe / itself is a whole disk (e.g. /dev/mmcblk0)
				rootdisk="$rootdev"
			fi
		fi

		if [[ -n "$bootdev" ]]; then
			local bd
			bd=$(lsblk -no PKNAME "$bootdev" 2>/dev/null || true)
			if [[ -n "$bd" ]]; then
				bootdisk="/dev/$bd"
			else
				bootdisk="$bootdev"
			fi
		fi

		if [[ -n "$bootefidev" ]]; then
			local ed
			ed=$(lsblk -no PKNAME "$bootefidev" 2>/dev/null || true)
			if [[ -n "$ed" ]]; then
				bootefidisk="/dev/$ed"
			else
				bootefidisk="$bootefidev"
			fi
		fi

		# List candidate block devices
		raw_devices=$(lsblk -dpno NAME,SIZE,MODEL | grep -E '/dev/(sd|hd|vd|nvme|mmcblk)' || true)

		if [[ -z "$raw_devices" ]]; then
			echo "No suitable block devices found."
			return 1
		fi

		while IFS= read -r line; do
			dev=$(awk '{print $1}' <<< "$line")
			size=$(awk '{print $2}' <<< "$line")
			model=${line#"$dev $size "}
			[[ -z "$model" || "$model" == "$size" ]] && model=""

			# Skip eMMC boot / RPMB pseudo-devices like /dev/mmcblk1boot0, /dev/mmcblk1boot1, /dev/mmcblk1rpmb
			if [[ "$dev" =~ mmcblk[0-9]+boot[0-9]+$ || "$dev" =~ mmcblk[0-9]+rpmb$ ]]; then
				continue
			fi

			# Skip zero-size or invalid devices
			bytes=$(lsblk -bdno SIZE "$dev" 2>/dev/null || echo 0)
			if [[ -z "$bytes" ]]; then
				bytes=0
			fi
			if (( bytes <= 0 )); then
				continue
			fi

			# Skip any disk that contains the root or boot partitions
			if [[ -n "$rootdisk" && "$dev" == "$rootdisk" ]]; then
				continue
			fi
			if [[ -n "$bootdisk" && "$dev" == "$bootdisk" ]]; then
				continue
			fi
			if [[ -n "$bootefidisk" && "$dev" == "$bootefidisk" ]]; then
				continue
			fi

			dev_options+=("$dev" "$size ${model}")
		done <<< "$raw_devices"

		if [[ ${#dev_options[@]} -eq 0 ]]; then
			if [[ -n "$DIALOG" ]]; then
					dialog_msgbox "Error" "No flashable block devices were found.\n\n(System disks are excluded automatically.)" 10 70
			else
					echo "No flashable block devices (excluding system disks) found."
			fi
			return 1
		fi

		local target

		if [[ -n "$DIALOG" ]]; then
			target=$(dialog_menu "Select target device" "\nSelect block device to flash.\n\n⚠  ALL DATA ON THE SELECTED DEVICE WILL BE LOST!" 15 76 3 -- "${dev_options[@]}")
		else
			echo "Available block devices (ALL DATA WILL BE LOST):"
			local i=0
			while [[ $i -lt ${#dev_options[@]} ]]; do
				echo "  ${dev_options[$i]}: ${dev_options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter device to flash (e.g. /dev/sdb): " target
		fi

		[[ -z "$target" ]] && return 1

		TARGET_DEVICE="$target"
		return 0
	}

	# Helper: confirmation dialog
	confirm_destroy_device() {
		local dev="$1"
		local msg="WARNING!\n\nYou are about to write a disk image to:\n\n  ${dev}\n\nAll existing data on this device will be irreversibly destroyed.\n\nDo you want to continue?"

		if [[ -n "$DIALOG" ]]; then
			if ! dialog_yesno "Final confirmation" "$msg" "" "" 15 72; then
				return 1
			fi
		else
			echo -e "$msg"
			read -rp "Type YES to continue: " answer
			[[ "$answer" != "YES" ]] && return 1
		fi
		return 0
	}

	# Helper: download image file
	# Download is always done using file_url (full path)
	# redi_url is only shown to the user as a clean short link
	download_image_file() {
		local file_url redi_url file_ext image_url filename dirname raw_filename

		# Always download using file_url
		file_url=$(jq -r '.file_url' <<< "$IMAGE_JSON")
		redi_url=$(jq -r '.redi_url // ""' <<< "$IMAGE_JSON")
		file_ext=$(jq -r '.file_extension // ""' <<< "$IMAGE_JSON")

		# Determine real downloadable URL (must be file_url)
		case "$file_url" in
			*.img.xz)  image_url="$file_url" ;;
			*.asc|*.torrent|*.sha*) image_url="${file_url%.*}" ;;
			*) image_url="$file_url" ;;
		esac

		filename=$(basename "$image_url")
		raw_filename="${filename%.xz}"

		LOCAL_IMAGE_PATH="${IMAGES_BASE}/${raw_filename}"

		# If already present, ask reuse
		if [[ -f "$LOCAL_IMAGE_PATH" ]]; then
			if [[ -n "$DIALOG" ]]; then
				dialog_yesno "Note" "\nUncompressed image already exists in ${IMAGES_BASE}/:\n\n${raw_filename}\n\nReuse this file?" "" "" 12 70 && return 0
			else
				read -rp "Image $LOCAL_IMAGE_PATH exists. Reuse? [y/N]: " reuse
				[[ "$reuse" =~ ^[Yy]$ ]] && return 0
			fi
			rm -f "$LOCAL_IMAGE_PATH"
		fi

		# File size for pv gauge
		local content_length
		content_length=$(jq -r '(.file_size // "0")' <<< "$IMAGE_JSON")
		[[ -z "$content_length" ]] && content_length=0

		# -------------------------
		# Download + decompress
		# -------------------------
		local display_url="$redi_url"
		[[ -z "$display_url" ]] && display_url="$image_url"

		local rc=0

		if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]] && (( content_length > 0 )); then
			local gauge_dir
			gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
			local gauge_fifo="${gauge_dir}/fifo"
			mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }

			$DIALOG --title "Armbian imager" \
				--gauge "\nDownloading and decompressing Armbian image...\n\n$display_url" \
				10 70 0 < "$gauge_fifo" &
			local gauge_pid=$!

			{
				curl -fSL "$image_url" 2>/dev/null \
					| pv -n -s "$content_length" 2> "$gauge_fifo" \
					| xz -T0 -dc \
					> "$LOCAL_IMAGE_PATH"
			} || rc=$?

			rm -f "$gauge_fifo"
			rmdir "$gauge_dir" 2>/dev/null || true
			wait "$gauge_pid" 2>/dev/null || true

			(( rc != 0 )) && {
				echo "Failed to download or decompress image: $image_url"
				rm -f "$LOCAL_IMAGE_PATH"
				return 1
			}

		else
			# Fallback simple mode
			if [[ -n "$DIALOG" ]]; then
				dialog_infobox "" "\nDownloading and decompressing Armbian image...\n\n$display_url" 8 70
			else
				echo "Downloading and decompressing: $display_url"
			fi

			curl -fSL "$image_url" \
				| xz -T0 -dc \
				> "$LOCAL_IMAGE_PATH" || {
					echo "Failed to download or decompress: $image_url"
					rm -f "$LOCAL_IMAGE_PATH"
					return 1
				}
		fi

		return 0
	}

	# Helper: flash image with dd + pv + whiptail gauge + verification
	flash_image_to_device() {
		local img="$LOCAL_IMAGE_PATH"
		local dev="$TARGET_DEVICE"

		if [[ ! -b "$dev" ]]; then
			echo "Target device $dev is not a block device."
			return 1
		fi

		if [[ ! -f "$img" ]]; then
			echo "Image file not found: $img"
			return 1
		fi

		# Get uncompressed image size for proper progress and verification
		local img_size_bytes
		img_size_bytes=$(stat -c '%s' "$img" 2>/dev/null || echo 0)

		if ! [[ "$img_size_bytes" =~ ^[0-9]+$ ]] || (( img_size_bytes <= 0 )); then
			echo "Unable to determine image size for $img"
			return 1
		fi

		sync

		# ------------------------------------------------------------
		# FLASH PHASE (with gauge if pv + $DIALOG available)
		# ------------------------------------------------------------
		if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]]; then
			local gauge_dir
			gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
			local gauge_fifo="${gauge_dir}/fifo"
			mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }

			# Reader: takes percentages from FIFO and feeds whiptail
			{
				while read -r line; do
					echo "$line"
				done < "$gauge_fifo"
			} | "$DIALOG" --title "Armbian imager" \
				--gauge "\nWriting image to $dev...\n\nPlease wait, this may take a while." 10 70 0 &
			local gauge_pid=$!

			# pv reads the image file, dd writes to device; pv stderr → FIFO (0..100)
			{
				pv -n -s "$img_size_bytes" "$img" \
					| dd of="$dev" bs=4M conv=fsync,noerror status=none
			} 2> "$gauge_fifo"

			# Close FIFO and wait for whiptail to exit
			rm -f "$gauge_fifo"
			rmdir "$gauge_dir" 2>/dev/null || true
			wait "$gauge_pid" 2>/dev/null || true
		else
			# Fallback: console progress
			if [[ -n "$DIALOG" ]]; then
				dialog_infobox "Armbian imager" "\nWriting image to $dev...\n\nProgress is shown in the console." 8 70
			else
				echo "Writing image to $dev ..."
			fi

			if command -v pv >/dev/null 2>&1; then
				pv -s "$img_size_bytes" "$img" \
					| dd of="$dev" bs=4M conv=fsync,noerror status=none
			else
				dd if="$img" of="$dev" bs=4M conv=fsync,noerror status=progress
			fi
		fi

		sync

		# ------------------------------------------------------------
		# VERIFY PHASE (compare img vs device, with optional gauge)
		# ------------------------------------------------------------
		local verify_result=2   # 1 = OK, 0 = FAILED, 2 = SKIPPED

		if command -v cmp >/dev/null 2>&1; then
			local block_size=$((4*1024*1024))
			local blocks=$(( (img_size_bytes + block_size - 1) / block_size ))

			if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]]; then
				# Gauge for verification
				local gauge_dir
				gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
				local gauge_fifo="${gauge_dir}/fifo"
				mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }
				{
					while read -r line; do
						echo "$line"
					done < "$gauge_fifo"
				} | "$DIALOG" --title "Armbian imager" \
					--gauge "\nVerifying written image on $dev...\n\nPlease wait." 10 70 0 &
				local v_pid=$!

				# dd reads from device, pv tracks progress, cmp compares against img
				verify_result=1
				{
					dd if="$dev" bs=$block_size count=$blocks status=none \
						| pv -n -s "$img_size_bytes" 2> "$gauge_fifo" \
						| cmp -n "$img_size_bytes" "$img" - >/dev/null
				} || verify_result=0

				rm -f "$gauge_fifo"
				rmdir "$gauge_dir" 2>/dev/null || true
				wait "$v_pid" 2>/dev/null || true
			else
				# No gauge, but still verify
				echo "Verifying written image..."
				if cmp -n "$img_size_bytes" \
					"$img" \
					<(dd if="$dev" bs=$block_size count=$blocks status=none) \
					>/dev/null 2>&1; then
					verify_result=1
				else
					verify_result=0
				fi
			fi
		fi

		sync

		# ------------------------------------------------------------
		# FINAL REPORT
		# ------------------------------------------------------------
		if [[ -n "$DIALOG" ]]; then
			case "$verify_result" in
				1)
					# Success: offer actions
					local action
					action=$(dialog_menu "Armbian imager" "\nFlashing and verification completed successfully.\n\nChoose what to do next:" 14 72 3 -- "REBOOT" "Reboot system now" "SHUTDOWN" "Power off the system" "EXIT" "Return to shell/menu")

					case "$action" in
						REBOOT)
							sync
							reboot
							;;
						SHUTDOWN)
							sync
							poweroff   # or: shutdown -h now
							;;
						*)
							# EXIT or dialog cancelled: just return success
							;;
					esac
					;;
				0)
					dialog_msgbox "Armbian imager" "⚠ Verification FAILED!\n\nData read from $dev does not match the image.\nPlease try again or check the device." 12 75
					return 1
					;;
				*)
					dialog_msgbox "Armbian imager" "Flashing completed.\n\nVerification was skipped (cmp not available)." 10 70
					;;
			esac
		else
			# Non-dialog / console mode
			case "$verify_result" in
				1)
					echo "Flashing completed and verified OK."
					read -rp "Action: [r]eboot, [s]hutdown, [e]xit? " action
					case "$action" in
						r|R)
							sync
							reboot
							;;
						s|S)
							sync
							poweroff   # or: shutdown -h now
							;;
						*)
							;;
					esac
					;;
				0)
					echo "Verification FAILED."
					return 1
					;;
				*)
					echo "Flashing completed. Verification skipped (cmp not available)."
					;;
			esac
		fi

		return 0
	}

	# Helper: return 0 if cache directory contains any downloaded image
	# (ignores the index file armbian-images.json). Intended for menu logic.
	images_cache_has_content() {
		[[ -d "$IMAGES_BASE" ]] || return 1
		if find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'armbian-images.json' | read -r _; then
			return 0
		fi
		return 1
	}

	case "$CMD" in
		"${commands[0]}")  # install = main interactive flow
			ensure_board_slug                    || return 1
			refresh_images_json                  || return 1
			confirm_board_or_choose_other        || return 1
			select_preapp_for_board         "$BOARD_SLUG" || return 1
			select_kernel_branch_for_board  "$BOARD_SLUG" || return 1
			select_image_variant_for_board  "$BOARD_SLUG" || return 1
			select_image_for_board          "$BOARD_SLUG" || return 1
			select_block_device             || return 1
			confirm_destroy_device "$TARGET_DEVICE" || return 1
			download_image_file             || return 1
			flash_image_to_device           || return 1
		;;
		"${commands[1]}")  # remove = remove downloaded images only
			if [[ -d "$IMAGES_BASE" ]]; then
				if [[ -n "$DIALOG" ]]; then
					if dialog_yesno "" "Remove all downloaded Armbian images in:\n\n$IMAGES_BASE\n\nThe index file (armbian-images.json) will be kept." "" "" 12 70; then
						find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'armbian-images.json' -delete
					fi
				else
					read -rp "Remove all downloaded images (keep armbian-images.json) in $IMAGES_BASE? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'armbian-images.json' -delete
					fi
				fi
			fi
		;;
		"${commands[2]}")  # purge = remove everything
			if [[ -d "$IMAGES_BASE" ]]; then
				if [[ -n "$DIALOG" ]]; then
					if dialog_yesno "" "Completely purge the images cache directory?\n\n$IMAGES_BASE\n\nIndex and all downloaded images will be removed." "" "" 12 70; then
						rm -rf "$IMAGES_BASE"
					fi
				else
					read -rp "Purge $IMAGES_BASE (remove everything)? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						rm -rf "$IMAGES_BASE"
					fi
				fi
			fi
		;;
		"${commands[3]}")  # status
			ensure_board_slug || return 1
			if refresh_images_json; then
				local count promoted_count
				if ! count=$(jq -r --arg board "$BOARD_SLUG" '
					def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
					[
					.. | objects
					| select(.board_slug? != null)
					| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
					| select(norm(.board_slug) == norm($board))
					]
					| length
				' "$IMAGES_JSON_PATH" 2>/dev/null); then
					echo "Images index: FAILED (parse error in index file)"
					return 1
				fi

				promoted_count=$(jq -r --arg board "$BOARD_SLUG" '
					def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
					[
					.. | objects
					| select(.board_slug? != null)
					| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
					| select(norm(.board_slug) == norm($board))
					| select(.promoted=="true")
					]
					| length
				' "$IMAGES_JSON_PATH" 2>/dev/null)

				echo "Images index: OK"
				echo "Board slug:        $BOARD_SLUG"
				echo "Images available:  $count"
				echo "Promoted images:   $promoted_count"
				[[ -d "$IMAGES_BASE" ]] && echo "Cache directory:   $IMAGES_BASE"
				[[ -n "$(command -v pv)" ]] && echo "Progress helper:   pv (enabled)" || echo "Progress helper:   pv (not installed)"

				# --- NEW: count flashable block devices (excluding system disks) ---
				local blockdev_count=0
				local raw_devices line dev bytes
				local rootdev bootdev bootefidev
				local rootdisk="" bootdisk="" bootefidisk=""

				# Find devices backing /, /boot, /boot/efi
				rootdev=$(findmnt -n -o SOURCE --nofsroot / 2>/dev/null || echo "")
				bootdev=$(findmnt -n -o SOURCE --nofsroot /boot 2>/dev/null || echo "")
				bootefidev=$(findmnt -n -o SOURCE --nofsroot /boot/efi 2>/dev/null || echo "")

				# Resolve to parent disks
				if [[ -n "$rootdev" ]]; then
					local rd
					rd=$(lsblk -no PKNAME "$rootdev" 2>/dev/null || true)
					rootdisk=${rd:+/dev/$rd}
					[[ -z "$rd" ]] && rootdisk="$rootdev"
				fi

				if [[ -n "$bootdev" ]]; then
					local bd
					bd=$(lsblk -no PKNAME "$bootdev" 2>/dev/null || true)
					bootdisk=${bd:+/dev/$bd}
					[[ -z "$bd" ]] && bootdisk="$bootdev"
				fi

				if [[ -n "$bootefidev" ]]; then
					local ed
					ed=$(lsblk -no PKNAME "$bootefidev" 2>/dev/null || true)
					bootefidisk=${ed:+/dev/$ed}
					[[ -z "$ed" ]] && bootefidisk="$bootefidev"
				fi

				# List candidate devices
				raw_devices=$(lsblk -dpno NAME | grep -E '/dev/(sd|hd|vd|nvme|mmcblk)' || true)

				if [[ -n "$raw_devices" ]]; then
					while IFS= read -r dev; do
						bytes=$(lsblk -bdno SIZE "$dev" 2>/dev/null || echo 0)
						(( bytes <= 0 )) && continue

						# Skip system disks
						[[ "$dev" == "$rootdisk" ]]     && continue
						[[ "$dev" == "$bootdisk" ]]     && continue
						[[ "$dev" == "$bootefidisk" ]]  && continue

						(( blockdev_count++ ))
					done <<< "$raw_devices"
				fi

				echo "Flashable devices: $blockdev_count"

				# If none available → fail status
				if (( blockdev_count < 1 )); then
					echo "No flashable block devices detected."
					return 1
				fi
				# --- END NEW ---
			else
				echo "Images index: FAILED (could not fetch $ALL_IMAGES_JSON_URL)"
				return 1
			fi
		;;
		"${commands[4]}")  # help
			echo -e "\nUsage: ${module_options["module_images,feature"]} <command> [board_slug]"
			echo -e "Commands:  ${module_options["module_images,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Interactive: filter by preinstalled app + stability + branch + variant, select image, flash to device."
			echo -e "\tremove\t- Remove downloaded image files (keep the index armbian-images.json)."
			echo -e "\tpurge\t- Remove the entire images cache directory (index + images)."
			echo -e "\tstatus\t- Show images index status and counts for the current board."
			echo -e "\thelp\t- Show this help message."
			echo
			echo "Notes:"
			echo "- Board slug defaults to \$BOARD if not given explicitly."
			echo "- Image list is taken from: $ALL_IMAGES_JSON_URL"
			echo "- Only records with real image file_extension are considered; entries whose"
			echo "  file_extension contains .asc, .torrent or .sha* are ignored."
			echo "- You can filter images by:"
			echo "    * file_application: ALL / STABLE / barebone / specific (OMV, HA, OpenHAB, ...)"
			echo "      - STABLE = download_repository == \"archive\""
			echo "    * branch"
			echo "    * variant"
			echo "- Image selector columns: version | distro | branch | variant | size (MB) | {preinstalled}."
			echo "- Menu marks promoted images with a leading '★'."
			echo "- Board matching is case- and separator-insensitive (uefi-x86, UEFI_X86, uefi x86, etc.)."
			echo
		;;
		"cache-status")  # internal: exit 0 if cache has any images, else 1
			images_cache_has_content
		;;
		*)
			${module_options["module_images,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_postgres,author"]="@armbian"
	["module_postgres,maintainer"]="@igorpecovnik"
	["module_postgres,feature"]="module_postgres"
	["module_postgres,example"]="install remove purge status help"
	["module_postgres,desc"]="Install PostgreSQL container (advanced relational database)"
	["module_postgres,status"]="Active"
	["module_postgres,doc_link"]="https://www.postgresql.org/docs/"
	["module_postgres,group"]="Database"
	["module_postgres,port"]="5432"
	["module_postgres,protocol"]="postgresql"
	["module_postgres,arch"]="x86-64 arm64"
	["module_postgres,dockerimage"]="tensorchord/pgvecto-rs:pg14-v0.2.0"
	["module_postgres,dockername"]="postgres"
	["module_postgres,help_install"]="Install PostgreSQL with custom credentials and image"
)

#
# Module PostgreSQL
#
function module_postgres () {
	local title="PostgreSQL"
	local port="${module_options["module_postgres,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	# Accept optional parameters
	local postgres_user="${2:-armbian}"
	local postgres_password="${3:-armbian}"
	local postgres_db="${4:-armbian}"
	local postgres_image="${5:-tensorchord/pgvecto-rs}"
	local postgres_tag="${6:-pg14-v0.2.0}"
	local postgres_container="${7:-postgres}"

	local dockerimage="${postgres_image}:${postgres_tag}"
	local dockername="$postgres_container"
	local base_dir="${SOFTWARE_FOLDER}/${postgres_container}"

	# Only the stock container publishes 5432 on the host. Modules that stand up
	# their own database (hedgedoc, immich, netbox) pass a container name and
	# reach it by that name over the lsio network, so they need no host port --
	# and publishing the same one twice means the second container never starts:
	#   Bind for 0.0.0.0:5432 failed: port is already allocated
	local -a publish_port=()
	if [[ "${postgres_container}" == "postgres" ]]; then
		publish_port=(-p "${port}:5432")
	fi

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--restart=always \
				-e POSTGRES_USER="${postgres_user}" \
				-e POSTGRES_PASSWORD="${postgres_password}" \
				-e POSTGRES_DB="${postgres_db}" \
				-e TZ="$(cat /etc/timezone)" \
				-v "${base_dir}/${postgres_container}/data:/var/lib/postgresql/data" \
				"${publish_port[@]}" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first. The parameters have to be passed
			# on: remove re-derives the container and image names from them, so
			# an argument-less call falls back to the default "postgres" and
			# removes that instead -- leaving the container actually being purged
			# in place, which then collides on its own name at the next install.
			if ! ${module_options["module_postgres,feature"]} ${commands[1]} \
				"$postgres_user" "$postgres_password" "$postgres_db" \
				"$postgres_image" "$postgres_tag" "$postgres_container"; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_postgres" "$title" \
				"Port: $port\nImage: ${module_options["module_postgres,dockerimage"]}\n\nInstall accepts custom parameters:\n [username] [password] [database] [image] [tag] [container_name]\n\nDefaults: armbian armbian armbian tensorchord/pgvecto-rs pg14-v0.2.0 postgres"
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_swag,author"]="@igorpecovnik"
	["module_swag,maintainer"]="@igorpecovnik"
	["module_swag,feature"]="module_swag"
	["module_swag,example"]="install remove purge status password help"
	["module_swag,desc"]="Secure Web Application Gateway "
	["module_swag,status"]="Active"
	["module_swag,doc_link"]="https://github.com/linuxserver/docker-swag"
	["module_swag,group"]="WebHosting"
	["module_swag,port"]="443"
	["module_swag,arch"]="x86-64 arm64"
	["module_swag,dockerimage"]="lscr.io/linuxserver/swag:latest"
	["module_swag,dockername"]="swag"
)

function module_swag() {
	local title="SWAG"
	local dockerimage="${module_options["module_swag,dockerimage"]}"
	local dockername="${module_options["module_swag,dockername"]}"
	local port="${module_options["module_swag,port"]}"

	local container=$(docker_get_container_id "$dockername")

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_swag,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Get URL via dialog
			SWAG_URL=$(dialog --title \
				"Secure Web Application Gateway URL?" \
				--inputbox "\nExamples: myhome.domain.org (port 80 and 443 must be exposed to internet)" \
				8 80 "" 3>&1 1>&2 2>&3);

			if [[ ${SWAG_URL} && $? -eq 0 ]]; then
				# Adjust hostname
				hostnamectl set-hostname $(echo ${SWAG_URL} | sed -E 's/^\s*.*:\/\///g')

				# Pull image
				docker_operation_progress pull "$dockerimage"

				# Create base directory
				docker_manage_base_dir create "$base_dir" || return 1

				# Run container
				docker_operation_progress run "$dockername" \
					-d \
					--name="$dockername" \
					--cap-add=NET_ADMIN \
					--net=lsio \
					-e PUID="${DOCKER_USERUID}" \
					-e PGID="${DOCKER_GROUPUID}" \
					-e TZ="$(cat /etc/timezone)" \
					-e URL="${SWAG_URL}" \
					-e VALIDATION=http \
					-p 443:443 \
					-p 80:80 \
					-v "${base_dir}/config:/config" \
					--restart unless-stopped \
					"$dockerimage"

				# Set password
				${module_options["module_swag,feature"]} ${commands[4]}
			else
				show_message <<< "Entering fully qualified domain name is required!"
			fi
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_swag,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # password
			SWAG_USER=$(dialog_inputbox "Secure webserver with .htaccess username and password" \
				"\nHit enter for USERNAME defaults" "armbian" 9 70)
			# Pre-generate default password
			local default_password=$(tr -dc 'A-Za-z0-9=' < /dev/urandom | head -c 10)
			# Ask if user wants to use auto-generated password
			if dialog_yesno "Password Configuration" \
				"\nAuto-generated password for '${SWAG_USER}':\n\n  ${default_password}\n\nUse this password?" \
				"Use Generated" "Enter Own" 12 70; then
				SWAG_PASSWORD="$default_password"
			else
				SWAG_PASSWORD=$(dialog_passwordbox "Enter new password for ${SWAG_USER}" \
					"\nEnter a custom password" 9 70)
			fi
			if [[ "${SWAG_USER}" && "${SWAG_PASSWORD}" ]]; then
				docker exec -it "$dockername" htpasswd -b -c /config/nginx/.htpasswd ${SWAG_USER} ${SWAG_PASSWORD} >/dev/null 2>&1
				docker restart "$dockername" >/dev/null
			fi
		;;
		"${commands[5]}") # help
			show_module_help "module_swag" "$title" \
				"Docker Image: $dockerimage\nPorts: 80, 443\n\nThis module requires a domain name during install."
		;;
		*)
			${module_options["module_swag,feature"]} ${commands[5]}
		;;
	esac
}

module_options+=(
	["module_plexmediaserver,author"]="@schwar3kat"
	["module_plexmediaserver,maintainer"]="@igorpecovnik"
	["module_plexmediaserver,feature"]="module_plexmediaserver"
	["module_plexmediaserver,example"]="install remove status help"
	["module_plexmediaserver,desc"]="Install plexmediaserver from repo using apt"
	["module_plexmediaserver,status"]="Active"
	["module_plexmediaserver,doc_link"]="https://www.plex.tv/"
	["module_plexmediaserver,group"]="Media"
	["module_plexmediaserver,port"]="32400"
	["module_plexmediaserver,arch"]="x86-64 arm64"

)
#
# Install plexmediaserver using apt
#
module_plexmediaserver() {
	local title="plexmediaserver"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_plexmediaserver,example"]}"

	case "$1" in
		"${commands[0]}")
			if [ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]; then
				echo "deb [arch=$(dpkg --print-architecture) \
				signed-by=/usr/share/keyrings/plexmediaserver.gpg] https://downloads.plex.tv/repo/deb public main" \
				| sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			else
				sed -i "/downloads.plex.tv/s/^#//g" /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			fi
			# Note: for compatibility with existing source file in some builds format must be gpg not asc
			# and location must be /usr/share/keyrings
			wget -qO- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor \
			| sudo tee /usr/share/keyrings/plexmediaserver.gpg > /dev/null 2>&1
			pkg_update
			pkg_install plexmediaserver
		;;
		"${commands[1]}")
			sed -i '/plexmediaserver.gpg/s/^/#/g' /etc/apt/sources.list.d/plexmediaserver.list
			pkg_remove plexmediaserver
		;;
		"${commands[2]}")
			if pkg_installed plexmediaserver; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			show_module_help "module_plexmediaserver" "$title" "" "native"
		;;
		*)
			${module_options["module_plexmediaserver,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_evcc,author"]="@naltatis"
	["module_evcc,maintainer"]="@igorpecovnik"
	["module_evcc,feature"]="module_evcc"
	["module_evcc,example"]="install remove purge status help"
	["module_evcc,desc"]="Install evcc container"
	["module_evcc,status"]="Active"
	["module_evcc,doc_link"]="https://docs.evcc.io/en"
	["module_evcc,group"]="HomeAutomation"
	["module_evcc,port"]="7070"
	["module_evcc,arch"]=""
	["module_evcc,dockerimage"]="evcc/evcc:latest"
	["module_evcc,dockername"]="evcc"
)
#
# Module evcc: Solar charging. Super simple
#
function module_evcc () {
	local title="evcc"
	local dockerimage="${module_options["module_evcc,dockerimage"]}"
	local dockername="${module_options["module_evcc,dockername"]}"
	local port="${module_options["module_evcc,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_evcc,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create config file
			touch "${base_dir}/evcc.yaml"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-v "${base_dir}/evcc.yaml:/app/evcc.yaml" \
				-v "${base_dir}/.evcc:/root/.evcc" \
				-v /etc/machine-id:/etc/machine-id \
				-p "${port}:7070" \
				-p 8887:8887 \
				-p 9522:9522/udp \
				-p 4712:4712 \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_evcc,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_evcc" "$title" \
				"Docker Image: $dockerimage\nPorts: $port (main), 8887, 9522/udp, 4712"
		;;
		*)
			${module_options["module_evcc,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_webmin,author"]="@Tearran"
	["module_webmin,maintainer"]="@Tearran"
	["module_webmin,feature"]="module_webmin"
	["module_webmin,example"]="help install remove start stop enable disable status check"
	["module_webmin,desc"]="Webmin setup and service setting."
	["module_webmin,status"]="Active"
	["module_webmin,doc_link"]="https://webmin.com/docs/"
	["module_webmin,group"]="Management"
	["module_webmin,port"]="10000"
	["module_webmin,arch"]="x86-64 arm64 armhf"
)

function module_webmin() {
	local title="webmin"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_webmin,example"]}"

	case "$1" in
		"${commands[0]}")
			## help/menu options for the module
			echo -e "\nUsage: ${module_options["module_webmin,feature"]} <command>"
			echo -e "Commands: ${module_options["module_webmin,example"]}"
			echo "Available commands:"
			if [[ -z "$condition" ]]; then
				echo -e "  install\t- Install $title."
			else

			if srv_active webmin; then
				echo -e "\tstop\t- Stop the $title service."
				echo -e "\tdisable\t- Disable $title from starting on boot."
			else
				echo -e "\tenable\t- Enable $title to start on boot."
				echo -e "\tstart\t- Start the $title service."
			fi
				echo -e "\tstatus\t- Show the status of the $title service."
				echo -e "\tremove\t- Remove $title."

			fi
			echo
		;;
		"${commands[1]}")
			## install webmin
			pkg_update
			pkg_install wget apt-transport-https
			echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list
			wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor | tee /usr/share/keyrings/webmin-archive-keyring.gpg > /dev/null
			pkg_update
			pkg_install webmin
			echo "Webmin installed successfully."
		;;
		"${commands[2]}")
			## remove webmin
			srv_disable webmin
			pkg_remove webmin
			rm -f /etc/apt/sources.list.d/webmin.list
			rm -f /usr/share/keyrings/webmin-archive-keyring.gpg
			pkg_update
			echo "Webmin removed successfully."
		;;

		"${commands[3]}")
			srv_start webmin
			echo "Webmin service started."
			;;

		"${commands[4]}")
			srv_stop webmin
			echo "Webmin service stopped."
			;;

		"${commands[5]}")
			srv_enable webmin
			echo "Webmin service enabled."
			;;

		"${commands[6]}")
			srv_disable webmin
			echo "Webmin service disabled."
			;;

		"${commands[7]}")
			srv_status webmin
			;;

		"${commands[8]}")
			## check webmin status
			if srv_active webmin; then
				echo "Webmin service is active."
				return 0
			elif ! srv_enabled webmin; then
				echo "Webmin service is disabled."
				return 1
			else
				echo "Webmin service is in an unknown state."
				return 1
			fi
			;;
		*)
		echo "Invalid command.try: '${module_options["module_webmin,example"]}'"

		;;
	esac
}

module_options+=(
	["module_radarr,author"]="@armbian"
	["module_radarr,maintainer"]="@igorpecovnik"
	["module_radarr,feature"]="module_radarr"
	["module_radarr,example"]="install remove purge status help"
	["module_radarr,desc"]="Install radarr container"
	["module_radarr,status"]="Active"
	["module_radarr,doc_link"]="https://wiki.servarr.com/radarr"
	["module_radarr,group"]="Downloaders"
	["module_radarr,port"]="7878"
	["module_radarr,arch"]="x86-64 arm64"
	["module_radarr,dockerimage"]="lscr.io/linuxserver/radarr:latest"
	["module_radarr,dockername"]="radarr"
)
#
# Module Radarr
#
function module_radarr () {
	local title="Radarr"
	local dockerimage="${module_options["module_radarr,dockerimage"]}"
	local dockername="${module_options["module_radarr,dockername"]}"
	local port="${module_options["module_radarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_radarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/radarr"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:7878" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/movies:/movies" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_radarr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_radarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_radarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_pi_hole,author"]="@armbian"
	["module_pi_hole,maintainer"]="@igorpecovnik"
	["module_pi_hole,feature"]="module_pi_hole"
	["module_pi_hole,example"]="install remove purge password status help"
	["module_pi_hole,desc"]="Install Pi-hole container"
	["module_pi_hole,status"]="Active"
	["module_pi_hole,doc_link"]="https://docs.pi-hole.net/"
	["module_pi_hole,group"]="DNS"
	["module_pi_hole,port"]="8811"
	["module_pi_hole,arch"]="x86-64 arm64"
	["module_pi_hole,dockerimage"]="pihole/pihole:latest"
	["module_pi_hole,dockername"]="pihole"
)
#
# Module Pi-Hole
#
function module_pi_hole () {
	local title="Pi-hole"
	local dockerimage="${module_options["module_pi_hole,dockerimage"]}"
	local dockername="${module_options["module_pi_hole,dockername"]}"
	local port="${module_options["module_pi_hole,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_pi_hole,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}")
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Ensure unbound dependency
			if ! docker_is_installed "unbound" "alpinelinux/unbound"; then
				module_unbound install
			fi

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Configure systemd-resolved before starting container
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p 53:53/tcp \
				-p 53:53/udp \
				-p "${port}:80" \
				-e TZ="$(cat /etc/timezone)" \
				-e PIHOLE_UID="${DOCKER_USERUID}" \
				-e PIHOLE_GID="${DOCKER_GROUPUID}" \
				-v "${base_dir}/etc-pihole:/etc/pihole" \
				-v "${base_dir}/etc-dnsmasq.d:/etc/dnsmasq.d" \
				--dns=9.9.9.9 \
				--restart=unless-stopped \
				--hostname pi.hole \
				-e VIRTUAL_HOST="pi.hole" \
				-e PROXY_LOCATION="pi.hole" \
				-e FTLCONF_LOCAL_IPV4="${LOCALIPADD}" \
				-e FTLCONF_dns_upstreams="unbound#5335" \
				"$dockerimage"

			# Add container IP to DNS configuration after container is running
			if srv_active systemd-resolved; then
				local container_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' "$dockername")
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1 ${container_ip}
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
			${module_options["module_pi_hole,feature"]} ${commands[3]}
		;;
		"${commands[1]}")
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# restore DNS settings
			if srv_active systemd-resolved; then
				rm -f /etc/systemd/resolved.conf.d/armbian-defaults.conf
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}")
			${module_options["module_pi_hole,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}")
			local container=$(docker_get_container_id "$dockername")
			if [[ -n "${container}" ]]; then
				SELECTED_PASSWORD=$(dialog_passwordbox "Enter new password for Pi-hole admin" "" 7 50)
				if [[ -n $SELECTED_PASSWORD ]]; then
					docker exec -it "$dockername" pihole setpassword "${SELECTED_PASSWORD}"
				fi
			else
				dialog_msgbox "Not Running" "$title container is not running.\n\nPlease install $title first." 10 50
			fi
		;;
		"${commands[4]}")
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[5]}")
			show_module_help "module_pi_hole" "$title" \
				"Web Interface: http://pi.hole:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_pi_hole,feature"]} ${commands[5]}
		;;
	esac
}


module_options+=(
	["module_immich,author"]=""
	["module_immich,maintainer"]="@igorpecovnik"
	["module_immich,feature"]="module_immich"
	["module_immich,example"]="install remove purge status help"
	["module_immich,desc"]="Install Immich (photo and video backup solution)"
	["module_immich,status"]="Active"
	["module_immich,doc_link"]="https://immich.app/docs"
	["module_immich,group"]="Media"
	["module_immich,port"]="8077"
	["module_immich,arch"]="x86-64 arm64"
	["module_immich,dockerimage"]="ghcr.io/imagegenius/immich:latest"
	["module_immich,dockername"]="immich"
)
#
# Module immich
#
function module_immich () {
	local title="Immich"
	local dockerimage="${module_options["module_immich,dockerimage"]}"
	local dockername="${module_options["module_immich,dockername"]}"
	local port="${module_options["module_immich,port"]}"

	# Database configuration
	local DATABASE_USER="immich"
	local DATABASE_PASSWORD="immich"
	local DATABASE_NAME="immich"
	local DATABASE_HOST="postgres-immich"
	local DATABASE_IMAGE="tensorchord/pgvecto-rs:pg14-v0.2.0"
	local DATABASE_PORT="5432"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_immich,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				dialog_msgbox "$title" "Immich container is already installed." 8 50
				return 0
			fi

			# Create base directory and subdirectories
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "$base_dir"/photos/{backups,encoded-video,library,profile,thumbs,upload}
			mkdir -p "$base_dir"/config "$base_dir"/libraries
			touch "$base_dir"/photos/{backups,thumbs,profile,upload,library,encoded-video}/.immich
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir"/

			# Install dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then
				module_redis install
			fi
			if ! docker container ls -a --format '{{.Names}}' | grep "^$DATABASE_HOST$"; then
				# Split image and tag: "tensorchord/pgvecto-rs:pg14-v0.2.0" -> image="tensorchord/pgvecto-rs" tag="pg14-v0.2.0"
				local pg_image="${DATABASE_IMAGE%:*}"
				local pg_tag="${DATABASE_IMAGE##*:}"
				module_postgres install "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" "$pg_image" "$pg_tag" "$DATABASE_HOST"
			fi

			# Wait for PostgreSQL to be ready with dialog_gauge progress
			local max_wait_pg=60
			local wait_count_pg=0
			(
				while [[ $wait_count_pg -lt $max_wait_pg ]]; do
					if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; then
						echo "XXX"; echo "100"; echo "PostgreSQL is ready!"; echo "XXX"
						exit 0
					fi

					echo "XXX"; echo "$((wait_count_pg * 100 / max_wait_pg))"; echo "Waiting for PostgreSQL to be ready..."; echo "XXX"
					sleep 2
					((wait_count_pg++))
				done
				echo "XXX"; echo "100"; echo "Timed out waiting for PostgreSQL"; echo "XXX"
			) | dialog_gauge "$title" "Waiting for PostgreSQL..." 8 60

			# Verify PostgreSQL is ready
			if ! docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; then
				dialog_msgbox "$title Installation Failed" \
					"PostgreSQL container failed to start properly.\n\nCheck logs with: docker logs $DATABASE_HOST" \
					10 60
				return 1
			fi

			dialog_infobox "$title" "Creating Immich database..." 5 50

			# Create database if it doesn't exist
			dialog_infobox "$title" "Checking database..." 5 50
			if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" | grep -q 1; then
				dialog_infobox "$title" "✅ Database '$DATABASE_NAME' already exists." 5 50
			else
				dialog_infobox "$title" "Creating database '$DATABASE_NAME'..." 5 50
				docker exec -i $DATABASE_HOST psql -U $DATABASE_USER <<-EOT
				CREATE DATABASE $DATABASE_NAME;
				GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
				EOT
				dialog_infobox "$title" "✅ Database '$DATABASE_NAME' created successfully." 5 50
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e DB_HOSTNAME=$DATABASE_HOST \
				-e DB_USERNAME=$DATABASE_USER \
				-e DB_PASSWORD=$DATABASE_PASSWORD \
				-e DB_DATABASE_NAME=$DATABASE_NAME \
				-e REDIS_HOSTNAME=redis \
				-e DB_PORT=$DATABASE_PORT \
				-e REDIS_PORT=6379 \
				-e REDIS_PASSWORD= \
				-e SERVER_HOST=0.0.0.0 \
				-e SERVER_PORT=8080 \
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/photos:/photos" \
				-v "${base_dir}/libraries:/libraries" \
				--restart=always \
				"$dockerimage"

			# Wait for Immich service to be available with dialog_gauge progress
			local max_wait_immich=120
			local wait_count_immich=0
			(
				while [[ $wait_count_immich -lt $max_wait_immich ]]; do
					if curl -sf http://localhost:${port}/ > /dev/null; then
						echo "XXX"; echo "100"; echo "Immich is ready!"; echo "XXX"
						exit 0
					fi

					echo "XXX"; echo "$((wait_count_immich * 100 / max_wait_immich))"; echo "Waiting for Immich to start..."; echo "XXX"
					sleep 2
					((wait_count_immich++))
				done
				echo "XXX"; echo "100"; echo "Timed out waiting for Immich"; echo "XXX"
			) | dialog_gauge "$title" "Starting Immich..." 8 60

			# Verify Immich is responding
			if ! curl -sf http://localhost:${port}/ > /dev/null; then
				dialog_msgbox "$title Warning" \
					"Immich container started but may not be fully ready yet.\n\nCheck status with: docker logs $dockername" \
					10 60
			else
				dialog_msgbox "$title Installation Complete" \
					"Immich has been installed successfully!\n\nAccess at: http://localhost:${port}\n\nDefault credentials need to be created on first visit." \
					12 60
			fi
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_immich,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only purge postgres and data directory if container/image removal succeeded
			local pg_image="${DATABASE_IMAGE%:*}"
			local pg_tag="${DATABASE_IMAGE##*:}"
			module_postgres purge "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" "$pg_image" "$pg_tag" "$DATABASE_HOST"
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_immich" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nRequires: Redis and PostgreSQL with vector support"
		;;
		*)
			${module_options["module_immich,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_solidping,author"]="@fclairamb"
	["module_solidping,maintainer"]="@fclairamb"
	["module_solidping,feature"]="module_solidping"
	["module_solidping,example"]="install remove purge status help"
	["module_solidping,desc"]="Install SolidPing container"
	["module_solidping,status"]="Active"
	["module_solidping,doc_link"]="https://docs.solidping.io"
	["module_solidping,group"]="Monitoring"
	["module_solidping,port"]="4000"
	["module_solidping,arch"]="x86-64 arm64"
	["module_solidping,dockerimage"]="ghcr.io/fclairamb/solidping:latest"
	["module_solidping,dockername"]="solidping"
)
#
# Module SolidPing
#
function module_solidping () {
	local title="SolidPing"
	local dockerimage="${module_options["module_solidping,dockerimage"]}"
	local dockername="${module_options["module_solidping,dockername"]}"
	local port="${module_options["module_solidping,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_solidping,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/solidping"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			# The worker name is derived from the hostname, so it must be set.
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--hostname "$dockername" \
				--restart=always \
				--user "${DOCKER_USERUID}:${DOCKER_GROUPUID}" \
				-p "${port}:4000" \
				-v "${base_dir}:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername" || return 1
			docker_operation_progress rmi "$dockerimage" || return 1
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_solidping,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_solidping" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_solidping,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_unbound,author"]="@igorpecovnik"
	["module_unbound,maintainer"]="@igorpecovnik"
	["module_unbound,feature"]="module_unbound"
	["module_unbound,example"]="install remove purge status help"
	["module_unbound,desc"]="Install unbound container"
	["module_unbound,status"]="Active"
	["module_unbound,doc_link"]="https://unbound.docs.nlnetlabs.nl/en/latest/"
	["module_unbound,group"]="DNS"
	["module_unbound,port"]="5335"
	["module_unbound,arch"]="x86-64"
	["module_unbound,dockerimage"]="alpinelinux/unbound:latest"
	["module_unbound,dockername"]="unbound"
)
#
# Module Unbound
#
function module_unbound () {
	local title="Unbound"
	local dockerimage="${module_options["module_unbound,dockerimage"]}"
	local dockername="${module_options["module_unbound,dockername"]}"
	local port="${module_options["module_unbound,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_unbound,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create unbound.conf with port from module_options
			cat > "${base_dir}/unbound.conf" <<-EOT
			server:
				interface: 0.0.0.0
				port: $port
				access-control: 0.0.0.0/0 allow
				do-ip4: yes
				do-udp: yes
				do-tcp: yes
				do-ip6: no
				verbosity: 1
			EOT
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-p "${port}:${port}/tcp" \
				-p "${port}:${port}/udp" \
				-v "${base_dir}/unbound.conf:/etc/unbound/unbound.conf:ro" \
				--name "$dockername" \
				--restart=unless-stopped \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_unbound,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_unbound" "$title" \
				"Docker Image: $dockerimage\nPort: $port (TCP/UDP)"
		;;
		*)
			${module_options["module_unbound,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_redis,author"]="@armbian"
	["module_redis,maintainer"]="@igorpecovnik"
	["module_redis,feature"]="module_redis"
	["module_redis,example"]="install remove purge status help"
	["module_redis,desc"]="Install Redis in a container (In-Memory Data Store)"
	["module_redis,status"]="Active"
	["module_redis,doc_link"]="https://redis.io/docs/"
	["module_redis,group"]="Database"
	["module_redis,port"]="6379"
	["module_redis,protocol"]="redis"
	["module_redis,arch"]="x86-64 arm64"
	["module_redis,dockerimage"]="redis:alpine"
	["module_redis,dockername"]="redis"
)
#
# Module Redis
#
function module_redis () {
	local title="Redis"
	local dockerimage="${module_options["module_redis,dockerimage"]}"
	local dockername="${module_options["module_redis,dockername"]}"
	local port="${module_options["module_redis,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/redis"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Opt-in cache mode, for Redis used purely as a cache (e.g. the shared
			# compiler cache of the Armbian build's ccache-remote extension): cap the
			# memory, evict least-recently-used keys at the cap, and skip disk
			# snapshots, which for a multi-GB cache under constant writes would dump
			# the whole dataset to disk every minute. Off by default: a general-purpose
			# Redis (sessions, locks, queues) must never evict or lose data.
			# At the cap every write evicts, and ccache objects are multi-MB, so
			# evicted and overwritten values are freed on a background thread
			# (lazyfree-*) instead of stalling the event loop that serves every client.
			#   REDIS_MAXMEMORY=48gb armbian-config --api module_redis install
			local -a server_args=()
			if [[ -n "${REDIS_MAXMEMORY}" ]]; then
				# Zero is rejected too: Redis reads maxmemory 0 as unlimited, which
				# would enable eviction mode with no cap at all.
				if [[ ! "${REDIS_MAXMEMORY,,}" =~ ^([0-9]+)(b|k|kb|m|mb|g|gb)?$ ]] ||
					((10#${BASH_REMATCH[1]} == 0)); then
					echo "Invalid REDIS_MAXMEMORY '${REDIS_MAXMEMORY}' (e.g. 512mb, 48gb)" >&2
					return 1
				fi
				server_args=(redis-server --maxmemory "${REDIS_MAXMEMORY}" --maxmemory-policy allkeys-lru --save "" --appendonly no
					--lazyfree-lazy-eviction yes --lazyfree-lazy-server-del yes)
			fi

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# No authentication: publish for this host and its containers only.
			local -a publish
			docker_publish_local publish "$port" 6379

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--restart=always \
				"${publish[@]}" \
				-v "${base_dir}/data:/data" \
				"$dockerimage" \
				"${server_args[@]}"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_redis,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_redis" "$title" \
				"Port: ${port}\nDocker Image: $dockerimage\nListens on 127.0.0.1 and the Docker bridge gateway (host and local containers) only; set BIND_ADDRESS (e.g. a LAN address, or 0.0.0.0) at install to serve other hosts\nCache mode: set REDIS_MAXMEMORY (e.g. 48gb) at install to cap memory with LRU eviction and no disk snapshots"
		;;
		*)
			${module_options["module_redis,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_qbittorrent,author"]="@qbittorrent"
	["module_qbittorrent,maintainer"]="@igorpecovnik"
	["module_qbittorrent,feature"]="module_qbittorrent"
	["module_qbittorrent,example"]="install remove purge status help"
	["module_qbittorrent,desc"]="Install qbittorrent container"
	["module_qbittorrent,status"]="Active"
	["module_qbittorrent,doc_link"]="https://github.com/qbittorrent/qBittorrent/wiki/"
	["module_qbittorrent,group"]="Downloaders"
	["module_qbittorrent,port"]="8090"
	["module_qbittorrent,arch"]="x86-64 arm64"
	["module_qbittorrent,dockerimage"]="lscr.io/linuxserver/qbittorrent:latest"
	["module_qbittorrent,dockername"]="qbittorrent"
)
#
# Module qBittorrent
#
function module_qbittorrent () {
	local title="qBittorrent"
	local dockerimage="${module_options["module_qbittorrent,dockerimage"]}"
	local dockername="${module_options["module_qbittorrent,dockername"]}"
	local port="${module_options["module_qbittorrent,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_qbittorrent,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/qbittorrent"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e WEBUI_PORT=8090 \
				-e TORRENTING_PORT=6881 \
				-p 8090:8090 \
				-p 6881:6881 \
				-p 6881:6881/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"

			# Wait for the LSIO image to actually bootstrap qBittorrent
			# and emit the per-session temporary password. The previous
			# code read 'docker logs' the instant after 'docker run'
			# returned — long before s6-overlay had spawned qbittorrent
			# and printed the password line — so the dialog usually
			# rendered with an empty password.
			#
			# Step 1: wait for the container to be 'running' (~1 s).
			# Step 2: poll the log for the password marker, up to ~30 s.
			wait_for_container_ready "$dockername" 10 1 "running" >/dev/null 2>&1 || true

			local temp_password=""
			local attempt
			for ((attempt = 1; attempt <= 30; attempt++)); do
				# 'A temporary password is provided for this session: <pw>'
				# Last whitespace-separated field of the matching line.
				temp_password=$(docker logs "$dockername" 2>&1 \
					| awk '/temporary password is provided for this session:/ {print $NF; exit}')
				[[ -n "$temp_password" ]] && break
				sleep 1
			done

			local install_msg="qBittorrent is listening at http://$LOCALIPADD:${port}\n\nLogin as: admin"
			if [[ -n "$temp_password" ]]; then
				install_msg+="\n\nTemporary password: ${temp_password}"
			else
				# Don't lie to the user with a blank field — point them
				# at where the password will appear once bootstrap finishes.
				install_msg+="\n\nTemporary password was not in the logs yet.\nRun:\n  docker logs ${dockername} 2>&1 | grep 'temporary password'\nin a few seconds to retrieve it."
			fi

			if [[ -t 1 ]]; then
				dialog_msgbox "qBittorrent installed" "$install_msg" 14 70
			else
				echo -e "\n${install_msg}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_qbittorrent,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_qbittorrent" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_qbittorrent,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_docker,author"]="@schwar3kat"
	["module_docker,maintainer"]="@igorpecovnik"
	["module_docker,feature"]="module_docker"
	["module_docker,example"]="install remove purge status help"
	["module_docker,desc"]="Install docker from a repo using apt"
	["module_docker,status"]="Active"
	["module_docker,doc_link"]="https://docs.docker.com"
	["module_docker,group"]="Containers"
	["module_docker,port"]=""
	["module_docker,arch"]="x86-64 arm64 armhf riscv64"
)
#
# Install Docker from repo using apt
#
function module_docker() {

	local title="docker"
	local condition=$(which "$title" 2>/dev/null)
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_docker,example"]}"

	case "$1" in
		"${commands[0]}")
			# Install docker from distribution maintained packages

			# Stop and disable Docker first to ensure clean state
			srv_stop docker 2>/dev/null || true
			srv_disable docker 2>/dev/null || true
			srv_stop containerd 2>/dev/null || true
			srv_disable containerd 2>/dev/null || true

			# Kill any remaining Docker processes
			killall dockerd containerd 2>/dev/null || true
			sleep 2

			# Reset systemd failure state
			systemctl reset-failed docker 2>/dev/null || true
			systemctl reset-failed containerd 2>/dev/null || true

			pkg_update
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				# Install docker-ce (upstream) for bookworm
				pkg_install ca-certificates curl gnupg
				install -m 0755 -d /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
				chmod a+r /etc/apt/keyrings/docker.asc
				echo \
					"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
					${DISTROID} stable" | \
					tee /etc/apt/sources.list.d/docker.list > /dev/null
				pkg_update
				pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			else
				if pkg_installed docker-ce; then pkg_remove docker-ce; fi
				if pkg_installed docker-ce-cli; then pkg_remove docker-ce-cli; fi
				if pkg_installed containerd.io; then pkg_remove containerd.io; fi
				if pkg_installed docker-buildx-plugin; then pkg_remove docker-buildx-plugin; fi
				if pkg_installed docker-compose-plugin; then pkg_remove docker-compose-plugin; fi
				rm -f /etc/apt/sources.list.d/docker.list
				# install new
				pkg_install docker.io docker-cli docker-compose docker-buildx
			fi
			groupadd docker 2>/dev/null || true
			if [[ -n "${SUDO_USER}" ]]; then
				usermod -aG docker "${SUDO_USER}"
			fi

			srv_enable docker containerd

			# Start Docker and capture exit status
			if ! srv_start docker 2>/dev/null; then
				dialog_msgbox "Docker Installation Failed" \
					"Docker service failed to start.\n\nService status:\n$(systemctl status docker --no-pager 2>&1 || true)\n\nRecent logs:\n$(journalctl -xeu docker.service --no-pager -n 50 2>&1 || true)" \
					20 80
				return 1
			fi

			# Wait for Docker daemon to be responsive with multiple checks
			local max_wait=60
			local wait_count=0
			local socket_path="/var/run/docker.sock"
			local retry_count=0
			local max_retries=2
			local status_message="Initializing..."

			# Use dialog_gauge for visual progress
			(
				while [[ $wait_count -lt $max_wait ]]; do
					# Check if service failed during startup - try restart
					if systemctl is-failed --quiet docker 2>/dev/null; then
						if [[ $retry_count -lt $max_retries ]]; then
							status_message="Service failed, restarting (attempt $((retry_count + 1))/$max_retries)..."
							srv_stop docker 2>/dev/null || true
							systemctl reset-failed docker 2>/dev/null || true
							sleep 2
							srv_start docker 2>/dev/null
							((retry_count++))
							echo "XXX"
							echo "$((wait_count * 100 / max_wait))"
							echo "$status_message"
							echo "XXX"
							continue
						else
							echo "Error: Docker service failed after $max_retries restart attempts" >&2
							exit 1
						fi
					fi

					# Check 1: Socket exists
					if [[ ! -S "$socket_path" ]]; then
						status_message="Waiting for Docker socket..."
						echo "XXX"
						echo "$((wait_count * 100 / max_wait))"
						echo "$status_message"
						echo "XXX"
						sleep 1
						((wait_count++))
						continue
					fi

					# Check 2: API is responsive (this is the real test)
					if docker info >/dev/null 2>&1; then
						echo "XXX"
						echo "100"
						echo "Docker daemon is ready!"
						echo "XXX"
						exit 0
					fi

					status_message="Waiting for Docker API ([$((wait_count + 1))/${max_wait}])..."
					echo "XXX"
					echo "$((wait_count * 100 / max_wait))"
					echo "$status_message"
					echo "XXX"
					sleep 1
					((wait_count++))
				done

				if [[ $wait_count -ge $max_wait ]]; then
					echo "Error: Docker daemon failed to start within ${max_wait}s" >&2
					exit 1
				fi
			) | dialog_gauge "Docker Installation" "Starting Docker daemon..." 8 80

			local daemon_exit_code=$?

			if [[ $daemon_exit_code -ne 0 ]]; then
				dialog_msgbox "Docker Installation Failed" \
					"Docker daemon failed to start.\n\nService status:\n$(systemctl status docker --no-pager 2>&1 || true)\n\nSocket check:\n$(ls -la "$socket_path" 2>&1 || true)" \
					20 80
				return 1
			fi

			if ! docker network ls --format "{{.Name}}" | grep -q "^lsio$"; then
				docker network create lsio
			fi
		;;
		"${commands[1]}")
			docker network rm lsio 2>/dev/null || true
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
				rm -f /etc/apt/sources.list.d/docker.list
			else
				pkg_remove docker.io docker-cli docker-compose docker-buildx
			fi
			# Remove docker0 bridge interface if it exists
			if ip link show docker0 &>/dev/null; then
				ip link delete docker0
			fi
		;;
		"${commands[2]}")
			${module_options["module_docker,feature"]} ${commands[1]}
			if [[ "${DISTROID}" == bookworm ]] || [[ "${DISTROID}" == trixie ]]; then
				rm -f /etc/apt/sources.list.d/docker.list
				rm -f /etc/apt/keyrings/docker.asc
			fi
			rm -rf /var/lib/docker
			rm -rf /var/lib/containerd
		;;
		"${commands[3]}")
			if ! command -v docker >/dev/null 2>&1; then
				return 1
			fi

			if ! docker network ls --format "{{.Name}}" | grep -q "^lsio$"; then
				return 1
			fi

			return 0
		;;
		"${commands[4]}")
			show_module_help "module_docker" "$title" \
				"Architecture: ${module_options["module_docker,arch"]}"
		;;
		*)
			${module_options["module_docker,feature"]} ${commands[4]}
		;;
	esac
}


module_options+=(
	["module_jellyfin,author"]="@armbian"
	["module_jellyfin,maintainer"]="@igorpecovnik"
	["module_jellyfin,feature"]="module_jellyfin"
	["module_jellyfin,example"]="install remove purge status help"
	["module_jellyfin,desc"]="Install jellyfin container"
	["module_jellyfin,status"]="Preview"
	["module_jellyfin,doc_link"]="https://jellyfin.org/docs/general/quick-start/"
	["module_jellyfin,group"]="Media"
	["module_jellyfin,port"]="8096"
	["module_jellyfin,arch"]="x86-64 arm64"
	["module_jellyfin,dockerimage"]="lscr.io/linuxserver/jellyfin:latest"
	["module_jellyfin,dockername"]="jellyfin"
)
#
# Module Jellyfin
#
function module_jellyfin () {
	local title="Jellyfin"
	local dockerimage="${module_options["module_jellyfin,dockerimage"]}"
	local dockername="${module_options["module_jellyfin,dockername"]}"
	local port="${module_options["module_jellyfin,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_jellyfin,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/jellyfin"

	# Hardware acceleration
	local hwacc=""
	if [[ "${LINUXFAMILY}" == "rk35xx" && "${BOOT_SOC}" == "rk3588" ]]; then
		# Add udev rules according to Jellyfin's recommendations for RKMPP
		cat > "/etc/udev/rules.d/50-rk3588-mpp.rules" <<- EOT
		KERNEL=="mpp_service", MODE="0660", GROUP="video"
		KERNEL=="rga", MODE="0660", GROUP="video"
		KERNEL=="system", MODE="0666", GROUP="video"
		KERNEL=="system-dma32", MODE="0666", GROUP="video"
		KERNEL=="system-uncached", MODE="0666", GROUP="video"
		KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video" RUN+="/usr/bin/chmod a+rw /dev/dma_heap"
		EOT
		# Reload only when udevd is actually running (absent in CI
		# containers, which would otherwise exit with 'Failed to
		# send reload request: No such file or directory' and abort
		# the caller's set -e).
		if [[ -S /run/udev/control ]]; then
			udevadm control --reload-rules && udevadm trigger
		fi

		# Pack `hwacc` to expose MPP/VPU hardware to the container
		for dev in dri dma_heap mali0 rga mpp_service \
			iep mpp-service vpu_service vpu-service \
			hevc_service hevc-service rkvdec rkvenc vepu h265e ; do
			[ -e "/dev/$dev" ] && hwacc+=" --device /dev/$dev"
		done
	elif [[ "${LINUXFAMILY}" == "bcm2711" ]]; then
		hwacc="--device=/dev/video10:/dev/video10 --device=/dev/video11:/dev/video11 --device=/dev/video12:/dev/video12"
	elif [[ "${LINUXFAMILY}" == "x86" ]]; then
		hwacc="--device=/dev/dri:/dev/dri"
	fi

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				$hwacc \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p 8096:8096 \
				-p 8920:8920 \
				-p 7359:7359/udp \
				-p 1900:1900/udp \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/tvseries:/data/tvshows" \
				-v "${base_dir}/movies:/data/movies" \
				-v "${base_dir}/music:/data/music" \
				-v "${base_dir}/books:/data/books" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# Drop udev rules upon removal. Reload only when udevd is
			# actually running (absent in CI containers — see install
			# branch above for the same guard).
			rm -f "/etc/udev/rules.d/50-rk3588-mpp.rules"
			if [[ -S /run/udev/control ]]; then
				udevadm control --reload-rules && udevadm trigger
			fi
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_jellyfin,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove config if container/image removal succeeded, keep media
			rm -rf "${base_dir}/config" 2>/dev/null || true
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_jellyfin" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage\n\nHardware acceleration: Auto-detected for RK3588, BCM2711, and x86"
		;;
		*)
			${module_options["module_jellyfin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_cockpit,author"]="@tearran"
	["module_cockpit,maintainer"]="@igorpecovnik"
	["module_cockpit,feature"]="module_cockpit"
	["module_cockpit,example"]="install remove purge status help"
	["module_cockpit,desc"]="Cockpit setup and service setting."
	["module_cockpit,status"]="Stable"
	["module_cockpit,doc_link"]="https://cockpit-project.org/guide/latest/"
	["module_cockpit,group"]="Management"
	["module_cockpit,port"]="9890"
	["module_cockpit,protocol"]="https"
	["module_cockpit,arch"]="x86-64 arm64 armhf"
)

function module_cockpit() {
	local title="cockpit"
	local condition=$(dpkg -s "cockpit" 2>/dev/null | sed -n "s/Status: //p")

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_cockpit,example"]}"

	case "$1" in

		"${commands[0]}")

			sudo mkdir -p /etc/systemd/system/cockpit.socket.d
			cat <<- EOF > /etc/systemd/system/cockpit.socket.d/override.conf
			[Socket]
			ListenStream=
			ListenStream=${module_options["module_cockpit,port"]}
			EOF

			## install cockpit
			pkg_update
			# qemu-kvm is a legacy meta that's only published for amd64
			# and arm64 (and Ubuntu carries it as a x86-leaning shim
			# pulling qemu-system-x86). It has no installation
			# candidate on riscv64, causing the cockpit install to
			# fail with "Package 'qemu-kvm' has no installation
			# candidate". qemu-system below is the modern arch-agnostic
			# meta - on each host it pulls qemu-system-<host-arch>,
			# which is what libvirt + cockpit-machines actually need.
			# UEFI guest firmware. The package is arch-specific: ovmf is
			# x86 only, while arm64/armhf guests can boot *only* via UEFI and
			# need the matching AAVMF build. riscv64 has no OVMF equivalent,
			# so it is simply left without one (same "no candidate" trap as
			# qemu-kvm above).
			local host_arch uefi_fw=""
			host_arch="$(dpkg --print-architecture)"
			case "${host_arch}" in
				amd64) uefi_fw="ovmf" ;;
				arm64) uefi_fw="qemu-efi-aarch64" ;;
				armhf) uefi_fw="qemu-efi-arm" ;;
			esac
			pkg_install cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-utils qemu-system ${uefi_fw}

			# On a desktop, also install the virt-manager GUI so VMs can be
			# managed locally, not just through Cockpit's web UI. Headless
			# servers skip it to avoid pulling in GTK and its dependencies.
			check_desktop
			if [[ -n "${DESKTOP_INSTALLED}" ]]; then
				pkg_install virt-manager
			fi

			usermod -a -G libvirt libvirtdbus
			usermod -a -G libvirt libvirt-qemu

			# add bridged networking if bridges exists on the system
			for f in /sys/class/net/*; do
				intf=$(basename $f)
				if [[ $intf =~ ^br[0-9] ]]; then
					cat <<- EOF > /etc/libvirt/kvm-hostbridge-${intf}.xml
					<network>
					<name>hostbridge-${intf}</name>
					<forward mode="bridge"/>
					<bridge name="${intf}"/>
					</network>
					EOF
					virsh net-define /etc/libvirt/kvm-hostbridge-${intf}.xml
					virsh net-start hostbridge-${intf}
					virsh net-autostart hostbridge-${intf}
				fi
			done

			# Default new VMs to UEFI. arm64/armhf guests are UEFI-only
			# already; x86 still defaults to SeaBIOS, so - gated to amd64 -
			# install a libvirt qemu hook that flips firmware-less x86 domains
			# to UEFI (firmware='efi') at prepare time. cockpit-machines and
			# virt-install create BIOS guests otherwise; domains that already
			# picked a firmware/loader (UEFI or an explicit BIOS choice) are
			# left untouched.
			if [[ "${host_arch}" == amd64 ]]; then
				mkdir -p /etc/libvirt/hooks
				# editorconfig-checker-disable
				cat > /etc/libvirt/hooks/qemu <<'HOOK'
#!/usr/bin/env python3
# Managed by Armbian config (module_cockpit) - changes may be overwritten.
# libvirt qemu hook: on the "prepare" phase, default firmware-less x86 guests
# to UEFI so newly created VMs boot UEFI (OVMF) instead of SeaBIOS.
import sys
import xml.etree.ElementTree as ET

op = sys.argv[2] if len(sys.argv) > 2 else ""
data = sys.stdin.read()
# Only the prepare phase transforms the XML libvirt then uses; every other
# phase must leave things alone (its stdout is ignored anyway).
if op != "prepare" or not data.strip():
    sys.exit(0)
try:
    dom = ET.fromstring(data)
except ET.ParseError:
    sys.stdout.write(data)
    sys.exit(0)
os_el = dom.find("os")
type_el = os_el.find("type") if os_el is not None else None
arch = type_el.get("arch", "") if type_el is not None else ""
# skip when the domain already commits to a firmware/loader, or isn't x86
already = (os_el is None or os_el.get("firmware")
           or os_el.find("loader") is not None
           or os_el.find("nvram") is not None)
if arch in ("x86_64", "i686") and not already:
    os_el.set("firmware", "efi")
    sys.stdout.write(ET.tostring(dom, encoding="unicode"))
else:
    sys.stdout.write(data)
HOOK
				# editorconfig-checker-enable
				chmod +x /etc/libvirt/hooks/qemu
				systemctl restart libvirtd 2>/dev/null || systemctl restart libvirt 2>/dev/null || true
			fi

			if dialog_yesno " Reboot required " "A reboot is required to start $title properly. Shall we reboot now?" "Reboot" "Cancel" 7 34; then
				reboot
			fi

		;;
		"${commands[1]}")
			## remove cockpit
			systemctl stop cockpit.socket 2>/dev/null
			systemctl stop cockpit 2>/dev/null
			systemctl disable cockpit 2>/dev/null
			for bridge in $(grep hostbridge /etc/libvirt/kvm-hostbridge-br*.xml 2>/dev/null | grep -o -P '(?<=name>).*(?=\</name)' 2>/dev/null); do
				virsh net-destroy ${bridge}
				virsh net-undefine ${bridge}
			done
			pkg_installed virt-manager && pkg_remove virt-manager
			rm -f /etc/libvirt/hooks/qemu
			for fw in ovmf qemu-efi-aarch64 qemu-efi-arm; do
				pkg_installed "$fw" && pkg_remove "$fw"
			done
			pkg_remove cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-machines dnsmasq virtinst qemu-utils qemu-system

		;;
		"${commands[2]}")
			for vm in $(virsh list --all --name); do virsh destroy "$vm" 2>/dev/null; virsh undefine "$vm" --remove-all-storage; done
			for net in $(virsh net-list --all --name); do
				virsh net-destroy "$net" 2>/dev/null
				virsh net-undefine "$net"
			done
			ip link show virbr0 &>/dev/null && ip link delete virbr0
			${module_options["module_cockpit,feature"]} ${commands[1]}
			rm -rf /var/lib/libvirt
		;;
		"${commands[3]}")
			if pkg_installed cockpit; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_cockpit,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_cockpit,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;
		*)
			${module_options["module_cockpit,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_netbox,author"]=""
	["module_netbox,maintainer"]="@igorpecovnik"
	["module_netbox,feature"]="module_netbox"
	["module_netbox,example"]="install remove purge status help"
	["module_netbox,desc"]="Install NetBox container (IPAM/DCIM tool)"
	["module_netbox,status"]="Active"
	["module_netbox,doc_link"]="https://netbox.readthedocs.io/en/stable/"
	["module_netbox,group"]="Management"
	["module_netbox,port"]="8222"
	["module_netbox,arch"]="x86-64 arm64"
	["module_netbox,dockerimage"]="netboxcommunity/netbox:latest"
	["module_netbox,dockername"]="netbox"
)

#
# Module netbox
#
function module_netbox () {
	local title="NetBox"
	local dockerimage="${module_options["module_netbox,dockerimage"]}"
	local dockername="${module_options["module_netbox,dockername"]}"
	local port="${module_options["module_netbox,port"]}"

	# Accept optional parameters
	local SUPERUSER_EMAIL="$2"
	local SUPERUSER_PASSWORD="$3"

	# Database configuration
	local DATABASE_USER="netbox"
	local DATABASE_PASSWORD="netbox"
	local DATABASE_NAME="netbox"
	local DATABASE_HOST="postgres-netbox"
	local DATABASE_IMAGE="postgres:17-alpine"
	local DATABASE_PORT="5432"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netbox,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Prompt for email and password using dialog
			[[ -z "$SUPERUSER_EMAIL" ]] && \
			SUPERUSER_EMAIL=$(dialog_inputbox "Enter NetBox superuser email" "")
			[[ -z "$SUPERUSER_EMAIL" ]] && SUPERUSER_EMAIL="info@armbian.com"
			[[ -z "$SUPERUSER_PASSWORD" ]] && \
			SUPERUSER_PASSWORD=$(dialog_passwordbox "Enter NetBox admin password" "" 8 50)
			[[ -z "$SUPERUSER_PASSWORD" ]] && SUPERUSER_PASSWORD="armbian"

			clear  # Clean up dialog artifacts

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Install dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then
				module_redis install
			fi
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			fi

			# Generate a random secret key (50+ chars)
			NETBOX_SECRET_KEY=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' </dev/urandom | head -c 64)

			# Create configuration directory and file
			mkdir -p "$base_dir/config"
			if [[ ! -f "$base_dir/config/configuration.py" ]]; then
				cat > "$base_dir/config/configuration.py" <<- EOT
				ALLOWED_HOSTS = ['*']
				DATABASE = {
					'NAME': '$DATABASE_NAME',
					'USER': '$DATABASE_USER',
					'PASSWORD': '$DATABASE_PASSWORD',
					'HOST': '$DATABASE_HOST',
					'PORT': '$DATABASE_PORT',
				}

				REDIS = {
					'tasks': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 0,
						'SSL': False,
					},
					'caching': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 1,
						'SSL': False,
					}
				}
				SECRET_KEY = '${NETBOX_SECRET_KEY}'
			EOT
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Run container
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e TZ="$(cat /etc/timezone)" \
				-e SUPERUSER_EMAIL="${SUPERUSER_EMAIL}" \
				-e SUPERUSER_PASSWORD="${SUPERUSER_PASSWORD}" \
				-e DB_NAME=netbox \
				-p "${port}:8080" \
				-v "${base_dir}/config:/etc/netbox/config" \
				-v "${base_dir}/reports:/etc/netbox/reports" \
				-v "${base_dir}/scripts:/etc/netbox/scripts" \
				--restart unless-stopped \
				"$dockerimage"; then
				echo "❌ Failed to start NetBox container"
				exit 1
			fi

			# Wait for web service
			sleep 5
			if [[ -t 1 ]]; then
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${port}/ > /dev/null; then
						break
					fi
				done | dialog_gauge "NetBox" "Preparing NetBox\n\nPlease wait! (can take a few minutes)"
			else
				echo "Waiting for NetBox to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${port}/ > /dev/null; then
						echo "✅ NetBox is responding."
						break
					fi
				done
			fi

			# Delete default API Token
			docker exec -i "$dockername" /opt/netbox/netbox/manage.py shell -c "from users.models import Token;Token.objects.filter(key='0123456789abcdef0123456789abcdef01234567').delete();"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_netbox,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only purge postgres and data directory if container/image removal succeeded
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_netbox" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nRequires: Redis and PostgreSQL\n\nOptional arguments for install:\n  superuser_email superuser_password"
		;;
		*)
			${module_options["module_netbox,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_adguardhome,author"]="@igorpecovnik"
	["module_adguardhome,maintainer"]="@igorpecovnik"
	["module_adguardhome,feature"]="module_adguardhome"
	["module_adguardhome,example"]="install remove purge status help"
	["module_adguardhome,desc"]="Install adguardhome container"
	["module_adguardhome,status"]="Active"
	["module_adguardhome,doc_link"]="https://github.com/AdguardTeam/AdGuardHome/wiki"
	["module_adguardhome,group"]="DNS"
	["module_adguardhome,port"]="3000"
	["module_adguardhome,arch"]=""
	["module_adguardhome,dockerimage"]="adguard/adguardhome:latest"
	["module_adguardhome,dockername"]="adguardhome"
)
#
# Module AdGuard Home
#
function module_adguardhome () {
	local title="AdGuard Home"
	local dockerimage="${module_options["module_adguardhome,dockerimage"]}"
	local dockername="${module_options["module_adguardhome,dockername"]}"
	local port="${module_options["module_adguardhome,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_adguardhome,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/adguardhome"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Configure systemd-resolved before starting container
			local resolved_active=false
			if srv_active systemd-resolved; then
				resolved_active=true
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi

			# Run container and check for success
			if ! docker_operation_progress run "$dockername" \
				-d \
				--net=host \
				-p 53:53/tcp -p 53:53/udp \
				-p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp \
				-p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
				-v "${base_dir}/workdir:/opt/adguardhome/work" \
				-v "${base_dir}/confdir:/opt/adguardhome/conf" \
				--name "$dockername" \
				--restart=always \
				"$dockerimage"; then
				# Container failed to start - restore DNS configuration
				if $resolved_active; then
					dialog_msgbox "$title Installation Failed" \
						"AdGuard Home container failed to start.\n\nRestoring DNS configuration..." \
						8 60
					cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
					srv_restart systemd-resolved
				fi
				return 1
			fi
			# Additional ports for advanced usage (uncomment if needed):
			#-p 67:67/udp -p 68:68/udp \ # DHCP server
			#-p 853:853/tcp \ # DNS-over-TLS
			#-p 5443:5443/tcp -p 5443:5443/udp \ # DNSCrypt
			# See: https://hub.docker.com/r/adguard/adguardhome

			# Add DNS configuration after container is running (only if start succeeded)
			if $resolved_active; then
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# Restore DNS settings
			if srv_active systemd-resolved; then
				rm -f /etc/systemd/resolved.conf.d/armbian-defaults.conf
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_adguardhome,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_adguardhome" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_adguardhome,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_omv,author"]="@igorpecovnik"
	["module_omv,maintainer"]="@igorpecovnik"
	["module_omv,feature"]="module_omv"
	["module_omv,example"]="install remove status help"
	["module_omv,desc"]="Install OpenMediaVault (OMV)"
	["module_omv,status"]="Active"
	["module_omv,doc_link"]="https://docs.openmediavault.org/en/stable/"
	["module_omv,group"]="NAS"
	["module_omv,port"]="80"
	["module_omv,arch"]="amd64 arm64 armhf i386"
	["module_omv,release"]="bookworm"
)

function module_omv() {
	local title="OpenMediaVault"
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_omv,example"]}"

	# Constants
	local omvKey="/usr/share/keyrings/openmediavault-archive-keyring.gpg"
	local omvKeyUrl="https://packages.openmediavault.org/public/archive.key"
	local omvSources="/etc/apt/sources.list.d/openmediavault.list"
	local omvRepo="https://packages.openmediavault.org/public"
	local resolvTmp="/tmp/omv_resolv.conf.bak"
	local forceIpv4="/etc/apt/apt.conf.d/99force-ipv4"
	local noTrans="/etc/apt/apt.conf.d/99no-translations"
	local omvCodename="sandworm"
	local arch codename

	# Helper function to cleanup temporary APT configs
	_omv_install_cleanup() {
		rm -f "${forceIpv4}" "${noTrans}"
	}

	case "$1" in
		"${commands[0]}")
			# Check if already installed
			if pkg_installed openmediavault 2>/dev/null; then
				echo "OpenMediaVault is already installed."
				return 0
			fi

			# Pre-installation checks
			# Check for desktop environment
			if dpkg -l gdm3 sddm lxdm xdm lightdm slim wdm 2>/dev/null | grep -q '^ii'; then
				echo "ERROR: This system is running a desktop environment!"
				echo "OMV installation is not supported on desktop systems."
				echo "See: https://forum.openmediavault.org"
				return 1
			fi

			# Check for Docker
			if [ -f "/.dockerenv" ]; then
				echo "ERROR: Docker detected. OMV does not work in Docker!"
				return 1
			fi

			# Check for LXC
			if grep -q 'machine-lxc' /proc/1/cgroup 2>/dev/null; then
				echo "ERROR: LXC detected. OMV does not work in LXC!"
				return 1
			fi

			# Check architecture
			arch="$(dpkg --print-architecture)"
			if [[ ! ${arch} =~ ^(amd64|arm64|armhf|i386)$ ]]; then
				echo "ERROR: Unsupported architecture: ${arch}"
				return 1
			fi

			# Check Debian version
			codename="$(lsb_release --codename --short 2>/dev/null || echo "unknown")"
			if [[ ! "${codename}" =~ ^(bookworm|trixie)$ ]]; then
				echo "ERROR: Unsupported Debian version: ${codename}"
				echo "Only Debian 12 (Bookworm) and 13 (Trixie) are supported."
				return 1
			fi

			# Set OMV codename based on Debian version
			if [[ "${codename}" == "trixie" ]]; then
				omvCodename="synchrony"
			fi

			echo "=== Installing ${title} on Debian ${codename} (${arch}) ==="

			# Save current resolv.conf for potential DNS recovery
			if [ -f "/etc/resolv.conf" ]; then
				cp -f /etc/resolv.conf "${resolvTmp}"
			fi

			# Force IPv4 for apt (optional, can be disabled if needed)
			echo 'Acquire::ForceIPv4 "true";' > "${forceIpv4}"

			# Disable translations for faster apt operations
			echo 'Acquire::Languages "none";' > "${noTrans}"

			echo "Updating package repositories..."
			if ! pkg_update; then
				echo "ERROR: Failed to update package repositories."
				_omv_install_cleanup
				return 1
			fi

			echo "Adding GPG key for OpenMediaVault..."
			if ! curl --max-time 60 -4 -fsSL "${omvKeyUrl}" | \
				gpg --yes --dearmor -o "${omvKey}"; then
				echo "ERROR: Failed to add GPG key."
				_omv_install_cleanup
				return 1
			fi

			echo "Adding OMV repository..."
			echo "deb [arch=${arch} signed-by=${omvKey}] ${omvRepo} ${omvCodename} main" | \
				tee "${omvSources}" > /dev/null

			echo "Updating repositories with OMV sources..."
			if ! pkg_update; then
				echo "ERROR: Failed to update repositories after adding OMV."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing prerequisites..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --no-install-recommends \
				postfix wget gnupg; then
				echo "ERROR: Failed to install prerequisites."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing OpenMediaVault keyring..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --no-install-recommends \
				openmediavault-keyring; then
				echo "ERROR: Failed to install OpenMediaVault keyring."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			echo "Installing OpenMediaVault..."
			if ! DEBIAN_FRONTEND=noninteractive pkg_install --auto-remove --show-upgraded \
				--allow-downgrades --allow-change-held-packages \
				--no-install-recommends \
				--option DPkg::Options::="--force-confdef" \
				--option DPkg::Options::="--force-confold" \
				openmediavault; then
				echo "ERROR: Failed to install OpenMediaVault."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			# Verify installation
			if ! pkg_installed openmediavault 2>/dev/null; then
				echo "ERROR: Failed to install OpenMediaVault."
				_omv_install_cleanup
				rm -f "${omvSources}" "${omvKey}"
				return 1
			fi

			# DNS validation - test if DNS is working
			echo "Testing DNS resolution..."
			if ! getent hosts omv-extras.org >/dev/null 2>&1; then
				echo "WARNING: DNS resolution is failing. Attempting to fix..."
				if [ -f "${resolvTmp}" ]; then
					cp -f "${resolvTmp}" /etc/resolv.conf
					echo "Restored original resolv.conf."
				fi
			fi

			# Cleanup
			_omv_install_cleanup
			rm -f "${resolvTmp}"

			# Populate configuration database
			if command -v omv-confdbadm >/dev/null 2>&1; then
				echo "Initializing OMV configuration..."
				omv-confdbadm populate
			fi

			# Defensively resolve a valid IP for the web interface
			web_ip="$(hostname -I | awk '{print $1}')"
			[[ -z "${web_ip}" ]] && web_ip="$(hostname -i | awk '{print $1}')"
			[[ -z "${web_ip}" ]] && web_ip="$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')"
			[[ -z "${web_ip}" ]] && web_ip="localhost"

			echo "=== ${title} installation completed successfully! ==="
			echo "Access the web interface at: http://${web_ip}"
			return 0
		;;
		"${commands[1]}")
			if ! pkg_installed openmediavault 2>/dev/null; then
				echo "OpenMediaVault is not installed."
				return 0
			fi

			echo "Removing OpenMediaVault..."

			# Try to stop services first
			if systemctl is-active --quiet openmediavault-engined 2>/dev/null; then
				systemctl stop openmediavault-engined
			fi

			# Remove the package
			DEBIAN_FRONTEND=noninteractive pkg_remove openmediavault

			# Remove repository configuration
			if [ -f "${omvSources}" ]; then
				echo "Removing OMV repository..."
				rm -f "${omvSources}"
			fi

			# Remove GPG key
			if [ -f "${omvKey}" ]; then
				echo "Removing OMV GPG key..."
				rm -f "${omvKey}"
			fi

			# Remove APT config files we created
			_omv_install_cleanup

			echo "OpenMediaVault removed successfully."
			return 0
		;;
		"${commands[2]}")
			if pkg_installed openmediavault 2>/dev/null; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_omv,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_omv,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title"
			echo -e "\tstatus\t- Check if $title is installed"
			echo -e "\tremove\t- Remove $title completely"
			echo
		;;
		*)
			${module_options["module_omv,feature"]} ${commands[3]}
		;;
	esac
}

module_options+=(
	["module_sabnzbd,author"]="@armbian"
	["module_sabnzbd,maintainer"]="@igorpecovnik"
	["module_sabnzbd,feature"]="module_sabnzbd"
	["module_sabnzbd,example"]="install remove purge status help"
	["module_sabnzbd,desc"]="Install sabnzbd container"
	["module_sabnzbd,status"]="Active"
	["module_sabnzbd,doc_link"]="https://sabnzbd.org/wiki/faq"
	["module_sabnzbd,group"]="Downloaders"
	["module_sabnzbd,port"]="8380"
	["module_sabnzbd,arch"]="x86-64 arm64"
	["module_sabnzbd,dockerimage"]="lscr.io/linuxserver/sabnzbd:latest"
	["module_sabnzbd,dockername"]="sabnzbd"
)
#
# Module SABnzbd
#
function module_sabnzbd () {
	local title="SABnzbd"
	local dockerimage="${module_options["module_sabnzbd,dockerimage"]}"
	local dockername="${module_options["module_sabnzbd,dockername"]}"
	local port="${module_options["module_sabnzbd,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sabnzbd,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/sabnzbd"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/downloads:/downloads" \
				-v "${base_dir}/incomplete:/incomplete-downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_sabnzbd,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_sabnzbd" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_sabnzbd,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_filebrowser,author"]="@armbian"
	["module_filebrowser,maintainer"]="@igorpecovnik"
	["module_filebrowser,feature"]="module_filebrowser"
	["module_filebrowser,example"]="install remove purge status help"
	["module_filebrowser,desc"]="Install Filebrowser container"
	["module_filebrowser,status"]="Active"
	["module_filebrowser,doc_link"]="https://filebrowser.org/"
	["module_filebrowser,group"]="Utilities"
	["module_filebrowser,port"]="8095"
	["module_filebrowser,arch"]="x86-64 arm64 armhf"
	["module_filebrowser,dockerimage"]="filebrowser/filebrowser:latest"
	["module_filebrowser,dockername"]="filebrowser"
)

#
# Module File Browser
#
function module_filebrowser () {
	local title="File Browser"
	local dockerimage="${module_options["module_filebrowser,dockerimage"]}"
	local dockername="${module_options["module_filebrowser,dockername"]}"
	local port="${module_options["module_filebrowser,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_filebrowser,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/filebrowser"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create database directory with proper ownership
			mkdir -p "${base_dir}/database"
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "${base_dir}/database"

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-v "${base_dir}/srv:/srv" \
				-v "${base_dir}/database:/database" \
				-v "${base_dir}/branding:/branding" \
				-v "${base_dir}/.filebrowser.json:/.filebrowser.json" \
				-e TZ="$(cat /etc/timezone)" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-p "${port}:80" \
				--restart=always \
				"$dockerimage" \
				--database /database/filebrowser.db

			# Wait for container to initialize and extract password from logs
			sleep 3
			local admin_password
			admin_password=$(docker logs "$dockername" 2>&1 | grep "initialized with randomly generated password" | awk -F': ' '{print $NF}')

			# Display credentials with 10-second countdown
			local countdown=10
			while [[ $countdown -gt 0 ]]; do
				dialog_infobox "${title} installed" \
					"Web Interface: http://${LOCALIPADD}:${port}\n\nUsername: admin\nPassword: ${admin_password}\n\nClosing in ${countdown} seconds..." 11 70
				sleep 1
				((countdown--))
			done
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_filebrowser,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_filebrowser" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_filebrowser,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_phpmyadmin,author"]="@igorpecovnik"
	["module_phpmyadmin,maintainer"]="@igorpecovnik"
	["module_phpmyadmin,feature"]="module_phpmyadmin"
	["module_phpmyadmin,example"]="install remove purge status help"
	["module_phpmyadmin,desc"]="Install phpmyadmin container"
	["module_phpmyadmin,status"]="Active"
	["module_phpmyadmin,doc_link"]="https://www.phpmyadmin.net/docs/"
	["module_phpmyadmin,group"]="Database"
	["module_phpmyadmin,port"]="8071"
	["module_phpmyadmin,arch"]="x86-64 arm64"
	["module_phpmyadmin,dockerimage"]="lscr.io/linuxserver/phpmyadmin:latest"
	["module_phpmyadmin,dockername"]="phpmyadmin"
)
#
# Module phpmyadmin-PDF
#
function module_phpmyadmin () {
	local title="phpMyAdmin"
	local dockerimage="${module_options["module_phpmyadmin,dockerimage"]}"
	local dockername="${module_options["module_phpmyadmin,dockername"]}"
	local port="${module_options["module_phpmyadmin,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_phpmyadmin,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e PMA_ARBITRARY=1 \
				-p "${port}:80" \
				-v "${base_dir}/config:/config" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_phpmyadmin,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_phpmyadmin" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_phpmyadmin,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_ghost,author"]="@igorpecovnik"
	["module_ghost,maintainer"]="@igorpecovnik"
	["module_ghost,feature"]="module_ghost"
	["module_ghost,example"]="install remove purge status help"
	["module_ghost,desc"]="Install Ghost CMS container"
	["module_ghost,status"]="Active"
	["module_ghost,doc_link"]="https://ghost.org/docs/"
	["module_ghost,group"]="WebHosting"
	["module_ghost,port"]="9190"
	["module_ghost,arch"]="x86-64 arm64"
	["module_ghost,dockerimage"]="ghost:6"
	["module_ghost,dockername"]="ghost"
)

#
# Module ghost
#
function module_ghost () {
	local title="Ghost CMS"
	local dockerimage="${module_options["module_ghost,dockerimage"]}"
	local dockername="${module_options["module_ghost,dockername"]}"
	local port="${module_options["module_ghost,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_ghost,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Install mysql if not installed
			if ! module_mysql status; then
				module_mysql install
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Exit if ghost is already running
			if docker_is_installed "$dockername" "$dockerimage"; then
				echo "Ghost container is already installed and running."
				exit 0
			fi

			# User inputs for MySQL
			local mysql_user="${2:-armbian}"
			local mysql_password="${3:-armbian}"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net=lsio \
				--restart unless-stopped \
				-e database__client=mysql \
				-e database__connection__host="mysql" \
				-e database__connection__user="${mysql_user}" \
				-e database__connection__password="${mysql_password}" \
				-e database__connection__database="ghost" \
				-p "${port}:2368" \
				-e url="http://$LOCALIPADD:${port}" \
				-v "$base_dir:/var/lib/ghost/content" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_ghost,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_ghost" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nOptional arguments for install:\n  db_user db_pass"
		;;
		*)
			${module_options["module_ghost,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_lidarr,author"]="@armbian"
	["module_lidarr,maintainer"]="@igorpecovnik"
	["module_lidarr,feature"]="module_lidarr"
	["module_lidarr,example"]="install remove purge status help"
	["module_lidarr,desc"]="Install lidarr container"
	["module_lidarr,status"]="Active"
	["module_lidarr,doc_link"]="https://wiki.servarr.com/lidarr"
	["module_lidarr,group"]="Downloaders"
	["module_lidarr,port"]="8686"
	["module_lidarr,arch"]="x86-64 arm64"
	["module_lidarr,dockerimage"]="lscr.io/linuxserver/lidarr:latest"
	["module_lidarr,dockername"]="lidarr"
)
#
# Module Lidarr
#
function module_lidarr () {
	local title="Lidarr"
	local dockerimage="${module_options["module_lidarr,dockerimage"]}"
	local dockername="${module_options["module_lidarr,dockername"]}"
	local port="${module_options["module_lidarr,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_lidarr,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/lidarr"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8686" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/music:/music" \
				-v "${base_dir}/downloads:/downloads" \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_lidarr,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_lidarr" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_lidarr,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,maintainer"]="@schwar3kat"
	["module_portainer,feature"]="module_portainer"
	["module_portainer,example"]="install remove purge status help"
	["module_portainer,desc"]="Install/uninstall/check status of portainer container"
	["module_portainer,status"]="Active"
	["module_portainer,doc_link"]="https://docs.portainer.io/"
	["module_portainer,group"]="Containers"
	["module_portainer,port"]="9000"
	["module_portainer,arch"]="x86-64 arm64"
	["module_portainer,dockerimage"]="portainer/portainer-ce:latest"
	["module_portainer,dockername"]="portainer"
)
#
# Module Portainer
#
function module_portainer () {
	local title="Portainer"
	local dockerimage="${module_options["module_portainer,dockerimage"]}"
	local dockername="${module_options["module_portainer,dockername"]}"
	local port="${module_options["module_portainer,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_portainer,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/portainer"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create Docker volume if it doesn't exist
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--restart=always \
				-p 9000:9000 \
				-p 8000:8000 \
				-p 9443:9443 \
				-v /run/docker.sock:/var/run/docker.sock \
				-v "${base_dir}/data:/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_portainer,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove Docker volume and data directory if container/image removal succeeded
			docker volume rm portainer_data 2>/dev/null || true
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_portainer" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_portainer,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_stirling,author"]="@Frooodle"
	["module_stirling,maintainer"]="@igorpecovnik"
	["module_stirling,feature"]="module_stirling"
	["module_stirling,example"]="install remove purge status help"
	["module_stirling,desc"]="Install stirling container"
	["module_stirling,status"]="Active"
	["module_stirling,doc_link"]="https://docs.stirlingpdf.com"
	["module_stirling,group"]="Media"
	["module_stirling,port"]="8075"
	["module_stirling,arch"]="x86-64 arm64"
	["module_stirling,dockerimage"]="stirlingtools/stirling-pdf:latest"
	["module_stirling,dockername"]="stirling-pdf"
)
#
# Module stirling-PDF
#
function module_stirling () {
	local title="Stirling PDF"
	local dockerimage="${module_options["module_stirling,dockerimage"]}"
	local dockername="${module_options["module_stirling,dockername"]}"
	local port="${module_options["module_stirling,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_stirling,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/stirling"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/trainingData" "${base_dir}/extraConfigs" "${base_dir}/logs" "${base_dir}/customFiles"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port}:8080" \
				-v "${base_dir}/trainingData:/usr/share/tessdata" \
				-v "${base_dir}/extraConfigs:/configs" \
				-v "${base_dir}/logs:/logs" \
				-v "${base_dir}/customFiles:/customFiles" \
				-e DOCKER_ENABLE_SECURITY=false \
				-e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
				-e LANGS=en_GB \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_stirling,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_stirling" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_stirling,feature"]} ${commands[4]}
		;;
	esac
}

module_options+=(
	["module_homepage,author"]="@armbian"
	["module_homepage,maintainer"]="@igorpecovnik"
	["module_homepage,feature"]="module_homepage"
	["module_homepage,example"]="install remove purge status help"
	["module_homepage,desc"]="Install homepage container"
	["module_homepage,status"]="Active"
	["module_homepage,doc_link"]="https://gethomepage.dev/configs/"
	["module_homepage,group"]="Management"
	["module_homepage,port"]="3021"
	["module_homepage,arch"]=""
	["module_homepage,dockerimage"]="ghcr.io/gethomepage/homepage:latest"
	["module_homepage,dockername"]="homepage"
)
#
# Module Homepage
#
function module_homepage () {
	local title="Homepage"
	local dockerimage="${module_options["module_homepage,dockerimage"]}"
	local dockername="${module_options["module_homepage,dockername"]}"
	local port="${module_options["module_homepage,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_homepage,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/homepage"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name="$dockername" \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e HOMEPAGE_ALLOWED_HOSTS="${LOCALIPADD}:${port},homepage.local:${port},localhost:${port}" \
				-p "${port}:3000" \
				-v "${base_dir}/config:/app/config" \
				-v /var/run/docker.sock:/var/run/docker.sock:ro \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_homepage,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_homepage" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_homepage,feature"]} ${commands[4]}
		;;
	esac
}

