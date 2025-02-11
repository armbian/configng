module_options+=(
	["module_nfsd,author"]="@igorpecovnik"
	["module_nfsd,feature"]="module_nfsd"
	["module_nfsd,desc"]="Install nfsd server"
	["module_nfsd,example"]="install remove manage add status clients servers help"
	["module_nfsd,port"]=""
	["module_nfsd,status"]="Active"
	["module_nfsd,arch"]=""
)
#
# Module nfsd
#
function module_nfsd () {
	local title="nfsd"
	local condition=$(which "$title" 2>/dev/null)?

	local service_name=nfs-server.service

	# we will store our config in subfolder
	mkdir -p /etc/exports.d/

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfsd,example"]}"

	NFSD_BASE="${SOFTWARE_FOLDER}/nfsd"

	case "$1" in
		"${commands[0]}")
			pkg_install nfs-common nfs-kernel-server
			# add some exports
			${module_options["module_nfsd,feature"]} ${commands[2]}
			srv_restart $service_name
		;;
		"${commands[1]}")
			pkg_remove nfs-kernel-server
		;;
		"${commands[2]}")
			while true; do
				LIST=() IFS=$'\n' LIST=($(grep "^[^#;]" /etc/exports.d/armbian.exports))
				LIST_LENGTH=${#LIST[@]}
				if [[ "${LIST_LENGTH}" -ge 1 ]]; then
					line=$(dialog --no-items \
					--title "Select export to edit" \
					--ok-label "Add" \
					--cancel-label "Apply" \
					--extra-button \
					--extra-label "Delete" \
					--menu "" \
					$((${LIST_LENGTH} + 6)) \
					80 \
					$((${LIST_LENGTH})) \
					${LIST[@]} 3>&1 1>&2 2>&3)
					exitstatus=$?
					case "$exitstatus" in
						0)
							${module_options["module_nfsd,feature"]} ${commands[3]}
						;;
						1)
							break
						;;
						3)
							sed -i '\?^'$line'?d' /etc/exports.d/armbian.exports
						;;
					esac
				else
					${module_options["module_nfsd,feature"]} ${commands[3]}
					break
				fi
			done
			srv_restart $service_name
		;;
		"${commands[3]}")
			# choose between most common options
			LIST=()
			LIST=("ro" "Allow read only requests" On)
			LIST+=("rw" "Allow read and write requests" OFF)
			LIST+=("sync" "Immediate sync all writes" On)
			LIST+=("fsid=0" "Check man pages" OFF)
			LIST+=("no_subtree_check" "Disables subtree checking, improves reliability" On)
			LIST_LENGTH=$((${#LIST[@]}/3))
			if add_folder=$(dialog --title \
							"Which folder do you want to export?" \
							--inputbox "" \
							6 80 "${SOFTWARE_FOLDER}" 3>&1 1>&2 2>&3); then
				if add_ip=$(dialog --title \
							"Which IP or range can access this folder?" \
							--inputbox "\nExamples: 192.168.1.1, 192.168.1.0/24" \
							8 80 "${LOCALSUBNET}" 3>&1 1>&2 2>&3); then
					if add_options=$(dialog --separate-output \
							--nocancel \
							--title "NFS volume options" \
							--checklist "" \
							$((${LIST_LENGTH} + 6)) 80 ${LIST_LENGTH} "${LIST[@]}" 3>&1 1>&2 2>&3); then
							echo "$add_folder $add_ip($(echo $add_options | tr ' ' ','))" \
							>> /etc/exports.d/armbian.exports
							[[ -n "${add_folder}" ]] && mkdir -p "${add_folder}"
					fi
				fi
			fi
		;;
		"${commands[4]}")
			pkg_installed nfs-kernel-server
		;;
		"${commands[5]}")
			show_message <<< $(printf '%s\n' "${NFS_CLIENTS_CONNECTED[@]}")
		;;
		"${commands[6]}")

			if ! pkg_installed nmap; then
				pkg_install nmap
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
								read
								sed -i '\?^'$nfs_server:$shares'?d' /etc/fstab
								echo "${nfs_server}:${shares} ${mount_folder} nfs ${mount_options}" >> /etc/fstab
								srv_daemon_reload
								mount ${mount_options}
							fi
							fi
						fi
					fi
		;;
		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_nfsd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_nfsd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tmanage\t- Edit exports in $title."
			echo -e "\tadd\t- Add exports to $title."
			echo -e "\tstatus\t- Installation status $title."
			echo -e "\tremove\t- Remove $title."
			echo
		;;
		*)
			${module_options["module_nfsd,feature"]} ${commands[7]}
		;;
	esac
}
