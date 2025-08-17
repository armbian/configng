module_options+=(
	["module_wireguard,author"]="@armbian"
	["module_wireguard,maintainer"]="@igorpecovnik"
	["module_wireguard,feature"]="module_wireguard"
	["module_wireguard,example"]="pull client server remove purge qrcode image container servermode help"
	["module_wireguard,desc"]="Install wireguard container"
	["module_wireguard,status"]="Active"
	["module_wireguard,doc_link"]="https://docs.linuxserver.io/images/docker-wireguard/#server-mode"
	["module_wireguard,group"]="Network"
	["module_wireguard,port"]="51820"
	["module_wireguard,arch"]="x86-64 arm64"
)
#
# Module wireguard
#
function module_wireguard () {
	local title="wireguard"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_wireguard,example"]}"

	WIREGUARD_BASE="${SOFTWARE_FOLDER}/wireguard"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			pkg_installed docker-ce || module_docker install

			# Create the base and config directory if it doesn't exist
			[[ -d "$WIREGUARD_BASE" ]] || mkdir -p "$WIREGUARD_BASE" || { echo "Couldn't create storage directory: $WIREGUARD_BASE"; exit 1; }
			[[ -d "$WIREGUARD_BASE/config/wg_confs/" ]] || mkdir -p "$WIREGUARD_BASE/config/wg_confs/" || { echo "Couldn't create config directory: $WIREGUARD_BASE/config/wg_confs/"; exit 1; }

			# Check if the image is already pulled
			${module_options["module_wireguard,feature"]} ${commands[6]}
			if [[ $? -ne 0 ]]; then
				docker pull lscr.io/linuxserver/wireguard:latest || { echo "Couldn't pull image: lscr.io/linuxserver/wireguard:latest"; exit 1; }
			fi
		;;
		"${commands[1]}")

			# Pull the image if not already done
			${module_options["module_wireguard,feature"]} ${commands[0]}

			# Create temp file
			TMP_FILE=$(mktemp)

			# Optional initial content
			if [[ -f "${WIREGUARD_BASE}/config/wg_confs/client.conf" ]]; then
				cp "${WIREGUARD_BASE}/config/wg_confs/client.conf" "$TMP_FILE"
			else
				echo "# WireGuard client configuration file" > "$TMP_FILE"
			fi

			# Ask user to edit content
			${EDITOR:-nano} "$TMP_FILE"

			# Use `install` to move the file with correct owner and permissions
			rm -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf"
			install -m 600 -o 1000 -g 1000 "$TMP_FILE" "${WIREGUARD_BASE}/config/wg_confs/client.conf"
			rm -f "$TMP_FILE"

			# Check if the container is running, if so, remove it
			${module_options["module_wireguard,feature"]} ${commands[7]}
			if [[ $? -eq 0 ]]; then
				docker rm -f wireguard >/dev/null 2>&1
			fi

			# Get local subnets from user input or use default
			if [[ -z $2 ]]; then
				LOCAL_SUBNETS=$($DIALOG --title "Enter comma delimited subnets for routing" --inputbox "\n* delete if this is not your local subnet \n" 9 70 "10.0.10.0/24" 3>&1 1>&2 2>&3)
			else
				LOCAL_SUBNETS="$2"
			fi

			docker run -d \
			--name=wireguard \
			--net=lsio \
			--cap-add=NET_ADMIN \
			--cap-add=SYS_MODULE \
			--privileged \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-v "${WIREGUARD_BASE}/config:/config" \
			--restart unless-stopped \
			--sysctl net.ipv4.ip_forward=1 \
			lscr.io/linuxserver/wireguard:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard >/dev/null 2>&1 && [[ -f "${WIREGUARD_BASE}/config/wg_confs/client.conf" ]]; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs wireguard\`)"
					exit 1
				fi
			done
			if [[ -n "${LOCAL_SUBNETS}" ]]; then
				# Create host-side route helper script for LAN routing via WireGuard container
				cat > "/usr/local/bin/add-vpn-lan-routes.sh" <<- EOT
				#!/bin/bash

				docker exec wireguard iptables -t nat -A POSTROUTING -o client -j MASQUERADE

				# Get the IP address of the WireGuard container dynamically
				CONTAINER_IP=\$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' wireguard)

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
				docker exec wireguard iptables -t nat -C POSTROUTING -o client -j MASQUERADE 2>/dev/null && \
				docker exec wireguard iptables -t nat -D POSTROUTING -o client -j MASQUERADE || true
				EOT
				# Loop through each subnet and append a route command
				IFS=',' read -ra SUBNETS <<< "$LOCAL_SUBNETS"
				for subnet in "${SUBNETS[@]}"; do
					echo "ip route show \"$subnet\" | grep -q \"$subnet\" && ip route del \"$subnet\" || true" >> /usr/local/bin/remove-vpn-lan-routes.sh
				done

				chmod +x /usr/local/bin/add-vpn-lan-routes.sh
				chmod +x /usr/local/bin/remove-vpn-lan-routes.sh

				echo -e "\n✅ Created: /usr/local/bin/add-vpn-lan-routes.sh"
				echo -e "Run this script to restore LAN routes via the WireGuard container."

				echo -e "\n✅ Created: /usr/local/bin/remove-vpn-lan-routes.sh"
				echo -e "Run this script to remove LAN routes via the WireGuard container."

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

			if [[ -z $2 ]]; then
				NUMBER_OF_PEERS=$($DIALOG --title "Enter comma delimited peer keywords" --inputbox " \n" 7 50 "laptop" 3>&1 1>&2 2>&3)
			fi
			if [[ $? -eq 0 ]]; then
				${module_options["module_wireguard,feature"]} ${commands[7]}
				if [[ $? -eq 0 ]]; then
					docker rm -f wireguard >/dev/null 2>&1
				fi

				# Remove client config if any
				rm -f "${WIREGUARD_BASE}/config/wg_confs/client.conf"

				docker run -d \
				--name=wireguard \
				--net=lsio \
				--cap-add=NET_ADMIN \
				--cap-add=SYS_MODULE `#optional` \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e SERVERURL=auto \
				-e SERVERPORT=51820 \
				-e PEERS="${NUMBER_OF_PEERS}" \
				-e PEERDNS=auto \
				-e INTERNAL_SUBNET=10.13.13.0 \
				-e ALLOWEDIPS=0.0.0.0/0 \
				-e PERSISTENTKEEPALIVE_PEERS= \
				-e LOG_CONFS=true \
				-p 51820:51820/udp \
				-v "${WIREGUARD_BASE}/config:/config" \
				--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
				--restart unless-stopped \
				lscr.io/linuxserver/wireguard:latest
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard >/dev/null 2>&1 && [[ -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf" ]]; then
							break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs wireguard\`)"
						exit 1
					fi
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
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[4]}")
			${module_options["module_wireguard,feature"]} ${commands[3]}
			[[ -n "${WIREGUARD_BASE}" && "${WIREGUARD_BASE}" != "/" ]] && rm -rf "${WIREGUARD_BASE}"
		;;
		"${commands[5]}")
			if [[ -z $2 ]]; then
				LIST=($(ls -1 ${WIREGUARD_BASE}/config/ | grep peer | cut -d"_" -f2))
				LIST_LENGTH=$((${#LIST[@]} / 2))
				SELECTED_PEER=$(dialog --title "Select peer" --no-items --menu "" $((${LIST_LENGTH} + 8)) 60 $((${LIST_LENGTH})) "${LIST[@]}" 3>&1 1>&2 2>&3)
			fi
			if [[ -n ${SELECTED_PEER} ]]; then
				clear
				docker exec -it wireguard /app/show-peer ${SELECTED_PEER}
				cat ${WIREGUARD_BASE}/config/peer_${SELECTED_PEER}/peer_${SELECTED_PEER}.conf
				read
			fi
		;;
		"${commands[6]}")
			if pkg_installed docker-ce; then
				local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
			fi
			if [[ "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[7]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
			fi
			if [[ "${container}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[8]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/wireguard?( |$)/{print $1}')
				local image=$(docker image ls -a | mawk '/wireguard?( |$)/{print $3}')
			fi
			if [[ "${container}" && "${image}" && -f "${WIREGUARD_BASE}/config/wg_confs/wg0.conf" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[9]}")
			echo -e "\nUsage: ${module_options["module_wireguard,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_wireguard,example"]}"
			echo "Available commands:"
			echo -e "\tpull\t\t- Pull $title image."
			echo -e "\tclient\t\t- Add client config $title."
			echo -e "\tserver\t\t- Add server config $title."
			echo -e "\tremove\t\t- Remove $title."
			echo -e "\tpurge\t\t- Purge $title with data."
			echo -e "\tqrcode\t\t- Show qrcodes for clients $title."
			echo -e "\timage\t\t- Image download status $title."
			echo -e "\tcontainer\t- Container run status $title."
			echo
		;;
		*)
			${module_options["module_wireguard,feature"]} ${commands[9]}
		;;
	esac
}
