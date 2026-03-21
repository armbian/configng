module_options+=(
	["module_swag,author"]="@igorpecovnik"
	["module_swag,maintainer"]="@igorpecovnik"
	["module_swag,feature"]="module_swag"
	["module_swag,example"]="install remove purge status password help"
	["module_swag,desc"]="Secure Web Application Gateway "
	["module_swag,status"]="Active"
	["module_swag,doc_link"]="https://github.com/linuxserver/docker-swag"
	["module_swag,group"]="WebHosting"
	["module_swag,port"]="443"
	["module_swag,arch"]="x86-64 arm64"
	["module_swag,dockerimage"]="lscr.io/linuxserver/swag:latest"
	["module_swag,dockername"]="swag"
)

function module_swag() {
	local title="SWAG"
	local dockerimage="${module_options["module_swag,dockerimage"]}"
	local dockername="${module_options["module_swag,dockername"]}"
	local port="${module_options["module_swag,port"]}"

	local container=$(docker_get_container_id "$dockername")

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_swag,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Get URL via dialog
			SWAG_URL=$(dialog --title \
				"Secure Web Application Gateway URL?" \
				--inputbox "\nExamples: myhome.domain.org (port 80 and 443 must be exposed to internet)" \
				8 80 "" 3>&1 1>&2 2>&3);

			if [[ ${SWAG_URL} && $? -eq 0 ]]; then
				# Adjust hostname
				hostnamectl set-hostname $(echo ${SWAG_URL} | sed -E 's/^\s*.*:\/\///g')

				# Pull image
				docker_operation_progress pull "$dockerimage"

				# Create base directory
				docker_manage_base_dir create "$base_dir" || return 1

				# Run container
				docker_operation_progress run "$dockername" \
					-d \
					--name="$dockername" \
					--cap-add=NET_ADMIN \
					--net=lsio \
					-e PUID="${DOCKER_USERUID}" \
					-e PGID="${DOCKER_GROUPUID}" \
					-e TZ="$(cat /etc/timezone)" \
					-e URL="${SWAG_URL}" \
					-e VALIDATION=http \
					-p 443:443 \
					-p 80:80 \
					-v "${base_dir}/config:/config" \
					--restart unless-stopped \
					"$dockerimage"

				# Set password
				${module_options["module_swag,feature"]} ${commands[4]}
			else
				show_message <<< "Entering fully qualified domain name is required!"
			fi
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_swag,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # password
			SWAG_USER=$(dialog_inputbox "Secure webserver with .htaccess username and password" \
				"\nHit enter for USERNAME defaults" "armbian" 9 70)
			# Pre-generate default password
			local default_password=$(tr -dc 'A-Za-z0-9=' < /dev/urandom | head -c 10)
			# Ask if user wants to use auto-generated password
			if dialog_yesno "Password Configuration" \
				"\nAuto-generated password for '${SWAG_USER}':\n\n  ${default_password}\n\nUse this password?" \
				"Use Generated" "Enter Own" 12 70; then
				SWAG_PASSWORD="$default_password"
			else
				SWAG_PASSWORD=$(dialog_passwordbox "Enter new password for ${SWAG_USER}" \
					"\nEnter a custom password" 9 70)
			fi
			if [[ "${SWAG_USER}" && "${SWAG_PASSWORD}" ]]; then
				docker exec -it "$dockername" htpasswd -b -c /config/nginx/.htpasswd ${SWAG_USER} ${SWAG_PASSWORD} >/dev/null 2>&1
				docker restart "$dockername" >/dev/null
			fi
		;;
		"${commands[5]}") # help
			docker_show_module_help "module_swag" "$title" \
				"Docker Image: $dockerimage\nPorts: 80, 443\n\nThis module requires a domain name during install."
		;;
		*)
			${module_options["module_swag,feature"]} ${commands[5]}
		;;
	esac
}
