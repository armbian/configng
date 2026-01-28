module_options+=(
	["module_immich,author"]=""
	["module_immich,maintainer"]="@igorpecovnik"
	["module_immich,feature"]="module_immich"
	["module_immich,example"]="install remove purge status help"
	["module_immich,desc"]="Install Immich (photo and video backup solution)"
	["module_immich,status"]="Active"
	["module_immich,doc_link"]="https://immich.app/docs"
	["module_immich,group"]="Media"
	["module_immich,port"]="8077"
	["module_immich,arch"]="x86-64 arm64"
)
#
# Module immich
#
function module_immich () {
	local title="immich"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	# Database
	local DATABASE_USER="immich"
	local DATABASE_PASSWORD="immich"
	local DATABASE_NAME="immich"
	local DATABASE_HOST="postgres-immich"
	local DATABASE_IMAGE="tensorchord/pgvecto-rs"
	local DATABASE_TAG="pg14-v0.2.0"
	local DATABASE_PORT="5432"
	local container=$(docker container ls -a --format '{{.ID}} {{.Names}}' | awk '$2 == "immich" {print $1}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep 'ghcr.io/imagegenius/immich:' | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_immich,example"]}"

	IMMICH_BASE="${SOFTWARE_FOLDER}/immich"

	case "$1" in
		"${commands[0]}")
			# Check if the module is already installed
			if [[ "${container}" && "${image}" ]]; then
				echo "Immich container is already installed."
				exit 0
			fi

			# workaround if we re-install
			mkdir -p \
			"$IMMICH_BASE"/photos/{backups,encoded-video,library,profile,thumbs,upload} \
			"$IMMICH_BASE"/config \
			"$IMMICH_BASE"/libraries
			touch "$IMMICH_BASE"/photos/{backups,thumbs,profile,upload,library,encoded-video}/.immich
			sudo chown -R 1000:1000 "$IMMICH_BASE"/

			# Install armbian-config dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then module_redis install; fi
			if ! docker container ls -a --format '{{.Names}}' | grep "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_TAG $DATABASE_HOST
			fi

			until docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; do
				echo "⏳ Waiting for PostgreSQL to be ready..."
				sleep 2
			done
			echo "✅ PostgreSQL is ready. Creating Immich DB..."

			if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" | grep -q 1; then
				echo "✅ Database '$DATABASE_NAME' exists."
			else
				docker exec -i $DATABASE_HOST psql -U $DATABASE_USER <<-EOT
				CREATE DATABASE $DATABASE_NAME;
				GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
				EOT
			fi

			# Download or update image
			docker pull ghcr.io/imagegenius/immich:latest

			# Run Immich container
			if ! docker run -d \
				--name=immich \
				--net=lsio \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e DB_HOSTNAME=$DATABASE_HOST \
				-e DB_USERNAME=$DATABASE_USER \
				-e DB_PASSWORD=$DATABASE_PASSWORD \
				-e DB_DATABASE_NAME=$DATABASE_NAME \
				-e REDIS_HOSTNAME=redis \
				-e DB_PORT=$DATABASE_PORT \
				-e REDIS_PORT=6379 \
				-e REDIS_PASSWORD= \
				-e SERVER_HOST=0.0.0.0 \
				-e SERVER_PORT=8080 \
				-p ${module_options["module_immich,port"]}:8080 \
				-v "${IMMICH_BASE}/config:/config" \
				-v "${IMMICH_BASE}/photos:/photos" \
				-v "${IMMICH_BASE}/libraries:/libraries" \
				--restart=always \
				ghcr.io/imagegenius/immich:latest; then
					echo "❌ Failed to start Immich container"
					exit 1
			fi

			sleep 5

			if [ -t 1 ]; then
				for s in {1..10}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Starting Immich Please wait..." 10 50 0
			else
				echo "Waiting for Immich to become available..."
				for s in {1..10}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						echo "✅ Immich is responding."
						break
					fi
				done
			fi
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container" 2>/dev/null || true
				# Wait for container to be fully removed
				for i in $(seq 1 10); do
					if ! docker container ls -a --format '{{.ID}}' | grep -q "^${container}$"; then
						break
					fi
					sleep 1
				done
			fi
		;;
		"${commands[2]}")
			${module_options["module_immich,feature"]} ${commands[1]}
			# Wait for container to be fully removed before removing image
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			if [[ -n "${IMMICH_BASE}" && "${IMMICH_BASE}" != "/" ]]; then
				rm -rf "${IMMICH_BASE}"
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
			echo -e "Usage: ${module_options["module_immich,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_immich,example"]}"
			echo "Available commands:"
			echo -e "	install	- Install $title."
			echo -e "	remove	- Remove $title."
			echo -e "	purge	- Purge $title data folder."
			echo -e "	status	- Installation status $title."
			echo
		;;
		*)
			${module_options["module_immich,feature"]} ${commands[4]}
		;;
	esac
}
