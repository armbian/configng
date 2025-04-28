module_options+=(
	["module_actualbudget,author"]=""
	["module_actualbudget,maintainer"]="@igorpecovnik"
	["module_actualbudget,feature"]="module_actualbudget"
	["module_actualbudget,example"]="install remove purge status help"
	["module_actualbudget,desc"]="Install actualbudget container"
	["module_actualbudget,status"]="Active"
	["module_actualbudget,doc_link"]="https://actualbudget.org/docs"
	["module_actualbudget,group"]="Finances"
	["module_actualbudget,port"]="5006"
	["module_actualbudget,arch"]=""
)
#
# Manages the lifecycle of the ActualBudget Docker container module.
#
# Supports installing, removing, purging, checking status, and displaying help for the ActualBudget containerized application.
#
function module_actualbudget () {
	local title="actualbudget"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/my_actual_budget?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/actual-server?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_actualbudget,example"]}"

	ACTUALBUDGET_BASE="${SOFTWARE_FOLDER}/actualbudget"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$ACTUALBUDGET_BASE" ]] || mkdir -p "$ACTUALBUDGET_BASE" || { echo "Couldn't create storage directory: $ACTUALBUDGET_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			--name my_actual_budget \
			--restart=unless-stopped \
			-v "${ACTUALBUDGET_BASE}/data:/data" \
			-p 5006:5006 \
			-p 443:443 \
			--restart unless-stopped \
			actualbudget/actual-server:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' my_actual_budget >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs actualbudget\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_actualbudget,feature"]} ${commands[1]}
			[[ -n "${ACTUALBUDGET_BASE}" && "${ACTUALBUDGET_BASE}" != "/" ]] && rm -rf "${ACTUALBUDGET_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_actualbudget,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_actualbudget,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_actualbudget,feature"]} ${commands[4]}
		;;
	esac
}
