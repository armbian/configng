module_options+=(
	["module_beszel,author"]="@armbian"
	["module_beszel,maintainer"]="@igorpecovnik"
	["module_beszel,feature"]="module_beszel"
	["module_beszel,example"]="install remove purge status help"
	["module_beszel,desc"]="Install Beszel container (lightweight server monitoring hub)"
	["module_beszel,status"]="Active"
	["module_beszel,doc_link"]="https://beszel.dev/guide/what-is-beszel"
	["module_beszel,group"]="Monitoring"
	["module_beszel,port"]="8090"
	["module_beszel,arch"]="x86-64 arm64"
	["module_beszel,dockerimage"]="henrygd/beszel:latest"
	["module_beszel,dockername"]="beszel"
)
#
# Module Beszel
#
function module_beszel () {
	local title="Beszel"
	local dockerimage="${module_options["module_beszel,dockerimage"]}"
	local dockername="${module_options["module_beszel,dockername"]}"
	local port="${module_options["module_beszel,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_beszel,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Run container — Beszel hub on port 8090 (its default).
			# --net=lsio so SWAG can resolve the container by name on
			# the LSIO bridge (LSIO ships a stock proxy-conf that
			# expects $upstream_app=beszel).
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e TZ="$(cat /etc/timezone)" \
				-p "${port}:8090" \
				-v "${base_dir}:/beszel_data" \
				--restart=always \
				"$dockerimage"

			# Auto-configure SWAG reverse proxy if available — best
			# effort. linuxserver/reverse-proxy-confs:master ships a
			# stock beszel.subfolder.conf.sample, but it assumes Beszel
			# is configured to serve at /beszel/. Beszel (PocketBase +
			# SvelteKit frontend) has no base-path support: the served
			# HTML emits absolute asset paths like /static/… and
			# /_app/…, so the browser asks SWAG for those at the root
			# and the page renders blank. We replace LSIO's stock
			# sample with one that strips /beszel/ at the upstream and
			# sub_filters the served HTML/CSS/JS so absolute asset
			# URLs are rewritten back to /beszel/-prefixed paths.
			# Subdomain proxying is the unbroken path; subfolder is
			# best-effort (runtime-built URLs in JS modules may still
			# 404). set/rewrite ordering matters — set vars must
			# precede `rewrite … break;`.
			if docker container ls -a --format "{{.Names}}" 2>/dev/null | grep -q "^swag$"; then
				docker exec swag rm -f \
					/config/nginx/proxy-confs/beszel.subfolder.conf \
					/config/nginx/proxy-confs/beszel.subfolder.conf.sample \
					/config/nginx/proxy-confs/beszel.subfolder.conf.enabled \
					2>/dev/null || true
			fi
			docker_seed_swag_proxy_conf "$dockername" <<- 'NGINX'
				## Custom Armbian seed — beszel subfolder proxy.
				## Best-effort: Beszel/PocketBase is not subpath-aware.
				## Subdomain proxying is the recommended path.
				location = /beszel { return 301 /beszel/; }

				location ^~ /beszel/ {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app beszel;
				set $upstream_port 8090;
				set $upstream_proto http;

				rewrite ^/beszel/(.*)$ /$1 break;

				proxy_pass $upstream_proto://$upstream_app:$upstream_port;

				## LSIO's proxy.conf (included above) already sets
				## proxy_read_timeout, the WebSocket Upgrade /
				## Connection headers, and proxy_http_version 1.1 —
				## redeclaring any of them here triggers nginx
				## 'duplicate directive' emerg errors and the reload
				## silently keeps the previous (broken) config.

				## sub_filter operates on uncompressed bytes only;
				## strip Accept-Encoding so the upstream returns plain
				## text we can rewrite.
				proxy_set_header Accept-Encoding "";

				sub_filter_once off;
				sub_filter_types text/html text/css application/javascript;
				sub_filter 'href="/'    'href="/beszel/';
				sub_filter "href='/"    "href='/beszel/";
				sub_filter 'src="/'     'src="/beszel/';
				sub_filter "src='/"     "src='/beszel/";
				sub_filter 'action="/'  'action="/beszel/';
				sub_filter 'url(/'      'url(/beszel/';
				}
			NGINX
			docker_configure_swag_proxy "$dockername" "8090"
			# Note: Beszel's own settings (Application URL) need to
			# be set to https://<swag-host>/beszel/ in the admin UI
			# after first login so emailed alerts and share links
			# line up; there's no bake-it-at-install env var for that.
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_beszel,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_beszel" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage\n\nLightweight monitoring hub. Install agents on monitored hosts via the web UI."
		;;
		*)
			${module_options["module_beszel,feature"]} ${commands[4]}
		;;
	esac
}
