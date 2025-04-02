module_options+=(
	["module_hastebin,author"]="@armbian"
	["module_hastebin,maintainer"]="@efectn"
	["module_hastebin,feature"]="module_hastebin"
	["module_hastebin,example"]="install remove purge status help"
	["module_hastebin,desc"]="Install hastebin container"
	["module_hastebin,status"]="Active"
	["module_hastebin,doc_link"]="https://github.com/rpardini/ansi-hastebin"
	["module_hastebin,group"]="Media"
	["module_hastebin,port"]="7777"
	["module_hastebin,arch"]="x86-64 arm64"
)
#
# Module hastebin
#
function module_hastebin () {
	local title="hastebin"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/hastebin?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/ansi-hastebin?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_hastebin,example"]}"

	HASTEBIN_BASE="${SOFTWARE_FOLDER}/hastebin"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			[[ -d "$HASTEBIN_BASE" ]] || mkdir -p "$HASTEBIN_BASE" || { echo "Couldn't create storage directory: $HASTEBIN_BASE"; exit 1; }
			mkdir -p "$HASTEBIN_BASE/pastes"

			wget -qO- https://raw.githubusercontent.com/armbian/hastebin-ansi/refs/heads/main/about.md > "$HASTEBIN_BASE/about.md"

			docker run -d \
			--name=hastebin \
			--net=lsio \
			-e STORAGE_TYPE=file \
			-e STORAGE_FILE_PATH="/app/pastes" \
			-e RATE_LIMITING_ENABLE=true \
			-e RATE_LIMITING_LIMIT=100 \
			-e RATE_LIMITING_WINDOW=300 \
			-p 7777:7777 \
			-v "${HASTEBIN_BASE}:/app:rw" \
			--restart unless-stopped \
			ghcr.io/armbian/ansi-hastebin:latest
			for i in $(seq 1 20); do
				if docker inspect -f '{{ index .Config.Labels "build_version" }}' hastebin >/dev/null 2>&1 ; then
					break
				else
					sleep 3
				fi
				if [ $i -eq 20 ] ; then
					echo -e "\nTimed out waiting for ${title} to start, consult your container logs for more info (\`docker logs hastebin\`)"
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
			${module_options["module_hastebin,feature"]} ${commands[1]}
			if [[ -n "${HASTEBIN_BASE}" && "${HASTEBIN_BASE}" != "/" ]]; then
				rm -rf "${HASTEBIN_BASE}"
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
			echo -e "\nUsage: ${module_options["module_hastebin,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_hastebin,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tremove\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_hastebin,feature"]} ${commands[4]}
		;;
	esac
}
