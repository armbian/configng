module_options+=(
	["module_duplicati,author"]="@armbian"
	["module_duplicati,maintainer"]="@igorpecovnik"
	["module_duplicati,feature"]="module_duplicati"
	["module_duplicati,example"]="install remove purge status help"
	["module_duplicati,desc"]="Install duplicati container"
	["module_duplicati,status"]="Active"
	["module_duplicati,doc_link"]="https://prev-docs.duplicati.com/en/latest/"
	["module_duplicati,group"]="Backup"
	["module_duplicati,port"]="8200"
	["module_duplicati,arch"]="x86-64 arm64"
)
#
# Module duplicati
#
function module_duplicati () {
	local title="duplicati"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=duplicati" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'duplicati' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_duplicati,example"]}"

	DUPLICATI_BASE="${SOFTWARE_FOLDER}/duplicati"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			shift
			# Accept encryption key and WebUI password from parameters if provided
			local DUPLICATI_ENCRYPTION_KEY="$1"
			local DUPLICATI_WEBUI_PASSWORD="$2"

			[[ -d "$DUPLICATI_BASE" ]] || mkdir -p "$DUPLICATI_BASE" || { echo "Couldn't create storage directory: $DUPLICATI_BASE"; exit 1; }

			# If no encryption key provided, prompt for it
			if [[ -z "${DUPLICATI_ENCRYPTION_KEY}" ]]; then
				DUPLICATI_ENCRYPTION_KEY=$($DIALOG --title "Duplicati Encryption Key" --inputbox "\nEnter an encryption key for Duplicati (at least 8 characters):" 9 60 "" 3>&1 1>&2 2>&3)
			fi

			# Check encryption key length
			if [[ -z "${DUPLICATI_ENCRYPTION_KEY}" || ${#DUPLICATI_ENCRYPTION_KEY} -lt 8 ]]; then
				echo -e "\nError: Encryption key must be at least 8 characters long!"
				exit 1
			fi

			# If no WebUI password provided, prompt for it
			if [[ -z "${DUPLICATI_WEBUI_PASSWORD}" ]]; then
				DUPLICATI_WEBUI_PASSWORD=$($DIALOG --title "Duplicati WebUI Password" --inputbox "\nEnter a password for Duplicati WebUI (at least 8 characters):" 9 60 "" 3>&1 1>&2 2>&3)
			fi

			# Check WebUI password length
			if [[ -z "${DUPLICATI_WEBUI_PASSWORD}" || ${#DUPLICATI_WEBUI_PASSWORD} -lt 8 ]]; then
				echo -e "\nError: WebUI password must be at least 8 characters long!"
				exit 1
			fi

			docker run -d \
			--net=lsio \
			--name duplicati \
			--restart=always \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e SETTINGS_ENCRYPTION_KEY="${DUPLICATI_ENCRYPTION_KEY}" \
			-e DUPLICATI__WEBSERVICE_PASSWORD="${DUPLICATI_WEBUI_PASSWORD}" \
			-p 8200:8200 \
			-v "${DUPLICATI_BASE}/config:/config" \
			-v "${DUPLICATI_BASE}/backups:/backups" \
			-v /:/source:ro \
			lscr.io/linuxserver/duplicati:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' duplicati 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs duplicati\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
		;;
		"${commands[2]}")
			${module_options["module_duplicati,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_duplicati,feature"]} ${commands[1]}
			if [[ -n "${DUPLICATI_BASE}" && "${DUPLICATI_BASE}" != "/" ]]; then
				rm -rf "${DUPLICATI_BASE}"
			fi

		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_duplicati,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_duplicati,example"]}"
			echo "Available commands:"
			echo -e "\tinstall [key] [password] - Install $title. (parameters optional)"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_duplicati,feature"]} ${commands[4]}
		;;
	esac
}
