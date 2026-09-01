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
	["module_hedgedoc,dockerimage"]="quay.io/hedgedoc/hedgedoc:latest"
	["module_hedgedoc,dockername"]="hedgedoc"
)

#
# Module hedgedoc
#
function module_hedgedoc () {
	local title="HedgeDoc"
	local dockerimage="${module_options["module_hedgedoc,dockerimage"]}"
	local dockername="${module_options["module_hedgedoc,dockername"]}"
	local port="${module_options["module_hedgedoc,port"]}"
	local DATABASE_HOST="hedgedoc-db"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hedgedoc,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"
	local DOMAIN="${2:-$LOCALIPADD}"
	local USE_SSL="${3:-false}"

	case "$1" in
		"${commands[0]}") # install
			# Check if already installed
			if docker_is_installed "$dockername" "$dockerimage"; then
				return 0
			fi

			# Database configuration
			local DATABASE_USER="hedgedoc"
			local DATABASE_NAME="hedgedoc"
			local DATABASE_IMAGE="postgres"
			local DATABASE_TAG="16-alpine"
			local DATABASE_PASSWORD
			local session_secret

			# Generate secure passwords and secrets
			DATABASE_PASSWORD=$(openssl rand -hex 16)
			session_secret=$(openssl rand -hex 32)

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1
			mkdir -p "${base_dir}/uploads"

			# Remove existing PostgreSQL container if present to ensure fresh installation
			if docker container ls -a --format '{{.Names}}' | grep -q "^${DATABASE_HOST}$"; then
				dialog_msgbox "Existing Database" \
					"Removing existing PostgreSQL container to ensure clean installation." 6 60
				module_postgres purge "" "" "" "" "" "$DATABASE_HOST"
			fi

			# Install PostgreSQL
			module_postgres install "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" \
				"$DATABASE_IMAGE" "$DATABASE_TAG" "$DATABASE_HOST"

			# Wait for PostgreSQL to be ready with progress
			local max_wait=30
			local wait_count=0
			(
				while [[ $wait_count -lt $max_wait ]]; do
					if docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" -c '\q' &>/dev/null; then
						echo "XXX"; echo "100"; echo "PostgreSQL is ready!"; echo "XXX"
						exit 0
					fi
					echo "XXX"; echo "$((wait_count * 100 / max_wait))"; \
						echo "Waiting for PostgreSQL to be ready..."; echo "XXX"
					sleep 2
					((wait_count++))
				done
				echo "XXX"; echo "0"; echo "PostgreSQL ready timeout"; echo "XXX"
				exit 1
			) | dialog_gauge "$title" "Waiting for PostgreSQL..." 8 60

			# Create database - drop if exists to ensure clean installation
			if docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME';" 2>/dev/null | grep -q 1; then
				# Database exists, drop it to ensure clean installation
				docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" <<-EOT
				DROP DATABASE $DATABASE_NAME;
				EOT
			fi

			# Create fresh database
			docker exec "$DATABASE_HOST" psql -U "$DATABASE_USER" -d "postgres" <<-EOT
			CREATE DATABASE $DATABASE_NAME;
			GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
			EOT

			dialog_msgbox "Database Ready" \
				"Database '$DATABASE_NAME' is ready for use." 6 50


			# Pull HedgeDoc image with progress
			docker_operation_progress pull "$dockerimage"

			# Run HedgeDoc container
			docker_operation_progress run "$dockername" \
				-d \
				--name "$dockername" \
				--net lsio \
				-e CMD_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:5432/${DATABASE_NAME}" \
				-e CMD_DOMAIN="${DOMAIN}" \
				-e CMD_PROTOCOL_USESSL="${USE_SSL}" \
				-e CMD_SESSION_SECRET="${session_secret}" \
				-e CMD_ALLOW_ANONYMOUS=true \
				-e CMD_URL_ADDPORT=false \
				-e CMD_ALLOW_EMAIL_REGISTER=true \
				-p "${port}:3000" \
				-v "${base_dir}/uploads:/hedgedoc/public/uploads" \
				--restart unless-stopped \
				"$dockerimage"

			# Wait for container to be ready
			wait_for_container_ready "$dockername" 30 3 "running"
		;;
		"${commands[1]}") # remove
			# Remove container and image
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_hedgedoc,feature"]} ${commands[1]}; then
				return 1
			fi
			# Purge PostgreSQL database
			module_postgres purge "" "" "" "" "" "$DATABASE_HOST"
			# Remove data directory
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_hedgedoc" "$title" \
				"Docker Image: $dockerimage\nPort: $port\nDatabase: PostgreSQL"
		;;
		*)
			${module_options["module_hedgedoc,feature"]} ${commands[4]}
		;;
	esac
}
