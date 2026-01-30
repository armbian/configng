module_options+=(
	["module_netdata,author"]="@armbian"
	["module_netdata,maintainer"]="@igorpecovnik"
	["module_netdata,feature"]="module_netdata"
	["module_netdata,example"]="install remove purge status help"
	["module_netdata,desc"]="Install netdata container"
	["module_netdata,status"]="Active"
	["module_netdata,doc_link"]="https://learn.netdata.cloud/"
	["module_netdata,group"]="Monitoring"
	["module_netdata,port"]="19999"
	["module_netdata,arch"]="x86-64 arm64"
)
#
# Module netdata
#
function module_netdata () {
	local title="netdata"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=netdata" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'netdata' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netdata,example"]}"

	NETDATA_BASE="${SOFTWARE_FOLDER}/netdata"

	case "$1" in
		"${commands[0]}")
			[[ -d "$NETDATA_BASE" ]] || mkdir -p "$NETDATA_BASE" || { echo "Couldn't create storage directory: $NETDATA_BASE"; return 1; }
			docker run -d \
			--name=netdata \
			--pid=host \
			--network=host \
			-v "${NETDATA_BASE}/netdataconfig:/etc/netdata" \
			-v "${NETDATA_BASE}/netdatalib:/var/lib/netdata" \
			-v "${NETDATA_BASE}/netdatacache:/var/cache/netdata" \
			-v /:/host/root:ro,rslave \
			-v /etc/passwd:/host/etc/passwd:ro \
			-v /etc/group:/host/etc/group:ro \
			-v /etc/localtime:/etc/localtime:ro \
			-v /proc:/host/proc:ro \
			-v /sys:/host/sys:ro \
			-v /etc/os-release:/host/etc/os-release:ro \
			-v /var/log:/host/var/log:ro \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart=always \
			--cap-add SYS_PTRACE \
			--cap-add SYS_ADMIN \
			--security-opt apparmor=unconfined \
			netdata/netdata
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' netdata 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
				break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs netdata\`)"
					return 1
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
			${module_options["module_netdata,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
			if [[ -n "${NETDATA_BASE}" && "${NETDATA_BASE}" != "/" ]]; then
				rm -rf "${NETDATA_BASE}"
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
			echo -e "\nUsage: ${module_options["module_netdata,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_netdata,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_netdata,feature"]} ${commands[4]}
		;;
	esac
}
