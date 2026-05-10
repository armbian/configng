module_options+=(
	["module_swag,author"]="@igorpecovnik"
	["module_swag,maintainer"]="@igorpecovnik"
	["module_swag,feature"]="module_swag"
	["module_swag,example"]="install remove purge status password help"
	["module_swag,desc"]="Secure Web Application Gateway"
	["module_swag,status"]="Active"
	["module_swag,doc_link"]="https://github.com/linuxserver/docker-swag"
	["module_swag,group"]="WebHosting"
	["module_swag,port"]="443"
	["module_swag,arch"]="x86-64 arm64"
	["module_swag,dockerimage"]="linuxserver/swag:latest"
	["module_swag,dockername"]="swag"
)

#
# Module SWAG - Secure Web Application Gateway
# A reverse proxy with SSL certification automation
#
function module_swag() {
	local title="SWAG"
	local dockerimage="${module_options["module_swag,dockerimage"]}"
	local dockername="${module_options["module_swag,dockername"]}"
	local port="${module_options["module_swag,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_swag,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Get URL via dialog
			local swag_url
			swag_url=$(dialog_inputbox "Secure Web Application Gateway - URL" \
				"Enter your fully qualified domain name\n\nExamples:\n  - myhome.domain.org\n  - example.com\n\nNote: Ports 80 and 443 must be exposed to the internet" \
				"" 15 90)

			# Check if user cancelled or entered empty value
			if [[ -z "$swag_url" ]]; then
				dialog_msgbox "Installation Cancelled" \
					"A fully qualified domain name is required for SWAG to function properly." 10 70
				return 1
			fi

			# Clean URL (remove protocol if present)
			swag_url=$(echo "$swag_url" | sed -E 's|^\s*https?://||' | sed 's|/.*$||')

			# DNS sanity check. Let's Encrypt's HTTP-01 challenge can
			# only succeed if the user's FQDN resolves to this host's
			# public IPv4. Detect mismatches early so the user can fix
			# DNS before we pull a 200 MB image and discover the cert
			# request fails. We don't hard-block — split-horizon DNS,
			# users mid-DNS-propagation, or test deployments are
			# legitimate cases for proceeding anyway.
			local resolved_ip="" public_ip=""
			# getent uses the system resolver (libc) — same resolver
			# Docker/SWAG will use at runtime. Take only the first
			# IPv4 to keep the comparison meaningful for users with
			# split AAAA/A records.
			resolved_ip=$(getent ahostsv4 "$swag_url" 2>/dev/null \
				| awk 'NR==1 {print $1}')
			# Try a few outbound endpoints; abort the loop on the
			# first valid IPv4 response. Skip the comparison entirely
			# if all fail (firewalled outbound, no internet) — better
			# than a false-positive warning.
			local endpoint
			for endpoint in https://api.ipify.org https://ifconfig.me https://icanhazip.com; do
				public_ip=$(curl -sS --max-time 4 -4 "$endpoint" 2>/dev/null | tr -d '[:space:]')
				[[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
				public_ip=""
			done

			if [[ -z "$resolved_ip" ]]; then
				if ! dialog_yesno "DNS Resolution Failed" \
					"${swag_url} did not resolve to any IPv4 address.\n\nLet's Encrypt cannot issue a certificate until the domain points at this host.\n\nProceed anyway?\n  (cert acquisition will retry on next container restart)" \
					"Proceed" "Cancel" 14 80; then
					return 1
				fi
			elif [[ -n "$public_ip" && "$resolved_ip" != "$public_ip" ]]; then
				if ! dialog_yesno "DNS Mismatch" \
					"${swag_url} resolves to:\n  ${resolved_ip}\n\nThis host's public IP is:\n  ${public_ip}\n\nLet's Encrypt's HTTP-01 challenge will land on ${resolved_ip}, not this host. Cert acquisition will fail.\n\nProceed anyway?" \
					"Proceed" "Cancel" 18 80; then
					return 1
				fi
			fi

			# Align the system hostname with the SWAG domain. armbian-config
			# already runs with root, so do this silently rather than
			# prompting — the original yes/no dialog was just noise on
			# the install path. Only surface a message if the call
			# fails (e.g. hostnamectl missing in a CI minimal image),
			# in which case we continue without aborting the install.
			if ! hostnamectl set-hostname "${swag_url}" 2>/dev/null; then
				dialog_msgbox "Hostname Update Failed" \
					"Could not set the system hostname to:\n  ${swag_url}\n\nSet it manually after install:\n  sudo hostnamectl set-hostname ${swag_url}\n\nContinuing with installation..." 12 70
			fi

			# Pull image
			if ! docker_operation_progress pull "$dockerimage"; then
				dialog_msgbox "Installation Failed" \
					"Failed to pull Docker image:\n  $dockerimage\n\nPlease check your internet connection and try again." 12 70
				return 1
			fi

			# Create base directory
			if ! docker_manage_base_dir create "$base_dir"; then
				dialog_msgbox "Installation Failed" \
					"Failed to create directory:\n  $base_dir" 10 60
				return 1
			fi


			# Run container
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--cap-add=NET_ADMIN \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
				-e TZ="$(cat /etc/timezone)" \
				-e URL="${swag_url}" \
				-e VALIDATION=http \
				-p 443:443 \
				-p 80:80 \
				-v "${base_dir}/config:/config" \
				--restart unless-stopped \
				"$dockerimage"; then
				dialog_msgbox "Installation Failed" \
					"Failed to start SWAG container.\n\nCheck logs with:\n  docker logs $dockername" 12 70
				return 1
			fi

			# Store URL globally for module-wide use (replaces IP detection)
			# This file is used by password, help, and status commands
			echo "$swag_url" > "${base_dir}/config/SWAG_URL"

			# Restart container to initialize SSL certificates
			dialog_infobox "Initializing SSL Certificates" \
				"SWAG installed. Restarting to initialize SSL certificates for:\n  ${swag_url}\n\nPlease wait..." 12 70
			sleep 2
			docker restart "$dockername" >/dev/null 2>&1

			# Wait for the actual cert file to appear, not for
			# dynamicssl.conf — the latter is created during nginx
			# config setup regardless of whether Let's Encrypt
			# succeeded or failed, so the previous check passed for
			# every install including ones that ended with no cert.
			# 90 s is the practical upper bound: ACME provisioning
			# typically completes within 15 s, but rate-limit holdoffs
			# and slow LE acks can push to a minute.
			local wait_count=0
			local cert_path="/config/keys/letsencrypt/fullchain.pem"
			while [[ $wait_count -lt 90 ]]; do
				if docker exec "$dockername" test -f "$cert_path" 2>/dev/null; then
					break
				fi
				sleep 1
				((wait_count++))
			done

			# Verify the cert was actually issued. If not, pull the
			# tail of the container log and grep for the typical ACME
			# failure markers so the user sees *why* it failed instead
			# of an opaque "installed" dialog. Don't return non-zero —
			# SWAG itself is running and the user can fix DNS / unblock
			# port 80 and `docker restart swag` to retry without
			# reinstalling.
			if ! docker exec "$dockername" test -f "$cert_path" 2>/dev/null; then
				local cert_failure_excerpt
				cert_failure_excerpt=$(docker logs --tail=200 "$dockername" 2>&1 \
					| grep -iE 'error|failed|challenge|timeout|rate limit|invalid|unauthorized|connection refused' \
					| tail -10)
				if [[ -z "$cert_failure_excerpt" ]]; then
					cert_failure_excerpt="(no obvious error markers found in last 200 log lines — run 'docker logs swag' for the full output)"
				fi
				dialog_msgbox "SSL Certificate Not Issued" \
					"Waited 90 s but no Let's Encrypt cert appeared at:\n  ${cert_path}\n\nMost common causes:\n  - ${swag_url} doesn't resolve to this host's public IP\n  - Port 80 isn't reachable from the internet (firewall/NAT)\n  - Let's Encrypt rate-limit hit (5 cert/week per registered domain)\n\nLog excerpt:\n${cert_failure_excerpt}\n\nFix the underlying issue and run:\n  docker restart ${dockername}\nto retry. SWAG itself is running — services proxied through it will work once a cert is in place." \
					25 100
			fi

			# Set password
			${module_options["module_swag,feature"]} ${commands[4]}
			;;

		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
			;;

		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_swag,feature"]} ${commands[1]}; then
				dialog_msgbox "Purge Failed" \
					"Failed to remove SWAG container and/or image.\n\nData directory preserved at:\n  $base_dir" 12 70
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
			dialog_msgbox "Purge Complete" \
				"SWAG has been completely removed, including all data." 10 60
			;;

		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
			;;

		"${commands[4]}") # password
			# Check if container is running
			if ! docker_get_container_id "$dockername" >/dev/null 2>&1; then
				dialog_msgbox "Container Not Running" \
					"SWAG container is not running.\n\nPlease install SWAG first:\n  ${module_options["module_swag,feature"]} ${commands[0]}" 12 70
				return 1
			fi

			# Read global SWAG_URL configuration (fallback to IP if not found)
			local display_url="$LOCALIPADD"
			if [[ -f "${base_dir}/config/SWAG_URL" ]]; then
				display_url=$(cat "${base_dir}/config/SWAG_URL")
			fi

			local swag_user
			swag_user=$(dialog_inputbox "Configure .htaccess Authentication" \
				"Enter username for .htaccess authentication\n\nThis will secure web access to your services" \
				"armbian" 12 80)

			if [[ -z "$swag_user" ]]; then
				dialog_msgbox "Operation Cancelled" \
					"Username cannot be empty. Operation cancelled." 10 60
				return 1
			fi

			# Pre-generate default password
			local default_password
			default_password=$(tr -dc 'A-Za-z0-9=' < /dev/urandom | head -c 10)

			# Ask if user wants to use auto-generated password
			local swag_password
			if dialog_yesno "Password Configuration" \
				"Auto-generated password for '${swag_user}':\n\n  ${default_password}\n\nUse this secure password?" \
				"Use Generated" "Enter Own" 15 80; then
				swag_password="$default_password"
			else
				swag_password=$(dialog_passwordbox "Enter Custom Password" \
					"Enter a secure password for ${swag_user}\n\nMinimum 8 characters recommended" 12 80)

				if [[ -z "$swag_password" ]]; then
					dialog_msgbox "Operation Cancelled" \
						"Password cannot be empty. Operation cancelled." 10 60
					return 1
				fi
			fi

			# Set the password in the container
			if docker exec -it "$dockername" htpasswd -b -c /config/nginx/.htpasswd "${swag_user}" "${swag_password}" >/dev/null 2>&1; then
				# nginx re-reads .htpasswd on every request — no
				# reload is strictly required for the new credentials
				# to take effect. Send SIGHUP anyway so any concurrent
				# config edit lands at the same time, without dropping
				# active connections (a full `docker restart` would).
				docker exec "$dockername" nginx -s reload >/dev/null 2>&1 || true

				# Show success message with credentials (using domain URL, not IP)
				dialog_infobox "Password Configuration Complete" \
					"Username: ${swag_user}\nPassword: ${swag_password}\n\nWeb Interface: https://${display_url}\n\nPlease save these credentials!" 15 80

				# Keep the info box visible for 5 seconds
				sleep 5
			else
				dialog_msgbox "Password Configuration Failed" \
					"Failed to set .htaccess password.\n\nCheck container logs with:\n  docker logs $dockername" 12 70
				return 1
			fi
			;;

		"${commands[5]}") # help
			# Read global SWAG_URL configuration (fallback to IP if not found)
			local stored_url="$LOCALIPADD"
			if [[ -f "${base_dir}/config/SWAG_URL" ]]; then
				stored_url=$(cat "${base_dir}/config/SWAG_URL")
			fi

			show_module_help "module_swag" "$title" \
				"Web Interface: https://${stored_url}\nPorts: 80, 443\nDocker Image: $dockerimage\n\nThis module requires a domain name during install.\n\nDocumentation: ${module_options["module_swag,doc_link"]}"
			;;

		*)
			${module_options["module_swag,feature"]} ${commands[5]}
			;;
	esac
}
