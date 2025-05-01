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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/postgres?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/pg14-v0.2.0?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	POSTGRES_BASE="${SOFTWARE_FOLDER}/postgres"

	case "$1" in
		"${commands[0]}")
			shift
			# Accept optional parameters
			local POSTGRES_USER="$1"
			local POSTGRES_PASSWORD="$2"
			local POSTGRES_DB="$3"
			pkg_installed docker-ce || module_docker install
			[[ -d "$POSTGRES_BASE" ]] || mkdir -p "$POSTGRES_BASE" || { echo "Couldn't create storage directory: $POSTGRES_BASE"; exit 1; }
			# Set defaults if empty
			POSTGRES_USER="${POSTGRES_USER:-armbian}"
			POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-armbian}"
			POSTGRES_DB="${POSTGRES_DB:-armbian}"
			docker run -d \
			--name=postgres \
			--net=lsio \
			-e POSTGRES_USER=${POSTGRES_USER} \
			-e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
			-e POSTGRES_DB=${POSTGRES_DB} \
			-e TZ="$(cat /etc/timezone)" \
			-p 5432:5432 \
			-v "${POSTGRES_BASE}/data:/var/lib/postgresql/data" \
			--restart unless-stopped \
			tensorchord/pgvecto-rs:pg14-v0.2.0
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' postgres >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs postgres\`)"
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
			${module_options["module_postgres,feature"]} ${commands[1]}
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
