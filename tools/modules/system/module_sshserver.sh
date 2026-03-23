module_options+=(
	["module_openssh-server,author"]="@armbian"
	["module_openssh-server,maintainer"]="@igorpecovnik"
	["module_openssh-server,feature"]="module_openssh-server"
	["module_openssh-server,example"]="install remove purge status help"
	["module_openssh-server,desc"]="Install openssh-server container"
	["module_openssh-server,status"]="Active"
	["module_openssh-server,doc_link"]="https://docs.linuxserver.io/images/docker-openssh-server/#server-mode"
	["module_openssh-server,group"]="Network"
	["module_openssh-server,port"]="2222"
	["module_openssh-server,arch"]="x86-64 arm64"
)
#
# Module openssh-server
#
function module_openssh-server () {
	local title="openssh-server"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=openssh-server" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep 'lscr.io/linuxserver/openssh-server:' | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openssh-server,example"]}"

	OPENSSHSERVER_BASE="${SOFTWARE_FOLDER}/openssh-server"

	case "$1" in
		"${commands[0]}")
			[[ -d "${OPENSSHSERVER_BASE}" ]] || mkdir -p "${OPENSSHSERVER_BASE}" || { echo "Couldn't create storage directory: ${OPENSSHSERVER_BASE}"; return 1; }
			USER_NAME=$(dialog_inputbox "Enter username" "\nHit enter for defaults" "upload")
			PUBLIC_KEY=$(dialog_inputbox "Enter public key" "" "" 9 50)
			MOUNT_POINT=$(dialog_inputbox "Enter shared folder path" "" "${SOFTWARE_FOLDER}/swag/config/www")
			docker run -d \
			--name=openssh-server \
			--net=lsio \
			--hostname=openssh-server `#optional` \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			-e PUBLIC_KEY="${PUBLIC_KEY}"  \
			-e SUDO_ACCESS=false \
			-e PASSWORD_ACCESS=false  \
			-e USER_PASSWORD=password \
			-e USER_NAME="${USER_NAME}" \
			-p 2222:2222 \
			-v "${OPENSSHSERVER_BASE}/config:/config" \
			-v "${MOUNT_POINT}:/config/storage" \
			--restart unless-stopped \
			lscr.io/linuxserver/openssh-server:latest
			wait_for_container_ready "openssh-server" 20 3 "running" || return 1
			# read container version
			container_version=$(docker exec openssh-server /bin/bash -c "grep ^PRETTY_NAME= /etc/os-release | sed -E 's/PRETTY_NAME=\"([^\"]*) v[0-9].*/\\1/'")
			# install rsync
			docker exec openssh-server /bin/bash -c "
			apk update; apk add rsync;
			echo '' > /etc/motd;
			echo \"Welcome to your sandboxed Armbian SSH environment running $container_version\" >> /etc/motd;
			echo '' >> /etc/motd;
			"
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_openssh-server,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${OPENSSHSERVER_BASE}" && "${OPENSSHSERVER_BASE}" != "/" ]]; then
				rm -rf "${OPENSSHSERVER_BASE}"
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
			echo -e "\nUsage: ${module_options["module_openssh-server,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openssh-server,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_openssh-server,feature"]} ${commands[4]}
		;;
	esac
}
