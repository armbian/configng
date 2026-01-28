module_options+=(
	["module_actualbudget,author"]="@armbian"
	["module_actualbudget,maintainer"]="@igorpecovnik"
	["module_actualbudget,feature"]="module_actualbudget"
	["module_actualbudget,example"]="install remove purge status help"
	["module_actualbudget,desc"]="Install actualbudget container"
	["module_actualbudget,status"]="Active"
	["module_actualbudget,doc_link"]="https://actualbudget.org/docs"
	["module_actualbudget,group"]="Finances"
	["module_actualbudget,port"]="5443"
	["module_actualbudget,arch"]="x86-64 arm64"
)
#
# Manages the lifecycle of the ActualBudget Docker container module.
#
# Supports installing, removing, purging, checking status, and displaying help for the ActualBudget containerized application.
#
function module_actualbudget () {
	local title="actualbudget"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi
	local container=$(docker container ls -a --filter "name=my_actual_budget" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'actual' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_actualbudget,example"]}"

	ACTUALBUDGET_BASE="${SOFTWARE_FOLDER}/actualbudget"

	case "$1" in
		"${commands[0]}")
			[[ -d "$ACTUALBUDGET_BASE" ]] || mkdir -p "$ACTUALBUDGET_BASE" || { echo "Couldn't create storage directory: $ACTUALBUDGET_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-e TZ="$(cat /etc/timezone)" \
			--name my_actual_budget \
			-v "${ACTUALBUDGET_BASE}/data:/data" \
			-p 5006:5006 \
			-p ${module_options["module_actualbudget,port"]}:443 \
			--restart=always \
			actualbudget/actual-server:latest
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' my_actual_budget 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs my_actual_budget\`)"
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
			${module_options["module_actualbudget,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			${module_options["module_actualbudget,feature"]} ${commands[1]}
			if [[ -n "${ACTUALBUDGET_BASE}" && "${ACTUALBUDGET_BASE}" != "/" ]]; then
				rm -rf "${ACTUALBUDGET_BASE}"
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
