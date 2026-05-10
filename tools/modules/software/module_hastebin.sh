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

			# Auto-configure SWAG reverse proxy if available — best
			# effort. Hastebin (haste-server fork) has no native
			# subpath support: its application.js calls /documents,
			# /raw/ and /about.md as absolute paths, and the inline
			# JS extracts the document key via
			# window.location.pathname.substring(1) — which under
			# /hastebin/<key> reads "hastebin/<key>" and breaks paste
			# viewing. We rewrite the absolute API paths in the JS
			# bundle so paste *creation* works, but viewing existing
			# pastes via /hastebin/<key> is broken without source
			# patches. Subdomain proxying is the recommended path.
			docker_seed_swag_proxy_conf "$dockername" <<- 'NGINX'
				## Custom Armbian seed — hastebin subfolder proxy.
				## Best-effort: hastebin is not subpath-aware. Paste
				## creation is functional; viewing /<key> is broken.
				## Subdomain proxying is the recommended path.
				location = /hastebin { return 301 /hastebin/; }

				location ^~ /hastebin/ {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app hastebin;
				set $upstream_port 7777;
				set $upstream_proto http;

				rewrite ^/hastebin/(.*)$ /$1 break;

				proxy_pass $upstream_proto://$upstream_app:$upstream_port;

				## sub_filter operates on uncompressed bytes only;
				## strip Accept-Encoding so the upstream returns
				## plain text we can rewrite.
				proxy_set_header Accept-Encoding "";

				sub_filter_once off;
				## text/html is always processed by default; listing it
				## here triggers a 'duplicate MIME type' nginx warn.
				sub_filter_types application/javascript text/css;
				## Rewrite the absolute API paths the haste-server JS
				## bundle uses, so they hit the proxy at /hastebin/…
				## (which then strips back to / for the upstream).
				sub_filter "'/documents'"  "'/hastebin/documents'";
				sub_filter '"/documents"'  '"/hastebin/documents"';
				sub_filter "'/raw/'"       "'/hastebin/raw/'";
				sub_filter '"/raw/"'       '"/hastebin/raw/"';
				sub_filter "'/about.md'"   "'/hastebin/about.md'";
				sub_filter '"/about.md"'   '"/hastebin/about.md"';
				}
			NGINX
			docker_configure_swag_proxy "$dockername" "7777"
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
