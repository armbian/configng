module_options+=(
	["module_nfsd,author"]="@igorpecovnik"
	["module_nfsd,feature"]="module_nfsd"
	["module_nfsd,desc"]="Install nfsd server"
	["module_nfsd,example"]="install remove manage add status help"
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

	local package_name=nfs-kernel-server
	local service_name=nfs-server.service

	# we will store our config in subfolder
	mkdir -p /etc/exports.d/

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_nfsd,example"]}"

	NFSD_BASE="${SOFTWARE_FOLDER}/nfsd"

	case "$1" in
		"${commands[0]}")
			apt_install_wrapper apt-get -y install $package_name
			# add some exports
			${module_options["module_nfsd,feature"]} ${commands[2]}
			service restart $service_name
		;;
		"${commands[1]}")
			apt_install_wrapper apt-get -y autopurge $package_name
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
			service restart $service_name
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
							6 80 "/armbian" 3>&1 1>&2 2>&3); then
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
					fi
				fi
			fi
		;;
		"${commands[4]}")
			check_if_installed $package_name
		;;
		"${commands[5]}")
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
			${module_options["module_nfsd,feature"]} ${commands[5]}
		;;
	esac
}
