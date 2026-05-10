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

			# Args after the image name REPLACE the prom/prometheus
			# default CMD wholesale (config.file, storage.tsdb.path,
			# console libraries / templates). To add anything we have
			# to redeclare those defaults, otherwise Prometheus starts
			# without --config.file, doesn't pick up the mounted
			# prometheus.yml, and SWAG returns 502.
			local -a prometheus_args=(
				"--config.file=/etc/prometheus/prometheus.yml"
				"--storage.tsdb.path=/prometheus"
				"--web.console.libraries=/usr/share/prometheus/console_libraries"
				"--web.console.templates=/usr/share/prometheus/consoles"
			)
			# When SWAG is on this host, tell Prometheus its external
			# URL so the rendered HTML, redirects, and API responses
			# use the /prometheus subpath. SWAG below rewrites
			# /prometheus/(.*) → /$1 at the proxy, so internally
			# Prometheus stays at route-prefix=/ — that keeps direct
			# port access working too.
			if docker container ls -a --format "{{.Names}}" 2>/dev/null | grep -q "^swag$" \
				&& [[ -n "${SWAG_URL:-}" ]]; then
				prometheus_args+=(
					"--web.external-url=https://${SWAG_URL}/prometheus/"
					"--web.route-prefix=/"
				)
			fi

			# Run container — prometheus_args go after the image name,
			# they're CMD overrides for the entrypoint.
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port}:9090" \
				-v "${base_dir}:/etc/prometheus" \
				--restart=always \
				"$dockerimage" \
				"${prometheus_args[@]}"

			# Auto-configure SWAG reverse proxy if available.
			# linuxserver/reverse-proxy-confs:master doesn't ship a
			# prometheus sample, so seed our own. set/rewrite ordering
			# matters: any `set` after `rewrite … break;` is silently
			# skipped at request time and proxy_pass renders "://:".
			docker_seed_swag_proxy_conf "prometheus" <<- 'NGINX'
				## Custom Armbian seed — prometheus subfolder proxy.
				location ^~ /prometheus {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app prometheus;
				set $upstream_port 9090;
				set $upstream_proto http;

				rewrite ^/prometheus/?(.*)$ /$1 break;

				proxy_pass $upstream_proto://$upstream_app:$upstream_port;
				}
			NGINX
			docker_configure_swag_proxy "prometheus" "9090"
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
