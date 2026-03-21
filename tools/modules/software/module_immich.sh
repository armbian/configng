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
	["module_immich,dockerimage"]="ghcr.io/imagegenius/immich:latest"
	["module_immich,dockername"]="immich"
)
#
# Module immich
#
function module_immich () {
	local title="Immich"
	local dockerimage="${module_options["module_immich,dockerimage"]}"
	local dockername="${module_options["module_immich,dockername"]}"
	local port="${module_options["module_immich,port"]}"

	# Database configuration
	local DATABASE_USER="immich"
	local DATABASE_PASSWORD="immich"
	local DATABASE_NAME="immich"
	local DATABASE_HOST="postgres-immich"
	local DATABASE_IMAGE="tensorchord/pgvecto-rs:pg14-v0.2.0"
	local DATABASE_PORT="5432"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_immich,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				echo "Immich container is already installed."
				exit 0
			fi

			# Create base directory and subdirectories
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "$base_dir"/photos/{backups,encoded-video,library,profile,thumbs,upload}
			mkdir -p "$base_dir"/config "$base_dir"/libraries
			touch "$base_dir"/photos/{backups,thumbs,profile,upload,library,encoded-video}/.immich
			chown -R "${DOCKER_USERUID}:${DOCKER_GROUPUID}" "$base_dir"/

			# Install dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then
				module_redis install
			fi
			if ! docker container ls -a --format '{{.Names}}' | grep "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			fi

			# Wait for PostgreSQL to be ready
			until docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; do
				echo "⏳ Waiting for PostgreSQL to be ready..."
				sleep 2
			done
			echo "✅ PostgreSQL is ready. Creating Immich DB..."

			# Create database if it doesn't exist
			if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" | grep -q 1; then
				echo "✅ Database '$DATABASE_NAME' exists."
			else
				docker exec -i $DATABASE_HOST psql -U $DATABASE_USER <<-EOT
				CREATE DATABASE $DATABASE_NAME;
				GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
				EOT
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Run container
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e PUID="${DOCKER_USERUID}" \
				-e PGID="${DOCKER_GROUPUID}" \
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
				-p "${port}:8080" \
				-v "${base_dir}/config:/config" \
				-v "${base_dir}/photos:/photos" \
				-v "${base_dir}/libraries:/libraries" \
				--restart=always \
				"$dockerimage"; then
				echo "❌ Failed to start Immich container"
				exit 1
			fi

			# Wait for service to be available
			sleep 5
			if [ -t 1 ]; then
				for s in {1..10}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${port}/ > /dev/null; then
						break
					fi
				done | dialog_gauge "Immich" "Starting Immich Please wait..."
			else
				echo "Waiting for Immich to become available..."
				for s in {1..10}; do
					sleep 10
					if curl -sf http://localhost:${port}/ > /dev/null; then
						echo "✅ Immich is responding."
						break
					fi
				done
			fi
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			${module_options["module_immich,feature"]} ${commands[1]}
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			docker_show_module_help "module_immich" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nRequires: Redis and PostgreSQL with vector support"
		;;
		*)
			${module_options["module_immich,feature"]} ${commands[4]}
		;;
	esac
}
