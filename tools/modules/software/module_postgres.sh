module_options+=(
	["module_postgres,author"]="@armbian"
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

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	# Accept optional parameters
	local POSTGRES_USER="$2"
	local POSTGRES_PASSWORD="$3"
	local POSTGRES_DB="$4"
	local POSTGRES_IMAGE="$5"
	local POSTGRES_TAG="$6"
	local POSTGRES_CONTAINER="$7"

	# Defaults if nothing is set
	POSTGRES_USER="${POSTGRES_USER:-armbian}"
	POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-armbian}"
	POSTGRES_DB="${POSTGRES_DB:-armbian}"
	POSTGRES_IMAGE="${POSTGRES_IMAGE:-tensorchord/pgvecto-rs}"
	POSTGRES_TAG="${POSTGRES_TAG:-pg14-v0.2.0}"
	POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-postgres}"
	local container=$(docker container ls -a --filter "name=^${POSTGRES_CONTAINER}$" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep "${POSTGRES_IMAGE}" | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	POSTGRES_BASE="${SOFTWARE_FOLDER}/${POSTGRES_CONTAINER}"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$POSTGRES_BASE" ]] || mkdir -p "$POSTGRES_BASE" || { echo "Couldn't create storage directory: $POSTGRES_BASE"; exit 1; }
			# Download or update image
			docker pull $POSTGRES_IMAGE
			docker run -d \
			--net=lsio \
			--name ${POSTGRES_CONTAINER} \
			--restart=always \
			-e POSTGRES_USER=${POSTGRES_USER} \
			-e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
			-e POSTGRES_DB=${POSTGRES_DB} \
			-e TZ="$(cat /etc/timezone)" \
			-v "${POSTGRES_BASE}/${POSTGRES_CONTAINER}/data:/var/lib/postgresql/data" \
			${POSTGRES_IMAGE}:${POSTGRES_TAG}
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' ${POSTGRES_CONTAINER} 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "
Timed out waiting for ${title} to start, consult logs (\`docker logs ${POSTGRES_CONTAINER}\`)"
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
			${module_options["module_postgres,feature"]} ${commands[1]} $POSTGRES_USER $POSTGRES_PASSWORD $POSTGRES_DB $POSTGRES_IMAGE $POSTGRES_CONTAINER
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
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
			echo -e "
Usage: ${module_options["module_postgres,feature"]} <command> [username] [password] [database]"
			echo "Commands: ${module_options["module_postgres,example"]}"
			echo -e "	install [username] [password] [database] - Install ${title} (defaults: armbian/armbian/armbian)"
			echo -e "	remove - Remove ${title}"
			echo -e "	purge  - Purge ${title} data"
			echo -e "	status - Check ${title} installation status"
			echo
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}
