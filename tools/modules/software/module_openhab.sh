module_options+=(
	["module_openhab,author"]="@igorpecovnik"
	["module_openhab,maintainer"]="@igorpecovnik"
	["module_openhab,feature"]="module_openhab"
	["module_openhab,example"]="install remove purge status help"
	["module_openhab,desc"]="Install Openhab"
	["module_openhab,status"]="Active"
	["module_openhab,doc_link"]="https://www.openhab.org/docs/tutorial"
	["module_openhab,group"]="HomeAutomation"
	["module_openhab,port"]="2080 2443 5007 9123"
	["module_openhab,arch"]="x86-64 arm64 armhf"
)
#
# Install openHAB from repo using apt
#
function module_openhab() {

	local title="openhab"
	local condition=$(which "$title" 2>/dev/null)

	if pkg_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/openhab?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/openhab?( |$)/{print $3}')
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_openhab,example"]}"

	OPENHAB_BASE="${SOFTWARE_FOLDER}/openhab"

	case "$1" in
		"${commands[0]}")
			pkg_installed docker-ce || module_docker install
			docker run -d \
			--name openhab \
			--net=lsio \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $1}'):8080 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $2}'):8443 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $3}'):5007 \
			-p $(echo "${module_options[module_openhab,port]}" | awk '{print $4}'):9123 \
			-v /etc/localtime:/etc/localtime:ro \
			-v /etc/timezone:/etc/timezone:ro \
			-v ${OPENHAB_BASE}/conf:/openhab/conf \
			-v ${OPENHAB_BASE}/userdata:/openhab/userdata \
			-v ${OPENHAB_BASE}/addons:/openhab/addons \
			-e USER_ID=1000 \
			-e GROUP_ID=1000 \
			-e CRYPTO_POLICY=unlimited \
			--restart=unless-stopped \
			openhab/openhab:latest
			;;
		"${commands[1]}")
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
			;;
		"${commands[2]}")
			${module_options["module_openhab,feature"]} ${commands[1]}
			if [[ -n "${OPENHAB_BASE}" && "${OPENHAB_BASE}" != "/" ]]; then
				rm -rf "${OPENHAB_BASE}"
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
			echo -e "\nUsage: ${module_options["module_openhab,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_openhab,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title."
			echo
		;;
		*)
			${module_options["module_haos,feature"]} ${commands[4]}
		;;
	esac
}
