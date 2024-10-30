module_options+=(
	["module_portainer,author"]="@armbian"
	["module_portainer,ref_link"]=""
	["module_portainer,feature"]="module_portainer"
	["module_portainer,desc"]="Install/uninstall/check status of portainer container"
	["module_portainer,example"]="module_portainer install|uninstall|status"
	["module_portainer,status"]="Active"
)
#
# Install portainer container
#
module_portainer() {

	if check_if_installed docker-ce; then
		local container=$(docker container ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $1}')
		local image=$(docker image ls -a | mawk '/portainer\/portainer(-ce)?( |$)/{print $3}')
	fi

	case "$1" in
		install)
			check_if_installed docker-ce || install_docker
			docker volume ls -q | grep -xq 'portainer_data' || docker volume create portainer_data
			docker run -d -p '9002:9000' --name=portainer --restart=always \
			-v '/run/docker.sock:/var/run/docker.sock' \
			-v '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro' \
			-v 'portainer_data:/data' 'portainer/portainer-ce'
		;;
		uninstall)
			[[ "${container}" ]] && docker container rm -f "$container"
			[[ "${image}" ]] && docker image rm "$image"
		;;
		status)
			[[ "${container}" ]] || [[ "${image}" ]] && return 0
		;;
	esac
}
