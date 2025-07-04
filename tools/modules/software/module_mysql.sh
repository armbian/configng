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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/mysql?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/mysql?( |$)/{print $1":"$2}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_mysql,example"]}"

	MYSQL_BASE="${SOFTWARE_FOLDER}/mysql"

	case $1 in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			# get parameters or fallback to dialog
			MYSQL_ROOT_PASSWORD="${2:-}"
			MYSQL_DATABASE="${3:-}"
			MYSQL_USER="${4:-}"
			MYSQL_PASSWORD="${5:-}"

			if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
				MYSQL_ROOT_PASSWORD=$($DIALOG --title "Enter root password for MySQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			fi
			if [[ -z "$MYSQL_DATABASE" ]]; then
				MYSQL_DATABASE=$($DIALOG --title "Enter database name for MySQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			fi
			if [[ -z "$MYSQL_USER" ]]; then
				MYSQL_USER=$($DIALOG --title "Enter user name for MySQL server" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			fi
			if [[ -z "$MYSQL_PASSWORD" ]]; then
				MYSQL_PASSWORD=$($DIALOG --title "Enter new password for ${MYSQL_USER}" --inputbox "\nHit enter for defaults" 9 50 "armbian" 3>&1 1>&2 2>&3)
			fi

			[[ -d "$MYSQL_BASE" ]] || mkdir -p "$MYSQL_BASE" || { echo "Couldn't create storage directory: $MYSQL_BASE"; exit 1; }

			docker pull mysql:lts
			docker run -d \
				--name mysql \
				--net=lsio \
				-e TZ="$(cat /etc/timezone)" \
				-e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-armbian}" \
				-e MYSQL_DATABASE="${MYSQL_DATABASE:-armbian}" \
				-e MYSQL_USER="${MYSQL_USER:-armbian}" \
				-e MYSQL_PASSWORD="${MYSQL_PASSWORD:-armbian}" \
				-p 3306:3306 \
				-v "${MYSQL_BASE}/data:/var/lib/mysql" \
				--restart unless-stopped \
				mysql:lts
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
			${module_options["module_mysql,feature"]} ${commands[1]}
			if [[ -n "${MYSQL_BASE}" && "${MYSQL_BASE}" != "/" ]]; then
				rm -rf "${MYSQL_BASE}"
			fi
		;;
		"${commands[3]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/mysql?( |$)/{print $1}')
				local image=$(docker image ls -a | mawk '/mysql?( |$)/{print $1":"$2}')
			fi
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
			echo -e "\t          Optionally accepts arguments:"
			echo -e "\t          root_password database user user_password"
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
