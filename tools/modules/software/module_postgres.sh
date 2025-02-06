module_options+=(
	["module_postgres,author"]="@Frooodle"
	["module_postgres,maintainer"]="@igorpecovnik"
	["module_postgres,feature"]="module_postgres"
	["module_postgres,example"]="install remove purge status help"
	["module_postgres,desc"]="Install postgres container"
	["module_postgres,status"]="Active"
	["module_postgres,doc_link"]="https://docs.postgrespdf.com"
	["module_postgres,group"]="Media"
	["module_postgres,port"]="8077"
	["module_postgres,arch"]="x86-64 arm64"
)
#
# Module postgres-PDF
#
function module_postgres () {
	local title="postgres"
	local condition=$(which "$title" 2>/dev/null)

	# read parameters from command install
	local parameter
	IFS=' ' read -r -a parameter <<< "${1}"
	for feature in postgres_user postgres_password postgres_db; do
	for selected in ${parameter[@]}; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
		done
	done

	# default values if not defined
	local postgres_user="${postgres_user:-armbian}"
	local postgres_password="${postgres_password:-armbian}"
	local postgres_db="${postgres_db:-armbian}"

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/postgres?()/{print $1}')
		local image=$(docker image ls -a | mawk '/postgres?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_postgres,example"]}"

	POSTGRES_BASE="${SOFTWARE_FOLDER}/postgres"

	case "${parameter[0]}" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$POSTGRES_BASE" ]] || mkdir -p "$POSTGRES_BASE" || { echo "Couldn't create storage directory: $POSTGRES_BASE"; exit 1; }
			#docker run -d \
			echo "
			--net=lsio \
			--name=postgres \
			-e POSTGRES_USER=${postgres_user} \
			-e POSTGRES_PASSWORD=${postgres_password} \
			-e POSTGRES_DB=${postgres_db} \
			-v "${POSTGRES_BASE}:/var/lib/postgresql/data" \
			-p 5432:5432 \
			postgres:16-alpine"
			exit
			for i in $(seq 1 20); do
				if [[ $(docker inspect -f '{{ .State.Status }}' postgres 2>/dev/null) == "running" ]] ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs postgres-pdf\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_postgres,feature"]} ${commands[1]}
			[[ -n "${POSTGRES_BASE}" && "${POSTGRES_BASE}" != "/" ]] && rm -rf "${POSTGRES_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_postgres,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_postgres,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tpostgres_user\t\t- username."
			echo -e "\tpostgres_password\t- password."
			echo -e "\tpostgres_db\t\t- database name."

			echo
		;;
		*)
			${module_options["module_postgres,feature"]} ${commands[4]}
		;;
	esac
}
