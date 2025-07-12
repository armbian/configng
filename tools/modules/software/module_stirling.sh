module_options+=(
	["module_stirling,author"]="@Frooodle"
	["module_stirling,maintainer"]="@igorpecovnik"
	["module_stirling,feature"]="module_stirling"
	["module_stirling,example"]="install remove purge status help"
	["module_stirling,desc"]="Install stirling container"
	["module_stirling,status"]="Active"
	["module_stirling,doc_link"]="https://docs.stirlingpdf.com"
	["module_stirling,group"]="Media"
	["module_stirling,port"]="8075"
	["module_stirling,arch"]="x86-64 arm64"
)
#
# Module stirling-PDF
#
function module_stirling () {
	local title="stirling"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/stirling-pdf?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/stirling-pdf?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_stirling,example"]}"

	STIRLING_BASE="${SOFTWARE_FOLDER}/stirling"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$STIRLING_BASE" ]] || mkdir -p "$STIRLING_BASE" || { echo "Couldn't create storage directory: $STIRLING_BASE"; exit 1; }
			docker run -d \
			--net=lsio \
			-p ${module_options["module_stirling,port"]}:8080 \
			-v "${STIRLING_BASE}/trainingData:/usr/share/tessdata" \
			-v "${STIRLING_BASE}/extraConfigs:/configs" \
			-v "${STIRLING_BASE}/logs:/logs" \
			-v "${STIRLING_BASE}/customFiles:/customFiles" \
			-e DOCKER_ENABLE_SECURITY=false \
			-e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
			-e LANGS=en_GB \
			--name stirling-pdf \
			--restart unless-stopped \
			stirlingtools/stirling-pdf:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' stirling-pdf >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs stirling-pdf\`)"
					exit 1
				fi
			done
		;;
		"${commands[1]}")
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		"${commands[2]}")
			${module_options["module_stirling,feature"]} ${commands[1]}
			[[ -n "${STIRLING_BASE}" && "${STIRLING_BASE}" != "/" ]] && rm -rf "${STIRLING_BASE}"
		;;
		"${commands[3]}")
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_stirling,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_stirling,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_stirling,feature"]} ${commands[4]}
		;;
	esac
}
