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

			# Auto-configure SWAG reverse proxy if available — best
			# effort. linuxserver/reverse-proxy-confs:master doesn't
			# ship an uptime-kuma sample, and Uptime Kuma itself has
			# no subpath support — its app uses absolute URLs and a
			# Socket.IO connection for live updates. We rewrite at
			# the proxy and sub_filter the literal absolute paths in
			# the served HTML/CSS/JS, plus pass through the WebSocket
			# upgrade. Runtime-built URLs (template literals, fetch
			# calls inside JS modules) will still target / and may
			# 404 against SWAG. Subdomain proxying is the unbroken
			# path; subfolder is best-effort. set/rewrite ordering
			# matters — set vars must precede rewrite … break;.
			docker_seed_swag_proxy_conf "uptime-kuma" <<- 'NGINX'
				## Custom Armbian seed — uptime-kuma subfolder proxy.
				## Best-effort: Uptime Kuma is not subpath-aware.
				## Subdomain proxying is the recommended path.
				location = /uptime-kuma { return 301 /uptime-kuma/; }

				location ^~ /uptime-kuma/ {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app uptime-kuma;
				set $upstream_port 3001;
				set $upstream_proto http;

				rewrite ^/uptime-kuma/(.*)$ /$1 break;

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
				sub_filter 'href="/'    'href="/uptime-kuma/';
				sub_filter "href='/"    "href='/uptime-kuma/";
				sub_filter 'src="/'     'src="/uptime-kuma/';
				sub_filter "src='/"     "src='/uptime-kuma/";
				sub_filter 'action="/'  'action="/uptime-kuma/';
				sub_filter 'url(/'      'url(/uptime-kuma/';
				}
			NGINX
			docker_configure_swag_proxy "uptime-kuma" "3001"
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
