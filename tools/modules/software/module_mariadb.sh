module_options+=(
	["module_mariadb,author"]="@igorpecovnik"
	["module_mariadb,maintainer"]="@igorpecovnik"
	["module_mariadb,feature"]="module_mariadb"
	["module_mariadb,example"]="install remove purge status help"
	["module_mariadb,desc"]="Install mariadb container"
	["module_mariadb,status"]="Active"
	["module_mariadb,doc_link"]="https://mariadb.org/documentation/"
	["module_mariadb,group"]="Database"
	["module_mariadb,port"]="3307"
	["module_mariadb,arch"]="x86-64 arm64"
)
#
# Module mariadb-PDF
#
function module_mariadb () {
	local title="mariadb"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/mariadb?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/mariadb?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mariadb,example"]}"

	MARIADB_BASE="${SOFTWARE_FOLDER}/mariadb"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$MARIADB_BASE" ]] || mkdir -p "$MARIADB_BASE" || { echo "Couldn't create storage directory: $MARIADB_BASE"; exit 1; }

			# get parameters
			MYSQL_ROOT_PASSWORD=$($DIALOG --title "Enter root password for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_DATABASE=$($DIALOG --title "Enter database name for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_USER=$($DIALOG --title "Enter user name for Mariadb SQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			MYSQL_PASSWORD=$($DIALOG --title "Enter new password for ${MYSQL_USER}" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			docker run -d \
			--name=mariadb \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" \
			-e "MYSQL_DATABASE=${MYSQL_DATABASE}" \
			-e "MYSQL_USER=${MYSQL_USER}" \
			-e "MYSQL_PASSWORD=${MYSQL_PASSWORD}" \
			-p ${module_options["module_mariadb,port"]}:3306 \
			-v "${MARIADB_BASE}/config:/config" \
			--restart unless-stopped \
			lscr.io/linuxserver/mariadb:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' mariadb >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs mariadb\`)"
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
			${module_options["module_mariadb,feature"]} ${commands[1]}
			if [[ -n "${MARIADB_BASE}" && "${MARIADB_BASE}" != "/" ]]; then
				rm -rf "${MARIADB_BASE}"
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
			echo -e "\nUsage: ${module_options["module_mariadb,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_mariadb,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_mariadb,feature"]} ${commands[4]}
		;;
	esac
}
