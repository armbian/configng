module_options+=(
	["module_navidrome,author"]="@armbian"
	["module_navidrome,maintainer"]="@igorpecovnik"
	["module_navidrome,feature"]="module_navidrome"
	["module_navidrome,example"]="install remove purge status help"
	["module_navidrome,desc"]="Install navidrome container"
	["module_navidrome,status"]="Active"
	["module_navidrome,doc_link"]="https://github.com/pynavidrome/navidrome/wiki"
	["module_navidrome,group"]="Downloaders"
	["module_navidrome,port"]="4533"
	["module_navidrome,arch"]="x86-64 arm64"
)
#
# Install Module navidrome
#
function module_navidrome () {
	local title="navidrome"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=navidrome" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'navidrome' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_navidrome,example"]}"

	NAVIDROME_BASE="${SOFTWARE_FOLDER}/navidrome"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$NAVIDROME_BASE" ]] || mkdir -p "$NAVIDROME_BASE"/{music,data} || { echo "Couldn't create storage directory: $NAVIDROME_BASE"; exit 1; }
			sudo chown -R 1000:1000 "$NAVIDROME_BASE"/
			docker run -d \
			--net=lsio \
			--name navidrome \
			--restart=always \
			--user 1000:1000 \
			-e TZ="$(cat /etc/timezone)" \
			-p 4533:4533 \
			-v "${NAVIDROME_BASE}/music:/music" \
			-v "${NAVIDROME_BASE}/data:/data" \
			deluan/navidrome:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' navidrome 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs navidrome\`)"
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
			${module_options["module_navidrome,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_navidrome,feature"]} ${commands[1]}
			if [[ -n "${NAVIDROME_BASE}" && "${NAVIDROME_BASE}" != "/" ]]; then
				rm -rf "${NAVIDROME_BASE}"
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
			echo -e "\nUsage: ${module_options["module_navidrome,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_navidrome,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_navidrome,feature"]} ${commands[4]}
		;;
	esac
}
