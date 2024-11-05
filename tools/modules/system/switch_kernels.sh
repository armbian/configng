module_options+=(
	["switch_kernels,author"]="@igorpecovnik"
	["switch_kernels,ref_link"]=""
	["switch_kernels,feature"]="switch_kernels"
	["switch_kernels,desc"]="Switching to alternative kernels"
	["switch_kernels,example"]="switch_kernels"
	["switch_kernels,status"]="Active"
)
#
# @description Switch between alternative kernels
#
function switch_kernels() {

	# we only allow switching kerneles that are in the test pool
	[[ -z "${KERNEL_TEST_TARGET}" ]] && KERNEL_TEST_TARGET="legacy,current,edge"
	local kernel_test_target=$(for x in ${KERNEL_TEST_TARGET//,/ }; do echo "linux-image-$x-${LINUXFAMILY}"; done;)
	local installed_kernel_version=$(dpkg -l | grep '^ii' | grep linux-image | awk '{print $2"="$3}')
	# just in case current is not installed
	[[ -n ${installed_kernel_version} ]] && local grep_current_kernel=" | grep -v ${installed_kernel_version}"
	local search_exec="apt-cache show ${kernel_test_target} | grep -E \"Package:|Version:|version:|family\" | grep -v \"Config-Version\" | sed -n -e 's/^.*: //p' | sed 's/\.$//g' | xargs -n3 -d'\n' | sed \"s/ /=/\" $grep_current_kernel"
	IFS=$'
'
	local LIST=()
	for line in $(eval ${search_exec}); do
		LIST+=($(echo $line | awk -F ' ' '{print $1 "      "}') $(echo $line | awk -F ' ' '{print "v"$2}'))
	done
	unset IFS
	local list_length=$((${#LIST[@]} / 2))
	if [ "$list_length" -eq 0 ]; then
		dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "No other kernels available!" 7 32
	else
		local target_version=$(whiptail --separate-output --title "Select kernel" --menu "ed" $((${list_length} + 7)) 80 $((${list_length})) "${LIST[@]}" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ -n "${target_version}" ]; then
			local branch=${target_version##*image-}
			armbian_fw_manipulate "reinstall" "${target_version/*=/}" "${branch%%-*}"
		fi
	fi
}

