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
# Module mariadb
#
function module_mariadb () {
	local title="mariadb"
	local condition=$(which "$title" 2>/dev/null)

	pkg_installed docker.io || module_docker install
	local container=$(docker container ls -a --filter "name=mariadb" --format '{{.ID}}')
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' | grep 'mariadb '| awk '{print $2}')

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mariadb,example"]}"

	MARIADB_BASE="${SOFTWARE_FOLDER}/mariadb"

	case "$1" in
		"${commands[0]}")
			[[ -d "$MARIADB_BASE" ]] || mkdir -p "$MARIADB_BASE" || { echo "Couldn't create storage directory: $MARIADB_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name mariadb \
			--restart=always \
			-p ${module_options["module_mariadb,port"]}:3306 \
			-v "${MARIADB_BASE}:/config" \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e "MYSQL_ROOT_PASSWORD=armbian" \
			-e "MYSQL_DATABASE=armbian" \
			-e "MYSQL_USER=armbian" \
			-e "MYSQL_PASSWORD=armbian" \
			lscr.io/linuxserver/mariadb:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' mariadb 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs mariadb\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
		;;
		"${commands[2]}")
			${module_options["module_mariadb,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
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
