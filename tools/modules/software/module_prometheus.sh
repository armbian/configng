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

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port}:9090" \
				-v "${base_dir}:/etc/prometheus" \
				--restart=always \
				"$dockerimage"
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
