module_options+=(
	["module_sabnzbd,author"]="@armbian"
	["module_sabnzbd,maintainer"]="@igorpecovnik"
	["module_sabnzbd,feature"]="module_sabnzbd"
	["module_sabnzbd,example"]="install remove purge status help"
	["module_sabnzbd,desc"]="Install sabnzbd container"
	["module_sabnzbd,status"]="Active"
	["module_sabnzbd,doc_link"]="https://sabnzbd.org/wiki/faq"
	["module_sabnzbd,group"]="Downloaders"
	["module_sabnzbd,port"]="8380"
	["module_sabnzbd,arch"]="x86-64 arm64"
)
#
# Module Sabnzbd
#
function module_sabnzbd () {
	local title="sabnzbd"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=sabnzbd" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'sabnzbd' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_sabnzbd,example"]}"

	SABNZBD_BASE="${SOFTWARE_FOLDER}/sabnzbd"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$SABNZBD_BASE" ]] || mkdir -p "$SABNZBD_BASE" || { echo "Couldn't create storage directory: $SABNZBD_BASE"; exit 1; }
			docker run -d \
			--name=sabnzbd \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p ${module_options["module_sabnzbd,port"]}:8080 \
			-v "${SABNZBD_BASE}/config:/config" \
			-v "${SABNZBD_BASE}/downloads:/downloads" `#optional` \
			-v "${SABNZBD_BASE}/incomplete:/incomplete-downloads" `#optional` \
			--restart=always \
			lscr.io/linuxserver/sabnzbd:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' sabnzbd 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "
Timed out waiting for ${title} to start, consult logs (\`docker logs sabnzbd\`)"
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
			${module_options["module_sabnzbd,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_sabnzbd,feature"]} ${commands[1]}
			if [[ -n "${SABNZBD_BASE}" && "${SABNZBD_BASE}" != "/" ]]; then
				rm -rf "${SABNZBD_BASE}"
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
			echo -e "
Usage: ${module_options["module_sabnzbd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_sabnzbd,example"]}"
			echo "Available commands:"
			echo -e "	install	- Install $title."
			echo -e "	status	- Installation status $title."
			echo -e "	remove	- Remove $title."
			echo -e "	purge	- Purge $title."
			echo
		;;
		*)
			${module_options["module_sabnzbd,feature"]} ${commands[4]}
		;;
	esac
}
