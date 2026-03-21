module_options+=(
	["module_stirling,author"]="@Frooodle"
	["module_stirling,maintainer"]="@igorpecovnik"
	["module_stirling,feature"]="module_stirling"
	["module_stirling,example"]="install remove purge status help"
	["module_stirling,desc"]="Install stirling container"
	["module_stirling,status"]="Active"
	["module_stirling,doc_link"]="https://docs.stirlingpdf.com"
	["module_stirling,group"]="Media"
	["module_stirling,port"]="8075"
	["module_stirling,arch"]="x86-64 arm64"
	["module_stirling,dockerimage"]="stirlingtools/stirling-pdf:latest"
	["module_stirling,dockername"]="stirling-pdf"
)
#
# Module stirling-PDF
#
function module_stirling () {
	local title="Stirling PDF"
	local dockerimage="${module_options["module_stirling,dockerimage"]}"
	local dockername="${module_options["module_stirling,dockername"]}"
	local port="${module_options["module_stirling,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_stirling,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/stirling"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Create subdirectories
			mkdir -p "${base_dir}/trainingData" "${base_dir}/extraConfigs" "${base_dir}/logs" "${base_dir}/customFiles"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p "${port}:8080" \
				-v "${base_dir}/trainingData:/usr/share/tessdata" \
				-v "${base_dir}/extraConfigs:/configs" \
				-v "${base_dir}/logs:/logs" \
				-v "${base_dir}/customFiles:/customFiles" \
				-e DOCKER_ENABLE_SECURITY=false \
				-e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
				-e LANGS=en_GB \
				--restart=always \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_stirling,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_stirling" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_stirling,feature"]} ${commands[4]}
		;;
	esac
}
