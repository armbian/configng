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

			# When SWAG is on this host, tell Beszel its public URL via
			# APP_URL. Beszel parses the URL and derives BASE_PATH
			# (the path component) and HUB_URL (the full URL),
			# injecting both into the served index.html — without
			# this, the frontend JS builds API calls against / and
			# they 404 through the proxy. Subpath deployment is
			# officially supported (https://beszel.dev/guide/reverse-proxy);
			# with APP_URL set, LSIO's stock subfolder.conf works as-is.
			local -a beszel_extra_env=()
			if [[ -n "${SWAG_URL:-}" ]]; then
				beszel_extra_env+=(-e "APP_URL=https://${SWAG_URL}/beszel")
			fi

			# Run container — Beszel hub on port 8090 (its default).
			# --net=lsio so SWAG can resolve the container by name on
			# the LSIO bridge (LSIO ships a stock proxy-conf that
			# expects $upstream_app=beszel).
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e TZ="$(cat /etc/timezone)" \
				"${beszel_extra_env[@]}" \
				-p "${port}:8090" \
				-v "${base_dir}:/beszel_data" \
				--restart=always \
				"$dockerimage"

			# LSIO ships a stock beszel.subfolder.conf.sample that
			# works as-is once APP_URL is set on the container.
			docker_configure_swag_proxy "$dockername" "8090"
			# Note: Shoutrrr alert links use PocketBase's own
			# Application URL (Settings → Application URL in the
			# admin UI), which is independent of APP_URL. Set it to
			# https://<swag-host>/beszel after first login so emailed
			# alerts and share links line up.
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
