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
			# --net=lsio so SWAG (on the same bridge) can reach
			# upstream by container name; otherwise the proxy-conf's
			# `proxy_pass http://octoprint:80` would fail to resolve.
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-v "${base_dir}:/octoprint/octoprint" \
				$device_params \
				-e TZ="$(cat /etc/timezone)" \
				-e ENABLE_MJPG_STREAMER=true \
				-p "${port}:80" \
				--restart=always \
				"$dockerimage"

			# Auto-configure SWAG reverse proxy if available.
			# linuxserver/reverse-proxy-confs:master doesn't ship an
			# octoprint sample, so seed our own first. The conf
			# rewrites /octoprint/* to /* on the upstream side and
			# sets X-Script-Name so OctoPrint emits URLs with the
			# /octoprint prefix.
			docker_seed_swag_proxy_conf "octoprint" <<- 'NGINX'
				## Custom Armbian seed — octoprint subfolder proxy.
				## set/rewrite ordering matters: `rewrite … break;`
				## ends the rewrite-module phase, and `set` lives in
				## that same phase. Any `set` *after* the break is
				## silently skipped at request time, leaving
				## $upstream_* empty and proxy_pass rendering "://:".
				## Always declare set vars first.
				location ^~ /octoprint {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app octoprint;
				set $upstream_port 80;
				set $upstream_proto http;

				rewrite ^/octoprint/?(.*)$ /$1 break;

				proxy_pass $upstream_proto://$upstream_app:$upstream_port;

				proxy_set_header X-Script-Name /octoprint;
				proxy_set_header X-Scheme $scheme;
				}
			NGINX
			# Restart octoprint after the SWAG conf is in place. On a
			# first install the container started under the old proxy
			# state (or none) and gets stuck on "Loading OctoPrint's
			# UI"; a restart picks up the X-Script-Name path and the
			# UI loads correctly. No-op if the container isn't running
			# (e.g. SWAG-less host where the seed/configure steps both
			# returned non-zero).
			if docker container ls --format '{{.Names}}' 2>/dev/null | grep -q "^${dockername}$"; then
				docker restart "$dockername" >/dev/null 2>&1 || true
			fi
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
