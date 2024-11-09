module_options+=(
	["module_uptimekuma,author"]="@armbian"
	["module_uptimekuma,ref_link"]=""
	["module_uptimekuma,feature"]="module_uptimekuma"
	["module_uptimekuma,desc"]="Install/uninstall/check status of uptime kuma container"
	["module_uptimekuma,example"]="install uninstall status"
	["module_uptimekuma,status"]="Active"
)
#
# Install uptime kuma
#
module_uptimekuma() {

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/uptime-kuma?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/uptime-kuma?( |$)/{print $3}')
	fi

	case "$1" in
		install)
			check_if_installed docker-ce || install_docker
			#docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1 >/dev/null
			docker run -d --quiet --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1 >/dev/null
			$DIALOG --msgbox "Uptime Kuma service has been installed successfully!\n\nIn a web browser go to http://localhost:3001 or \nhttp://127.0.0.1:3001 on this computer." 10 70
		;;
		uninstall)
			[[ "${container}" ]] && docker container rm -f "$container" >/dev/null
			[[ "${image}" ]] && docker image rm "$image" >/dev/null
		;;
		status)
			[[ "${container}" ]] || [[ "${image}" ]] && return 0
		;;
	esac
}
