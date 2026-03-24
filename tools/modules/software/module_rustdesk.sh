module_options+=(
	["module_rustdesk,author"]="@armbian"
	["module_rustdesk,maintainer"]="@armbian"
	["module_rustdesk,feature"]="module_rustdesk"
	["module_rustdesk,example"]="install remove purge status help"
	["module_rustdesk,desc"]="Install RustDesk Server containers (hbbs/hbbr for self-hosted remote desktop)"
	["module_rustdesk,status"]="Active"
	["module_rustdesk,doc_link"]="https://github.com/rustdesk/rustdesk/wiki/Server"
	["module_rustdesk,group"]="Monitoring"
	["module_rustdesk,port"]="21114"
	["module_rustdesk,arch"]="x86-64 arm64"
	["module_rustdesk,dockerimage"]="rustdesk/rustdesk-server:latest"
	["module_rustdesk,dockername"]="rustdesk"
)

#
# Module RustDesk Server
#
function module_rustdesk () {
	local title="RustDesk Server"
	local dockerimage="${module_options["module_rustdesk,dockerimage"]}"
	local dockername="${module_options["module_rustdesk,dockername"]}"
	local port="${module_options["module_rustdesk,port"]}"
	local base_dir="/armbian/rustdesk"

	# RustDesk server components
	local hbbs_name="rustdesk-hbbs"
	local hbbr_name="rustdesk-hbbr"
	local hbbs_port="21114"
	local hbbr_port="21117"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_rustdesk,example"]}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$hbbs_name" "$dockerimage"; then
				return 0
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Create base directory for keys and data
			docker_manage_base_dir create "$base_dir" || return 1

			# Generate key pair for hbbs (ID server)
			if [[ ! -f "$base_dir/id_ed25519" ]]; then
				dialog_msgbox "Generating Keys" "Generating RustDesk server key pair...\n\nThis will create secure keys for the RustDesk ID server (hbbs) and relay server (hbbr)." 8 60
				docker run --rm -v "$base_dir:/data" "$dockerimage" hbbs -g > "$base_dir/id_server.txt" 2>/dev/null || true
			fi

			# Run hbbs (ID/Rendezvous server)
			docker_operation_progress run "$hbbs_name" \
				-d \
				--name "$hbbs_name" \
				--net lsio \
				-v "$base_dir:/data" \
				-p "${hbbs_port}:21114" \
				-p "21115:21115" \
				-p "21116:21116" \
				--restart unless-stopped \
				"$dockerimage" hbbs -r "$hbbr_name:21117" --key "$base_dir/id_ed25519"

			# Run hbbr (Relay server)
			docker_operation_progress run "$hbbr_name" \
				-d \
				--name "$hbbr_name" \
				--net lsio \
				-v "$base_dir:/data" \
				-p "${hbbr_port}:21117" \
				--restart unless-stopped \
				"$dockerimage" hbbr --key "$base_dir/id_ed25519"

			# Wait for containers to be ready
			wait_for_container_ready "$hbbs_name" 30 3 "running"
			wait_for_container_ready "$hbbr_name" 30 3 "running"
			;;
		"${commands[1]}") # remove
			# Remove both containers and image
			docker_operation_progress rm "$hbbs_name"
			docker_operation_progress rm "$hbbr_name"
			docker_operation_progress rmi "$dockerimage"
			;;
		"${commands[2]}") # purge
			# Remove containers and image first
			if ! ${module_options["module_rustdesk,feature"]} ${commands[1]}; then
				return 1
			fi
			# Remove data directory with keys
			docker_manage_base_dir remove "$base_dir"
			;;
		"${commands[3]}") # status
			# Return 0 if both containers are installed
			docker_is_installed "$hbbs_name" "$dockerimage" && docker_is_installed "$hbbr_name" "$dockerimage"
			;;
		"${commands[4]}") # help
			show_module_help "module_rustdesk" "$title" \
				"Docker Image: $dockerimage\n\nComponents:\n- hbbs (ID Server): Port $hbbs_port\n- hbbr (Relay Server): Port $hbbr_port\n\nRustDesk Server enables self-hosted remote desktop connectivity without relying on public servers."
			;;
		*)
			${module_options["module_rustdesk,feature"]} ${commands[4]}
			;;
	esac
}
