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

			# Auto-configure SWAG reverse proxy if available.
			# linuxserver/reverse-proxy-confs:master ships a stock
			# beszel.subfolder.conf.sample, but it assumes Beszel
			# itself is configured to serve at /beszel/ — Beszel
			# (PocketBase under the hood) doesn't actually support a
			# base path, so /beszel/ reaches upstream as /beszel/ and
			# Beszel returns nothing. Inject a rewrite into the live
			# conf so the upstream sees /.
			docker_configure_swag_proxy "$dockername" "8090"
			if docker container ls -a --format "{{.Names}}" 2>/dev/null | grep -q "^swag$" \
				&& docker exec swag test -f /config/nginx/proxy-confs/beszel.subfolder.conf 2>/dev/null \
				&& ! docker exec swag grep -q "rewrite \^/beszel/" /config/nginx/proxy-confs/beszel.subfolder.conf 2>/dev/null; then
				# Idempotent: only inject if the rewrite isn't there
				# already. Place after the last `set $upstream_proto`
				# line so the set vars are still defined when proxy_pass
				# evaluates the upstream URL.
				docker exec swag sed -i '/set \$upstream_proto/a\\trewrite ^/beszel/(.*)$ /$1 break;' \
					/config/nginx/proxy-confs/beszel.subfolder.conf 2>/dev/null || true
				docker exec swag nginx -s reload >/dev/null 2>&1 || true
			fi
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
