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

			# ARP flux sysctls for accurate scans on multi-NIC hosts.
			# NetAlertX itself warns when these aren't set; without
			# them the kernel answers ARP requests on any interface
			# regardless of which NIC the address belongs to, which
			# pollutes the device list. NetAlertX runs with
			# --network=host so the sysctls have to live on the host
			# namespace; drop a sysctl.d snippet and reload.
			# https://docs.netalertx.com/docker-troubleshooting/arp-flux-sysctls/
			local sysctl_file="/etc/sysctl.d/99-armbian-netalertx-arp.conf"
			if [[ ! -f "$sysctl_file" ]]; then
				cat > "$sysctl_file" <<- 'EOF'
					# Managed by armbian-config (module_netalertx install).
					# Reduce ARP flux for NetAlertX's host-network scanner.
					# https://docs.netalertx.com/docker-troubleshooting/arp-flux-sysctls/
					net.ipv4.conf.all.arp_ignore=1
					net.ipv4.conf.all.arp_announce=2
				EOF
				sysctl --system > /dev/null 2>&1 || true
			fi

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

			# When SWAG is on this host, pass SUB_PATH=netalertx (no-op
			# on the current 26.5.4 image — its nginx template
			# ignores the variable — but forward-compatible for when
			# upstream wires it through; we keep the conf below
			# regardless).
			# --network=host (raw sockets for ARP scanning) means SWAG
			# can't reach this container by name on the lsio bridge,
			# so the proxy below targets the host's IP directly.
			local -a netalertx_extra_env=()
			if docker container ls -a --format "{{.Names}}" 2>/dev/null | grep -q "^swag$"; then
				netalertx_extra_env+=(-e "SUB_PATH=netalertx")
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
				"${netalertx_extra_env[@]}" \
				-v "${base_dir}/config:/data/config:rw" \
				-v "${base_dir}/db:/data/db:rw" \
				$mount_params \
				--restart unless-stopped \
				"$dockerimage"

			# Auto-configure SWAG reverse proxy if available — best
			# effort. linuxserver/reverse-proxy-confs:master doesn't
			# ship a netalertx sample, so we seed our own.
			#
			# NetAlertX 26.5.4 has no real subpath support: the
			# rendered HTML/CSS/JS uses absolute /static/, /server/,
			# /img/ paths, and the page also makes runtime fetch()
			# calls against absolute URLs. We rewrite the literal
			# strings in the response body via sub_filter so the
			# initial page + static assets load under /netalertx/,
			# and then a catch-all fallback inside the proxy block
			# handles the upstream side.
			#
			# Caveat — this only fixes URLs that exist as literal
			# strings in the served bytes. Anything assembled in JS
			# at runtime (template literals, string concatenation in
			# XHR/fetch, EventSource(...)) will still target / and
			# 404 against SWAG. Until NetAlertX ships actual SUB_PATH
			# behaviour, the UI will look loaded but most data won't
			# populate. Direct port (LOCALIPADD:${port}) or a SWAG
			# subdomain are the unbroken paths. SUB_PATH=netalertx
			# is left set so this just starts working when upstream
			# fixes it.
			#
			# Heredoc is unquoted (NGINX, not 'NGINX') so $LOCALIPADD
			# and ${port} expand at install time; nginx variables and
			# regex anchors are escaped with \$ to pass through.
			docker_seed_swag_proxy_conf "netalertx" <<- NGINX
				## Custom Armbian seed — netalertx subfolder proxy.
				## Best-effort: NetAlertX 26.5.4 isn't subpath-aware,
				## so we sub_filter literal absolute paths in the
				## delivered HTML/CSS/JS. Runtime-built URLs are out
				## of scope and will still 404.
				location = /netalertx { return 301 /netalertx/; }

				location ^~ /netalertx/ {
				include /config/nginx/proxy.conf;

				set \$upstream_app ${LOCALIPADD};
				set \$upstream_port ${port};
				set \$upstream_proto http;

				rewrite ^/netalertx/(.*)\$ /\$1 break;

				proxy_pass \$upstream_proto://\$upstream_app:\$upstream_port;

				## sub_filter needs the upstream to send uncompressed
				## bytes; NetAlertX honours Accept-Encoding so we
				## stomp on it here.
				proxy_set_header Accept-Encoding "";

				sub_filter_once off;
				sub_filter_types text/html text/css application/javascript;
				sub_filter 'href="/'    'href="/netalertx/';
				sub_filter "href='/"    "href='/netalertx/";
				sub_filter 'src="/'     'src="/netalertx/';
				sub_filter "src='/"     "src='/netalertx/";
				sub_filter 'action="/'  'action="/netalertx/';
				sub_filter 'url(/'      'url(/netalertx/';
				}
			NGINX
			docker_configure_swag_proxy "netalertx" "${port}"
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
			# Drop the ARP-flux sysctl snippet seeded at install. The
			# settings only mattered while NetAlertX was scanning;
			# leaving them behind would surprise an admin who later
			# investigates 'why is my host's ARP behaviour different'.
			rm -f /etc/sysctl.d/99-armbian-netalertx-arp.conf
			sysctl --system > /dev/null 2>&1 || true
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
