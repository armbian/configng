module_options+=(
	["module_armbianrouter,author"]="@armbian"
	["module_armbianrouter,maintainer"]="@efectn"
	["module_armbianrouter,feature"]="module_armbianrouter"
	["module_armbianrouter,example"]="install remove purge status help"
	["module_armbianrouter,desc"]="Install armbian router container"
	["module_armbianrouter,status"]="Active"
	["module_armbianrouter,doc_link"]="https://github.com/armbian/armbian-router"
	["module_armbianrouter,group"]="Armbian"
	["module_armbianrouter,port"]="8080 8081 8082 8083 8084 8100"
	["module_armbianrouter,arch"]="x86-64 arm64"
)

function download_all_images() {
	wget -qO- https://github.armbian.com/all-images.json > "${1}/all-images.json"
}

#
# Module armbianrouter
#
function module_armbianrouter () {
	local title="armbianrouter"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a --format '{{.ID}} {{.Names}}' | mawk '$2 ~ /^armbianrouter/ {print $1}')
		local image=$(docker image ls -a | mawk '/armbian-router?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbianrouter,example"]}"

	ROUTER_BASE="${SOFTWARE_FOLDER}/armbian_router"

	declare -A routers
	routers["8080"]="dlrouter-debs"
	routers["8081"]="dlrouter-images"
	routers["8082"]="dlrouter-archive"
	routers["8083"]="dlrouter-debs-beta"
	routers["8084"]="dlrouter-cache"
	routers["8100"]="dlrouter-content"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$ROUTER_BASE" ]] || mkdir -p "$ROUTER_BASE" || { echo "Couldn't create storage directory: $ROUTER_BASE"; exit 1; }

			# Download all config yaml files
			for port in "${!routers[@]}"; do
				wget -qO- https://github.armbian.com/${routers[$port]}.yaml > "${ROUTER_BASE}/${routers[$port]}.yaml"
				sed -i "s|/scripts/redirect-config|/app|g" "${ROUTER_BASE}/${routers[$port]}.yaml"
			done

			# Download geoip database
			wget -qO- https://github.armbian.com/GeoLite2-ASN.mmdb > "${ROUTER_BASE}/GeoLite2-ASN.mmdb"
			wget -qO- https://github.armbian.com/GeoLite2-City.mmdb > "${ROUTER_BASE}/GeoLite2-City.mmdb"

			# Download all images json
			download_all_images "${ROUTER_BASE}"

			for port in "${!routers[@]}"; do
				docker run -d \
					--name=armbianrouter-${routers[$port]} \
					--net=lsio \
					-p $port:$port \
					-v "${ROUTER_BASE}:/app" \
					--restart unless-stopped \
					ghcr.io/armbian/armbian-router:latest /bin/dlrouter --config /app/${routers[$port]}.yaml
				for i in $(seq 1 20); do
					if docker inspect -f '{{ index .Config.Labels "build_version" }}' armbianrouter-${routers[$port]} >/dev/null 2>&1 ; then
						break
					else
						sleep 3
					fi
					if [ $i -eq 20 ] ; then
						echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs armbianrouter-dlrouter-{debs,images,archive,debs-beta,cache}\`)"
						exit 1
					fi
				done
			done
		;;
		"${commands[1]}")
			for port in "${!routers[@]}"; do
				docker container rm -f armbianrouter-${routers[$port]} >/dev/null
			done

			if [[ "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
		;;
		"${commands[2]}")
			${module_options["module_armbianrouter,feature"]} ${commands[1]}
			if [[ -n "${ROUTER_BASE}" && "${ROUTER_BASE}" != "/" ]]; then
				rm -rf "${ROUTER_BASE}"
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
			echo -e "\nUsage: ${module_options["module_armbianrouter,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbianrouter,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_armbianrouter,feature"]} ${commands[4]}
		;;
	esac
}
