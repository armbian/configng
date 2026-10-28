module_options+=(
	["module_shlink,author"]="@igorpecovnik"
	["module_shlink,maintainer"]="@igorpecovnik"
	["module_shlink,feature"]="module_shlink"
	["module_shlink,example"]="install remove purge status help"
	["module_shlink,desc"]="Install Shlink URL shortener container"
	["module_shlink,status"]="Active"
	["module_shlink,doc_link"]="https://shlink.io/documentation/"
	["module_shlink,group"]="WebHosting"
	["module_shlink,port"]="8085"
	["module_shlink,arch"]="x86-64 arm64"
	["module_shlink,dockerimage"]="shlinkio/shlink:stable"
	["module_shlink,dockername"]="shlink"
)
#
# Module Shlink
#
# Shlink is a self-hosted URL shortener with a REST API. Data is stored in
# SQLite. The short domain and the API key are kept in shlink.env, so a
# reinstall keeps them.
#
function module_shlink () {
	local title="Shlink"
	local dockerimage="${module_options["module_shlink,dockerimage"]}"
	local dockername="${module_options["module_shlink,dockername"]}"
	local port="${module_options["module_shlink,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_shlink,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/shlink"
	local data_dir="${base_dir}/data"
	local env_file="${base_dir}/shlink.env"

	case "$1" in
		"${commands[0]}") # install
			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# The container runs as uid 1001
			mkdir -p "$data_dir" && chown 1001:1001 "$data_dir" || return 1

			if [[ ! -f "$env_file" ]]; then
				# SHLINK_DOMAIN skips the question in unattended installs
				local domain="${SHLINK_DOMAIN:-}"
				# Ask on a terminal only. Cancel stops the install.
				if [[ -z "$domain" && -t 0 ]]; then
					domain=$(dialog_inputbox "$title short domain" \
						"\nDomain of the short links, e.g. go.example.com.\nKeep the default to use it on the local network." \
						"${LOCALIPADD}:${port}" 11 70) || return 1
				fi
				# Accept host[:port] only. Empty means the local default.
				domain="${domain#*://}"
				domain="${domain%%/*}"
				domain="${domain:-${LOCALIPADD}:${port}}"
				if [[ ! "$domain" =~ ^[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
					echo "Invalid Shlink domain: ${domain}" >&2
					dialog_msgbox "$title" "\nInvalid domain: ${domain}\n\nUse host or host:port, e.g. go.example.com." 9 60
					return 1
				fi
				# A domain without a port is served over HTTPS by a reverse proxy
				local https="true"
				[[ "$domain" == *:* ]] && https="false"
				local api_key
				api_key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
				install -m 600 /dev/null "$env_file"
				cat > "$env_file" <<- EOT
				DEFAULT_DOMAIN=${domain}
				IS_HTTPS_ENABLED=${https}
				INITIAL_API_KEY=${api_key}
				EOT
			fi

			# Behind a reverse proxy (HTTPS), publish on localhost only.
			# SWAG reaches the container over the lsio network.
			local publish="${port}:8080"
			grep -q '^IS_HTTPS_ENABLED=true' "$env_file" && publish="127.0.0.1:${port}:8080"

			# Run container
			docker_operation_progress run "$dockername" \
				-d \
				--net=lsio \
				--name "$dockername" \
				--restart=unless-stopped \
				--env-file "$env_file" \
				-e TZ="${TZ:-Etc/UTC}" \
				-p "$publish" \
				-v "${data_dir}:/etc/shlink/data" \
				"$dockerimage"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername" || return 1
			docker_operation_progress rmi "$dockerimage" || return 1
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_shlink,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_shlink" "$title" \
				"Docker Image: $dockerimage\nPort: $port\nSettings and API key: ${env_file}\nData: ${data_dir}"
		;;
		*)
			${module_options["module_shlink,feature"]} ${commands[4]}
		;;
	esac
}
