module_options+=(
	["module_redis,author"]="@armbian"
	["module_redis,maintainer"]="@igorpecovnik"
	["module_redis,feature"]="module_redis"
	["module_redis,example"]="install remove purge status help"
	["module_redis,desc"]="Install Redis in a container (In-Memory Data Store)"
	["module_redis,status"]="Active"
	["module_redis,doc_link"]="https://redis.io/docs/"
	["module_redis,group"]="Database"
	["module_redis,port"]="6379"
	["module_redis,arch"]="x86-64 arm64"
)
#
# Module redis
#
function module_redis () {
	local title="redis"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi
	local container=$(docker container ls -a --filter "name=redis" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'redis '| awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	REDIS_BASE="${SOFTWARE_FOLDER}/redis"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$REDIS_BASE" ]] || mkdir -p "$REDIS_BASE" || { echo "Couldn't create storage directory: $REDIS_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name redis \
			--restart=always \
			-p 6379:6379 \
			-v "${REDIS_BASE}/data:/data" \
			redis:alpine
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' redis 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs redis\`)"
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
			${module_options["module_redis,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_redis,feature"]} ${commands[1]}
			if [[ -n "${REDIS_BASE}" && "${REDIS_BASE}" != "/" ]]; then
				rm -rf "${REDIS_BASE}"
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
			echo -e "\nUsage: ${module_options["module_redis,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_redis,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_redis,feature"]} ${commands[4]}
		;;
	esac
}
