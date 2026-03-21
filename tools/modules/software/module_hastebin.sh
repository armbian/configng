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
			docker_show_module_help "module_hastebin" "$title" \
				"Docker Image: $dockerimage\nPort: $port"
		;;
		*)
			${module_options["module_hastebin,feature"]} ${commands[4]}
		;;
	esac
}
