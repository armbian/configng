module_options+=(
	["module_transmission,author"]="@armbian"
	["module_transmission,maintainer"]="@igorpecovnik"
	["module_transmission,feature"]="module_transmission"
	["module_transmission,example"]="install remove purge status help"
	["module_transmission,desc"]="Install transmission container"
	["module_transmission,status"]="Active"
	["module_transmission,doc_link"]="https://transmissionbt.com/"
	["module_transmission,group"]="Downloaders"
	["module_transmission,port"]="9091 51413"
	["module_transmission,arch"]="x86-64 arm64"
)
#
# Module transmission
#
function module_transmission () {
	local title="transmission"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=transmission" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'transmission' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_transmission,example"]}"

	TRANSMISSION_BASE="${SOFTWARE_FOLDER}/transmission"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$TRANSMISSION_BASE" ]] || mkdir -p "$TRANSMISSION_BASE" || { echo "Couldn't create storage directory: $TRANSMISSION_BASE"; exit 1; }
			TRANSMISSION_USER=$($DIALOG --title "Enter username for Transmission client" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			TRANSMISSION_PASS=$($DIALOG --title "Enter password for Transmission client" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			docker run -d \
			--name=transmission \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e USER="${TRANSMISSION_USER}" \
			-e PASS="${TRANSMISSION_PASS}" \
			-e WHITELIST="${TRANSMISSION_WHITELIST}" \
			-p 9091:9091 \
			-p 51413:51413 \
			-p 51413:51413/udp \
			-v "${TRANSMISSION_BASE}/config:/config" \
			-v "${TRANSMISSION_BASE}/downloads:/downloads" \
			-v "${TRANSMISSION_BASE}/watch:/watch" \
			--restart=always \
			lscr.io/linuxserver/transmission:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' transmission 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs transmission\`)"
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
			${module_options["module_transmission,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_transmission,feature"]} ${commands[1]}
			if [[ -n "${TRANSMISSION_BASE}" && "${TRANSMISSION_BASE}" != "/" ]]; then
				rm -rf "${TRANSMISSION_BASE}"
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
			echo -e "\nUsage: ${module_options["module_transmission,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_transmission,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_transmission,feature"]} ${commands[4]}
		;;
	esac
}
