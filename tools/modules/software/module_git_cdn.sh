module_options+=(
	["module_git_cdn,author"]="@igorpecovnik"
	["module_git_cdn,maintainer"]="@igorpecovnik"
	["module_git_cdn,feature"]="module_git_cdn"
	["module_git_cdn,example"]="install remove purge status help"
	["module_git_cdn,desc"]="Install git_cdn container (caching git+http proxy for GitHub clones)"
	["module_git_cdn,status"]="Active"
	["module_git_cdn,doc_link"]="https://gitlab.com/grouperenault/git_cdn"
	["module_git_cdn,group"]="Utilities"
	["module_git_cdn,port"]="8000"
	["module_git_cdn,arch"]="x86-64"
	["module_git_cdn,dockerimage"]="registry.gitlab.com/grouperenault/git_cdn:latest"
	["module_git_cdn,dockername"]="git_cdn"
	["module_git_cdn,upstream"]="https://github.com/"
)
#
# Module git_cdn — git+http(s) caching proxy / CDN (Groupe Renault)
#
function module_git_cdn () {
	local title="git_cdn"
	local dockerimage="${module_options["module_git_cdn,dockerimage"]}"
	local dockername="${module_options["module_git_cdn,dockername"]}"
	local port="${module_options["module_git_cdn,port"]}"
	local upstream="${module_options["module_git_cdn,upstream"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_git_cdn,example"]}"

	local base_dir="${SOFTWARE_FOLDER}/${dockername}"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the cache bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			# git_cdn mirrors a single upstream git server (GITSERVER_UPSTREAM)
			# and caches it under WORKING_DIRECTORY, served over http on :8000.
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--init \
				--net=lsio \
				--restart=always \
				--publish "${port}:8000" \
				--env GITSERVER_UPSTREAM="$upstream" \
				--env WORKING_DIRECTORY="/git-data" \
				--volume "${base_dir}/cache:/git-data" \
				"$dockerimage"

			local install_msg="git_cdn is proxying ${upstream} on port ${port}\n\nPoint git at this server on each consumer host:\n\n  git config --global url.\"http://${LOCALIPADD}:${port}/\".insteadOf ${upstream}\n\nThen clone GitHub repos as usual — fetches are served from the local cache:\n\n  git clone ${upstream}<owner>/<repo>.git"

			if [[ -t 1 ]]; then
				dialog_msgbox "git_cdn installed" "$install_msg" 16 70
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
			if ! ${module_options["module_git_cdn,feature"]} ${commands[1]}; then
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
			show_module_help "module_git_cdn" "$title" \
				"Caching git+http(s) proxy / CDN that mirrors one upstream git server near your CI workers, reducing WAN usage on repeated clones.\n\nUpstream: ${upstream}\nProxy port: ${port}\nDocker Image: ${dockerimage}\nCache directory: ${base_dir}/cache\n\nNote: the upstream image is x86-64 only.\n\nClient configuration — on each git host:\n  git config --global url.\"http://<server>:${port}/\".insteadOf ${upstream}\n\nThen clone normally:\n  git clone ${upstream}<owner>/<repo>.git"
		;;
		*)
			${module_options["module_git_cdn,feature"]} ${commands[4]}
		;;
	esac
}
