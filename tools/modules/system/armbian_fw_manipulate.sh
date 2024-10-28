module_options+=(
	["armbian_fw_manipulate,author"]="@igorpecovnik"
	["armbian_fw_manipulate,ref_link"]=""
	["armbian_fw_manipulate,feature"]="armbian_fw_manipulate"
	["armbian_fw_manipulate,desc"]="freeze, unhold, reinstall armbian related packages."
	["armbian_fw_manipulate,example"]="armbian_fw_manipulate unhold/freeze/reinstall"
	["armbian_fw_manipulate,status"]="Active"
)
#
# freeze/unhold/reinstall armbian firmware packages
#
armbian_fw_manipulate() {

	local function=$1
	local version=$2
	local branch=$3

	[[ -n $version ]] && local version="=${version}"

	# fallback to $BRANCH
	[[ -z "${branch}" ]] && branch="${BRANCH}"
	[[ -z "${branch}" ]] && branch="current" # fallback in case we switch to very old BSP that have no such info

	# packages to install
	local armbian_packages=(
		"linux-u-boot-${BOARD}-${branch}"
		"linux-image-${branch}-${LINUXFAMILY}"
		"linux-dtb-${branch}-${LINUXFAMILY}"
		"armbian-zsh"
		"armbian-bsp-cli-${BOARD}-${branch}"
	)

	# reinstall headers only if they were previously installed
	if are_headers_installed; then
		local armbian_packages+="linux-headers-${branch}-${LINUXFAMILY}"
	fi

	local packages=""
	for pkg in "${armbian_packages[@]}"; do
		if [[ "${function}" == reinstall ]]; then
			local pkg_search=$(apt search "$pkg" 2> /dev/null | grep "^$pkg")
			if [[ $? -eq 0 && -n "${pkg_search}" ]]; then
				if [[ "${pkg_search}" == *$version* ]] ; then
				packages+="$pkg${version} ";
				else
				packages+="$pkg ";
				fi
			fi
		else
			if check_if_installed $pkg; then
				packages+="$pkg${version} "
			fi
		fi
	done
	for pkg in "${packages[@]}"; do
		case $function in
			unhold) apt-mark unhold ${pkg} | show_infobox ;;
			hold) apt-mark hold ${pkg} | show_infobox ;;
			reinstall)
				apt_install_wrapper apt-get -y --simulate --download-only --allow-change-held-packages --allow-downgrades install ${pkg}
				if [[ $? == 0 ]]; then
					apt_install_wrapper apt-get -y purge "linux-u-boot-*" "linux-image-*" "linux-dtb-*" "linux-headers-*" "armbian-zsh-*" "armbian-bsp-cli-*" # remove all branches
					apt_install_wrapper apt-get -y --allow-change-held-packages install ${pkg}
					apt_install_wrapper apt-get -y autoremove
					apt_install_wrapper apt-get -y clean
				else
					exit 1
				fi


				;;
			*) return ;;
		esac
	done
}

