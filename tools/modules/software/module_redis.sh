module_options+=(
	["module_redis,author"]=""
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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/redis?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/redis?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	REDIS_BASE="${SOFTWARE_FOLDER}/redis"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$REDIS_BASE" ]] || mkdir -p "$REDIS_BASE" || { echo "Couldn't create storage directory: $REDIS_BASE"; exit 1; }
			docker run -d \
			--name=redis \
			--net=lsio \
			-p 6379:6379 \
			-v "${REDIS_BASE}/data:/data" \
			--restart unless-stopped \
			redis:alpine
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' redis >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs redis\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi

			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
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
