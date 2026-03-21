module_options+=(
	["module_pi_hole,author"]="@armbian"
	["module_pi_hole,maintainer"]="@igorpecovnik"
	["module_pi_hole,feature"]="module_pi_hole"
	["module_pi_hole,example"]="install remove purge password status help"
	["module_pi_hole,desc"]="Install Pi-hole container"
	["module_pi_hole,status"]="Active"
	["module_pi_hole,doc_link"]="https://docs.pi-hole.net/"
	["module_pi_hole,group"]="DNS"
	["module_pi_hole,port"]="8811"
	["module_pi_hole,arch"]="x86-64 arm64"
	["module_pi_hole,dockerimage"]="pihole/pihole:latest"
	["module_pi_hole,dockername"]="pihole"
)
#
# Module Pi-Hole
#
function module_pi_hole () {
	local title="Pi-hole"
	local dockerimage="${module_options["module_pi_hole,dockerimage"]}"
	local dockername="${module_options["module_pi_hole,dockername"]}"
	local port="${module_options["module_pi_hole,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_pi_hole,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}")
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Ensure unbound dependency
			if ! docker_is_installed "unbound" "alpinelinux/unbound"; then
				module_unbound install
			fi

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Configure systemd-resolved if not already done
			[[ ! -f "/etc/systemd/resolved.conf.d/armbian-defaults.conf" ]] && ${module_options["module_pi_hole,feature"]} ${commands[1]}

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-p 53:53/tcp \
				-p 53:53/udp \
				-p "${port}:80" \
				-e TZ="$(cat /etc/timezone)" \
				-e PIHOLE_UID="${DOCKER_USERUID}" \
				-e PIHOLE_GID="${DOCKER_GROUPUID}" \
				-v "${base_dir}/etc-pihole:/etc/pihole" \
				-v "${base_dir}/etc-dnsmasq.d:/etc/dnsmasq.d" \
				--dns=9.9.9.9 \
				--restart=unless-stopped \
				--hostname pi.hole \
				-e VIRTUAL_HOST="pi.hole" \
				-e PROXY_LOCATION="pi.hole" \
				-e FTLCONF_LOCAL_IPV4="${LOCALIPADD}" \
				-e FTLCONF_dns_upstreams="unbound#5335" \
				"$dockerimage"

			local container_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' "$dockername")
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1 ${container_ip}
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
			${module_options["module_pi_hole,feature"]} ${commands[3]}
		;;
		"${commands[1]}")
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"

			# restore DNS settings
			if srv_active systemd-resolved; then
				rm -f /etc/systemd/resolved.conf.d/armbian-defaults.conf
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}")
			${module_options["module_pi_hole,feature"]} ${commands[1]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}")
			local container=$(docker_get_container_id "$dockername")
			if [[ -n "${container}" ]]; then
				SELECTED_PASSWORD=$(dialog_passwordbox "Enter new password for Pi-hole admin" "" 7 50)
				if [[ -n $SELECTED_PASSWORD ]]; then
					docker exec -it "$dockername" pihole setpassword "${SELECTED_PASSWORD}"
				fi
			else
				dialog_msgbox "Not Running" "$title container is not running.\n\nPlease install $title first." 10 50
			fi
		;;
		"${commands[4]}")
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[5]}")
			docker_show_module_help "module_pi_hole" "$title" \
				"Web Interface: http://pi.hole:${port}\nDocker Image: $dockerimage"
		;;
		*)
			${module_options["module_pi_hole,feature"]} ${commands[5]}
		;;
	esac
}

