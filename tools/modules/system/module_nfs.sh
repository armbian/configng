module_options+=(
	["module_nfs,author"]="@igorpecovnik"
	["module_nfs,feature"]="module_nfs"
	["module_nfs,desc"]="Install nfs client"
	["module_nfs,example"]="install remove servers help"
	["module_nfs,port"]=""
	["module_nfs,status"]="Active"
	["module_nfs,arch"]=""
)
#
# Module nfs client
#
function module_nfs () {
	local title="nfs"
	local condition=$(which "$title" 2>/dev/null)?

	local package_name=nfs-common

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfs,example"]}"

	nfs_BASE="${SOFTWARE_FOLDER}/nfs"

	case "$1" in
		"${commands[0]}")
			apt_install_wrapper apt-get -y install $package_name
		;;
		"${commands[1]}")
			apt_install_wrapper apt-get -y autopurge $package_name
		;;
		"${commands[2]}")

			if ! check_if_installed nmap; then
				apt_install_wrapper apt-get -y install nmap
			fi

			LIST=($(nmap -oG - -p2049 ${LOCALSUBNET} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there
					LIST=($(showmount -e "${nfs_server}" | tail -n +2 | cut -d" " -f1 | sort))
					VERIFIED_LIST=()
					local tempfolder=$(mktemp -d)
					local alreadymounted=$(df | grep $nfs_server | cut -d" " -f1 | xargs)
					for i in "${LIST[@]}"; do
						mount -n -t nfs $nfs_server:$i ${tempfolder} 2>/dev/null
						if [[ $? -eq 0 ]]; then
							if echo "${alreadymounted}" | grep -vq $i; then
							VERIFIED_LIST+=($i)
							fi
							umount ${tempfolder}
						fi
					done
					VERIFIED_LIST_LENGTH=$((${#VERIFIED_LIST[@]}))
					if shares=$(dialog --no-items \
						--title "Network filesystem (NFS) shares on ${nfs_server}" \
						--menu "" \
						$((${VERIFIED_LIST_LENGTH} + 6)) \
						80 \
						$((${VERIFIED_LIST_LENGTH})) \
						${VERIFIED_LIST[@]} 3>&1 1>&2 2>&3)
						then
							if mount_folder=$(dialog --title \
							"Where do you want to mount $shares ?" \
							--inputbox "" \
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
								if mount_options=$(dialog --title \
								"Which mount options do you want to use?" \
							--inputbox "" \
							6 80 "auto,noatime 0 0" 3>&1 1>&2 2>&3); then
								mkdir -p ${mount_folder}
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								systemctl daemon-reload
								mount ${mount_folder}
								show_message <<< $(mount -t nfs4 | cut -d" " -f1)
							fi
							fi
						fi
					fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_nfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tservers\t- Find and mount shares $title."
			echo
		;;
		*)
			${module_options["module_nfs,feature"]} ${commands[3]}
		;;
	esac
}
