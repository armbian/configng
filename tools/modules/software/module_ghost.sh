module_options+=(
	["module_ghost,author"]="@igorpecovnik"
	["module_ghost,maintainer"]="@igorpecovnik"
	["module_ghost,feature"]="module_ghost"
	["module_ghost,example"]="install remove purge status help"
	["module_ghost,desc"]="Install Ghost CMS container"
	["module_ghost,status"]="Active"
	["module_ghost,doc_link"]="https://ghost.org/docs/"
	["module_ghost,group"]="WebHosting"
	["module_ghost,port"]="9190"
	["module_ghost,arch"]="x86-64 arm64"
)

#
# Module ghost
#
function module_ghost () {
	local title="ghost"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
		local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
	fi

	GHOST_BASE="${SOFTWARE_FOLDER}/ghost"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_ghost,example"]}"

	case $1 in
	"${commands[0]}")

		# instatall mysql if not installed
		if ! module_mysql status; then
			module_mysql install
		fi

		# exit if ghost is already running
		if module_ghost status; then
			exit 0
		fi

		MYSQL_USER="${2:-armbian}"
		MYSQL_PASSWORD="${3:-armbian}"

		[[ -d "$GHOST_BASE" ]] || mkdir -p "$GHOST_BASE" || { echo "Couldn't create storage directory: $GHOST_BASE"; exit 1; }
		docker pull ghost:5-alpine
		docker run -d \
			--name ghost \
			--net=lsio \
			--restart unless-stopped \
			-e database__client=mysql \
			-e database__connection__host="mysql" \
			-e database__connection__user="${MYSQL_USER}" \
			-e database__connection__password="${MYSQL_PASSWORD}" \
			-e database__connection__database="ghost" \
			-p ${module_options["module_ghost,port"]}:2368 \
			-e url=http://$LOCALIPADD:${module_options["module_ghost,port"]} \
			-v "$GHOST_BASE:/var/lib/ghost/content" \
			ghost:6
		;;
	"${commands[1]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
				local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
			fi
			if [[ "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
	"${commands[2]}")
			${module_options["module_ghost,feature"]} ${commands[1]}
			if [[ -n "${GHOST_BASE}" && "${GHOST_BASE}" != "/" ]]; then
				rm -rf "${GHOST_BASE}"
			fi
		;;
	"${commands[3]}")
			if pkg_installed docker-ce; then
				local container=$(docker container ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1}')
				local image=$(docker image ls -a | mawk '/(^|[[:space:]])ghost([[:space:]]|$)/{print $1":"$2}')
			fi
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
	"${commands[4]}")
		echo -e "\nUsage: ${module_options["module_ghost,feature"]} <command>"
		echo -e "Commands:  ${module_options["module_ghost,example"]}"
		echo "Available commands:"
		echo -e "\tinstall\t- Install $title."
		echo -e "\t         Optionally accepts arguments:"
		echo -e "\t         db_host db_user db_pass db_name url"
		echo -e "\tremove\t- Remove $title."
		echo -e "\tpurge\t- Purge $title image and data."
		echo -e "\tstatus\t- Show container status."
		echo
		;;
	*)
			module_ghost "${commands[4]}"
		;;
	esac
}
