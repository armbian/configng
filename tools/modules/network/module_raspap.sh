module_options+=(
	["module_raspap,author"]="@armbian"
	["module_raspap,maintainer"]="@igorpecovnik"
	["module_raspap,feature"]="module_raspap"
	["module_raspap,example"]="install remove purge status help"
	["module_raspap,desc"]="Install raspap container"
	["module_raspap,status"]="Active"
	["module_raspap,doc_link"]="https://docs.raspap.com/"
	["module_raspap,group"]="Network"
	["module_raspap,port"]="51820"
	["module_raspap,arch"]="x86-64 arm64 armhf"
)
#
# Module raspap
#
function module_raspap () {
	local title="raspap"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/raspap?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/raspap-docker?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_raspap,example"]}"

	RASPAP_BASE="${SOFTWARE_FOLDER}/raspap"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$RASPAP_BASE" ]] || mkdir -p "$RASPAP_BASE" || { echo "Couldn't create storage directory: $RASPAP_BASE"; exit 1; }
			if [[ ${ARCH} == x86_64 ]]; then
				docker run -d \
				--name raspap \
				-it \
				--privileged \
				--network=host \
				-v /sys/fs/cgroup:/sys/fs/cgroup:rw \
				--cap-add SYS_ADMIN \
				--restart unless-stopped \
				ghcr.io/raspap/raspap-docker:latest
			fi
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' raspap >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs raspap\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_raspap,feature"]} ${commands[1]}
			[[ -n "${RASPAP_BASE}" && "${RASPAP_BASE}" != "/" ]] && rm -rf "${RASPAP_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_raspap,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_raspap,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_raspap,feature"]} ${commands[4]}
		;;
	esac
}
