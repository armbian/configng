module_options+=(
	["module_netbox,author"]=""
	["module_netbox,maintainer"]="@igorpecovnik"
	["module_netbox,feature"]="module_netbox"
	["module_netbox,example"]="install remove purge status help"
	["module_netbox,desc"]="Install NetBox container (IPAM/DCIM tool)"
	["module_netbox,status"]="Active"
	["module_netbox,doc_link"]="https://netbox.readthedocs.io/en/stable/"
	["module_netbox,group"]="Management"
	["module_netbox,port"]="8222"
	["module_netbox,arch"]="x86-64 arm64"
	["module_netbox,dockerimage"]="netboxcommunity/netbox:latest"
	["module_netbox,dockername"]="netbox"
	["module_netbox,servicename"]="netbox"
)

#
# Module netbox
#
function module_netbox () {
	local title="NetBox"
	local dockerimage="${module_options["module_netbox,dockerimage"]}"
	local dockername="${module_options["module_netbox,dockername"]}"
	local port="${module_options["module_netbox,port"]}"

	# Accept optional parameters
	local SUPERUSER_EMAIL="$2"
	local SUPERUSER_PASSWORD="$3"

	# Database configuration
	local DATABASE_USER="netbox"
	local DATABASE_PASSWORD="netbox"
	local DATABASE_NAME="netbox"
	local DATABASE_HOST="postgres-netbox"
	local DATABASE_IMAGE="postgres"
	local DATABASE_TAG="17-alpine"
	local DATABASE_PORT="5432"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netbox,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/$dockername"

	case "$1" in
		"${commands[0]}") # install
			# Prompt for email and password using dialog
			[[ -z "$SUPERUSER_EMAIL" ]] && \
			SUPERUSER_EMAIL=$(dialog_inputbox "Enter NetBox superuser email" "")
			[[ -z "$SUPERUSER_EMAIL" ]] && SUPERUSER_EMAIL="info@armbian.com"
			[[ -z "$SUPERUSER_PASSWORD" ]] && \
			SUPERUSER_PASSWORD=$(dialog_passwordbox "Enter NetBox admin password" "" 8 50)
			[[ -z "$SUPERUSER_PASSWORD" ]] && SUPERUSER_PASSWORD="armbian"

			clear  # Clean up dialog artifacts

			# Create base directory
			docker_manage_base_dir create "$base_dir" || return 1

			# Install dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then
				module_redis install
			fi
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^$DATABASE_HOST$"; then
				# module_postgres install <user> <password> <db> <image-repo> <image-tag> <container-name>
				# (six positional args; image and tag must be passed separately, the
				# previous five-arg form fused them and produced
				# "postgres:17-alpine:postgres-netbox" — Docker 404 on pull.)
				module_postgres install "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_NAME" "$DATABASE_IMAGE" "$DATABASE_TAG" "$DATABASE_HOST"
			fi

			# Generate a random secret key (50+ chars)
			NETBOX_SECRET_KEY=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' </dev/urandom | head -c 64)

			# When SWAG is on this host, NetBox needs to know it lives
			# at /netbox/ — otherwise Django renders absolute paths
			# (form action="/login/?next=/netbox", static URIs like
			# /static/…) that 404 once SWAG strips them at /netbox.
			# Same applies to CSRF: Django rejects POSTs whose Origin
			# header isn't in CSRF_TRUSTED_ORIGINS, so the SWAG host
			# has to be listed there.
			#
			# Both settings are real Python in configuration.py, not
			# env vars — netboxcommunity/netbox reads /etc/netbox/
			# config/configuration.py, not BASE_PATH/CSRF_TRUSTED_*
			# from the container env.
			local netbox_base_path=""
			local netbox_csrf_origins=""
			if docker container ls -a --format "{{.Names}}" 2>/dev/null | grep -q "^swag$"; then
				netbox_base_path="BASE_PATH = 'netbox/'"
				if [[ -n "${SWAG_URL:-}" ]]; then
					netbox_csrf_origins="CSRF_TRUSTED_ORIGINS = ['https://${SWAG_URL}']"
				fi
			fi

			# Create configuration directory and file
			mkdir -p "$base_dir/config"
			if [[ ! -f "$base_dir/config/configuration.py" ]]; then
				cat > "$base_dir/config/configuration.py" <<- EOT
				ALLOWED_HOSTS = ['*']
				${netbox_base_path}
				${netbox_csrf_origins}
				DATABASE = {
					'NAME': '$DATABASE_NAME',
					'USER': '$DATABASE_USER',
					'PASSWORD': '$DATABASE_PASSWORD',
					'HOST': '$DATABASE_HOST',
					'PORT': '$DATABASE_PORT',
				}

				REDIS = {
					'tasks': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 0,
						'SSL': False,
					},
					'caching': {
						'HOST': 'redis',
						'PORT': 6379,
						'PASSWORD': '',
						'DATABASE': 1,
						'SSL': False,
					}
				}
				SECRET_KEY = '${NETBOX_SECRET_KEY}'
			EOT
			fi

			# Pull image
			docker_operation_progress pull "$dockerimage"

			# Run container. The BASE_PATH / CSRF_TRUSTED_ORIGINS
			# settings that make NetBox SWAG-aware are baked into
			# configuration.py above (env vars are not consumed by
			# upstream NetBox).
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				-e TZ="$(cat /etc/timezone)" \
				-e SUPERUSER_EMAIL="${SUPERUSER_EMAIL}" \
				-e SUPERUSER_PASSWORD="${SUPERUSER_PASSWORD}" \
				-e DB_NAME=netbox \
				-p "${port}:8080" \
				-v "${base_dir}/config:/etc/netbox/config" \
				-v "${base_dir}/reports:/etc/netbox/reports" \
				-v "${base_dir}/scripts:/etc/netbox/scripts" \
				--restart unless-stopped \
				"$dockerimage"; then
				echo "❌ Failed to start NetBox container"
				exit 1
			fi

			# Wait for web service
			sleep 5
			if [[ -t 1 ]]; then
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${port}/ > /dev/null; then
						break
					fi
				done | dialog_gauge "NetBox" "Preparing NetBox\n\nPlease wait! (can take a few minutes)"
			else
				echo "Waiting for NetBox to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${port}/ > /dev/null; then
						echo "✅ NetBox is responding."
						break
					fi
				done
			fi

			# Auto-configure SWAG reverse proxy if available.
			# linuxserver/reverse-proxy-confs:master doesn't ship a
			# netbox sample, so seed our own first.  No-op on hosts
			# without SWAG, and skipped if a sample is already in
			# place (LSIO upstream / hand-edited admin override).
			# `<<-` strips ALL leading tabs (not spaces) from each line
			# of the heredoc body before it reaches stdin, so the body
			# below uses tabs to indent in source (editorconfig keeps
			# the file tab-only) while emitting unindented nginx — the
			# server doesn't care about whitespace inside a `location`
			# block.
			docker_seed_swag_proxy_conf "netbox" <<- 'NGINX'
				## Custom Armbian seed — netbox subfolder proxy.
				## upstream NetBox runs with BASE_PATH=netbox so the
				## upstream URI is /netbox, not /. No path rewriting.
				location ^~ /netbox {
				include /config/nginx/proxy.conf;
				include /config/nginx/resolver.conf;

				set $upstream_app netbox;
				set $upstream_port 8080;
				set $upstream_proto http;

				proxy_pass $upstream_proto://$upstream_app:$upstream_port;
				}
			NGINX
			docker_configure_swag_proxy "netbox" "8080"

			# Delete default API Token
			docker exec -i "$dockername" /opt/netbox/netbox/manage.py shell -c "from users.models import Token;Token.objects.filter(key='0123456789abcdef0123456789abcdef01234567').delete();"
		;;
		"${commands[1]}") # remove
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_netbox,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only purge postgres and data directory if container/image removal succeeded
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_netbox" "$title" \
				"Docker Image: $dockerimage\nPort: $port\n\nRequires: Redis and PostgreSQL\n\nOptional arguments for install:\n  superuser_email superuser_password"
		;;
		*)
			${module_options["module_netbox,feature"]} ${commands[4]}
		;;
	esac
}
