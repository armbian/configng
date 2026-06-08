module_options+=(
	["module_aptcacherng,author"]="@sameersbn"
	["module_aptcacherng,maintainer"]="@igorpecovnik"
	["module_aptcacherng,feature"]="module_aptcacherng"
	["module_aptcacherng,example"]="install remove purge status help"
	["module_aptcacherng,desc"]="Install apt-cacher-ng container (caching proxy for Debian/Ubuntu apt repos)"
	["module_aptcacherng,status"]="Active"
	["module_aptcacherng,doc_link"]="https://www.unix-ag.uni-kl.de/~bloch/acng/"
	["module_aptcacherng,group"]="Utilities"
	["module_aptcacherng,port"]="3142"
	["module_aptcacherng,arch"]="x86-64 arm64"
	["module_aptcacherng,dockerimage"]="sameersbn/apt-cacher-ng:3.3-20200524"
	["module_aptcacherng,dockername"]="apt-cacher-ng"
)
#
# Module apt-cacher-ng
#
function module_aptcacherng () {
	local title="apt-cacher-ng"
	local dockerimage="${module_options["module_aptcacherng,dockerimage"]}"
	local dockername="${module_options["module_aptcacherng,dockername"]}"
	local port="${module_options["module_aptcacherng,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_aptcacherng,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/${dockername}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the cache bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--init \
				--net=lsio \
				--restart=always \
				--publish "${port}:3142" \
				--volume "${base_dir}/cache:/var/cache/apt-cacher-ng" \
				"$dockerimage"

			local install_msg="apt-cacher-ng is listening on port ${port}\n\nPoint clients at this server by adding the following line to\n/etc/apt/apt.conf.d/00aptproxy on each consumer host:\n\n  Acquire::http::Proxy \"http://${LOCALIPADD}:${port}\";\n\nStatus page: http://${LOCALIPADD}:${port}/acng-report.html"

			if [[ -t 1 ]]; then
				dialog_msgbox "apt-cacher-ng installed" "$install_msg" 16 70
			else
				echo -e "\n${install_msg}\n"
			fi
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_aptcacherng,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove cache directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_aptcacherng" "$title" \
				"Caching proxy for Debian / Ubuntu apt repositories.\n\nProxy port: ${port}\nDocker Image: ${dockerimage}\nCache directory: ${base_dir}/cache\nStatus page: http://localhost:${port}/acng-report.html\n\nClient configuration — on each apt host:\n  echo 'Acquire::http::Proxy \"http://<server>:${port}\";' \\\\\n    | sudo tee /etc/apt/apt.conf.d/00aptproxy"
		;;
		*)
			${module_options["module_aptcacherng,feature"]} ${commands[4]}
		;;
	esac
}
