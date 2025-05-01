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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/immich?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/immich?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_immich,example"]}"

	IMMICH_BASE="${SOFTWARE_FOLDER}/immich"

	case "$1" in
		"${commands[0]}")
			shift

			if ! pkg_installed docker-ce; then
				module_docker install
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
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^postgres$'; then module_postgres install; fi

			until docker exec -i postgres psql -U armbian -c '\q' 2>/dev/null; do
				echo "⏳ Waiting for PostgreSQL to be ready..."
				sleep 2
			done
			echo "✅ PostgreSQL is ready. Creating Immich DB..."

			if docker exec -i postgres psql -U armbian -tAc "SELECT 1 FROM pg_database WHERE datname='immich';" | grep -q 1; then
				echo "✅ Database 'immich' exists."
			else
				docker exec -i postgres psql -U armbian <<-EOT
				CREATE DATABASE immich;
				GRANT ALL PRIVILEGES ON DATABASE immich TO armbian;
				EOT
			fi

			# Run Immich container
			if ! docker run -d \
				--name=immich \
				--net=lsio \
				-e PUID=1000 \
				-e PGID=1000 \
				-e TZ="$(cat /etc/timezone)" \
				-e DB_HOSTNAME=postgres \
				-e DB_USERNAME=armbian \
				-e DB_PASSWORD=armbian \
				-e DB_DATABASE_NAME=immich \
				-e REDIS_HOSTNAME=redis \
				-e DB_PORT=5432 \
				-e REDIS_PORT=6379 \
				-e REDIS_PASSWORD= \
				-e SERVER_HOST=0.0.0.0 \
				-e SERVER_PORT=8080 \
				-p ${module_options["module_immich,port"]}:8080 \
				-v "${IMMICH_BASE}/config:/config" \
				-v "${IMMICH_BASE}/photos:/photos" \
				-v "${IMMICH_BASE}/libraries:/libraries" \
				--restart unless-stopped \
				ghcr.io/imagegenius/immich:latest; then
					echo "❌ Failed to start Immich container"
					exit 1
			fi

			sleep 5

			if [ -t 1 ]; then
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Starting Immich\n\nPlease wait..." 10 50 0
			else
				echo "Waiting for Immich to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_immich,port"]}/ > /dev/null; then
						echo "✅ Immich is responding."
						break
					fi
				done
			fi
		;;
		"${commands[1]}")
			if [ -n "$container" ]; then
				docker container rm -f "$container" >/dev/null
			fi

			if [ -n "$image" ]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			module_immich "${commands[1]}"
			if [ -n "$IMMICH_BASE" ] && [ "$IMMICH_BASE" != "/" ]; then
				rm -rf "$IMMICH_BASE"
			fi
		;;
		"${commands[3]}")
			if [ -n "$container" ] && [ -n "$image" ]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_immich,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_immich,example"]}"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			module_immich "${commands[4]}"
		;;
	esac
}
