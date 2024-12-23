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
)

function module_swag() {
	local title="swag"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/swag?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/swag?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_swag,example"]}"

	SWAG_BASE="${SOFTWARE_FOLDER}/swag"

	case "$1" in
		"${commands[0]}")
			SWAG_URL=$(dialog --title \
			"Secure Web Application Gateway URL?" \
			--inputbox "\nExamples: myhome.domain.org (port 80 and 443 must be exposed to internet)" \
			8 80 "" 3>&1 1>&2 2>&3);

			if [[ ${SWAG_URL} && $? -eq 0 ]]; then

				# adjust hostname
				hostnamectl set-hostname $(echo ${SWAG_URL} | sed -E 's/^\s*.*:\/\///g')
				# install docker
				pkg_installed docker-ce || module_docker install

				[[ -d "$SWAG_BASE" ]] || mkdir -p "$SWAG_BASE" || { echo "Couldn't create storage directory: $SWAG_BASE"; exit 1; }

				docker run -d \
				--name=swag \
				--cap-add=NET_ADMIN \
				--net=lsio \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e URL="${SWAG_URL}" \
				-e VALIDATION=http \
				-p 443:443 \
				-p 80:80 \
				-v "${SWAG_BASE}/config:/config" \
				--restart unless-stopped \
				lscr.io/linuxserver/swag
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' swag >/dev/null 2>&1 ; then
						break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs swag\`)"
						exit 1
					fi
				done
				# set password
				${module_options["module_swag,feature"]} ${commands[4]}
			else
				show_message <<< "Entering fully qualified domain name is required!"
			fi
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			[[ -n "${SWAG_BASE}" && "${SWAG_BASE}" != "/" ]] && rm -rf "${SWAG_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			SWAG_USER=$($DIALOG --title "Secure webserver with .htaccess username and password" \
			--inputbox "\nHit enter for USERNAME defaults" 9 70 "armbian" 3>&1 1>&2 2>&3)
			SWAG_PASSWORD=$($DIALOG --title "Enter new password for ${SWAG_USER}" \
			--inputbox "\nHit enter for auto generated password" 9 70 "$(tr -dc 'A-Za-z0-9=' < /dev/urandom | head -c 10)" 3>&1 1>&2 2>&3)
			if [[ "${SWAG_USER}" && "${SWAG_PASSWORD}" ]]; then
				docker exec -it swag htpasswd -b -c /config/nginx/.htpasswd ${SWAG_USER} ${SWAG_PASSWORD} >/dev/null 2>&1
				docker restart ${container} >/dev/null
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_swag,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_swag,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tpassword\t- Set .htaccess password for $title."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_swag,feature"]} ${commands[5]}
		;;
	esac
}
