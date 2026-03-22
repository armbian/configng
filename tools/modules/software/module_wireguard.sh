module_options+=(
	["module_wireguard,author"]="@armbian"
	["module_wireguard,maintainer"]="@igorpecovnik"
	["module_wireguard,feature"]="module_wireguard"
	["module_wireguard,example"]="install client server remove purge qrcode status help"
	["module_wireguard,desc"]="Install wireguard container"
	["module_wireguard,status"]="Active"
	["module_wireguard,doc_link"]="https://docs.linuxserver.io/images/docker-wireguard/#server-mode"
	["module_wireguard,group"]="Network"
	["module_wireguard,port"]="51820"
	["module_wireguard,arch"]="x86-64 arm64"
	["module_wireguard,dockerimage"]="lscr.io/linuxserver/wireguard:latest"
	["module_wireguard,dockername"]="wireguard"
)

#
# Module wireguard
#
function module_wireguard () {
	local title="WireGuard"
	local dockerimage="${module_options["module_wireguard,dockerimage"]}"
	local dockername="${module_options["module_wireguard,dockername"]}"
	local port="${module_options["module_wireguard,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wireguard,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}")
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create the base and config directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "$base_dir/config/wg_confs/" || { echo "Couldn't create config directory: $base_dir/config/wg_confs/"; exit 1; }
		;;
		"${commands[1]}")
			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			# Create temp file
			local TMP_FILE=$(mktemp)

			# Optional initial content
			if [[ -f "${base_dir}/config/wg_confs/client.conf" ]]; then
				cp "${base_dir}/config/wg_confs/client.conf" "$TMP_FILE"
			else
				echo "# WireGuard client configuration file" > "$TMP_FILE"
			fi

			# Ask user to edit content
			${EDITOR:-nano} "$TMP_FILE"

			# Use `install` to move the file with correct owner and permissions
			rm -f "${base_dir}/config/wg_confs/wg0.conf"
			install -m 600 -o "${DOCKER_USERUID}" -g "${DOCKER_GROUPUID}" "$TMP_FILE" "${base_dir}/config/wg_confs/client.conf"
			rm -f "$TMP_FILE"

			# Check if the container is running, if so, remove it
			${module_options["module_wireguard,feature"]} ${commands[6]}
			if [[ $? -eq 0 ]]; then
				docker_operation_progress rm "$dockername"
			fi

			# Get local subnets from user input or use default
			if [[ -z $2 ]]; then
			LOCAL_SUBNETS=$(dialog_inputbox "Enter comma delimited subnets for routing" "\n* delete if this is not your local subnet \n" "10.0.10.0/24" 9 70)
			else
				LOCAL_SUBNETS="$2"
			fi

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE \
				--privileged \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-v "${base_dir}/config:/config" \
				--restart unless-stopped \
				--sysctl net.ipv4.ip_forward=1 \
				"$dockerimage"

			wait_for_container_ready "$dockername" 20 3 "running" '[[ -f "${base_dir}/config/wg_confs/client.conf" ]]' || exit 1
			if [[ -n "${LOCAL_SUBNETS}" ]]; then
				# Create host-side route helper script for LAN routing via WireGuard container
				cat > "/usr/local/bin/add-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash

				docker exec "$dockername" iptables -t nat -A POSTROUTING -o client -j MASQUERADE

				# Get the IP address of the WireGuard container dynamically
				CONTAINER_IP=\$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$dockername")

				if [[ -z "\$CONTAINER_IP" ]]; then
					echo "WireGuard container not found or not running"
					exit 1
				fi

				echo "Adding LAN routes via container IP: \$CONTAINER_IP"

				# Add route for specific LAN subnets (customize as needed)
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route add $subnet via \"\$CONTAINER_IP\"" >> /usr/local/bin/add-vpn-lan-routes.sh
				done

				cat > "/usr/local/bin/remove-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash
				docker exec "$dockername" iptables -t nat -C POSTROUTING -o client -j MASQUERADE 2>/dev/null && \
				docker exec "$dockername" iptables -t nat -D POSTROUTING -o client -j MASQUERADE || true
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route show \"$subnet\" | grep -q \"$subnet\" && ip route del \"$subnet\" || true" >> /usr/local/bin/remove-vpn-lan-routes.sh
				done

				chmod +x /usr/local/bin/add-vpn-lan-routes.sh
				chmod +x /usr/local/bin/remove-vpn-lan-routes.sh

				cat > "/etc/systemd/system/add-vpn-lan-routes.service" <<- EOT
				[Unit]
				Description=Add routes for LAN via WireGuard Docker container
				After=network-online.target docker.service
				Wants=network-online.target

				[Service]
				Type=oneshot
				ExecStart=/usr/local/bin/add-vpn-lan-routes.sh
				RemainAfterExit=yes

				[Install]
				WantedBy=multi-user.target
				EOT

				# Remove routes just in case they were added before
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true

				systemctl daemon-reexec
				systemctl daemon-reload
				systemctl enable add-vpn-lan-routes.service
				systemctl restart add-vpn-lan-routes.service
			fi
		;;
		"${commands[2]}")
			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			local dialog_rc
			if [[ -z $2 ]]; then
				NUMBER_OF_PEERS=$(dialog_inputbox "Enter comma delimited peer keywords" "Valid characters: letters, numbers, hyphens, underscores" "laptop" 9 70)
				dialog_rc=$?
			else
				NUMBER_OF_PEERS="$2"
				dialog_rc=0
			fi
			if [[ $dialog_rc -eq 0 ]]; then
				# Validate peer names - reject spaces, newlines, and special characters
				# First, remove all newlines, carriage returns, and extra spaces from the input
				NUMBER_OF_PEERS=$(echo "$NUMBER_OF_PEERS" | tr -d '\n\r' | tr -s ' ')

				# Check for common help text patterns that might have been accidentally captured
				if [[ "$NUMBER_OF_PEERS" =~ --help ]] || [[ "$NUMBER_OF_PEERS" =~ usage ]] || [[ "$NUMBER_OF_PEERS" =~ Usage ]]; then
					dialog_msgbox "Error" "Invalid input: Help text detected\n\nPlease enter only comma-separated peer names without any additional text or commands.\n\nExample: laptop,desktop,phone" 10 60
					exit 1
				fi

				# Split by comma and validate each peer name
				IFS=',' read -ra peers_array <<< "$NUMBER_OF_PEERS"
				for peer in "${peers_array[@]}"; do
					# Trim leading and trailing whitespace more safely
					peer="${peer#"${peer%%[![:space:]]*}"}"
					peer="${peer%"${peer##*[![:space:]]}"}"
					# Skip empty peer names
					[[ -z "$peer" ]] && continue
					# Check for invalid characters (spaces, special chars except hyphen and underscore)
					if [[ ! "$peer" =~ ^[a-zA-Z0-9_-]+$ ]]; then
						dialog_msgbox "Error" "Invalid peer name: '$peer'\n\nPeer names must contain only:\n  - Letters (a-z, A-Z)\n  - Numbers (0-9)\n  - Hyphens (-)\n  - Underscores (_)\n\nSpaces, newlines and special characters are not allowed." 11 60
						exit 1
					fi
				done
				${module_options["module_wireguard,feature"]} ${commands[6]}
				if [[ $? -eq 0 ]]; then
					docker_operation_progress rm "$dockername"
				fi

				# Remove client config if any
				rm -f "${base_dir}/config/wg_confs/client.conf"

				docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e SERVERURL=auto \
				-e SERVERPORT=$port \
				-e PEERS="${NUMBER_OF_PEERS}" \
				-e PEERDNS=auto \
				-e INTERNAL_SUBNET=10.13.13.0 \
				-e ALLOWEDIPS=0.0.0.0/0 \
				-e PERSISTENTKEEPALIVE_PEERS= \
				-e LOG_CONFS=true \
				-p $port:51820/udp \
				-v "${base_dir}/config:/config" \
				--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
				--restart unless-stopped \
				"$dockerimage"

			wait_for_container_ready "$dockername" 20 3 "running" '[[ -f "${base_dir}/config/wg_confs/wg0.conf" ]]' || exit 1

				# Wait for peer configs to be created by the container
				local peer_wait_count=0
				local max_peer_wait=10
				while [[ $peer_wait_count -lt $max_peer_wait ]]; do
					peer_count=$(find "${base_dir}/config/" -name "peer_*.conf" -type f 2>/dev/null | wc -l)
					if [[ $peer_count -gt 0 ]]; then
						break
					fi
					sleep 1
					((peer_wait_count++))
				done

				${module_options["module_wireguard,feature"]} ${commands[5]}
			fi
		;;
		"${commands[3]}")
			if srv_active add-vpn-lan-routes; then
				srv_stop add-vpn-lan-routes.service
				srv_disable add-vpn-lan-routes.service
			fi
			# Run route removal script only if it exists, ignore errors
			if [[ -f "/usr/local/bin/remove-vpn-lan-routes.sh" ]]; then
				bash /usr/local/bin/remove-vpn-lan-routes.sh || true
			fi
			# Remove files
			rm -f /usr/local/bin/add-vpn-lan-routes.sh
			rm -f /usr/local/bin/remove-vpn-lan-routes.sh
			rm -f /etc/systemd/system/add-vpn-lan-routes.service
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[4]}")
			${module_options["module_wireguard,feature"]} ${commands[3]}
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[5]}")
		if [[ -z $2 ]]; then
			local LIST=()
			# Find all peer config files recursively
			while IFS= read -r -d '' peer_conf; do
				peer="${peer_conf#peer_}"
				peer="${peer%.conf}"
				[[ -n "$peer" ]] && LIST+=("$peer" "$peer")
			done < <(find "${base_dir}/config/" -name "peer_*.conf" -type f -printf "%f\0")
			local LIST_LENGTH=$((${#LIST[@]} / 2))

				# Check if there are any peers to display
				if [[ $LIST_LENGTH -eq 0 ]]; then
					dialog_msgbox "No peers found" "No WireGuard peer configs found.\n\nPlease create a server configuration first:\n  ${module_options["module_wireguard,feature"]} server <peer_names>" 10 60
					return 0
				fi
			local SELECTED_PEER=$(dialog_menu "Select peer" "" $((${LIST_LENGTH} + 8)) 60 ${LIST_LENGTH} -- "${LIST[@]}")
		else
			local SELECTED_PEER="$2"
		fi
			if [[ -n ${SELECTED_PEER} ]]; then
				# Validate peer name to prevent command injection
				if [[ ! "${SELECTED_PEER}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
					dialog_msgbox "Error" "Invalid peer name: '${SELECTED_PEER}'\n\nPeer names must contain only letters, numbers, hyphens, and underscores." 10 60
					return 1
				fi
				clear
				docker exec -it "$dockername" /app/show-peer "${SELECTED_PEER}"
				cat "${base_dir}/config/peer_${SELECTED_PEER}/peer_${SELECTED_PEER}.conf"
				read
			fi
		;;
		"${commands[6]}")
			if [[ "$2" == server && -f "${base_dir}/config/wg_confs/client.conf" ]]; then
				return 1
			fi
			docker_is_installed "wireguard" "lscr.io/linuxserver/wireguard"
		;;
		"${commands[7]}")
			show_module_help "module_wireguard" "$title" \
				"Port: $port (UDP)"
		;;
		*)
			${module_options["module_wireguard,feature"]} ${commands[7]}
		;;
	esac
}
