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
)

#
# Module netbox
#
function module_netbox () {
	local title="netbox"
	local condition=$(which "$title" 2>/dev/null)

	# Accept optional parameters
	local SUPERUSER_EMAIL="$2"
	local SUPERUSER_PASSWORD="$3"

	# Database
	local DATABASE_USER="netbox"
	local DATABASE_PASSWORD="netbox"
	local DATABASE_NAME="netbox"
	local DATABASE_HOST="postgres-netbox"
	local DATABASE_IMAGE="postgres:17-alpine"
	local DATABASE_PORT="5432"

	if pkg_installed docker-ce; then
		local container=$(docker ps -q -f "name=^netbox$")
		local image=$(docker images -q netboxcommunity/netbox)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netbox,example"]}"

	NETBOX_BASE="${SOFTWARE_FOLDER}/netbox"

	case "$1" in
		"${commands[0]}")
			# Prompt for email and password using dialog
			[[ -z "$SUPERUSER_EMAIL" ]] && \
			SUPERUSER_EMAIL=$($DIALOG --title "Enter NetBox superuser email" --inputbox "" 8 50 3>&1 1>&2 2>&3)
			[[ -z "$SUPERUSER_EMAIL" ]] && SUPERUSER_EMAIL="info@armbian.com"
			[[ -z "$SUPERUSER_PASSWORD" ]] && \
			SUPERUSER_PASSWORD=$($DIALOG --title "Enter NetBox admin password" --passwordbox "" 8 50 3>&1 1>&2 2>&3)
			[[ -z "$SUPERUSER_PASSWORD" ]] && SUPERUSER_PASSWORD="armbian"

			clear  # Clean up dialog artifacts

			pkg_installed docker-ce || module_docker install
			[[ -d "$NETBOX_BASE" ]] || mkdir -p "$NETBOX_BASE" || { echo "Couldn't create storage directory: $NETBOX_BASE"; exit 1; }

			# Install armbian-config dependencies
			if ! docker container ls -a --format '{{.Names}}' | grep -q '^redis$'; then module_redis install; fi
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^$DATABASE_HOST$"; then
				module_postgres install $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			fi

			# Generate a random secret key (50+ chars)
			NETBOX_SECRET_KEY=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' </dev/urandom | head -c 64)

			# Generate starting configuration
			[[ -d "$NETBOX_BASE/config" ]] || mkdir -p "$NETBOX_BASE/config"

			if [[ ! -f "$NETBOX_BASE/config/configuration.py" ]]; then
				cat > "$NETBOX_BASE/config/configuration.py" <<- EOT
				ALLOWED_HOSTS = ['*']
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

			# Download or update image
			docker pull netboxcommunity/netbox:latest

			if ! docker run -d \
			--name=netbox \
			--net=lsio \
			-e TZ="$(cat /etc/timezone)" \
			-e SUPERUSER_EMAIL="${SUPERUSER_EMAIL}" \
			-e SUPERUSER_PASSWORD="${SUPERUSER_PASSWORD}" \
			-e DB_NAME=netbox \
			-p ${module_options["module_netbox,port"]}:8080 \
			-v "${NETBOX_BASE}/config:/etc/netbox/config" \
			-v "${NETBOX_BASE}/reports:/etc/netbox/reports" \
			-v "${NETBOX_BASE}/scripts:/etc/netbox/scripts" \
			--restart unless-stopped \
			netboxcommunity/netbox:latest ; then
				echo "❌ Failed to start NetBox container"; exit 1
			fi

			# waiting for web
			sleep 5

			if [[ -t 1 ]]; then
				# We have a terminal, use dialog
				for s in {1..30}; do
					for i in {0..100..10}; do
						echo "$i"
						sleep 1
					done
					if curl -sf http://localhost:${module_options["module_netbox,port"]}/ > /dev/null; then
						break
					fi
				done | $DIALOG --gauge "Preparing NetBox\n\nPlease wait! (can take a few minutes) " 10 50 0
			else
				# No terminal, fallback to echoing progress
				echo "Waiting for NetBox to become available..."
				for s in {1..30}; do
					sleep 10
					if curl -sf http://localhost:${module_options["module_netbox,port"]}/ > /dev/null; then
						echo "✅ NetBox is responding."
						break
					fi
				done
			fi

			# Delete default API Token
			docker exec -i netbox /opt/netbox/netbox/manage.py shell -c "from users.models import Token;Token.objects.filter(key='0123456789abcdef0123456789abcdef01234567').delete();"

		;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_netbox,feature"]} ${commands[1]}
			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
			module_postgres purge $DATABASE_USER $DATABASE_PASSWORD $DATABASE_NAME $DATABASE_IMAGE $DATABASE_HOST
			if [[ -n "${NETBOX_BASE}" && "${NETBOX_BASE}" != "/" ]]; then
				rm -rf "${NETBOX_BASE}"
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
			echo -e "\nUsage: ${module_options["module_netbox,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netbox,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\thelp\t- Show this help message."
			echo
		;;
		*)
			${module_options["module_netbox,feature"]} ${commands[4]}
		;;
	esac
}
