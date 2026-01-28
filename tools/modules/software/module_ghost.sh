module_options+=(
	["module_ghost,author"]="@igorpecovnik"
	["module_ghost,maintainer"]="@igorpecovnik"
	["module_ghost,feature"]="module_ghost"
	["module_ghost,example"]="install remove purge status help"
	["module_ghost,desc"]="Install Ghost CMS container"
	["module_ghost,status"]="Active"
	["module_ghost,doc_link"]="https://ghost.org/docs/"
	["module_ghost,group"]="WebHosting"
	["module_ghost,port"]="9190"
	["module_ghost,arch"]="x86-64 arm64"
)

#
# Module ghost
#
function module_ghost () {
	local title="ghost"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=ghost" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep '^ghost:' | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_ghost,example"]}"

	GHOST_BASE="${SOFTWARE_FOLDER}/ghost"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			# Install mysql if not installed
			if ! module_mysql status; then
				module_mysql install
			fi

			# Exit if ghost is already running
			if [[ "${container}" && "${image}" ]]; then
				echo "Ghost container is already installed and running."
				exit 0
			fi

			MYSQL_USER="${2:-armbian}"
			MYSQL_PASSWORD="${3:-armbian}"

			[[ -d "$GHOST_BASE" ]] || mkdir -p "$GHOST_BASE" || { echo "Couldn't create storage directory: $GHOST_BASE"; exit 1; }
			docker run -d \
				--name ghost \
				--net=lsio \
				--restart unless-stopped \
				-e database__client=mysql \
				-e database__connection__host="mysql" \
				-e database__connection__user="${MYSQL_USER}" \
				-e database__connection__password="${MYSQL_PASSWORD}" \
				-e database__connection__database="ghost" \
				-p "${module_options["module_ghost,port"]}:2368" \
				-e url="http://$LOCALIPADD:${module_options["module_ghost,port"]}" \
				-v "$GHOST_BASE:/var/lib/ghost/content" \
				ghost:6

			# Wait for container to start
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' ghost 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs ghost\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null 2>&1
			fi
		;;
		"${commands[2]}")
			${module_options["module_ghost,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null 2>&1 || true
			fi
			if [[ -n "${GHOST_BASE}" && "${GHOST_BASE}" != "/" ]]; then
				rm -rf "${GHOST_BASE}"
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
			echo -e "\nUsage: ${module_options["module_ghost,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_ghost,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\t         Optionally accepts arguments:"
			echo -e "\t         db_user db_pass"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_ghost,feature"]} ${commands[4]}
		;;
	esac
}
