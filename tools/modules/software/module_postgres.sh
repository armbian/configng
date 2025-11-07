module_options+=(
	["module_postgres,author"]=""
	["module_postgres,maintainer"]="@igorpecovnik"
	["module_postgres,feature"]="module_postgres"
	["module_postgres,example"]="install remove purge status help"
	["module_postgres,desc"]="Install PostgreSQL container (advanced relational database)"
	["module_postgres,status"]="Active"
	["module_postgres,doc_link"]="https://www.postgresql.org/docs/"
	["module_postgres,group"]="Database"
	["module_postgres,port"]="5432"
	["module_postgres,arch"]="x86-64 arm64"
)

#
# Module postgres
#
function module_postgres () {
	local title="postgres"
	local condition=$(which "$title" 2>/dev/null)

	# Accept optional parameters
	local POSTGRES_USER="$2"
	local POSTGRES_PASSWORD="$3"
	local POSTGRES_DB="$4"
	local POSTGRES_IMAGE="$5"
	local POSTGRES_CONTAINER="$6"

	# Defaults if nothing is set
	POSTGRES_USER="${POSTGRES_USER:-armbian}"
	POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-armbian}"
	POSTGRES_DB="${POSTGRES_DB:-armbian}"
	POSTGRES_IMAGE="${POSTGRES_IMAGE:-tensorchord/pgvecto-rs:pg14-v0.2.0}"
	POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-postgres}"

	if pkg_installed docker-ce; then
		local container=$(docker ps -q -f "name=^${POSTGRES_CONTAINER}$")
		local image=$(docker images -q $POSTGRES_IMAGE)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	POSTGRES_BASE="${SOFTWARE_FOLDER}/${POSTGRES_CONTAINER}"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$POSTGRES_BASE" ]] || mkdir -p "$POSTGRES_BASE" || { echo "Couldn't create storage directory: $POSTGRES_BASE"; exit 1; }
			# Download or update image
			docker pull $POSTGRES_IMAGE
			docker run -d \
			--name=${POSTGRES_CONTAINER} \
			--net=lsio \
			-e POSTGRES_USER=${POSTGRES_USER} \
			-e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
			-e POSTGRES_DB=${POSTGRES_DB} \
			-e TZ="$(cat /etc/timezone)" \
			-v "${POSTGRES_BASE}/${POSTGRES_CONTAINER}/data:/var/lib/postgresql/data" \
			--restart unless-stopped \
			${POSTGRES_IMAGE}
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' ${POSTGRES_CONTAINER} >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs ${POSTGRES_CONTAINER}\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "${container}" >/dev/null
			fi
			if [[ -n "${image}" ]]; then
				docker image rm "${image}" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_postgres,feature"]} ${commands[1]} $POSTGRES_USER $POSTGRES_PASSWORD $POSTGRES_DB $POSTGRES_IMAGE $POSTGRES_CONTAINER
			if [[ -n "${POSTGRES_BASE}" && "${POSTGRES_BASE}" != "/" ]]; then
				rm -rf "${POSTGRES_BASE}"
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
			# Help
			echo -e "\nUsage: ${module_options["module_postgres,feature"]} <command> [username] [password] [database]"
			echo "Commands: ${module_options["module_postgres,example"]}"
			echo -e "\tinstall [username] [password] [database] - Install ${title} (defaults: armbian/armbian/armbian)"
			echo -e "\tremove - Remove ${title}"
			echo -e "\tpurge  - Purge ${title} data"
			echo -e "\tstatus - Check ${title} installation status"
			echo
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}
