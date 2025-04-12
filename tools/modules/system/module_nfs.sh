module_options+=(
	["module_nfs,author"]="@igorpecovnik"
	["module_nfs,feature"]="module_nfs"
	["module_nfs,desc"]="Install nfs client"
	["module_nfs,example"]="install remove servers mounts help"
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

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfs,example"]}"

	nfs_BASE="${SOFTWARE_FOLDER}/nfs"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common
		;;
		"${commands[1]}")
			pkg_remove nfs-common
		;;
		"${commands[2]}")

			if ! pkg_installed nmap; then pkg_install nmap; fi
			if ! pkg_installed nfs-common; then pkg_install nfs-common; fi

			local subnet=$($DIALOG --title "Choose subnet to search for NFS server" --inputbox "\nValid format: <IP Address>/<Subnet Mask Length>" 9 60 "${LOCALSUBNET}" 3>&1 1>&2 2>&3)
			LIST=($(nmap -oG - -p2049 ${subnet} | grep '/open/' | cut -d' ' -f2 | grep -v "${LOCALIPADD}"))
			LIST_LENGTH=$((${#LIST[@]}))
			if nfs_server=$(dialog --no-items \
				--title "Network filesystem (NFS) servers in subnet" \
				--menu "" \
				$((${LIST_LENGTH} + 6)) \
				80 \
				$((${LIST_LENGTH})) \
				${LIST[@]} 3>&1 1>&2 2>&3); then
					# verify if we can connect there. adding timeout kill as it can hang if server doesn't share to this client
					LIST=($(timeout --kill 10s 5s showmount -e "${nfs_server}" 2>/dev/null | tail -n +2 | cut -d" " -f1 | sort))
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
								srv_daemon_reload
								mount ${mount_folder}
								show_message <<< $(mount -t nfs4 | cut -d" " -f1)
							fi
							fi
						fi
					fi
		;;
		"${commands[3]}")
			local list=($(mount --type=nfs4 | cut -d" " -f1))
			if shares=$(dialog --no-items \
						--title "Mounted NFS shares" \
						--menu "" \
						$((${#list[@]} + 6)) \
						80 \
						$((${#list[@]})) \
						${list[@]} 3>&1 1>&2 2>&3); then
						echo "Chosen $mount"
			read
			fi
		;;
		"${commands[4]}")
			echo -e "\nUsage: ${module_options["module_nfs,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfs,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tservers\t- Find and mount shares $title."
			echo
		;;
		*)
			${module_options["module_nfs,feature"]} ${commands[4]}
		;;
	esac
}
