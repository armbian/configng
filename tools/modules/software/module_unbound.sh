module_options+=(
	["module_unbound,author"]="@igorpecovnik"
	["module_unbound,maintainer"]="@igorpecovnik"
	["module_unbound,feature"]="module_unbound"
	["module_unbound,example"]="install remove purge status help"
	["module_unbound,desc"]="Install unbound container"
	["module_unbound,status"]="Active"
	["module_unbound,doc_link"]="https://unbound.docs.nlnetlabs.nl/en/latest/"
	["module_unbound,group"]="DNS"
	["module_unbound,port"]="5335"
	["module_unbound,arch"]="x86-64"
)
#
# Module Unbound
#
function module_unbound () {
	local title="unbound"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi

	local container=$(docker container ls -a --filter "name=unbound" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep 'alpinelinux/unbound:' | head -1) || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_unbound,example"]}"

	UNBOUND_BASE="${SOFTWARE_FOLDER}/unbound"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			# Check if the module is already installed
			if [[ "${container}" && "${image}" ]]; then
				echo "Unbound container is already installed."
				return 0
			fi

			[[ -d "$UNBOUND_BASE" ]] || mkdir -p "$UNBOUND_BASE" || { echo "Couldn't create storage directory: $UNBOUND_BASE"; exit 1; }

			# Create unbound.conf
			cat > "${UNBOUND_BASE}/unbound.conf" <<-EOT
			server:
				interface: 0.0.0.0
				port: 5335
				access-control: 0.0.0.0/0 allow
				do-ip4: yes
				do-udp: yes
				do-tcp: yes
				do-ip6: no
				verbosity: 1
			EOT

			docker run -d \
			--net=lsio \
			-e PUID=1000 \
			-e PGID=1000 \
			-p ${module_options["module_unbound,port"]}:${module_options["module_unbound,port"]}/tcp \
			-p ${module_options["module_unbound,port"]}:${module_options["module_unbound,port"]}/udp \
			-v ${UNBOUND_BASE}/unbound.conf:/etc/unbound/unbound.conf:ro \
			--name unbound \
			--restart=unless-stopped \
			alpinelinux/unbound
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' unbound >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs unbound\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
			if [[ "${image}" ]]; then
				sleep 2
				docker image rm -f "$image" 2>/dev/null || true
			fi
		;;
		"${commands[2]}")
			${module_options["module_unbound,feature"]} ${commands[1]}
			[[ -n "${UNBOUND_BASE}" && "${UNBOUND_BASE}" != "/" ]] && rm -rf "${UNBOUND_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_unbound,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_unbound,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_unbound,feature"]} ${commands[4]}
		;;
	esac
}
