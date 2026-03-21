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
