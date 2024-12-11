module_options+=(
	["module_armbian_firmware,author"]="@igorpecovnik"
	["module_armbian_firmware,feature"]="module_armbian_firmware"
	["module_armbian_firmware,example"]="select install show hold unhold repository headers help"
	["module_armbian_firmware,desc"]="Module for Armbian firmware manipulating."
	["module_armbian_firmware,status"]="review"
)

function module_armbian_firmware() {
	local title="Armbian FW"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_firmware,example"]}"

	case "$1" in
		"${commands[0]}") # choose kernel from the list

			# We are updating beta packages repository quite often. In order to make sure, update won't break, always update package list
			apt_install_wrapper	apt-get update

			# make sure to proceed if this variable is not defined. This can surface on some old builds
			[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,vendor,current,edge"

			# show warning when packages are put on hold and ask to release it
			if ${module_options["module_armbian_firmware,feature"]} ${commands[3]} "status"; then
				if $DIALOG --title "Warning!" --yesno "Firmware upgrade is disabled. Release hold and proceed?" 7 60; then
					${module_options["module_armbian_firmware,feature"]} ${commands[4]}
				else
					exit 0
				fi
			fi

			# by default we define which kernels are suitable
			if ! $DIALOG --title "Advanced options" --yesno "Show only mainstream kernels on the list?" 7 60; then
				KERNEL_TEST_TARGET="legacy,vendor,current,edge"
			fi

			# read what is possible to install
			local kernel_test_target=$(\
				for kernel_test_target in ${KERNEL_TEST_TARGET//,/ }
				do
					echo "linux-image-${kernel_test_target}-${LINUXFAMILY}"
				done
				)
			local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}' | head -1)

			# workaroun in case current is not installed
			[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"

			# main search command
			local search_exec="apt-cache show ${kernel_test_target} \
			| grep -E \"Package:|Version:|version:|family\" \
			| grep -v \"Config-Version\" \
			| sed -n -e 's/^.*: //p' \
			| sed 's/\.$//g' \
			| xargs -n3 -d'\n' \
			| sed \"s/ /=/\" $grep_current_kernel"

			# construct a list of kernels with their Armbian release versions and kernel version
			IFS=$'\n'
			local LIST=()
			for line in $(eval ${search_exec}); do
				LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
			done
			unset IFS

			# generate selection menu
			local list_length=$((${#LIST[@]} / 2))
			if [ "$list_length" -eq 0 ]; then
				$DIALOG --backtitle "$BACKTITLE" --title " Warning " --msgbox "No other kernels available!" 7 31
			else
				if target_version=$(\
						$DIALOG \
						--separate-output \
						--title "Select kernel" \
						--menu "" \
						$((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" \
						3>&1 1>&2 2>&3)
				then
					# extract branch
					local branch=${target_version##*image-}
					# call install function
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch%%-*}" "${target_version/*=/}"
				fi
			fi

		;;

		"${commands[1]}") # purge old and install new packages from desired branch and version

			# input parameters
			local branch=$2
			local version=$3
			local hide=$3
			local headers=$5

			# generate list
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${branch}" "${version}" "hide" "" "$headers"

			# purge and install
			for pkg in ${packages[@]}; do
				purge_pkg=$(echo $pkg | sed -e 's/linux-image.*/linux-image*/;s/linux-dtb.*/linux-dtb*/;s/linux-headers.*/linux-headers*/;s/armbian-firmware.*/armbian-firmware*/')
				# if test install is succesfull, proceed
				apt_install_wrapper apt-get -y --simulate --download-only --allow-downgrades install "${pkg}"
				if [[ $? == 0 ]]; then
					apt_install_wrapper	apt-get -y purge "${purge_pkg}"
					apt_install_wrapper apt-get --allow-downgrades -y install "${pkg}"
				fi
			done
			if [[ -z "${headers}" ]]; then
				if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
					"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
					reboot
				fi
			fi


		;;
		"${commands[2]}") # generate a list of possible packages to install

			# input parameters
			local branch="$2"
			local version="$3"
			local hide="$4"
			local repository="$5"
			local headers="$6"

			# if branch is not defined, we use the one that is currently installed
			[[ -z $branch ]] && local branch=$BRANCH
			[[ -z $BRANCH ]] && local branch="current"

			# if repository is not defined, we use stable one
			[[ -z $repository ]] && local repository="apt.armbian.com"

			# select Armbian packages we want to searching for
			armbian_packages=(
				"linux-image-${branch}-${LINUXFAMILY}"
				"linux-dtb-${branch}-${LINUXFAMILY}"
			)

			# install full firmware if it was installed previously
			if dpkg -l | grep -E "armbian-firmware-full" >/dev/null; then
				armbian_packages+=("armbian-firmware-full")
				else
				armbian_packages+=("armbian-firmware")
			fi

			# install headers only if they were previously installed
			if dpkg -l | grep -E "linux-headers" >/dev/null; then
				armbian_packages+=("linux-headers-${branch}-${LINUXFAMILY}")
			fi

			# only install headers if parameter headers == true
			if  [[ "${headers}" == true ]]; then
				armbian_packages=("linux-headers-${branch}-${LINUXFAMILY}")
				armbian_packages+=(
									"build-essential"
									"git"
									)
			fi

			# when we select a specific version of Armbian, we need to make sure that version exists
			# for each package we want to install. In case desired version does not exists, it installs
			# package without specifying version. This prevent breaking install in case some
			# package version was removed from repository. Just in case.
			packages=""
			for pkg in ${armbian_packages[@]}; do
				# use package + version if found else use package if found
				if apt-cache show "$pkg" 2> /dev/null \
					| grep -E "Package:|^Version:|family" \
					| sed -n -e 's/^.*: //p' \
					| sed 's/\.$//g' \
					| xargs -n2 -d'\n' \
					| grep ${pkg} | grep -e ${version} >/dev/null 2>&1; then
					packages+="${pkg}=${version} ";
				elif
					apt-cache show "$pkg" 2> /dev/null \
					| grep -E "Package:|^Version:|family" \
					| sed -n -e 's/^.*: //p' \
					| sed 's/\.$//g' \
					| xargs -n2 -d'\n' \
					| grep "${pkg}" >/dev/null 2>&1 ; then
					packages+="${pkg} ";
				fi
			done

			# if this is called with a parameter hide, we only prepare this list but don't show its content
			[[ "$4" != "hide" ]] && echo ${packages[@]}

		;;
		"${commands[3]}") # holds Armbian firmware packages or provides status

			# input parameter
			local status=$2

			# generate a list of packages
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# we are only interested in which Armbian packages are put on hold
			if [[ "$status" == "status" ]]; then
				local get_hold=($(apt-mark showhold))
				local test_hold=($(for all_packages in ${packages[@]}; do
					for hold_packages in ${get_hold[@]}; do
					echo $all_packages | grep $hold_packages
					done
				done))
			[[ -z ${test_hold[@]} ]] && return 1 || return 0
			else
				# put Armbian packages on hold
				apt-mark hold ${packages[@]} >/dev/null 2>&1
			fi

		;;
		"${commands[4]}") # unhold Armbian firmware packages

			# generate a list of packages
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# release Armbian packages from hold
			apt-mark unhold ${packages[@]} >/dev/null 2>&1

		;;
		"${commands[5]}") # switches repository to rolling / stable and performs update or provides status

			# input parameters

			local repository=$2
			local status=$3

			if grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list; then
				if [[ "$repository" == "rolling" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "rolling" ]]; then
					sed -i "s/http:\/\/[^ ]*/http:\/\/beta.armbian.com/" /etc/apt/sources.list.d/armbian.list
					apt_install_wrapper	apt-get update
				fi
			else
				if [[ "$repository" == "stable" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "stable" ]]; then
					sed -i "s/http:\/\/[^ ]*/http:\/\/apt.armbian.com/" /etc/apt/sources.list.d/armbian.list
					apt_install_wrapper	apt-get update
				fi
			fi

			# if we are not only checking status, it reinstall firmware automatically
			[[ "$status" != "status" ]] && ${module_options["module_armbian_firmware,feature"]} ${commands[1]}
		;;

		"${commands[6]}") # installs kernel headers

			# input parameters
			local command=$2
			local version=$3

			# if version is not set, use the one from installed kernel
			if [[ "${command}" == "install" ]]; then
				if [[ -f /etc/armbian-release ]]; then
					[[ -z "${version}" ]] && version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $3}')
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "" "${version}" "" "true"
				else
					# for non armbian builds
					apt_install_wrapper apt-get install "linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
				fi
			elif [[ "${command}" == "remove" ]]; then
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "${version}" "hide" "" "true"
				apt_install_wrapper apt-get -y autopurge ${packages[@]}
			else
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "${version}" "hide" "" "true"
				if check_if_installed ${packages[@]}; then
					return 0
				else
					return 1
				fi
			fi

		;;


		"${commands[7]}")
			echo -e "\nUsage: ${module_options["module_armbian_firmware,feature"]} <command> <switches>"
			echo -e "Commands:  ${module_options["module_armbian_firmware,example"]}"
			echo "Available commands:"
			echo -e "\tselect    \t- TUI to select $title.              \t switches: [ stable | rolling ]"
			echo -e "\tinstall   \t- Install $title.                    \t switches: [ \$branch | \$version ]"
			echo -e "\tshow      \t- Show $title packages.              \t switches: [ \$branch | \$version | hide ]"
			echo -e "\thold      \t- Mark $title packages as held back. \t switches: [status] returns true or false"
			echo -e "\tunhold    \t- Unset $title packages set as held back."
			echo -e "\trepository\t- Selects repository and performs update. \t switches: [ stable | rolling ]"
			echo -e "\theaders   \t- Kernel headers management.         \t switches: [ install | remove | status ]"
			echo
		;;
		*)
		${module_options["module_armbian_firmware,feature"]} ${commands[7]}
		;;
	esac
}
