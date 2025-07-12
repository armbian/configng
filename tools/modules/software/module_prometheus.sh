module_options+=(
	["module_prometheus,author"]="@armbian"
	["module_prometheus,maintainer"]="@efectn"
	["module_prometheus,feature"]="module_prometheus"
	["module_prometheus,example"]="install remove purge status help"
	["module_prometheus,desc"]="Install prometheus container"
	["module_prometheus,status"]="Active"
	["module_prometheus,doc_link"]="https://prometheus.io/docs/"
	["module_prometheus,group"]="Monitoring"
	["module_prometheus,port"]="9191"
	["module_prometheus,arch"]="x86-64 arm64"
)
#
# Module prometheus
#
function module_prometheus () {
	local title="prometheus"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/prometheus?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/prometheus?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_prometheus,example"]}"

	PROMETHEUS_BASE="${SOFTWARE_FOLDER}/prometheus"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$PROMETHEUS_BASE" ]] || mkdir -p "$PROMETHEUS_BASE" || { echo "Couldn't create storage directory: $PROMETHEUS_BASE"; exit 1; }

			# Create dummy prometheus config file if it is not exist
			if [ ! -f "$PROMETHEUS_BASE/prometheus.yml" ]; then
				# // editorconfig-checker-disable
  				cat <<- EOF > "$PROMETHEUS_BASE/prometheus.yml"
				global:
				  scrape_interval: 15s
				  evaluation_interval: 15s

				scrape_configs:
				  - job_name: 'prometheus'
				    static_configs:
				      - targets: ['localhost:9090']
				EOF
				# // editorconfig-checker-enable
			fi

			docker run -d \
			--name=prometheus \
			--net=lsio \
			-p ${module_options["module_prometheus,port"]}:9090 \
			-v "${PROMETHEUS_BASE}:/etc/prometheus" \
			--restart unless-stopped \
			prom/prometheus
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' prometheus >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs prometheus\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_prometheus,feature"]} ${commands[1]}
			[[ -n "${PROMETHEUS_BASE}" && "${PROMETHEUS_BASE}" != "/" ]] && rm -rf "${PROMETHEUS_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_prometheus,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_prometheus,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_prometheus,feature"]} ${commands[4]}
		;;
	esac
}
