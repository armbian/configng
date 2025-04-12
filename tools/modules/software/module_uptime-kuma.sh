module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,maintainer"]="@igorpecovnik"
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,example"]="install remove purge status help"
	["module_uptimekuma,desc"]="Install uptimekuma container"
	["module_uptimekuma,status"]="Active"
	["module_uptimekuma,doc_link"]="https://github.com/louislam/uptime-kuma/wiki"
	["module_uptimekuma,group"]="Downloaders"
	["module_uptimekuma,port"]="3001"
	["module_uptimekuma,arch"]="x86-64 arm64"
)
#
# Module uptimekuma
#
function module_uptimekuma () {
	local title="uptimekuma"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/uptime-kuma?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/uptime-kuma?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_uptimekuma,example"]}"

	UPTIMEKUMA_BASE="${SOFTWARE_FOLDER}/uptimekuma"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$UPTIMEKUMA_BASE" ]] || mkdir -p "$UPTIMEKUMA_BASE" || { echo "Couldn't create storage directory: $UPTIMEKUMA_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			--name uptime-kuma \
			--restart=always \
			-p 3001:3001 \
			-v "${UPTIMEKUMA_BASE}:/app/data" \
			louislam/uptime-kuma:1
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' uptime-kuma >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs uptimekuma\`)"
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
			${module_options["module_uptimekuma,feature"]} ${commands[1]}
			if [[ -n "${UPTIMEKUMA_BASE}" && "${UPTIMEKUMA_BASE}" != "/" ]]; then
				rm -rf "${UPTIMEKUMA_BASE}"
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
			echo -e "\nUsage: ${module_options["module_uptimekuma,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_uptimekuma,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_uptimekuma,feature"]} ${commands[4]}
		;;
	esac
}
