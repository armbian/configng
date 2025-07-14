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

		SMTP_SERVER="${4:-smtp.eu.mailgun.org}"
		SMTP_PORT="${5:-465}"
		SMTP_SECURE="${6:-true}"

		GHOST_URL=$($DIALOG --title "Enter Ghost URL" --inputbox "\nHit enter for defaults" 9 50 "http://$LOCALIPADD:${module_options["module_ghost,port"]}" 3>&1 1>&2 2>&3)
		SMTP_USER=$($DIALOG --title "Enter Mailgun SMTP user name" --inputbox "\nHit enter for defaults" 9 50 "postmaster@yourdomain.com" 3>&1 1>&2 2>&3)
		SMTP_PASS=$($DIALOG --title "Enter Mailgun SMTP password" --inputbox "\nHit enter for defaults" 9 50 "your-mailgun-smtp-password" 3>&1 1>&2 2>&3)
		SMTP_FROM=$($DIALOG --title "Enter Mailgun SMTP from" --inputbox "\nHit enter for defaults" 9 50 "Ghost <noreply@yourdomain.com>" 3>&1 1>&2 2>&3)

		[[ -d "$GHOST_BASE"/settings ]] || mkdir -p "$GHOST_BASE"/settings || { echo "Couldn't create storage directory: $GHOST_BASE/settings"; exit 1; }

		# Prepare config
		cat <<- EOF > "$GHOST_BASE/settings/config.production.json"
		{
		  "url": "${GHOST_URL}",
		  "server": {
		    "port": 2368,
		    "host": "::"
			  },
		  "mail": {
		    "transport": "SMTP",
		    "options": {
	      "service": "Mailgun",
		      "host": "${SMTP_SERVER}",
		      "port": ${SMTP_PORT},
	      "secure": ${SMTP_SECURE},
	      "auth": {
	        "user": "${SMTP_USER}",
	        "pass": "${SMTP_PASS}"
		      }
		    },
		    "from": "${SMTP_FROM}"
		  },
		  "logging": {
		    "transports": [
		      "file",
		      "stdout"
		    ]
		  },
		  "process": "systemd",
		  "paths": {
		    "contentPath": "/var/lib/ghost/content"
		  }
		}
		EOF

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
			-e url="${GHOST_URL}" \
			-p ${module_options["module_ghost,port"]}:2368 \
			-v "$GHOST_BASE/content:/var/lib/ghost/content" \
			-v "$GHOST_BASE/settings/config.production.json:/var/lib/ghost/config.production.json:ro" \
			ghost:5-alpine
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
