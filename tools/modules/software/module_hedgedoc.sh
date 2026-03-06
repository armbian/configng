module_options+=(
	["module_hedgedoc,author"]="@armbian"
	["module_hedgedoc,maintainer"]="@efectn"
	["module_hedgedoc,feature"]="module_hedgedoc"
	["module_hedgedoc,example"]="install remove purge status help"
	["module_hedgedoc,desc"]="Install HedgeDoc container (real-time collaborative markdown editor)"
	["module_hedgedoc,status"]="Active"
	["module_hedgedoc,doc_link"]="https://docs.hedgedoc.org/"
	["module_hedgedoc,group"]="WebHosting"
	["module_hedgedoc,port"]="3100"
	["module_hedgedoc,arch"]="x86-64 arm64"
)

#
# Module hedgedoc
#
function module_hedgedoc () {
	local title="hedgedoc"
	local condition=$(which "$title" 2>/dev/null)

	local DOMAIN="${2:-$LOCALIPADD}"
	local USE_SSL="${3:-false}"

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/(^|[[:space:]])hedgedoc([[:space:]]|$)/{print $1}')
		local image=$(docker image ls -a | mawk '/linuxserver\/hedgedoc?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hedgedoc,example"]}"

	HEDGEDOC_BASE="${SOFTWARE_FOLDER}/hedgedoc"

	case "$1" in
		"${commands[0]}")
			# Exit if hedgedoc is already running
			if module_hedgedoc status; then
				exit 0
			fi

			local DATABASE_HOST="hedgedoc-db"
			local DATABASE_USER="hedgedoc"
			local DATABASE_NAME="hedgedoc"
			local DATABASE_PASSWORD=$(openssl rand -hex 8)

            		# Install postgres if not installed
			if ! module_postgres status "${DATABASE_USER}" "${DATABASE_PASSWORD}" "${DATABASE_NAME}" "" "${DATABASE_HOST}"; then
				module_postgres install "${DATABASE_USER}" "${DATABASE_PASSWORD}" "${DATABASE_NAME}" "postgres:16-alpine" "${DATABASE_HOST}"
			fi

			[[ -d "$HEDGEDOC_BASE" ]] || mkdir -p "$HEDGEDOC_BASE" || { echo "Couldn't create storage directory: $HEDGEDOC_BASE"; exit 1; }
			mkdir -p "$HEDGEDOC_BASE/uploads"

			session_secret=$(openssl rand -hex 32)

			docker run -d \
			--name=hedgedoc \
			--net=lsio \
			-e CMD_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:5432/${DATABASE_NAME}" \
			-e CMD_DOMAIN="${DOMAIN}" \
			-e CMD_PROTOCOL_USESSL="${USE_SSL}" \
			-e CMD_SESSION_SECRET="${session_secret}" \
			-e CMD_ALLOW_ANONYMOUS=true \
			-e CMD_URL_ADDPORT=false \
			-e CMD_ALLOW_EMAIL_REGISTER=true \
			-p ${module_options["module_hedgedoc,port"]}:3000 \
			-v "${HEDGEDOC_BASE}/uploads:/hedgedoc/public/uploads" \
			--restart unless-stopped \
			quay.io/hedgedoc/hedgedoc:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ .State.Running }}' hedgedoc 2>/dev/null | grep -q "true"; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ]; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs hedgedoc\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_hedgedoc,feature"]} ${commands[1]}
			if [[ -n "${HEDGEDOC_BASE}" && "${HEDGEDOC_BASE}" != "/" ]]; then
				rm -rf "${HEDGEDOC_BASE}"
			fi
			# Also purge the database container
			module_postgres purge "" "" "" "" "hedgedoc-db"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_hedgedoc,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_hedgedoc,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title with PostgreSQL database."
			echo -e "\tremove\t- Remove $title container and image."
			echo -e "\tpurge\t- Remove $title and delete all data including database."
			echo -e "\tstatus\t- Check $title installation status."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_hedgedoc,feature"]} ${commands[4]}
		;;
	esac
}
