module_options+=(
	["module_adguardhome,author"]="@igorpecovnik"
	["module_adguardhome,maintainer"]="@igorpecovnik"
	["module_adguardhome,feature"]="module_adguardhome"
	["module_adguardhome,example"]="install remove purge status help"
	["module_adguardhome,desc"]="Install adguardhome container"
	["module_adguardhome,status"]="Active"
	["module_adguardhome,doc_link"]="https://github.com/AdguardTeam/AdGuardHome/wiki"
	["module_adguardhome,group"]="DNS"
	["module_adguardhome,port"]="3000"
	["module_adguardhome,arch"]=""
	["module_adguardhome,dockerimage"]="adguard/adguardhome:latest"
	["module_adguardhome,dockername"]="adguardhome"
)
#
# Module AdGuard Home
#
function module_adguardhome () {
	local title="AdGuard Home"
	local dockerimage="${module_options["module_adguardhome,dockerimage"]}"
	local dockername="${module_options["module_adguardhome,dockername"]}"
	local port="${module_options["module_adguardhome,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_adguardhome,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/adguardhome"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Configure systemd-resolved before starting container
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi

			docker_operation_progress run "$dockername" \
				-d \
				--net=host \
				-p 53:53/tcp -p 53:53/udp \
				-p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp \
				-p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
				-v "${base_dir}/workdir:/opt/adguardhome/work" \
				-v "${base_dir}/confdir:/opt/adguardhome/conf" \
				--name "$dockername" \
				--restart=always \
				"$dockerimage"
			# Additional ports for advanced usage (uncomment if needed):
			#-p 67:67/udp -p 68:68/udp \ # DHCP server
			#-p 853:853/tcp \ # DNS-over-TLS
			#-p 5443:5443/tcp -p 5443:5443/udp \ # DNSCrypt
			# See: https://hub.docker.com/r/adguard/adguardhome

			# Add DNS configuration after container is running
			if srv_active systemd-resolved; then
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# Restore DNS settings
			if srv_active systemd-resolved; then
				rm -f /etc/systemd/resolved.conf.d/armbian-defaults.conf
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}") # purge
			${module_options["module_adguardhome,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_adguardhome" "$title" \
				"Web Interface: http://localhost:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_adguardhome,feature"]} ${commands[4]}
		;;
	esac
}
