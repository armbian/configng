#
# Install plexmediaserver using apt
#
module_plexmediaserver() {
	local title="plexmediaserver"
	local condition=$(which "$title" 2>/dev/null)

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_plexmediaserver,example"]}"

	case "$1" in
		"${commands[0]}")
			if [ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]; then
				echo "deb [arch=$(dpkg --print-architecture) \
				signed-by=/usr/share/keyrings/plexmediaserver.gpg] https://downloads.plex.tv/repo/deb public main" \
				| sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			else
				sed -i "/downloads.plex.tv/s/^#//g" /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1
			fi
			# Note: for compatibility with existing source file in some builds format must be gpg not asc
			# and location must be /usr/share/keyrings
			wget -qO- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor \
			| sudo tee /usr/share/keyrings/plexmediaserver.gpg > /dev/null 2>&1
			pkg_update
			pkg_install plexmediaserver
		;;
		"${commands[1]}")
			sed -i '/plexmediaserver.gpg/s/^/#/g' /etc/apt/sources.list.d/plexmediaserver.list
			pkg_remove plexmediaserver
		;;
		"${commands[2]}")
			if pkg_installed plexmediaserver; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_portainer,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_portainer,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_plexmediaserver,feature"]} ${commands[3]}
		;;
	esac
}
