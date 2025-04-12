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

	# BRANCH, KERNELPKG_VERSION, KERNELPKG_LINUXFAMILY may require being updated after kernel switch
	update_kernel_env

	case "$1" in

		# choose kernel from the list
		"${commands[0]}")

			# We are updating beta packages repository quite often. In order to make sure, update won't break, always update package list

			pkg_update

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
			if ! $DIALOG --title "Advanced options" --yesno --defaultno "Show only mainstream kernels on the list?" 7 60; then
				KERNEL_TEST_TARGET="legacy,vendor,current,edge"
			fi

			# read what is possible to install
			local kernel_test_target=$(\
				for kernel_test_target in ${KERNEL_TEST_TARGET//,/ }
				do
					# Exception for Rockchip
					if [[ "${BOARDFAMILY}" == "rockchip-rk3588" ]]; then
						if [[ "${kernel_test_target}" == "vendor" ]]; then
							echo "linux-image-${kernel_test_target}-rk35xx"
						elif [[ "${kernel_test_target}" =~ ^(current|edge)$ ]]; then
							echo "linux-image-${kernel_test_target}-rockchip64"
						fi
					else
						echo "linux-image-${kernel_test_target}-${LINUXFAMILY}"
					fi
				done
				)
			local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}' | head -1)

			# workaround in case current is not installed
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
					local branch=$(echo "${target_version}" | cut -d'-' -f3)
					local linuxfamily=$(echo "${target_version}" | cut -d'-' -f4 | cut -d'=' -f1)
					# call install function
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "${target_version/*=/}" "" "" "${linuxfamily}"
				fi
			fi

		;;

		# purge old and install new packages from desired branch and version
		"${commands[1]}")

			# We are updating beta packages repository quite often. In order to make sure, update won't break, always update package list
			pkg_update

			cat > "/etc/apt/preferences.d/armbian-upgrade-policy" <<- EOT
			Package: armbian-bsp* armbian-firmware* linux-*
			Pin: release a=${DISTROID}
			Pin-Priority: 1001
			EOT
			trap '{ rm -f -- "/etc/apt/preferences.d/armbian-upgrade-policy"; }' EXIT

			# input parameters
			local branch=$2
			local version="$( echo $3 | tr -d '\011\012\013\014\015\040')" # remove tabs and spaces from version
			local hide=$4
			local headers=$5
			local linuxfamily=$6

			# generate list
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${branch}" "${version}" "hide" "" "$headers" "$linuxfamily"

			# purge and install
			for pkg in ${packages[@]}; do
				# if test install is succesfull, proceed
				if [[ -z $(LC_ALL=C apt-get install --simulate --download-only --allow-downgrades --reinstall "${pkg}" 2>/dev/null | grep "not possible") ]]; then
					purge_pkg=$(echo $pkg | sed -e 's/linux-image.*/linux-image*/;s/linux-dtb.*/linux-dtb*/;s/linux-headers.*/linux-headers*/;s/armbian-firmware-*/armbian-firmware*/')
					pkg_remove "${purge_pkg}"
					pkg_install --allow-downgrades "${pkg}"
				else
					echo "Error: Package ${pkg} install not possible due to network / repository problem. Try again later and report to Armbian forums"
					exit 0
				fi
			done
			# at the end, also switch bsp
			# if branch is not defined, we use the one that is currently installed
			#[[ -z $branch ]] && local branch=$BRANCH
			#[[ -z $BRANCH ]] && local branch="current"
			#local bsp=$(dpkg -l | grep -E "armbian-bsp-cli" | awk '{print $2}' | sed "s/legacy\|vendor\|current\|edge/${branch}/g")
			#if apt-get install --simulate --download-only --allow-downgrades --reinstall "${bsp}" > /dev/null 2>&1; then
			#	pkg_remove "armbian-bsp-cli*"
			#	pkg_install --allow-downgrades "${bsp}"
			#fi
			# remove upgrade policy
			rm -f /etc/apt/preferences.d/armbian-upgrade-policy
			if test -t 0 && [[ "${headers}" != "true" ]]; then
				if $DIALOG --title " Reboot required " --yes-button "Reboot" --no-button "Cancel" --yesno \
					"A reboot is required to apply the changes. Shall we reboot now?" 7 34; then
					reboot
				fi
			fi
		;;

		# generate a list of possible packages to install
		"${commands[2]}")

			# input parameters
			local branch="${2:-$BRANCH}"
			local version="$( echo $3 | tr -d '\011\012\013\014\015\040')" # remove tabs and spaces from version
			local hide="$4"
			local repository="$5"
			local headers="$6"
			local linuxfamily="${7:-$KERNELPKG_LINUXFAMILY}"

			# if repository is not defined, we use stable one
			[[ -z $repository ]] && local repository="apt.armbian.com"

			# select Armbian packages we want to searching for
			armbian_packages=(
				"linux-image-${branch}-${linuxfamily}"
				"linux-dtb-${branch}-${linuxfamily}"
			)

			# install full firmware if it was installed previously
			#if dpkg -l | grep -E "armbian-firmware-full" >/dev/null; then
			#	armbian_packages+=("armbian-firmware-full")
			#	else
			#	armbian_packages+=("armbian-firmware")
			#fi

			# install headers only if they were previously installed
			if dpkg -l | grep -E "linux-headers" >/dev/null; then
				armbian_packages+=("linux-headers-${branch}-${linuxfamily}")
			fi

			# only install headers if parameter headers == true
			if  [[ "${headers}" == true ]]; then
				armbian_packages=("linux-headers-${branch}-${linuxfamily}")
			fi

			# when we select a specific version of Armbian, we need to make sure that version exists
			# for each package we want to install. In case desired version does not exists, it installs
			# package without specifying version. This prevent breaking install in case some
			# package version was removed from repository. Just in case.
			packages=""
			for pkg in ${armbian_packages[@]}; do

				# look into cache
				local cache_show=$(apt-cache show "$pkg" 2> /dev/null | grep -E "Package:|^Version:|family" \
					| sed -n -e 's/^.*: //p' \
					| sed 's/\.$//g' \
					| xargs -n2 -d'\n' \
					| grep "${pkg}")

				# use package + version if found else use package if found
				if [[ -n "${version}" && -n "${cache_show}" ]]; then
					if [[ -n $(echo "$cache_show" | grep "$version""$" ) ]]; then
						packages+="${pkg}=${version} ";
					fi
				elif [[ -n "${cache_show}" ]]; then
					packages+="${pkg} ";
				fi
			done

			# if this is called with a parameter hide, we only prepare this list but don't show its content
			[[ "$4" != "hide" ]] && echo ${packages[@]}

		;;

		# holds Armbian firmware packages or provides status
		"${commands[3]}")

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

		# unhold Armbian firmware packages
		"${commands[4]}")

			# generate a list of packages
			${module_options["module_armbian_firmware,feature"]} ${commands[2]} "" "" hide

			# release Armbian packages from hold
			apt-mark unhold ${packages[@]} >/dev/null 2>&1

		;;

		# switches repository to rolling / stable and performs update or provides status
		"${commands[5]}")

			# input parameters
			local repository=$2
			local status=$3

			local branch=${BRANCH}
			local linuxfamily=${LINUXFAMILY:-$KERNELPKG_LINUXFAMILY}

			local sources_files=()
			for file in "/etc/apt/sources.list.d/armbian.list" "/etc/apt/sources.list.d/armbian.sources"; do
				[[ -e "$file" ]] && sources_files+=("$file")
			done

			if grep -q 'apt.armbian.com' "${sources_files[@]}"; then
				if [[ "$repository" == "rolling" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "rolling" ]]; then
					sed -i 's|[a-zA-Z0-9.-]*\.armbian\.com|beta.armbian.com|g' "${sources_files[@]}"
					pkg_update
				fi
			else
				if [[ "$repository" == "stable" && "$status" == "status" ]]; then
					return 1
				elif [[ "$status" == "status" ]]; then
					return 0
				fi
				# performs list change & update if this is needed
				if [[ "$repository" == "stable" ]]; then
					sed -i 's|[a-zA-Z0-9.-]*\.armbian\.com|apt.armbian.com|g' "${sources_files[@]}"
					pkg_update
				fi
			fi

			# if we are not only checking status, it reinstall firmware automatically
			[[ "$status" != "status" ]] && ${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${branch}" "" "" "" "${linuxfamily}"
		;;

		# installs kernel headers
		"${commands[6]}")

			# input parameters
			local command=$2
			local version=${3:-$KERNELPKG_VERSION}

			if [[ "${command}" == "install" ]]; then
				if [[ -f /etc/armbian-image-release ]]; then
					# for armbian OS
					${module_options["module_armbian_firmware,feature"]} ${commands[1]} "${BRANCH}" "${version}" "" "true" "${KERNELPKG_LINUXFAMILY}"
				else
					# for non armbian builds
					pkg_install "linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')"
				fi
			elif [[ "${command}" == "remove" ]]; then
				# remove headers packages
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${BRANCH}" "${version}" "hide" "" "true" "${KERNELPKG_LINUXFAMILY}"
				if [ "${#packages[@]}" -gt 0 ]; then
					if dpkg -l | grep -qw ${packages[@]/=*/}; then
						pkg_remove ${packages[@]/=*/}
					fi
				fi
			else
				# return 0 if packages are installed else 1
				${module_options["module_armbian_firmware,feature"]} ${commands[2]} "${BRANCH}" "${version}" "hide" "" "true" "${KERNELPKG_LINUXFAMILY}"
				if pkg_installed ${packages[@]/=*/}; then
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
			echo -e "\theaders   \t- Kernel headers management.         \t\t switches: [ install | remove | status ]"
			echo
		;;
		*)
			${module_options["module_armbian_firmware,feature"]} ${commands[7]}
		;;
	esac
}
