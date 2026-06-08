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
	["module_immich,servicename"]="immich"
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
				dialog_msgbox "$title" "Immich container is already installed." 8 50
				return 0
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
				# Split image and tag: "tensorchord/pgvecto-rs:pg14-v0.2.0" -> image="tensorchord/pgvecto-rs" tag="pg14-v0.2.0"
				local pg_image="${DATABASE_IMAGE%:*}"
				local pg_tag="${DATABASE_IMAGE##*:}"
				module_postgres install "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" "$pg_image" "$pg_tag" "$DATABASE_HOST"
			fi

			# Wait for PostgreSQL to be ready with dialog_gauge progress
			local max_wait_pg=60
			local wait_count_pg=0
			(
				while [[ $wait_count_pg -lt $max_wait_pg ]]; do
					if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; then
						echo "XXX"; echo "100"; echo "PostgreSQL is ready!"; echo "XXX"
						exit 0
					fi

					echo "XXX"; echo "$((wait_count_pg * 100 / max_wait_pg))"; echo "Waiting for PostgreSQL to be ready..."; echo "XXX"
					sleep 2
					((wait_count_pg++))
				done
				echo "XXX"; echo "100"; echo "Timed out waiting for PostgreSQL"; echo "XXX"
			) | dialog_gauge "$title" "Waiting for PostgreSQL..." 8 60

			# Verify PostgreSQL is ready
			if ! docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -c '\q' 2>/dev/null; then
				dialog_msgbox "$title Installation Failed" \
					"PostgreSQL container failed to start properly.\n\nCheck logs with: docker logs $DATABASE_HOST" \
					10 60
				return 1
			fi

			dialog_infobox "$title" "Creating Immich database..." 5 50

			# Create database if it doesn't exist
			dialog_infobox "$title" "Checking database..." 5 50
			if docker exec -i $DATABASE_HOST psql -U $DATABASE_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" | grep -q 1; then
				dialog_infobox "$title" "✅ Database '$DATABASE_NAME' already exists." 5 50
			else
				dialog_infobox "$title" "Creating database '$DATABASE_NAME'..." 5 50
				docker exec -i $DATABASE_HOST psql -U $DATABASE_USER <<-EOT
				CREATE DATABASE $DATABASE_NAME;
				GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
				EOT
				dialog_infobox "$title" "✅ Database '$DATABASE_NAME' created successfully." 5 50
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Run container
			docker_operation_progress run "$dockername" \
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
				"$dockerimage"

			# Wait for Immich service to be available with dialog_gauge progress
			local max_wait_immich=120
			local wait_count_immich=0
			(
				while [[ $wait_count_immich -lt $max_wait_immich ]]; do
					if curl -sf http://localhost:${port}/ > /dev/null; then
						echo "XXX"; echo "100"; echo "Immich is ready!"; echo "XXX"
						exit 0
					fi

					echo "XXX"; echo "$((wait_count_immich * 100 / max_wait_immich))"; echo "Waiting for Immich to start..."; echo "XXX"
					sleep 2
					((wait_count_immich++))
				done
				echo "XXX"; echo "100"; echo "Timed out waiting for Immich"; echo "XXX"
			) | dialog_gauge "$title" "Starting Immich..." 8 60

			# Auto-configure SWAG reverse proxy if available
			docker_configure_swag_proxy "immich" "8080"

			# Verify Immich is responding
			if ! curl -sf http://localhost:${port}/ > /dev/null; then
				dialog_msgbox "$title Warning" \
					"Immich container started but may not be fully ready yet.\n\nCheck status with: docker logs $dockername" \
					10 60
			else
				dialog_msgbox "$title Installation Complete" \
					"Immich has been installed successfully!\n\nAccess at: http://localhost:${port}\n\nDefault credentials need to be created on first visit." \
					12 60
			fi
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_immich,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only purge postgres and data directory if container/image removal succeeded
			local pg_image="${DATABASE_IMAGE%:*}"
			local pg_tag="${DATABASE_IMAGE##*:}"
			module_postgres purge "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" "$pg_image" "$pg_tag" "$DATABASE_HOST"
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_immich" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nRequires: Redis and PostgreSQL with vector support"
		;;
		*)
			${module_options["module_immich,feature"]} ${commands[4]}
		;;
	esac
}
