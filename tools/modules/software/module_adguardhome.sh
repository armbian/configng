module_options+=(
	["module_adguardhome,author"]="@igorpecovnik"
	["module_adguardhome,maintainer"]="@igorpecovnik"
	["module_adguardhome,feature"]="module_adguardhome"
	["module_adguardhome,example"]="install remove purge status help"
	["module_adguardhome,desc"]="Install adguardhome container"
	["module_adguardhome,status"]="Active"
	["module_adguardhome,doc_link"]="https://github.com/AdguardTeam/AdGuardHome/wiki"
	["module_adguardhome,group"]="DNS"
	["module_adguardhome,port"]="3000"
	["module_adguardhome,arch"]=""
)
#
# Module adguardhome
#
function module_adguardhome () {
	local title="adguardhome"
	local condition=$(which "$title" 2>/dev/null)

	# Ensure Docker is available for commands that need it (install, remove, purge)
	if [[ "$1" != "status" && "$1" != "help" ]]; then
		if ! module_docker status >/dev/null 2>&1; then
			module_docker install
		fi
	fi
	local container=$(docker container ls -a --filter "name=adguardhome" --format '{{.ID}}' 2>/dev/null) || echo ""
	local image=$(docker image ls -a --format '{{.Repository}} {{.ID}}' 2>/dev/null | grep 'adguard' | awk '{print $2}') || echo ""

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_adguardhome,example"]}"

	ADGUARDHOME_BASE="${SOFTWARE_FOLDER}/adguardhome"

	case "$1" in
		"${commands[0]}")
			if ! module_docker status >/dev/null 2>&1; then
				module_docker install
			fi
			[[ -d "$ADGUARDHOME_BASE" ]] || mkdir -p "$ADGUARDHOME_BASE" || { echo "Couldn't create storage directory: $ADGUARDHOME_BASE"; exit 1; }
			if [[ ! -f "/etc/systemd/resolved.conf.d/armbian-defaults.conf" ]]; then
				${module_options["module_adguardhome,feature"]} ${commands[1]}
			fi
			docker run -d \
			--net=host \
			-p 53:53/tcp -p 53:53/udp \
			-p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp \
			-p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
			-v "${ADGUARDHOME_BASE}/workdir:/opt/adguardhome/work" \
			-v "${ADGUARDHOME_BASE}/confdir:/opt/adguardhome/conf" \
			--name adguardhome \
			--restart=always \
			adguard/adguardhome
			#-p 67:67/udp -p 68:68/udp \ # add if you intend to use AdGuard Home as a DHCP server.
			#-p 853:853/tcp \ # if you are going to run AdGuard Home as a DNS-over-TLS⁠ server.
			#-p 5443:5443/tcp -p 5443:5443/udp \ add if you are going to run AdGuard Home as a DNSCrypt⁠ server.
			# More info: https://hub.docker.com/r/adguard/adguardhome
			for i in $(seq 1 20); do
				state="$(docker inspect -f '{{.State.Status}}' adguardhome 2>/dev/null || true)"
				if [[ "$state" == "running" ]]; then
					break
				fi
				sleep 3
				if [[ $i -eq 20 ]]; then
					echo -e "\nTimed out waiting for ${title} to start, consult logs (\`docker logs adguardhome\`)"
					exit 1
				fi
			done
			local container_ip=$(docker inspect --format '{{ .NetworkSettings.Networks.lsio.IPAddress }}' adguardhome)
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNS=127.0.0.1 ${container_ip}
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[1]}")
			if [[ "${container}" ]]; then
				echo "Removing container: $container"
				docker container rm -f "$container"
			fi
			# restore DNS settings
			if srv_active systemd-resolved; then
				mkdir -p /etc/systemd/resolved.conf.d/
				cat > "/etc/systemd/resolved.conf.d/armbian-defaults.conf" <<- EOT
				[Resolve]
				DNSStubListener=no
				EOT
				srv_restart systemd-resolved
				sleep 2
			fi
		;;
		"${commands[2]}")
			${module_options["module_adguardhome,feature"]} ${commands[1]}
			if [[ "${image}" ]]; then
				docker image rm "$image"
			fi
			${module_options["module_adguardhome,feature"]} ${commands[1]}
			if [[ -n "${ADGUARDHOME_BASE}" && "${ADGUARDHOME_BASE}" != "/" ]]; then
				rm -rf "${ADGUARDHOME_BASE}"
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
			echo -e "\nUsage: ${module_options["module_adguardhome,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_adguardhome,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tpurge\t- Purge $title data folder."
			echo -e "\tstatus\t- Installation status $title."

			echo
		;;
		*)
			${module_options["module_adguardhome,feature"]} ${commands[4]}
		;;
	esac
}
