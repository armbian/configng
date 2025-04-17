module_options+=(
	["module_netdata,author"]="@armbian"
	["module_netdata,maintainer"]="@igorpecovnik"
	["module_netdata,feature"]="module_netdata"
	["module_netdata,example"]="install remove purge status help"
	["module_netdata,desc"]="Install netdata container"
	["module_netdata,status"]="Active"
	["module_netdata,doc_link"]="https://transmissionbt.com/"
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

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/netdata?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/netdata?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_netdata,example"]}"

	NETDATA_BASE="${SOFTWARE_FOLDER}/netdata"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$NETDATA_BASE" ]] || mkdir -p "$NETDATA_BASE" || { echo "Couldn't create storage directory: $NETDATA_BASE"; exit 1; }
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
			--restart unless-stopped \
			--cap-add SYS_PTRACE \
			--cap-add SYS_ADMIN \
			--security-opt apparmor=unconfined \
			netdata/netdata
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' netdata >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs netdata\`)"
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
			${module_options["module_netdata,feature"]} ${commands[1]}
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
			echo
		;;
		*)
			${module_options["module_netdata,feature"]} ${commands[4]}
		;;
	esac
}
