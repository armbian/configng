module_options+=(
	["module_mysql,author"]="@igorpecovnik"
	["module_mysql,maintainer"]="@igorpecovnik"
	["module_mysql,feature"]="module_mysql"
	["module_mysql,example"]="install remove purge status help"
	["module_mysql,desc"]="Install mysql container"
	["module_mysql,status"]="Active"
	["module_mysql,doc_link"]="https://hub.docker.com/_/mysql"
	["module_mysql,group"]="Database"
	["module_mysql,port"]="3306"
	["module_mysql,arch"]="x86-64 arm64"
)

#
# Module mysql
#
function module_mysql () {
	local title="mysql"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=mysql" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep '^mysql ' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mysql,example"]}"

	MYSQL_BASE="${SOFTWARE_FOLDER}/mysql"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			# Exit if mysql is already running
			if [[ "${container}" && "${image}" ]]; then
				echo "MySQL container is already installed."
				exit 0
			fi

			MYSQL_ROOT_PASSWORD="${2:-armbian}"
			MYSQL_DATABASE="${3:-armbian}"
			MYSQL_USER="${4:-armbian}"
			MYSQL_PASSWORD="${5:-armbian}"

			[[ -d "$MYSQL_BASE" ]] || mkdir -p "$MYSQL_BASE" || { echo "Couldn't create storage directory: $MYSQL_BASE"; exit 1; }

			docker run -d \
				--name mysql \
				--net=lsio \
				-e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
				-e MYSQL_DATABASE="${MYSQL_DATABASE}" \
				-e MYSQL_USER="${MYSQL_USER}" \
				-e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
				-v "${MYSQL_BASE}:/var/lib/mysql" \
				-p "${module_options["module_mysql,port"]}:3306" \
				--restart unless-stopped \
				mysql:lts

			# Wait for MySQL to be ready
			until docker exec mysql \
				env MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
				mysql -uroot -e "SELECT 1;" &>/dev/null; do
				echo "⏳ Waiting for MySQL to accept connections..."
				sleep 2
			done

			# Create additional databases
			MYSQL_DATABASES=("ghost") # Add any additional databases you want to create here
			for MYSQL_DATABASE in "${MYSQL_DATABASES[@]}"; do
				echo "⏳ Creating database: $MYSQL_DATABASE and granting privileges..."

				docker exec -i mysql \
				env MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
				mysql -uroot <<-EOF
					CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
					GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '${MYSQL_USER}'@'%';
					FLUSH PRIVILEGES;
				EOF
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
		;;
		"${commands[2]}")
			${module_options["module_mysql,feature"]} ${commands[1]}
			if [[ -n "${MYSQL_BASE}" && "${MYSQL_BASE}" != "/" ]]; then
				rm -rf "${MYSQL_BASE}"
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
			echo -e "\nUsage: ${module_options["module_mysql,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_mysql,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\t         Optionally accepts arguments:"
			echo -e "\t         root_password database user user_password"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_mysql,feature"]} ${commands[4]}
		;;
	esac
}
