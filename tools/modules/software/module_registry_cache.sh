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
