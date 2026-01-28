module_options+=(
	["module_homepage,author"]="@armbian"
	["module_homepage,maintainer"]="@igorpecovnik"
	["module_homepage,feature"]="module_homepage"
	["module_homepage,example"]="install remove purge status help"
	["module_homepage,desc"]="Install homepage container"
	["module_homepage,status"]="Active"
	["module_homepage,doc_link"]="https://gethomepage.dev/configs/"
	["module_homepage,group"]="Management"
	["module_homepage,port"]="3021"
	["module_homepage,arch"]=""
)
#
# Module homepage
#
function module_homepage () {
	local title="homepage"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=homepage" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'homepage' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_homepage,example"]}"

	HOMEPAGE_BASE="${SOFTWARE_FOLDER}/homepage"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$HOMEPAGE_BASE" ]] || mkdir -p "$HOMEPAGE_BASE" || { echo "Couldn't create storage directory: $HOMEPAGE_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name homepage \
			-e PUID=1000 \
			-e PGID=1000 \
			-e HOMEPAGE_ALLOWED_HOSTS=${LOCALIPADD}:${module_options["module_homepage,port"]},homepage.local:${module_options["module_homepage,port"]},localhost:${module_options["module_homepage,port"]} \
			-p ${module_options["module_homepage,port"]}:3000 \
			-v "${HOMEPAGE_BASE}/config:/app/config" \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart=always \
			ghcr.io/gethomepage/homepage:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' homepage 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs homepage\`)"
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
			${module_options["module_homepage,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_homepage,feature"]} ${commands[1]}
			if [[ -n "${HOMEPAGE_BASE}" && "${HOMEPAGE_BASE}" != "/" ]]; then
				rm -rf "${HOMEPAGE_BASE}"
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
			echo -e "\nUsage: ${module_options["module_homepage,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_homepage,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Remove $title and delete its data."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_homepage,feature"]} ${commands[4]}
		;;
	esac
}
